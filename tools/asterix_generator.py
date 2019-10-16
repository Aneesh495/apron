#!/usr/bin/env python3
"""
Apron Synthetic Eurocontrol Asterix Cat 011/012 Generator
Module: tools.asterix_generator

Generates synthetic A-SMGCS Asterix Cat 011 surface target frames and
Cat 012 safety alert records for stress testing real-time ingestion pipelines.
"""

import argparse
import random
import struct
import json
from typing import List, Dict, Any


def generate_cat011_records(target_count: int, timestamp: float = 43200.0) -> List[Dict[str, Any]]:
    targets = []
    for i in range(target_count):
        trk = 100 + i
        callsign = f"TGT{trk:03d}"
        x = (random.random() - 0.5) * 4000.0
        y = (random.random() - 0.5) * 2000.0
        vx = (random.random() - 0.5) * 20.0
        vy = (random.random() - 0.5) * 20.0
        targets.append({
            "sac": 25,
            "sic": 1,
            "trackNumber": trk,
            "timeOfDay": timestamp,
            "x": x,
            "y": y,
            "vx": vx,
            "vy": vy,
            "modeA": 0o1000 + i,
            "callsign": callsign,
            "confirmed": True
        })
    return targets


def pack_cat011_binary(records: List[Dict[str, Any]]) -> bytes:
    buffer = bytearray()
    for r in records:
        cs_bytes = r["callsign"].encode("ascii").ljust(8, b" ")
        block = struct.pack(">BBHHffffH8s",
                            11, 36,
                            r["sac"], r["sic"],
                            r["x"], r["y"],
                            r["vx"], r["vy"],
                            r["modeA"], cs_bytes)
        buffer.extend(block)
    return bytes(buffer)


def main():
    parser = argparse.ArgumentParser(description="Eurocontrol Asterix generator")
    parser.add_argument("--targets", type=int, default=50, help="Number of surface radar targets")
    parser.add_argument("--output", type=str, default="targets.bin", help="Output binary file")
    args = parser.parse_args()

    records = generate_cat011_records(args.targets)
    raw_data = pack_cat011_binary(records)
    with open(args.output, "wb") as f:
        f.write(raw_data)
    print(f"Generated {len(records)} Asterix Cat 011 records to {args.output} ({len(raw_data)} bytes)")


if __name__ == "__main__":
    main()
