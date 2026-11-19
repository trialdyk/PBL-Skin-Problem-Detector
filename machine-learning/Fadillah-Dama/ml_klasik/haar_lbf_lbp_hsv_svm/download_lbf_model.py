"""Download the pretrained LBF model linked by the OpenCV Facemark tutorial."""
from pathlib import Path
import shutil
import urllib.error
import urllib.request

folder = Path(__file__).resolve().parent / 'lbf_models'
folder.mkdir(exist_ok=True)
model_path = folder / 'lbfmodel.yaml'
temporary_path = folder / 'lbfmodel.yaml.download'
url = 'https://raw.githubusercontent.com/kurnianggoro/GSOC2017/master/data/lbfmodel.yaml'

if model_path.is_file():
    print('Model sudah tersedia:', model_path)
else:
    try:
        print('Mengunduh lbfmodel.yaml dari sumber tutorial OpenCV...', flush=True)
        with urllib.request.urlopen(url, timeout=60) as response:
            with temporary_path.open('wb') as output:
                shutil.copyfileobj(response, output)
        with temporary_path.open('rb') as source:
            header = source.read(128)
        if b'%YAML' not in header:
            raise ValueError('File unduhan bukan YAML OpenCV. Periksa sumber unduhan.')
        temporary_path.replace(model_path)
        print('Model siap:', model_path)
    except urllib.error.URLError as error:
        raise SystemExit(
            'Unduhan gagal. Jalankan dari terminal lokal dengan internet, atau unduh '
            + url + ' dan simpan sebagai ' + str(model_path)
        ) from error
    finally:
        temporary_path.unlink(missing_ok=True)
