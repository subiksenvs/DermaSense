"""Image I/O utilities with EXIF scrubbing."""
import base64
import io
import cv2
import numpy as np
from PIL import Image


def read_image_bgr(data: bytes) -> np.ndarray:
    """
    Read image from bytes directly into BGR numpy array using OpenCV.
    Completely avoids PIL heap object allocation and strips EXIF naturally.
    Immediately downscales large camera images to max 512px to guarantee low memory.
    """
    nparr = np.frombuffer(data, np.uint8)
    img_bgr = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if img_bgr is None:
        raise ValueError("Failed to decode image")

    # Ingest directly at analysis resolution (max 512px)
    h, w = img_bgr.shape[:2]
    if max(h, w) > 512:
        scale = 512.0 / max(h, w)
        new_w = int(w * scale)
        new_h = int(h * scale)
        img_bgr = cv2.resize(img_bgr, (new_w, new_h), interpolation=cv2.INTER_AREA)

    return img_bgr


def encode_png_base64(img: np.ndarray) -> str:
    """
    Encode numpy array as base64 PNG data URI with optimal compression.
    """
    # Use PNG compression level 4 for fast encoding and low RAM
    success, buffer = cv2.imencode(".png", img, [cv2.IMWRITE_PNG_COMPRESSION, 4])
    if not success:
        raise ValueError("Failed to encode image as PNG")

    b64_str = base64.b64encode(buffer).decode("ascii")
    return f"data:image/png;base64,{b64_str}"



def resize_max(img: np.ndarray, max_size: int) -> np.ndarray:
    """Resize image so largest dimension is max_size, maintaining aspect ratio."""
    h, w = img.shape[:2]
    if max(h, w) <= max_size:
        return img

    scale = max_size / max(h, w)
    new_w = int(w * scale)
    new_h = int(h * scale)
    return cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_AREA)
