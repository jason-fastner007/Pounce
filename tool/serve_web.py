#!/usr/bin/env python3
"""Liefert build/web lokal aus – mit denselben Headern wie web/_headers (Skwasm mit mehreren Threads).

    flutter build web --wasm --release --dart-define=SC_PROXY=http://localhost:8787/?url=
    dart run tool/proxy/dev_proxy.dart &
    python3 tool/serve_web.py            # http://localhost:8080
    python3 tool/serve_web.py 9000 --no-isolate
"""
import functools
import http.server
import pathlib
import sys

root = pathlib.Path(__file__).resolve().parent.parent / 'build' / 'web'
args = [a for a in sys.argv[1:] if not a.startswith('--')]
port = int(args[0]) if args else 8080
isolate = '--no-isolate' not in sys.argv


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map,
                      '.wasm': 'application/wasm', '.mjs': 'text/javascript'}

    def end_headers(self):
        if isolate:
            self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
            self.send_header('Cross-Origin-Embedder-Policy', 'credentialless')
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()


if not (root / 'index.html').exists():
    sys.exit(f'{root} fehlt – erst "flutter build web --wasm" ausführen.')
print(f'Pounce: http://localhost:{port}  ({"mehrere Threads" if isolate else "ohne Isolation"})')
http.server.ThreadingHTTPServer(('127.0.0.1', port), functools.partial(Handler, directory=root)).serve_forever()
