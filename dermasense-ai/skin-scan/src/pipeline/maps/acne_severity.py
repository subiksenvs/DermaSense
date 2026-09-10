"""Inflammatory acne and active breakout severity detection."""
import cv2
import numpy as np
from typing import Dict


def acne_severity_map(img_bgr: np.ndarray, masks: Dict[str, np.ndarray], context=None) -> np.ndarray:
    """
    Compute inflammatory acne and breakout severity map.
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

    # 1. Inflammatory redness halo (elevated a* compared to local skin)
    a_face = a_chan[face_mask]
    a_thresh = np.percentile(a_face, 75)
    inflamed_halo = np.clip(a_chan - a_thresh, 0, None)

    # 2. Elevated papule/pustule core (morphological top-hat and black-hat)
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (11, 11))
    tophat = cv2.morphologyEx(gray, cv2.MORPH_TOPHAT, kernel)
    blackhat = cv2.morphologyEx(gray, cv2.MORPH_BLACKHAT, kernel)
    core_contrast = np.maximum(tophat, blackhat).astype(np.float32)

    # Combine: inflammatory lesion must have BOTH elevated redness AND localized core contrast
    acne_score = (inflamed_halo * 0.6) + (core_contrast * 0.4)

    # Filter out large flat areas using morphological open
    kernel_clean = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
    acne_score = cv2.morphologyEx(acne_score, cv2.MORPH_OPEN, kernel_clean)

    acne_map = cv2.GaussianBlur(acne_score, (9, 9), 2)

    face_vals = acne_map[face_mask]
    if len(face_vals) > 0 and face_vals.max() > 1e-6:
        p95 = np.percentile(face_vals, 95)
        acne_map = acne_map / (p95 + 1e-6)

    acne_map[~face_mask] = 0
    return np.clip(acne_map, 0, 1).astype(np.float32)
