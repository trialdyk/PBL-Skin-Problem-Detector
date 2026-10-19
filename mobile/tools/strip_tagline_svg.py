"""Buang path tagline (#5E4553) dari lockup horizontal."""
from pathlib import Path
import re

src = Path("assets/images/dermascan-horizontal-tagline-color.svg")
s = src.read_text(encoding="utf-8")
# Hapus path tagline (inkMuted)
cleaned, n = re.subn(r'<path fill="#5E4553"[^/]*/>', "", s)
# Crop viewBox supaya fokus mark + wordmark (tanpa ruang tagline bawah)
cleaned = cleaned.replace(
    'width="827" height="256" viewBox="0 0 827 256"',
    'width="827" height="180" viewBox="0 0 827 180"',
)
out = Path("assets/images/dermascan-horizontal-color.svg")
out.write_text(cleaned, encoding="utf-8")
print(f"stripped {n} tagline path(s), wrote {out} ({len(cleaned)} chars)")
