"""Skin barrier health and sensitivity compromise index."""
import cv2
import numpy as np
from typing import Dict


def barrier_health_map(img_bgr: np.ndarray, masks: Dict[str, np.ndarray], context=None) -> np.ndarray:
    """
    Compute skin barrier compromise / sensitivity map.
    """
    h, w = img_bgr.shape[:2]
    if context is not None:
        gray = context.gray
        a_chan = context.lab[..., 1].astype(np.float32)
        face_mask = context.face_mask
    else:
        gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
        lab = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2LAB).astype(np.float32)
        a_chan = lab[..., 1]
        face_mask = np.zeros((h, w), dtype=bool)
        for m in masks.values():
            face_mask |= m > 0

    if not face_mask.any():
        return np.zeros((h, w), dtype=np.float32)

    # 1. Micro-flakiness: high-frequency surface noise (stratum corneum peeling)
    high_freq = cv2.Laplacian(gray, cv2.CV_32F, ksize=3)
    micro_flaking = cv2.GaussianBlur(np.abs(high_freq), (9, 9), 0)

    # 2. Sub-clinical erythema (reactive micro-inflammation)
    a_face = a_chan[face_mask]
    a_median = np.median(a_face)
    erythema_excess = np.clip(a_chan - a_median, 0, None)

    # 3. Patchy dryness: local brightness standard deviation
    blur = cv2.GaussianBlur(gray.astype(np.float32), (15, 15), 0)
    patchiness = cv2.GaussianBlur(np.abs(gray.astype(np.float32) - blur), (15, 15), 0)

    compromise = (micro_flaking * 0.4) + (erythema_excess * 0.4) + (patchiness * 0.2)
    compromise_map = cv2.GaussianBlur(compromise, (11, 11), 3)

    face_vals = compromise_map[face_mask]
    if len(face_vals) > 0 and face_vals.max() > 1e-6:
        p95 = np.percentile(face_vals, 95)
        compromise_map = compromise_map / (p95 + 1e-6)

    compromise_map[~face_mask] = 0
    return np.clip(compromise_map, 0, 1).astype(np.float32)
