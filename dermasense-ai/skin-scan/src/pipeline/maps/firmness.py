"""Skin firmness and laxity estimation via contour tension and gravitational descent vectors."""
import cv2
import numpy as np
from typing import Dict


def firmness_map(img_bgr: np.ndarray, masks: Dict[str, np.ndarray]) -> np.ndarray:
    """
    Compute skin laxity / sagging severity map (inverse of firmness).

    Evaluates structural contour tension, downward tissue vectors,
    and micro-folds around jawline, jowls, and cheek borders.

    Args:
        img_bgr: Input BGR image
        masks: Dict of region masks

    Returns:
        Normalized laxity / sagging severity map [0, 1]
    """
    h, w = img_bgr.shape[:2]
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)

    face_mask = np.zeros((h, w), dtype=bool)
    for m in masks.values():
        face_mask |= m > 0

    if not face_mask.any():
        return np.zeros((h, w), dtype=np.float32)

    # Gravitational descent analysis: vertical structure tensor
    dx = cv2.Sobel(gray, cv2.CV_32F, 1, 0, ksize=3)
    dy = cv2.Sobel(gray, cv2.CV_32F, 0, 1, ksize=3)

    # Sagging produces downward tension folds (dominant vertical gradient)
    descent_intensity = np.abs(dy) - 0.5 * np.abs(dx)
    descent_intensity = np.clip(descent_intensity, 0, None)

    # Lower face and jawline weighting (jowls & chin laxity)
    lower_face_weight = np.linspace(0.4, 1.8, h).reshape(-1, 1).repeat(w, axis=1)
    laxity = descent_intensity * lower_face_weight

    laxity_map = cv2.GaussianBlur(laxity, (15, 15), 4)

    # Normalize within face
    face_vals = laxity_map[face_mask]
    if len(face_vals) > 0 and face_vals.max() > 1e-6:
        p95 = np.percentile(face_vals, 95)
        laxity_map = laxity_map / (p95 + 1e-6)

    laxity_map[~face_mask] = 0
    return np.clip(laxity_map, 0, 1).astype(np.float32)
