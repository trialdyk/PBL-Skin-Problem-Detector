@AGENTS.md

# Claude Code

Aturan struktur kode, langkah menambah endpoint, dan perintah ada di `AGENTS.md`
(diimpor di atas). Jangan menyalin isinya ke sini; ubah `AGENTS.md` saja.

- Kerjakan dari folder `backend/`. Gunakan `.venv` di folder ini.
- Kontrak API = `openapi.json`, bukan markdown yang ditulis dari kode.
  Setelah menambah/mengubah endpoint: `python scripts/export_openapi.py`, lalu
  sesuaikan `../docs/api.md` hanya untuk konteks non-OpenAPI (mobile/env/keamanan).
  Pastikan `pytest tests/test_openapi.py` hijau.
- Commit tanpa baris `Co-Authored-By`.
