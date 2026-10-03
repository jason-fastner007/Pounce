#!/usr/bin/env python3
"""Entfernt Custom Sections (Symbolnamen, producers, target_features) aus einer .wasm-Datei.

Die Sections dienen nur dem Debugging; der Code bleibt unverändert.
    python3 tool/strip_wasm.py web/deckengine.wasm
"""
import sys


def leb128(data: bytes, i: int) -> tuple[int, int]:
    result = shift = 0
    while True:
        byte = data[i]
        i += 1
        result |= (byte & 0x7F) << shift
        shift += 7
        if byte < 0x80:
            return result, i


def strip(path: str) -> None:
    data = open(path, 'rb').read()
    if data[:4] != b'\0asm':
        sys.exit(f'{path}: keine WebAssembly-Datei')
    out = bytearray(data[:8])
    i = 8
    while i < len(data):
        start = i
        section_id = data[i]
        size, body = leb128(data, i + 1)
        i = body + size
        if section_id != 0:
            out += data[start:i]
    open(path, 'wb').write(out)
    print(f'{path}: {len(data)} -> {len(out)} Bytes')


if __name__ == '__main__':
    for p in sys.argv[1:]:
        strip(p)
