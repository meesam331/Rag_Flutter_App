import io
import os
import unittest
from types import SimpleNamespace
from unittest.mock import patch

import app


class ApiTests(unittest.TestCase):
    def setUp(self):
        app.document_db = None
        app.document_name = ""
        self.client = app.app.test_client()
        self.page = SimpleNamespace(
            page_content="The library closes at 8 PM.",
            metadata={"page": 0},
        )

    def test_upload_and_ask(self):
        database = SimpleNamespace(
            as_retriever=lambda **_kwargs: SimpleNamespace(
                invoke=lambda _question: [self.page]
            )
        )
        with (
            patch("app.PyPDFLoader") as pdf_loader,
            patch("app.RecursiveCharacterTextSplitter") as splitter,
            patch("app.Chroma.from_documents", return_value=database),
        ):
            pdf_loader.return_value.load.return_value = [self.page]
            splitter.return_value.split_documents.return_value = [self.page]
            upload = self.client.post(
                "/upload",
                data={"file": (io.BytesIO(b"pdf"), "hours.pdf")},
                content_type="multipart/form-data",
            )

        self.assertEqual(upload.status_code, 200)

        with (
            patch.dict(os.environ, {"GROQ_API_KEY": "test-key"}),
            patch("app.ChatGroq") as chat,
        ):
            chat.return_value.invoke.return_value.content = "It closes at 8 PM."
            answer = self.client.post(
                "/ask", json={"question": "When does the library close?"}
            )

        self.assertEqual(answer.status_code, 200)
        self.assertEqual(answer.get_json()["answer"], "It closes at 8 PM.")
        self.assertEqual(answer.get_json()["sources"], ["hours.pdf (page 1)"])
        self.assertEqual(chat.call_args.kwargs["api_key"], "test-key")

    def test_ask_needs_a_pdf(self):
        response = self.client.post("/ask", json={"question": "What is inside?"})
        self.assertEqual(response.status_code, 400)

    def test_health_reports_key_status_without_exposing_key(self):
        with patch.dict(os.environ, {"GROQ_API_KEY": "test-key"}):
            response = self.client.get("/health")

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.get_json()["groq_configured"])
        self.assertNotIn("test-key", response.get_data(as_text=True))

    def test_ask_explains_missing_key(self):
        app.document_db = object()
        with patch.dict(os.environ, {}, clear=True):
            response = self.client.post("/ask", json={"question": "Question?"})

        self.assertEqual(response.status_code, 503)
        self.assertIn(".env", response.get_json()["error"])

    def test_upload_rejects_non_pdf(self):
        response = self.client.post(
            "/upload",
            data={"file": (io.BytesIO(b"text"), "notes.txt")},
            content_type="multipart/form-data",
        )
        self.assertEqual(response.status_code, 400)

    def test_upload_reports_indexing_error(self):
        with (
            patch("app.PyPDFLoader") as pdf_loader,
            patch("app.RecursiveCharacterTextSplitter") as splitter,
            patch("app.Chroma.from_documents", side_effect=RuntimeError),
        ):
            pdf_loader.return_value.load.return_value = [self.page]
            splitter.return_value.split_documents.return_value = [self.page]
            response = self.client.post(
                "/upload",
                data={"file": (io.BytesIO(b"pdf"), "hours.pdf")},
                content_type="multipart/form-data",
            )

        self.assertEqual(response.status_code, 500)
        self.assertIn("prepare", response.get_json()["error"])


if __name__ == "__main__":
    unittest.main()
