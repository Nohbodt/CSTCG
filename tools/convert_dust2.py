#!/usr/bin/env python3
"""Convert the supplied binary STL to a Godot-importable OBJ without repair.

The input is preserved byte for byte. Degenerate faces are omitted and recorded;
no missing floors, doors, connectors, or collision surfaces are invented.
Uses only the Python standard library.
"""

import argparse
import hashlib
import json
import math
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DESTINATION = ROOT / "assets/maps/dust2"
SCALE = 0.6  # Provisional gameplay calibration, not an official map-unit conversion.


def convert(source: Path) -> None:
    data = source.read_bytes()
    if len(data) < 84:
        raise ValueError("Truncated binary STL")
    count = struct.unpack_from("<I", data, 80)[0]
    if count > 1_000_000 or len(data) != 84 + count * 50:
        raise ValueError("Invalid binary STL length or excessive face count")
    triangles = []
    minimum = [math.inf] * 3
    maximum = [-math.inf] * 3
    for row in struct.iter_unpack("<12fH", data[84:]):
        vertices = [row[i:i + 3] for i in (3, 6, 9)]
        if not all(math.isfinite(n) for vertex in vertices for n in vertex):
            raise ValueError("Non-finite vertex")
        for vertex in vertices:
            for axis in range(3):
                minimum[axis] = min(minimum[axis], vertex[axis])
                maximum[axis] = max(maximum[axis], vertex[axis])
        triangles.append(vertices)
    origin = [(minimum[0] + maximum[0]) / 2,
              (minimum[1] + maximum[1]) / 2, minimum[2]]
    vertices, faces, lookup = [], [], {}
    degenerate = 0
    for triangle in triangles:
        transformed = [((p[0] - origin[0]) * SCALE,
                        (p[2] - origin[2]) * SCALE,
                        -(p[1] - origin[1]) * SCALE) for p in triangle]
        a, b, c = transformed
        u = [b[i] - a[i] for i in range(3)]
        w = [c[i] - a[i] for i in range(3)]
        cross = [u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2], u[0] * w[1] - u[1] * w[0]]
        if sum(n * n for n in cross) < 1e-14:
            degenerate += 1
            continue
        indices = []
        for point in transformed:
            # Exact transformed coordinates retain geometry; no spatial welding tolerance.
            if point not in lookup:
                vertices.append(point)
                lookup[point] = len(vertices)
            indices.append(lookup[point])
        faces.append(indices)
    DESTINATION.mkdir(parents=True, exist_ok=True)
    preserved = DESTINATION / "source.stl"
    if preserved.exists() and preserved.read_bytes() != data:
        raise ValueError("A different source.stl already exists; refusing to overwrite it")
    preserved.write_bytes(data)
    with (DESTINATION / "dust2.obj").open("w") as out:
        out.write("# Supplied STL, Z-up to Godot Y-up; no inferred topology repairs.\n")
        out.write("o Dust2_UserSupplied\n")
        for vertex in vertices:
            out.write("v %.9f %.9f %.9f\n" % vertex)
        out.write("s off\n")
        for face in faces:
            out.write("f %d %d %d\n" % tuple(face))
    metadata = {
        "source_filename": source.name, "source_sha256": hashlib.sha256(data).hexdigest(),
        "obj_sha256": hashlib.sha256((DESTINATION / "dust2.obj").read_bytes()).hexdigest(),
        "source_triangles": count, "render_collision_triangles": len(faces),
        "degenerate_faces_removed": degenerate, "unique_vertices": len(vertices),
        "source_bounds": {"minimum": minimum, "maximum": maximum},
        "source_origin": origin, "source_axis_up": "Z", "game_axis_up": "Y",
        "scale": SCALE, "transform": "X=(x-origin_x)*scale, Y=(z-min_z)*scale, Z=-(y-origin_y)*scale",
        "scale_status": "provisional gameplay scale; original STL has no physical-unit metadata",
        "geometry_repairs": [], "navigation_is_derived": True,
    }
    previous_manifest = DESTINATION / "manifest.json"
    if previous_manifest.exists():
        previous = json.loads(previous_manifest.read_text())
        if previous.get("source_sha256") == metadata["source_sha256"]:
            metadata["source_filename"] = previous["source_filename"]
    (DESTINATION / "manifest.json").write_text(json.dumps(metadata, indent=2) + "\n")
    print(json.dumps(metadata, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    convert(parser.parse_args().source)
