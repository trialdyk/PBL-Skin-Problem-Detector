from pathlib import Path
import re

s = Path("assets/images/dermascan-horizontal-tagline-color.svg").read_text(
    encoding="utf-8"
)
print("len", len(s))
print(s[:400])
print("--- fills", set(re.findall(r'fill="([^"]+)"', s)))
# Find dark wordmark / tagline paths (ink)
for m in re.finditer(r"<path[^>]+>", s):
    chunk = m.group(0)
    if 'fill="#1F1A1D"' in chunk or 'fill="#5E4553"' in chunk:
        print(chunk[:120], "...")
