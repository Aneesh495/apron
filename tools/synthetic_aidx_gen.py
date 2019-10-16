#!/usr/bin/env python3
"""
Apron Synthetic AIDX Traffic Stream Generator
Module: tools.synthetic_aidx_gen

Generates high-volume, synthetically realistic IATA AIDX XML and JSON flight
schedules and milestone updates for benchmark testing and throughput analysis.
"""

import argparse
import random
from typing import List, Dict, Any


AIRLINES = ["BAW", "DLH", "AFR", "KLM", "UAE", "VIR", "SIA", "UAL", "AAL"]
AC_TYPES = ["A320", "A321", "B738", "A359", "B77W", "B789", "A388"]
DESTINATIONS = ["KJFK", "KLAX", "OMDB", "LFPG", "EDDF", "EHAM", "VHHH", "RJTT"]


def generate_flight_record(flight_idx: int, base_epoch: int) -> Dict[str, Any]:
    airline = random.choice(AIRLINES)
    flight_num = f"{random.randint(100, 999)}"
    ac_type = random.choice(AC_TYPES)
    dest = random.choice(DESTINATIONS)
    sobt = base_epoch + flight_idx * 180
    tobt = sobt + random.randint(-300, 600)
    tsat = tobt + random.randint(120, 480)
    ttot = tsat + random.randint(600, 1200)

    return {
        "callsign": f"{airline}{flight_num}",
        "airline": airline,
        "flightNumber": flight_num,
        "origin": "EGLL",
        "destination": dest,
        "aircraftType": ac_type,
        "stand": f"{random.choice(['201', '202', '301', '501', '502', '503'])}",
        "sobt": sobt,
        "tobt": tobt,
        "tsat": tsat,
        "ttot": ttot
    }


def generate_schedule(count: int, start_epoch: int = 1700000000) -> List[Dict[str, Any]]:
    return [generate_flight_record(i, start_epoch) for i in range(count)]


def main():
    parser = argparse.ArgumentParser(description="Synthetic AIDX traffic generator")
    parser.add_argument("--count", type=int, default=100, help="Number of flight records")
    parser.add_argument("--format", choices=["json", "xml"], default="json", help="Output format")
    args = parser.parse_args()

    flights = generate_schedule(args.count)
    if args.format == "json":
        import json
        print(json.dumps(flights, indent=2))
    else:
        print("<IATA_AIDX_FlightLegNotifRQ>")
        for f in flights:
            print(f"  <FlightLeg><FlightNumber>{f['callsign']}</FlightNumber></FlightLeg>")
        print("</IATA_AIDX_FlightLegNotifRQ>")


if __name__ == "__main__":
    main()
