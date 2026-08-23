import urllib.request
import cv2
import numpy as np
from src.pipeline.compose import run_scan

req = urllib.request.Request('https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/Vijay_in_2023.jpg/800px-Vijay_in_2023.jpg', headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req) as response:
    img_array = np.asarray(bytearray(response.read()), dtype=np.uint8)
    img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

try:
    print(run_scan(img)['scores'])
except Exception as e:
    import traceback
    traceback.print_exc()
