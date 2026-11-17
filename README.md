# Pagewise

Pagewise is a Flutter app for asking questions about a PDF. Upload one PDF,
type a question, and get an answer with page sources.

## How it works

- Flutter provides the upload and question screens.
- Flask reads the PDF and splits its text into passages.
- Chroma and a local sentence-embedding model find relevant passages.
- Groq answers using those passages.

Only one PDF is kept at a time. Uploading another PDF replaces it. The PDF
stays in backend memory and is cleared when Flask stops. The relevant passages
and your question are sent to Groq to generate an answer. Scanned PDFs without
selectable text are not supported.

## Requirements

- Python 3.13
- Flutter
- [uv](https://docs.astral.sh/uv/)
- A Groq API key

## Setup

Run these commands from the project folder in PowerShell:

```powershell
Copy-Item .env.example .env
notepad .env
```

In `.env`, replace the example value with your **new** Groq key:

```text
GROQ_API_KEY=your_new_key
```

Keep `.env` private. It is ignored by Git. Never commit or share your API key.
If you shared a key publicly, revoke it and create a replacement.

## Run the backend

From the project folder, run:

```powershell
uv run --python 3.13 --with-requirements backend\requirements.txt -- python backend\app.py
```

The first PDF upload downloads Chroma's small built-in embedding model, so it
may take a little longer.

## Run Flutter

Open a second PowerShell terminal in the project folder:

```powershell
flutter pub get
flutter run -d chrome
```

For the Android emulator, run `flutter run` instead. The app uses
`http://127.0.0.1:5000` on desktop and web, and `http://10.0.2.2:5000` on the
Android emulator.

## Run backend tests

```powershell
uv run --python 3.13 --with-requirements backend\requirements.txt -- python -m unittest discover -s backend -p "test_*.py"
```

## API

- `POST /upload` — upload a PDF using the `file` form field.
- `POST /ask` — send JSON such as `{"question": "What is the main idea?"}`.
