"""Eye bags and infraorbital puffiness detection via 3D contour shadow gradient."""
import cv2
import numpy as np
from typing import Dict


def eye_bags_map(img_bgr: np.ndarray, masks: Dict[str, np.ndarray], context=None) -> np.ndarray:
    """
    Compute eye bags and puffiness severity map.
    Detects 3D contour bulge using vertical luminance gradients.
    """
    h, w = img_bgr.shape[:2]
    gray = context.gray.astype(np.float32) if context is not None else cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY).astype(np.float32)

    under_eye_mask = masks.get("under_eyes", None)
    if under_eye_mask is None or np.count_nonzero(under_eye_mask) == 0:
        under_eye_mask = np.zeros((h, w), dtype=np.uint8)
        cv2.ellipse(under_eye_mask, (int(w * 0.35), int(h * 0.40)), (int(w * 0.12), int(h * 0.08)), 0, 0, 360, 255, -1)
        cv2.ellipse(under_eye_mask, (int(w * 0.65), int(h * 0.40)), (int(w * 0.12), int(h * 0.08)), 0, 0, 360, 255, -1)

    # Vertical gradient: puffy bags have bright top curve transitioning to dark shadow trough
    sobel_y = cv2.Sobel(gray, cv2.CV_32F, 0, 1, ksize=5)
    # Positive vertical gradient corresponds to light-to-shadow transition under gravity
    downward_shadow = np.clip(sobel_y, 0, None)

    # Local variance to detect swollen tissue contour
    blur = cv2.GaussianBlur(gray, (15, 15), 0)
    curvature = np.abs(gray - blur)

    puffiness_raw = (downward_shadow * 0.7) + (curvature * 0.3)

    # Soft infraorbital mask
    dilated = cv2.dilate(under_eye_mask, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (11, 11)))
    soft_mask = cv2.GaussianBlur(dilated.astype(np.float32) / 255.0, (11, 11), 0)

    bags_map = puffiness_raw * soft_mask
    bags_map = cv2.GaussianBlur(bags_map, (9, 9), 2)

    active_vals = bags_map[dilated > 0]
    if len(active_vals) > 0 and active_vals.max() > 1e-6:
        bags_map = bags_map / (np.percentile(active_vals, 95) + 1e-6)

    return np.clip(bags_map, 0, 1).astype(np.float32)
