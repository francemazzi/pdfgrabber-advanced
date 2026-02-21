/**
 * PDFGrabber Web App - Main JavaScript
 */

function pdfGrabberApp() {
  return {
    // State
    view: "services",
    loading: true,
    services: [],
    selectedService: null,
    books: [],
    files: [],
    stats: {},

    // Library
    loadingLibrary: false,
    selectedBooks: [],
    searchQuery: "",

    // Login
    showLoginModal: false,
    loginForm: {
      username: "",
      password: "",
    },
    loginError: null,
    loggingIn: false,
    currentToken: null,

    // Download
    downloading: false,
    downloadProgress: {},
    downloadedCount: 0,
    totalDownloads: 0,
    ws: null,

    // API Base URL
    apiUrl: window.location.origin,

    // Initialize
    async init() {
      await this.loadServices();
      await this.loadStats();
    },

    // Load services from API
    async loadServices() {
      try {
        const response = await fetch(`${this.apiUrl}/api/services`);
        const data = await response.json();
        this.services = data.services;
      } catch (error) {
        console.error("Failed to load services:", error);
        alert(
          "Failed to load services. Please check if the backend is running."
        );
      } finally {
        this.loading = false;
      }
    },

    // Select a service
    async selectService(service) {
      this.selectedService = service;
      this.showLoginModal = true;
      this.loginError = null;
    },

    // Login to service
    async login() {
      this.loggingIn = true;
      this.loginError = null;

      try {
        const response = await fetch(
          `${this.apiUrl}/api/services/${this.selectedService.code}/login`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify(this.loginForm),
          }
        );

        if (!response.ok) {
          throw new Error("Invalid credentials");
        }

        const data = await response.json();
        this.currentToken = data.token;
        this.showLoginModal = false;

        // Load library
        await this.loadLibrary();

        // Reset form
        this.loginForm = { username: "", password: "" };
      } catch (error) {
        this.loginError =
          error.message || "Login failed. Please check your credentials.";
      } finally {
        this.loggingIn = false;
      }
    },

    // Load library
    async loadLibrary() {
      this.loadingLibrary = true;
      this.view = "library";

      try {
        const response = await fetch(
          `${this.apiUrl}/api/services/${this.selectedService.code}/library`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({ token: this.currentToken }),
          }
        );

        if (!response.ok) {
          throw new Error("Failed to load library");
        }

        const data = await response.json();
        this.books = data.books;
      } catch (error) {
        console.error("Failed to load library:", error);
        alert("Failed to load library. Please try logging in again.");
        this.view = "services";
      } finally {
        this.loadingLibrary = false;
      }
    },

    // Toggle book selection
    toggleBook(bookId) {
      const index = this.selectedBooks.indexOf(bookId);
      if (index > -1) {
        this.selectedBooks.splice(index, 1);
      } else {
        this.selectedBooks.push(bookId);
      }
    },

    // Download single book
    async downloadSingle(book) {
      this.selectedBooks = [book.id];
      await this.downloadSelected();
    },

    // Download selected books
    async downloadSelected() {
      if (this.selectedBooks.length === 0) {
        return;
      }

      this.downloading = true;
      this.downloadProgress = {};
      this.downloadedCount = 0;
      this.totalDownloads = this.selectedBooks.length;

      // Initialize progress for each book
      this.selectedBooks.forEach((bookId) => {
        const book = this.books.find((b) => b.id === bookId);
        this.downloadProgress[bookId] = {
          title: book?.title || bookId,
          progress: 0,
          message: "Starting...",
        };
      });

      // Connect WebSocket
      await this.connectWebSocket();

      // Send download request
      this.ws.send(
        JSON.stringify({
          action: "download",
          service: this.selectedService.code,
          token: this.currentToken,
          book_ids: this.selectedBooks,
        })
      );
    },

    // Connect to WebSocket
    async connectWebSocket() {
      return new Promise((resolve, reject) => {
        const clientId = "client_" + Math.random().toString(36).substr(2, 9);
        const wsUrl = `ws://${window.location.hostname}:${window.location.port}/ws/download/${clientId}`;

        this.ws = new WebSocket(wsUrl);

        this.ws.onopen = () => {
          console.log("WebSocket connected");
          resolve();
        };

        this.ws.onmessage = (event) => {
          const data = JSON.parse(event.data);
          this.handleDownloadMessage(data);
        };

        this.ws.onerror = (error) => {
          console.error("WebSocket error:", error);
          reject(error);
        };

        this.ws.onclose = () => {
          console.log("WebSocket closed");
        };
      });
    },

    // Handle download progress messages
    handleDownloadMessage(data) {
      const { status, book_id, progress, message, title } = data;

      if (status === "started") {
        this.downloadProgress[book_id] = {
          title: title || book_id,
          progress: 0,
          message: "Starting download...",
        };
      } else if (status === "progress") {
        this.downloadProgress[book_id].progress = Math.round(progress);
        this.downloadProgress[book_id].message = message || "Downloading...";
      } else if (status === "completed") {
        this.downloadProgress[book_id].progress = 100;
        this.downloadProgress[book_id].message = "Completed!";
        this.downloadedCount++;
      } else if (status === "error") {
        this.downloadProgress[book_id].message = "Error: " + message;
      } else if (status === "all_completed") {
        const completedFiles = data.files || [];

        setTimeout(() => {
          this.downloading = false;
          this.selectedBooks = [];
          this.ws.close();

          // Auto-download the ZIP with all completed PDFs
          if (completedFiles.length > 0) {
            this.autoDownloadZip(completedFiles);
          }

          // Reload files
          this.loadFiles();
          this.loadStats();
        }, 1500);
      }
    },

    // Load downloaded files
    async loadFiles() {
      try {
        const response = await fetch(`${this.apiUrl}/api/files`);
        const data = await response.json();
        this.files = data.files;
      } catch (error) {
        console.error("Failed to load files:", error);
      }
    },

    // Load statistics
    async loadStats() {
      try {
        const response = await fetch(`${this.apiUrl}/api/stats`);
        const data = await response.json();
        this.stats = data;
      } catch (error) {
        console.error("Failed to load stats:", error);
      }
    },

    // Computed: Filtered books
    get filteredBooks() {
      if (!this.searchQuery) {
        return this.books;
      }

      const query = this.searchQuery.toLowerCase();
      return this.books.filter(
        (book) =>
          book.title.toLowerCase().includes(query) ||
          book.id.toLowerCase().includes(query)
      );
    },

    // Auto-download ZIP with completed files
    autoDownloadZip(filePaths) {
      const paths = filePaths.join(",");
      const url = `${this.apiUrl}/api/files/download-zip?paths=${encodeURIComponent(paths)}`;

      // Trigger browser download via hidden link
      const a = document.createElement("a");
      a.href = url;
      a.download = "pdfgrabber_download.zip";
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
    },

    // Format file size
    formatSize(bytes) {
      if (bytes === 0) return "0 B";
      const k = 1024;
      const sizes = ["B", "KB", "MB", "GB"];
      const i = Math.floor(Math.log(bytes) / Math.log(k));
      return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + " " + sizes[i];
    },

    // Format date
    formatDate(isoString) {
      if (!isoString) return "";
      const d = new Date(isoString);
      return d.toLocaleDateString("it-IT", {
        day: "2-digit",
        month: "2-digit",
        year: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      });
    },
  };
}
