# Frontend Dockerfile for PDFGrabber Web UI
FROM nginx:alpine

# Copy static files
COPY index.html /usr/share/nginx/html/
COPY static/ /usr/share/nginx/html/static/

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

