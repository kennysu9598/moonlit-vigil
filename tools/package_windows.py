"""Create a fresh portable Windows prototype package using Godot + PCK."""
import argparse,datetime,hashlib,json,pathlib,shutil,subprocess,zipfile

parser=argparse.ArgumentParser()
parser.add_argument('--godot',required=True,help='Installed Windows Godot GUI exe, not the console wrapper')
args=parser.parse_args()
root=pathlib.Path(__file__).resolve().parents[1]
exe=pathlib.Path(args.godot).resolve()
if not exe.is_file() or exe.suffix.lower()!='.exe' or '_console' in exe.stem:
    raise SystemExit('Please supply the existing Windows Godot GUI .exe without _console.')
stamp=datetime.datetime.now().strftime('%Y%m%dT%H%M%S%f')
destination=root/'dist'/stamp/'MoonlitVigil'
destination.mkdir(parents=True,exist_ok=False)
def run_godot(label,arguments):
    log=destination.parent/(label+'.log')
    subprocess.run([str(exe),'--headless','--path',str(root),'--log-file',str(log)]+arguments,check=True)
    content=log.read_text(encoding='utf-8-sig',errors='replace')
    if 'ERROR:' in content or 'SCRIPT ERROR' in content:
        raise SystemExit('Godot reported an error; inspect '+str(log))
run_godot('import',['--editor','--import','--quit'])
run_godot('export',['--export-pack','Windows Portable',str(destination/'MoonlitVigil.pck')])
shutil.copy2(exe,destination/'MoonlitVigil.exe')
shutil.copytree(root/'assets/licenses',destination/'licenses')
for name in ['LICENSE','ASSET_LICENSES.md','README.md']:
    shutil.copy2(root/name,destination/name)
manifest={str(p.relative_to(destination)):hashlib.sha256(p.read_bytes()).hexdigest() for p in destination.rglob('*') if p.is_file()}
(destination/'SHA256.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
archive=destination.parent/'MoonlitVigil-windows-x86_64.zip'
with zipfile.ZipFile(archive,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for p in destination.rglob('*'):
        if p.is_file():z.write(p,str(p.relative_to(destination.parent)))
print(archive)
