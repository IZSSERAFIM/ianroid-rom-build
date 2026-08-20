#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""校验构建产出的 recovery.img：确认打包进去的是本机 prebuilt 内核。

单独成文件而非塞进 workflow 的 heredoc —— YAML 块标量对缩进敏感，
顶格的 heredoc 内容会提前终止块，导致整个 workflow 解析失败。
"""
import struct
import sys
import re
import zlib

EXPECT = {
    'base': 0x40000000,
    'kernel': 0x40008000,
    'ramdisk': 0x44000000,
    'tags': 0x4E000000,
    'pagesize': 2048,
}
NEED_DRIVERS = (b'st7703', b'gt1x', b'Goodix')


def main(path):
    d = open(path, 'rb').read()
    if d[:8] != b'ANDROID!':
        print(f'!! {path} 不是 Android boot image')
        return 1

    ks, ka, rs, ra, ss, sa, tg, ps = struct.unpack_from('<8I', d, 8)
    cmdline = d[64:576].split(b'\x00')[0].decode('ascii', 'replace')
    base = ka - 0x8000

    print(f'大小        : {len(d):,} bytes')
    print(f'kernel/ramdisk: {ks:,} / {rs:,} bytes')
    print(f'cmdline     : {cmdline}')

    got = {'base': base, 'kernel': ka, 'ramdisk': ra, 'tags': tg, 'pagesize': ps}
    bad = 0
    for k, want in EXPECT.items():
        ok = got[k] == want
        bad += (not ok)
        shown = got[k] if k == 'pagesize' else f'0x{got[k]:08X}'
        exp = want if k == 'pagesize' else f'0x{want:08X}'
        print(f'  {k:<9}: {shown:<12} 期望 {exp:<12} {"OK" if ok else "!! 不符"}')

    # 解压内核，确认是本机那一份
    k = d[ps:ps + ks]
    m = re.search(b'\x1f\x8b\x08', k)
    raw = k
    if m:
        try:
            raw = zlib.decompressobj(16 + zlib.MAX_WBITS).decompress(k[m.start():])
        except Exception as e:
            print(f'  内核解压失败: {e}')

    b = re.search(rb'Linux version [0-9][^\x00\n]{0,120}', raw)
    banner = b.group().decode() if b else '(未找到)'
    print(f'内核 banner : {banner}')
    if 'zxl@zxl' not in banner:
        print('  !! 警告: banner 中没有 zxl@zxl，可能不是本机 prebuilt 内核')
        bad += 1

    for kw in NEED_DRIVERS:
        present = kw in raw
        bad += (not present)
        print(f'  含 {kw.decode():<8}: {"是" if present else "否  !! 缺失"}')

    print('判定:', '全部通过' if bad == 0 else f'{bad} 项异常')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
