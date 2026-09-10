"""Wrinkles and fine lines detection using multi-scale directional Gabor filter banks."""
import cv2
import numpy as np
from typing import Dict


def wrinkles_map(img_bgr: np.ndarray, masks: Dict[str, np.ndarray]) -> np.ndarray:
    """
    Compute wrinkle and fine line density map.

    Uses a bank of 2D Gabor wavelets across 4 orientations and 2 scales
    specifically tuned to detect elongated skin rhytides (forehead lines,
    crow's feet, nasolabial creases, and infraorbital fine lines).

    Args:
        img_bgr: Input BGR image
        masks: Dict of region masks

    Returns:
        Normalized wrinkle intensity map [0, 1]
    """
    h, w = img_bgr.shape[:2]
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)

    # Combined face mask
    face_mask = np.zeros((h, w), dtype=bool)
    for m in masks.values():
        face_mask |= m > 0

    if not face_mask.any():
        return np.zeros((h, w), dtype=np.float32)

    # Focus priority weighting on wrinkle-prone anatomical regions
    priority_mask = np.zeros((h, w), dtype=np.float32)
    if "forehead" in masks:
        priority_mask += (masks["forehead"] > 0) * 1.2
    if "crows_feet" in masks:
        priority_mask += (masks["crows_feet"] > 0) * 1.5
    if "nasolabial" in masks:
        priority_mask += (masks["nasolabial"] > 0) * 1.3
    if "under_eyes" in masks:
        priority_mask += (masks["under_eyes"] > 0) * 1.1
    priority_mask = np.clip(priority_mask, 0.6, 2.0)

    # Contrast enhancement for subtle line visibility
    clahe = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8))
    enhanced_gray = clahe.apply(gray)

    # Multi-directional Gabor filter bank
    # Wrinkles run horizontally (forehead), diagonally (crows feet), or vertically (nasolabial)
    thetas = [0, np.pi / 4, np.pi / 2, 3 * np.pi / 4]
    lambdas = [4.0, 7.0]  # fine lines to deeper creases
    accumulated_response = np.zeros((h, w), dtype=np.float32)

    for theta in thetas:
        for lambd in lambdas:
            kernel = cv2.getGaborKernel(
                ksize=(15, 15),
                sigma=2.0,
                theta=theta,
                lambd=lambd,
                gamma=0.5,
                psi=0,
                ktype=cv2.CV_32F
            )
            filtered = cv2.filter2D(enhanced_gray, cv2.CV_32F, kernel)
            filtered = np.abs(filtered)
            accumulated_response = np.maximum(accumulated_response, filtered)

    # High-pass line verification (wrinkles must be dark linear valleys)
    blur = cv2.GaussianBlur(enhanced_gray, (9, 9), 0)
    dark_valleys = np.clip(blur.astype(np.float32) - enhanced_gray.astype(np.float32), 0, None)

    # Combine Gabor response with dark valleys
    wrinkle_raw = accumulated_response * (dark_valleys / (dark_valleys.max() + 1e-6))
    wrinkle_raw *= priority_mask

    # Smooth into a continuous heatmap
    wrinkle_map = cv2.GaussianBlur(wrinkle_raw, (7, 7), 2)

    # Normalize within face
    face_vals = wrinkle_map[face_mask]
    if len(face_vals) > 0 and face_vals.max() > 1e-6:
        p95 = np.percentile(face_vals, 95)
        p5 = np.percentile(face_vals, 5)
        if p95 > p5:
            wrinkle_map = np.clip((wrinkle_map - p5) / (p95 - p5), 0, 1)
        else:
            wrinkle_map = wrinkle_map / face_vals.max()

    wrinkle_map[~face_mask] = 0
    return np.clip(wrinkle_map, 0, 1).astype(np.float32)
