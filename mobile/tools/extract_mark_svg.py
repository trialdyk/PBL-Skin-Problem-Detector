from pathlib import Path

src = Path("assets/images/dermascan-horizontal-tagline-color.svg")
s = src.read_text(encoding="utf-8")
idx = s.find('fill="#1F1A1D"')
if idx < 0:
    raise SystemExit("wordmark not found")
start = s.rfind("<path", 0, idx)
mark = s[:start].rstrip()
out = (
    mark.replace(
        'width="827" height="256" viewBox="0 0 827 256"',
        'width="250" height="256" viewBox="20 20 230 220"',
    )
    + "</svg>\n"
)
Path("assets/images/dermascan-mark-color.svg").write_text(out, encoding="utf-8")
print("wrote", len(out), "chars")
