# 🐳 Guida Rapida Docker per PDFGrabber

## 🎯 Perché usare Docker?

✅ **Non serve installare Python** - tutto è già incluso  
✅ **Zero problemi di configurazione** - funziona al primo colpo  
✅ **Uguale su Windows, Mac e Linux** - nessuna differenza  
✅ **Isolato dal tuo sistema** - nessun conflitto con altri programmi  
✅ **Playwright pre-configurato** - i browser sono già inclusi  

---

## 📥 Installazione Docker Desktop

### 1️⃣ Scarica Docker Desktop

Vai su: **https://www.docker.com/products/docker-desktop/**

- **Windows**: Download for Windows
- **macOS Intel**: Download for Mac with Intel chip  
- **macOS Apple Silicon (M1/M2/M3)**: Download for Mac with Apple chip
- **Linux**: Segui le istruzioni sul sito

### 2️⃣ Installa Docker Desktop

- **Windows/Mac**: Esegui il file scaricato e segui la procedura guidata
- **Linux**: Usa il terminale (vedi DOCKER-GUIDE.md per dettagli)

### 3️⃣ Avvia Docker Desktop

- Apri Docker Desktop dal menu Start (Windows) o Launchpad (Mac)
- **Attendi che l'icona diventi verde** (significa che è pronto)

---

## 🚀 Come Usare PDFGrabber

### Prima Volta

1. **Apri il terminale** nella cartella `pdfgrabber-advanced`
   - Windows: Shift + tasto destro → "Apri finestra PowerShell qui"
   - Mac: Trascina la cartella sull'icona Terminale
   - Linux: Tasto destro → "Apri nel terminale"

2. **Costruisci l'immagine Docker** (richiede 5-10 minuti)
   ```bash
   docker compose build
   ```

3. **Avvia PDFGrabber**
   ```bash
   docker compose run --rm pdfgrabber
   ```

### Usi Successivi

Ogni volta che vuoi usare PDFGrabber, basta un comando:

```bash
docker compose run --rm pdfgrabber
```

---

## 📁 Dove Sono i Miei File?

I PDF scaricati sono nella cartella `files/` sul TUO computer (non dentro Docker):

```
pdfgrabber-advanced/
├── files/
│   ├── bsm/       ← I tuoi PDF di bSmart
│   ├── mcm/       ← I tuoi PDF di MEE2
│   └── ...
├── config.ini     ← Le tue impostazioni
└── db.json       ← I tuoi utenti e token
```

**Puoi accedervi normalmente** con Esplora File o Finder!

---

## ⚡ Comandi Essenziali

```bash
# Costruire/ricostruire l'immagine (prima volta o dopo aggiornamenti)
docker compose build

# Avviare PDFGrabber
docker compose run --rm pdfgrabber

# Fermare tutto
docker compose down

# Ricostruire da zero (se qualcosa va storto)
docker compose build --no-cache
```

---

## 🔧 Problemi Comuni

### "Docker is not running"
➡️ Apri Docker Desktop e attendi che sia verde

### "Cannot connect to the Docker daemon"
➡️ Riavvia Docker Desktop

### Build troppo lenta
➡️ È normale la prima volta (scarica ~800MB), poi sarà veloce

### Errori generici
➡️ Prova a ricostruire da zero:
```bash
docker compose down
docker compose build --no-cache
```

---

## ❓ Domande Frequenti

**Q: Devo tenere Docker Desktop sempre aperto?**  
A: Solo quando usi PDFGrabber. Puoi chiuderlo dopo.

**Q: I miei dati sono al sicuro?**  
A: Sì! Tutto è salvato sul tuo computer, non dentro Docker.

**Q: Quanto spazio occupa?**  
A: Circa 1.3 GB (Docker + immagine PDFGrabber).

**Q: Posso usare PDFGrabber senza Docker?**  
A: Sì, segui le istruzioni tradizionali nel README.md.

**Q: Funziona offline?**  
A: Sì, dopo la prima costruzione. Ma serve internet per scaricare i libri!

---

## 📚 Documentazione Completa

Per una guida dettagliata con tutte le spiegazioni, vedi: **[DOCKER-GUIDE.md](DOCKER-GUIDE.md)**

---

## 🎉 Riepilogo Ultra-Rapido

```bash
# 1. Installa Docker Desktop (una volta)
#    https://www.docker.com/products/docker-desktop/

# 2. Costruisci (prima volta)
docker compose build

# 3. Usa PDFGrabber (sempre)
docker compose run --rm pdfgrabber

# 4. Trova i PDF
#    Nella cartella: files/
```

**È tutto! Buon download! 📚✨**

