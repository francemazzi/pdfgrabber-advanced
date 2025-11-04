"""
bSmart Dynamic Key Extractor
============================
Versione migliorata del modulo bSmart che estrae la chiave AES dinamicamente
dal sito invece di usare una chiave hardcoded.

Questo approccio è più robusto e resistente agli aggiornamenti della piattaforma.
Basato sull'implementazione JavaScript originale.
"""

import requests
from requests.exceptions import Timeout, ConnectionError, RequestException
import umsgpack
import tarfile
from io import BytesIO
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad
import fitz
import lib
import config
import re
import base64
from typing import Optional, Dict, Tuple

service = "bsm"

# La chiave verrà estratta dinamicamente - non più hardcoded
key: Optional[bytes] = None

bsmart_baseurl = "https://www.bsmart.it"
bsmart_myurl = "https://my.bsmart.it"

config_obj = config.getconfig()


class BSmartKeyExtractor:
    """
    Classe per estrarre dinamicamente la chiave AES dal sito bSmart.
    
    Questo approccio analizza il JavaScript della pagina per trovare
    la chiave offuscata e la decodifica automaticamente.
    """
    
    def __init__(self, base_url: str = bsmart_myurl):
        self.base_url = base_url
        self.cached_key: Optional[bytes] = None
    
    def fetch_encryption_key(self) -> bytes:
        """
        Estrae la chiave AES dinamicamente dal sito bSmart.
        
        Processo:
        1. Scarica la homepage
        2. Trova il riferimento allo script JavaScript principale
        3. Scarica lo script minificato
        4. Cerca il pattern dove la chiave è offuscata
        5. Deoffusca ed estrae la chiave Base64
        6. Converte in bytes
        
        Returns:
            bytes: La chiave AES decodificata
            
        Raises:
            Exception: Se non riesce a estrarre la chiave
        """
        try:
            print(f"[+] Fetching homepage from {self.base_url}")
            
            # Step 1: Scarica homepage
            page_response = requests.get(self.base_url, timeout=30)
            page_response.raise_for_status()
            page_html = page_response.text
            
            # Step 2: Trova script principale
            script_match = re.search(r'<script src="(/scripts/.*?\.min\.js)">', page_html)
            if not script_match:
                raise Exception("Cannot find main script reference in homepage")
            
            script_path = script_match.group(1)
            script_url = f"{self.base_url}{script_path}"
            print(f"[+] Found script: {script_path}")
            
            # Step 3: Scarica script JavaScript
            script_response = requests.get(script_url, timeout=30)
            script_response.raise_for_status()
            script_text = script_response.text
            
            # Step 4: Trova la sezione con la chiave offuscata
            key_pattern_start = 'var i=String.fromCharCode'
            if key_pattern_start not in script_text:
                raise Exception("Cannot find key obfuscation pattern in script")
            
            key_script = script_text[script_text.find(key_pattern_start):]
            key_script = key_script[:key_script.find('()')]
            
            # Step 5: Estrai i codici carattere
            char_codes_match = re.search(
                r'var i=String\.fromCharCode\(([\d,]+)\)', 
                key_script
            )
            if not char_codes_match:
                raise Exception("Cannot extract character codes")
            
            char_codes = char_codes_match.group(1)
            source_characters = [chr(int(code)) for code in char_codes.split(',')]
            print(f"[+] Extracted {len(source_characters)} source characters")
            
            # Step 6: Estrai la mappa degli indici
            index_matches = re.findall(r'i\[(\d+)\]', key_script)
            if not index_matches:
                raise Exception("Cannot extract index map")
            
            indices = [int(idx) for idx in index_matches]
            print(f"[+] Extracted {len(indices)} indices")
            
            # Step 7: Ricostruisci lo snippet usando la mappa
            snippet = ''.join(source_characters[i] for i in indices)
            
            # Step 8: Estrai la stringa Base64 dallo snippet
            base64_match = re.search(
                r"'([A-Za-z0-9+/]{20,}={0,2})'", 
                snippet
            )
            if not base64_match:
                raise Exception("Cannot find Base64 key in deobfuscated snippet")
            
            base64_key = base64_match.group(1)
            print(f"[+] Found Base64 key: {base64_key[:16]}...")
            
            # Step 9: Decodifica da Base64 a bytes
            decoded_key = base64.b64decode(base64_key)
            print(f"[+] Successfully extracted AES key ({len(decoded_key)} bytes)")
            print(f"[+] Key hex: {decoded_key.hex()}")
            
            # Cache la chiave per riutilizzo
            self.cached_key = decoded_key
            return decoded_key
            
        except requests.RequestException as e:
            raise Exception(f"Network error while fetching encryption key: {str(e)}")
        except Exception as e:
            raise Exception(f"Failed to extract encryption key: {str(e)}")
    
    def get_key(self, force_refresh: bool = False) -> bytes:
        """
        Ottiene la chiave AES, usando la cache se disponibile.
        
        Args:
            force_refresh: Se True, forza il re-fetch anche se c'è una chiave in cache
            
        Returns:
            bytes: La chiave AES
        """
        if self.cached_key is None or force_refresh:
            self.cached_key = self.fetch_encryption_key()
        return self.cached_key


# Istanza globale del key extractor
_key_extractor = BSmartKeyExtractor()


def get_encryption_key(force_refresh: bool = False) -> bytes:
    """
    Funzione helper per ottenere la chiave di cifratura.
    
    Args:
        force_refresh: Se True, forza il re-fetch della chiave
        
    Returns:
        bytes: La chiave AES
    """
    global key
    key = _key_extractor.get_key(force_refresh)
    return key


def getlogindata(username: str, password: str, baseurl: str) -> dict:
    """Effettua login e ottiene i dati di autenticazione."""
    try:
        r = requests.post(
            baseurl + "/api/v5/session", 
            data={"password": password, "email": username}, 
            timeout=30
        )
        return r.json()
    except Timeout:
        raise TimeoutError("Connection timeout: bSmart server is not responding")
    except ConnectionError:
        raise ConnectionError("Cannot connect to bSmart server")
    except RequestException as e:
        raise Exception(f"Request failed: {str(e)}")


def getlibrary(token: str, baseurl: str) -> list:
    """Ottiene la lista dei libri nella libreria."""
    r = requests.get(
        baseurl + "/api/v5/books", 
        headers={"AUTH_TOKEN": token}, 
        params={"per_page": 1000000, "page_thumb_size": "medium"}, 
        timeout=30
    )
    return r.json()


def getpreactivations(token: str, baseurl: str) -> list:
    """Ottiene i libri pre-attivati."""
    r = requests.get(
        baseurl + "/api/v5/books/preactivations", 
        headers={"AUTH_TOKEN": token}, 
        timeout=30
    )
    return r.json()


def getbookinfo(token: str, bookid: str, revision: int, operation: str, baseurl: str) -> dict:
    """Ottiene informazioni dettagliate su un libro specifico."""
    r = requests.get(
        baseurl + "/api/v5/books/" + str(bookid) + "/" + str(revision) + "/" + operation, 
        headers={"AUTH_TOKEN": token}, 
        params={"per_page": 1000000}, 
        timeout=30
    )
    return r.json()


def downloadpack(url: str, progress, total: int, done: int) -> tarfile.TarFile:
    """Scarica e decomprime un asset pack."""
    r = requests.get(url, stream=True, timeout=60)
    length = int(r.headers.get("content-length", 1))
    file = b""
    for data in r.iter_content(chunk_size=102400):
        file += data
        progress(round(done + len(file) / length * total))
    return tarfile.open(fileobj=BytesIO(file))


def cover(token: str, bookid: str, data: dict) -> bytes:
    """Scarica la copertina di un libro."""
    r = requests.get(data["cover"], timeout=30)
    return r.content


def decryptfile(file) -> Tuple[bytes, str]:
    """
    Decripta un file PDF criptato con AES.
    
    La chiave viene ottenuta dinamicamente se non ancora caricata.
    
    Args:
        file: File object da decifrare
        
    Returns:
        Tuple[bytes, str]: (contenuto decriptato, MD5 hash)
    """
    global key
    
    # Assicurati che la chiave sia stata caricata
    if key is None:
        print("[!] AES key not loaded, fetching dynamically...")
        get_encryption_key()
    
    # Leggi header con metadata
    header = umsgpack.unpackb(file.read(256).rstrip(b"\x00"))
    
    # Estrai IV (Initialization Vector)
    iv = file.read(16)
    
    # Crea oggetto AES in modalità CBC
    obj = AES.new(key, AES.MODE_CBC, iv)
    
    # Decripta la parte criptata
    encrypted_part = file.read(header["start"] - 256 - 16)
    dec = obj.decrypt(encrypted_part)
    
    # Rimuovi padding PKCS7 e concatena con parte non criptata
    decrypted = unpad(dec, AES.block_size) + file.read()
    
    return decrypted, header["md5"]


def login(username: str, password: str, baseurl: str = bsmart_baseurl) -> Optional[str]:
    """
    Effettua login su bSmart.
    
    Args:
        username: Email utente
        password: Password
        baseurl: URL base della piattaforma
        
    Returns:
        Optional[str]: Auth token se login riuscito, None altrimenti
    """
    try:
        logindata = getlogindata(username, password, baseurl)
        if "auth_token" not in logindata:
            error_msg = logindata.get("message", "Unknown error")
            print("Login failed: " + error_msg)
            return None
        else:
            return logindata["auth_token"]
    except (TimeoutError, ConnectionError) as e:
        print(f"Connection error: {str(e)}")
        raise
    except Exception as e:
        print(f"Login error: {str(e)}")
        raise


def checktoken(token: str, baseurl: str = bsmart_baseurl) -> bool:
    """Verifica se un token è ancora valido."""
    test = getlibrary(token, baseurl)
    return "message" not in test


def library(token: str, baseurl: str = bsmart_baseurl, service: str = service) -> dict:
    """
    Ottiene la libreria completa di libri disponibili.
    
    Args:
        token: Auth token
        baseurl: URL base
        service: Nome del servizio (per config)
        
    Returns:
        dict: Dizionario con i libri disponibili
    """
    books = dict()
    
    # Libri normali
    for i in getlibrary(token, baseurl):
        if i["liquid_text"]:
            # Sembra che liquid_text non si riferisca al formato dei libri
            # Per ora, abilita il download di tutti i libri
            pass
        books[str(i["id"])] = {
            "title": i["title"], 
            "revision": i["current_edition"]["revision"], 
            "cover": i["cover"]
        }
    
    # Libri pre-attivati (se abilitato in config)
    if config_obj.getboolean(service, "Preactivations", fallback=True):
        for i in getpreactivations(token, baseurl):
            for book in i["books"]:
                if book["liquid_text"]:
                    continue
                books[str(book["id"])] = {
                    "title": book["title"], 
                    "revision": book["current_edition"]["revision"], 
                    "cover": book["cover"]
                }
    
    return books


def downloadbook(token: str, bookid: str, data: dict, progress, baseurl: str = bsmart_baseurl) -> fitz.Document:
    """
    Scarica e assembla un libro completo.
    
    Args:
        token: Auth token
        bookid: ID del libro
        data: Metadati del libro
        progress: Callback per progress updates
        baseurl: URL base
        
    Returns:
        fitz.Document: Documento PDF completo
    """
    global key
    
    # Assicurati che la chiave sia caricata prima di iniziare il download
    if key is None:
        progress(0, "Loading encryption key")
        get_encryption_key()
    
    revision = data["revision"]
    
    progress(1, "Getting resources")
    resources = getbookinfo(token, bookid, revision, "resources", baseurl)
    assetpacks = getbookinfo(token, bookid, revision, "asset_packs", baseurl)
    index = getbookinfo(token, bookid, revision, "index", baseurl)
    
    # Crea mapping MD5 -> (page_id, label)
    resmd5 = {}
    for i in resources:
        if i["resource_type_id"] != 14:
            continue
        if pdf := next((j for j in i["assets"] if j["use"] == "page_pdf"), False):
            resmd5[pdf["md5"]] = i["id"], i["title"]
    
    pagespdf, labelsmap = {}, {}
    
    progress(3, "Downloading pdf")
    pagespack = downloadpack(
        next(i["url"] for i in assetpacks if i["label"] == "page_pdf"), 
        progress, 90, 3
    )
    
    progress(93, "Decrypting pages")
    for member in pagespack.getmembers():
        file = pagespack.extractfile(member)
        if file:
            output, md5 = decryptfile(file)
            if md5 not in resmd5:
                print("Broken book! Unknown page found in the asset pack!")
                continue
            pid, label = resmd5[md5]
            pagespdf[pid] = output
            labelsmap[pid] = label
    
    # Assembla PDF finale
    pdf = fitz.Document()
    toc, labels = [], []
    
    bookmarks = {i["first_page"]["id"]: i["title"] for i in index if "first_page" in i}
    for i, (pageid, pagepdfraw) in enumerate(sorted(pagespdf.items())):
        pagepdf = fitz.Document(stream=pagepdfraw, filetype="pdf")
        pdf.insert_pdf(pagepdf)
        labels.append(labelsmap[pageid])
        if pageid in bookmarks:
            toc.append([1, bookmarks[pageid], i + 1])
    
    progress(98, "Applying toc/labels")
    pdf.set_page_labels(lib.generatelabelsrule(labels))
    pdf.set_toc(toc)
    
    return pdf


def refresh_key():
    """
    Forza il refresh della chiave AES.
    Utile se la chiave cambia e lo script smette di funzionare.
    """
    print("[+] Forcing key refresh...")
    get_encryption_key(force_refresh=True)
    print("[+] Key refreshed successfully")


if __name__ == "__main__":
    """
    Test del key extractor.
    Esegui: python services/bsmdynamic.py
    """
    print("=" * 60)
    print("bSmart Dynamic Key Extractor - Test")
    print("=" * 60)
    print()
    
    try:
        # Test estrazione chiave
        encryption_key = get_encryption_key()
        print()
        print("✅ Test completed successfully!")
        print(f"   Key length: {len(encryption_key)} bytes")
        print(f"   Key (hex): {encryption_key.hex()}")
        
        # Confronta con la chiave hardcoded nel vecchio script
        old_key = bytes.fromhex("1e00b89873139d2104ed501a8bf8689b")
        if encryption_key == old_key:
            print("   ℹ️  Key matches the old hardcoded key")
        else:
            print("   ⚠️  Key is DIFFERENT from old hardcoded key!")
            print(f"   Old key: {old_key.hex()}")
            print("   This means bSmart has updated their encryption!")
            
    except Exception as e:
        print()
        print(f"❌ Test failed: {str(e)}")
        import traceback
        traceback.print_exc()

