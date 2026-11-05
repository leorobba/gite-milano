"""Genera assets/style.css da assets/style.src.css.

I token del tema scuro sono scritti una sola volta nel sorgente tra /*@DARK e @END*/;
qui vengono duplicati in due blocchi:
  - @media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) {...} }  -> segue il sistema
  - :root[data-theme="dark"] {...}                                                 -> scelta del pulsante sole/luna
Uso:  py scripts/build-css.py
"""
import pathlib, re

root = pathlib.Path(__file__).resolve().parent.parent
src = (root / 'assets' / 'style.src.css').read_text(encoding='utf-8')
m = re.search(r'/\*@DARK\n(.*?)\n@END\*/', src, flags=re.S)
if not m:
    raise SystemExit('blocco /*@DARK ... @END*/ non trovato')
tokens = m.group(1).strip('\n')
indent = lambda s, n: '\n'.join((' ' * n + l.strip()) if l.strip() else l for l in s.split('\n'))
dark = ('/* tema scuro: segue il sistema, a meno che il pulsante sole/luna non abbia scelto il chiaro */\n'
        '@media (prefers-color-scheme: dark){\n  :root:not([data-theme="light"]){\n' + indent(tokens, 4) + '\n  }\n}\n'
        '/* tema scuro scelto con il pulsante sole/luna */\n'
        ':root[data-theme="dark"]{\n' + indent(tokens, 2) + '\n}')
out = ('/* FILE GENERATO da scripts/build-css.py: modifica assets/style.src.css */\n'
       + src[:m.start()] + dark + src[m.end():])
(root / 'assets' / 'style.css').write_text(out, encoding='utf-8')
print('assets/style.css generato,', len(out), 'caratteri')
