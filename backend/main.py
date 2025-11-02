"""
PDFGrabber Web API
FastAPI backend for PDFGrabber web interface
"""

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from pydantic import BaseModel
from typing import Optional, Dict, List
import sys
import os
from pathlib import Path
import json
import asyncio
import queue
import threading

# Add parent directory to path to import PDFGrabber modules
sys.path.insert(0, str(Path(__file__).parent.parent))

import utils
import config as config_module

app = FastAPI(
    title="PDFGrabber API",
    description="Web API for PDFGrabber - Download your digital books",
    version="2.0.0"
)

# Enable CORS for frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load config
config = config_module.getconfig()

# Models
class LoginRequest(BaseModel):
    username: str
    password: str

class TokenRequest(BaseModel):
    token: str

class DownloadRequest(BaseModel):
    service: str
    token: str
    book_ids: List[str]

# Active WebSocket connections for progress updates
active_connections: Dict[str, WebSocket] = {}


# ============== ENDPOINTS ==============

@app.get("/")
async def root():
    """API root endpoint"""
    return {
        "name": "PDFGrabber API",
        "version": "2.0.0",
        "status": "running"
    }


@app.get("/api/services")
async def get_services():
    """Get all available services"""
    return {
        "services": [
            {"code": code, "name": name}
            for code, name in utils.services.items()
        ],
        "oneshots": [
            {"code": code, "name": name}
            for code, name in utils.oneshots.items()
        ]
    }


@app.post("/api/services/{service}/login")
async def login_service(service: str, credentials: LoginRequest):
    """Login to a service and get token"""
    if service not in utils.services:
        raise HTTPException(status_code=404, detail="Service not found")
    
    try:
        token = utils.login(service, credentials.username, credentials.password)
        if token:
            return {
                "success": True,
                "token": token,
                "service": service
            }
        else:
            raise HTTPException(status_code=401, detail="Invalid credentials")
    except TimeoutError as e:
        raise HTTPException(status_code=504, detail="Connection timeout - the service is not responding")
    except ConnectionError as e:
        raise HTTPException(status_code=503, detail="Cannot connect to the service")
    except Exception as e:
        error_msg = str(e)
        if "timeout" in error_msg.lower():
            raise HTTPException(status_code=504, detail="Connection timeout - the service is not responding")
        raise HTTPException(status_code=500, detail=error_msg)


@app.post("/api/services/{service}/check-token")
async def check_token(service: str, token_req: TokenRequest):
    """Verify if a token is valid"""
    if service not in utils.services:
        raise HTTPException(status_code=404, detail="Service not found")
    
    try:
        is_valid = utils.checktoken(service, token_req.token)
        return {
            "valid": is_valid,
            "service": service
        }
    except Exception as e:
        return {
            "valid": False,
            "error": str(e)
        }


@app.post("/api/services/{service}/library")
async def get_library(service: str, token_req: TokenRequest):
    """Get user's library from a service"""
    if service not in utils.services:
        raise HTTPException(status_code=404, detail="Service not found")
    
    try:
        books = utils.library(service, token_req.token)
        if books is None:
            raise HTTPException(status_code=401, detail="Invalid token or no books found")
        
        # Convert to list format for frontend
        books_list = [
            {
                "id": book_id,
                "title": book_data.get("title", "Unknown"),
                "data": book_data
            }
            for book_id, book_data in books.items()
        ]
        
        return {
            "service": service,
            "books": books_list,
            "count": len(books_list)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/files")
async def list_downloaded_files():
    """List all downloaded PDF files"""
    files_dir = Path("files")
    if not files_dir.exists():
        return {"files": []}
    
    files_list = []
    for service_dir in files_dir.iterdir():
        if service_dir.is_dir():
            for pdf_file in service_dir.glob("*.pdf"):
                stat = pdf_file.stat()
                files_list.append({
                    "service": service_dir.name,
                    "filename": pdf_file.name,
                    "path": str(pdf_file.relative_to(files_dir)),
                    "size": stat.st_size,
                    "modified": stat.st_mtime
                })
    
    return {
        "files": sorted(files_list, key=lambda x: x["modified"], reverse=True),
        "count": len(files_list)
    }


@app.get("/api/files/{service}/{filename}")
async def download_file(service: str, filename: str):
    """Download a PDF file"""
    file_path = Path("files") / service / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="File not found")
    
    return FileResponse(
        path=str(file_path),
        filename=filename,
        media_type="application/pdf"
    )


@app.websocket("/ws/download/{client_id}")
async def websocket_download(websocket: WebSocket, client_id: str):
    """WebSocket endpoint for real-time download progress"""
    await websocket.accept()
    active_connections[client_id] = websocket
    
    try:
        while True:
            # Keep connection alive and receive download requests
            data = await websocket.receive_json()
            
            if data.get("action") == "download":
                await handle_download(client_id, data)
            
    except WebSocketDisconnect:
        if client_id in active_connections:
            del active_connections[client_id]


async def handle_download(client_id: str, data: dict):
    """Handle book download with progress updates"""
    websocket = active_connections.get(client_id)
    if not websocket:
        return
    
    service = data.get("service")
    token = data.get("token")
    book_ids = data.get("book_ids", [])
    
    try:
        # Get library to get book data (run in thread to avoid blocking)
        loop = asyncio.get_event_loop()
        books = await loop.run_in_executor(None, utils.library, service, token)
        
        for idx, book_id in enumerate(book_ids):
            if book_id not in books:
                await websocket.send_json({
                    "status": "error",
                    "book_id": book_id,
                    "message": f"Book {book_id} not found in library"
                })
                continue
            
            book_data = books[book_id]
            
            # Send start message
            await websocket.send_json({
                "status": "started",
                "book_id": book_id,
                "title": book_data.get("title"),
                "current": idx + 1,
                "total": len(book_ids)
            })
            
            # Progress callback with thread-safe queue
            progress_queue = queue.Queue()
            download_complete = threading.Event()
            
            def sync_progress(perc, msg=""):
                # Put progress updates in thread-safe queue
                try:
                    progress_queue.put_nowait({"perc": perc, "msg": msg})
                    print(f"Progress update queued: {perc}% - {msg}")
                except queue.Full:
                    pass  # Skip if queue is full
            
            async def send_progress():
                # Monitor queue and send progress updates
                while not download_complete.is_set():
                    try:
                        # Check queue for updates
                        while not progress_queue.empty():
                            progress_data = progress_queue.get_nowait()
                            await websocket.send_json({
                                "status": "progress",
                                "book_id": book_id,
                                "progress": progress_data["perc"],
                                "message": progress_data["msg"],
                                "current": idx + 1,
                                "total": len(book_ids)
                            })
                        await asyncio.sleep(0.2)  # Check every 200ms
                    except Exception as e:
                        print(f"Error sending progress: {e}")
                        break
            
            # Download book
            try:
                # Start progress monitor task
                progress_task = asyncio.create_task(send_progress())
                
                # Run download in thread to not block event loop
                def download_wrapper():
                    try:
                        print(f"Starting download for book {book_id}")
                        result = utils.downloadbook(service, token, book_id, book_data, sync_progress)
                        print(f"Download completed for book {book_id}, file: {result}")
                        return result
                    except Exception as e:
                        print(f"ERROR in download_wrapper: {type(e).__name__}: {str(e)}")
                        import traceback
                        traceback.print_exc()
                        raise
                    finally:
                        download_complete.set()
                        print(f"Download complete event set for book {book_id}")
                
                pdf_path = await loop.run_in_executor(None, download_wrapper)
                print(f"After run_in_executor, pdf_path: {pdf_path}")
                
                # Wait for progress task to send remaining updates
                await asyncio.sleep(0.5)
                progress_task.cancel()
                print(f"Progress task cancelled for book {book_id}")
                
                # Send final progress
                await websocket.send_json({
                    "status": "progress",
                    "book_id": book_id,
                    "progress": 100,
                    "message": "Download completed",
                    "current": idx + 1,
                    "total": len(book_ids)
                })
                print(f"Sent final progress for book {book_id}")
                
                # Send completion message
                await websocket.send_json({
                    "status": "completed",
                    "book_id": book_id,
                    "title": book_data.get("title"),
                    "path": str(pdf_path),
                    "current": idx + 1,
                    "total": len(book_ids)
                })
                print(f"Sent completion message for book {book_id}")
                
            except Exception as e:
                print(f"ERROR in download handling: {type(e).__name__}: {str(e)}")
                import traceback
                traceback.print_exc()
                await websocket.send_json({
                    "status": "error",
                    "book_id": book_id,
                    "message": str(e),
                    "current": idx + 1,
                    "total": len(book_ids)
                })
        
        # All downloads complete
        print(f"All downloads complete, sending all_completed message")
        await websocket.send_json({
            "status": "all_completed",
            "total": len(book_ids)
        })
        print(f"all_completed message sent")
        
    except Exception as e:
        print(f"ERROR in handle_download: {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
        await websocket.send_json({
            "status": "error",
            "message": str(e)
        })


@app.get("/api/stats")
async def get_stats():
    """Get statistics about downloaded files"""
    files_dir = Path("files")
    if not files_dir.exists():
        return {
            "total_files": 0,
            "total_size": 0,
            "services": {}
        }
    
    stats = {
        "total_files": 0,
        "total_size": 0,
        "services": {}
    }
    
    for service_dir in files_dir.iterdir():
        if service_dir.is_dir():
            service_files = list(service_dir.glob("*.pdf"))
            service_size = sum(f.stat().st_size for f in service_files)
            
            stats["services"][service_dir.name] = {
                "files": len(service_files),
                "size": service_size
            }
            stats["total_files"] += len(service_files)
            stats["total_size"] += service_size
    
    return stats


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)

