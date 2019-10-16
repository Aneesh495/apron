#!/usr/bin/env python3
"""
Apron Airfield Vector SVG & Telemetry Visualizer
Module: tools.airfield_visualizer

Renders scalable vector graphics (SVG) diagrams of airport airfield layouts,
active aircraft positions, taxiway routes, runway safety areas, and RIMCAS
conflict zones from JSON airfield definitions and live surveillance streams.
"""

import json
import math
import sys
from typing import Dict, Any, List


def generate_airfield_svg(layout: Dict[str, Any], targets: List[Dict[str, Any]] = None, width: int = 1200, height: int = 800) -> str:
    """Generates an SVG string visualizing runways, taxiways, stands, and aircraft."""
    svg_parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="{width}" height="{height}">',
        '  <style>',
        '    .background { fill: #0b132b; }',
        '    .runway { stroke: #3a506b; stroke-width: 28; stroke-linecap: round; }',
        '    .runway-center { stroke: #ffffff; stroke-width: 2; stroke-dasharray: 10,10; }',
        '    .taxiway { stroke: #1c2541; stroke-width: 12; stroke-linecap: round; fill: none; }',
        '    .stand { fill: #48cae4; stroke: #0077b6; stroke-width: 2; }',
        '    .aircraft { fill: #ffb703; stroke: #fb8500; stroke-width: 2; }',
        '    .text { font-family: monospace; font-size: 11px; fill: #e0e1dd; }',
        '  </style>',
        f'  <rect width="{width}" height="{height}" class="background" />',
        '  <g id="airfield-title">',
        f'    <text x="30" y="40" class="text" font-size="18px" font-weight="bold">{layout.get("name", "Aerodrome")} ({layout.get("icao", "ICAO")})</text>',
        '  </g>',
        '  <g id="runways">'
    ]

    # Draw runways
    cx = width / 2.0
    cy = height / 2.0
    runways = layout.get("runways", [])
    for idx, rwy in enumerate(runways):
        heading_rad = math.radians(rwy.get("heading", 90.0) - 90.0)
        length_px = rwy.get("lengthMeters", 3600) * 0.18
        offset_y = (idx - (len(runways) - 1) / 2.0) * 110.0

        x1 = cx - (length_px / 2.0) * math.cos(heading_rad)
        y1 = cy + offset_y - (length_px / 2.0) * math.sin(heading_rad)
        x2 = cx + (length_px / 2.0) * math.cos(heading_rad)
        y2 = cy + offset_y + (length_px / 2.0) * math.sin(heading_rad)

        svg_parts.append(f'    <line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" class="runway" />')
        svg_parts.append(f'    <line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" class="runway-center" />')
        svg_parts.append(f'    <text x="{x1 - 35:.1f}" y="{y1 + 4:.1f}" class="text">{rwy.get("designator", "")}</text>')

    svg_parts.append('  </g>')

    # Draw stands
    svg_parts.append('  <g id="stands">')
    stands = layout.get("stands", [])
    for idx, stand in enumerate(stands):
        sx = 180 + (idx % 8) * 85
        sy = 140 + (idx // 8) * 70
        svg_parts.append(f'    <circle cx="{sx}" cy="{sy}" r="9" class="stand" />')
        svg_parts.append(f'    <text x="{sx - 10}" y="{sy + 22}" class="text">{stand.get("id", "")}</text>')
    svg_parts.append('  </g>')

    # Draw radar targets if provided
    if targets:
        svg_parts.append('  <g id="targets">')
        for t in targets:
            tx = cx + t.get("x", 0.0) * 0.18
            ty = cy + t.get("y", 0.0) * 0.18
            cs = t.get("callsign", "TGT")
            svg_parts.append(f'    <circle cx="{tx:.1f}" cy="{ty:.1f}" r="6" class="aircraft" />')
            svg_parts.append(f'    <text x="{tx + 9:.1f}" y="{ty - 6:.1f}" class="text">{cs}</text>')
        svg_parts.append('  </g>')

    svg_parts.append('</svg>')
    return '\n'.join(svg_parts)


def main():
    if len(sys.argv) < 2:
        print("Usage: airfield_visualizer.py <layout_json_path> [output_svg_path]")
        sys.exit(1)

    layout_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else "airfield.svg"

    with open(layout_file, "r") as f:
        layout = json.load(f)

    svg_data = generate_airfield_svg(layout)
    with open(output_file, "w") as f:
        f.write(svg_data)
    print(f"Generated airfield visualization: {output_file}")


if __name__ == "__main__":
    main()
