"""Convert a raw image to Android sparse format (streaming, low memory)."""
import struct, sys

BLK = 4096
CHUNK_BLKS = 16384  # 64 MiB per chunk
src, dst = sys.argv[1], sys.argv[2]

import os
size = os.path.getsize(src)
assert size % BLK == 0
total_blks = size // BLK
chunks = []  # (type, blks, offset)
pos = 0
with open(src, 'rb') as f:
    while pos < total_blks:
        n = min(CHUNK_BLKS, total_blks - pos)
        data = f.read(n * BLK)
        if data.count(0) == len(data):
            chunks.append((0xCAC3, n, None))
        else:
            chunks.append((0xCAC1, n, pos * BLK))
        pos += n

with open(src, 'rb') as f, open(dst, 'wb') as o:
    o.write(struct.pack('<IHHHHIIII', 0xED26FF3A, 1, 0, 28, 12, BLK, total_blks, len(chunks), 0))
    for t, n, off in chunks:
        if t == 0xCAC1:
            o.write(struct.pack('<HHII', t, 0, n, 12 + n * BLK))
            f.seek(off)
            left = n * BLK
            while left:
                b = f.read(min(left, 8 << 20))
                o.write(b)
                left -= len(b)
        else:
            o.write(struct.pack('<HHII', t, 0, n, 12))
print('done', len(chunks), 'chunks')
