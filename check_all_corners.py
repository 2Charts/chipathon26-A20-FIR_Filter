import pya
import sys

layout = pya.Layout()
layout.read("librelane/runs/RUN_2026-09-01_11-23-58/final/gds/system_top_pad_wrapper.gds")
top = layout.top_cell()

m2_layer = layout.layer(36, 0)
m2_pin = layout.layer(36, 10) 

dbu = layout.dbu
w = 1110.0
h = 550.0

corners = {
    "Bottom-Left": pya.Box(0, 0, int(5 / dbu), int(25 / dbu)),
    "Bottom-Right": pya.Box(int((w-5) / dbu), 0, int(w / dbu), int(25 / dbu)),
    "Top-Left": pya.Box(0, int((h-25) / dbu), int(5 / dbu), int(h / dbu)),
    "Top-Right": pya.Box(int((w-5) / dbu), int((h-25) / dbu), int(w / dbu), int(h / dbu))
}

for name, bbox in corners.items():
    shapes_found = []
    for li in [m2_layer, m2_pin]:
        for shape in top.shapes(li).each_overlapping(bbox):
            shapes_found.append(shape.bbox())
    
    print(f"--- {name} ---")
    if not shapes_found:
        print("NO METAL2 FOUND")
    else:
        for b in shapes_found:
            print(f"  {b.left * dbu:.2f}, {b.bottom * dbu:.2f} to {b.right * dbu:.2f}, {b.top * dbu:.2f} um")
