import pya
import sys

layout = pya.Layout()
layout.read("librelane/runs/RUN_2026-09-01_11-23-58/final/gds/system_top_pad_wrapper.gds")
top = layout.top_cell()

m2_layer = layout.layer(36, 0)
m2_pin = layout.layer(36, 10) 

dbu = layout.dbu
print(f"DBU: {dbu}")
bbox = pya.Box(0, 0, int(5 / dbu), int(25 / dbu))

shapes_found = []
for li in [m2_layer, m2_pin]:
    for shape in top.shapes(li).each_overlapping(bbox):
        shapes_found.append(shape.bbox())

if not shapes_found:
    print("NO METAL2 FOUND IN THE CORNER")
else:
    print("METAL2 SHAPES FOUND IN THE CORNER:")
    for b in shapes_found:
        print(f"  {b.left * dbu:.2f}, {b.bottom * dbu:.2f} to {b.right * dbu:.2f}, {b.top * dbu:.2f} um")
