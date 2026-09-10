"""Pore dilation severity map detecting visibly enlarged and clogged follicular openings."""
import cv2
import numpy as np
from typing import Dict


def pore_dilation_map(img_bgr: np.ndarray, masks: Dict[str, np.ndarray], context=None) -> np.ndarray:
    """
    Compute dilated / enlarged pore severity map.
    """
    h, w = img_bgr.shape[:2]
    gray = context.gray if context is not None else cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    face_mask = context.face_mask if context is not None else None

    if face_mask is None:
        face_mask = np.zeros((h, w), dtype=bool)
        for m in masks.values():
            face_mask |= m > 0

    if not face_mask.any():
        return np.zeros((h, w), dtype=np.float32)

    # Black-hat transform extracts dark circular depressions larger than typical micro-pores
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7, 7))
    blackhat = cv2.morphologyEx(gray, cv2.MORPH_BLACKHAT, kernel)

    # Threshold for significant follicular depression depth
    _, dilated_thresh = cv2.threshold(blackhat, 10, 255, cv2.THRESH_TOZERO)

    # Connected component analysis to filter by dilated pore size
    num_labels, labels, stats, centroids = cv2.connectedComponentsWithStats(
        (dilated_thresh > 0).astype(np.uint8), connectivity=8
    )

    dilated_mask = np.zeros((h, w), dtype=np.float32)
    for i in range(1, num_labels):
        area = stats[i, cv2.CC_STAT_AREA]
        # Dilated pores have larger area than fine micro-pores
        if 10 <= area <= 150:
            dilated_mask[labels == i] = float(area)

    # Smooth into a continuous heatmap
    dilation_density = cv2.GaussianBlur(dilated_mask, (15, 15), 5)

    # Emphasize T-zone and central cheeks where dilation is clinically relevant
    t_zone_boost = np.ones((h, w), dtype=np.float32)
    if "nose" in masks:
        t_zone_boost += (masks["nose"] > 0) * 0.5
    if "cheeks" in masks:
        t_zone_boost += (masks["cheeks"] > 0) * 0.3

    dilation_density *= t_zone_boost

    face_vals = dilation_density[face_mask]
    if len(face_vals) > 0 and face_vals.max() > 1e-6:
        p95 = np.percentile(face_vals, 95)
        dilation_density = dilation_density / (p95 + 1e-6)

    dilation_density[~face_mask] = 0
    return np.clip(dilation_density, 0, 1).astype(np.float32)
