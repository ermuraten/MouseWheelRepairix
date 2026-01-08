#!/usr/bin/env python3
from PIL import Image
import sys

if len(sys.argv) != 3:
    print("Usage: process_icon.py <input> <output>")
    sys.exit(1)

input_path = sys.argv[1]
output_path = sys.argv[2]

# Load image
img = Image.open(input_path).convert("RGBA")
datas = img.getdata()

newData = []
for item in datas:
    # If pixel is white-ish (bright), make it transparent
    # Otherwise keep it (black shape)
    if item[0] > 230 and item[1] > 230 and item[2] > 230:
        newData.append((0, 0, 0, 0))  # Transparent
    else:
        newData.append((0, 0, 0, 255))  # Black, opaque

img.putdata(newData)
img.save(output_path, "PNG")
print(f"Created {output_path}")
