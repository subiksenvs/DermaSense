"""Skin tone evenness and dyschromia analysis using Individual Typology Angle (ITA) variance."""
import cv2
import numpy as np
from typing import Dict


def tone_evenness_map(img_bgr: np.ndarray, masks: Dict[str, np.ndarray]) -> np.ndarray:
    """
    Compute skin tone unevenness / mottled dyschromia map.

    Calculates localized standard deviation of chromaticity (CIELAB a*, b*)
    and Individual Typology Angle (ITA) across facial regions.

    Args:
        img_bgr: Input BGR image
        masks: Dict of region masks

    Returns:
        Normalized tone unevenness map [0, 1] (0 = perfectly even, 1 = mottled/uneven)
    """
    h, w = img_bgr.shape[:2]
    lab = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2LAB).astype(np.float32)
    l_chan, a_chan, b_chan = lab[..., 0], lab[..., 1], lab[..., 2]

    face_mask = np.zeros((h, w), dtype=bool)
    for m in masks.values():
        face_mask |= m > 0

    if not face_mask.any():
        return np.zeros((h, w), dtype=np.float32)

    # Individual Typology Angle (ITA) calculation: ITA = arctan((L - 50) / b) * 180 / pi
    b_safe = np.where(np.abs(b_chan - 128) < 1e-3, 1e-3, b_chan - 128)
    ita = np.arctan((l_chan * (100.0 / 255.0) - 50.0) / b_safe) * (180.0 / np.pi)

    # Local spatial standard deviation of ITA
    ita_blur = cv2.GaussianBlur(ita, (21, 21), 0)
    ita_std = np.sqrt(cv2.GaussianBlur((ita - ita_blur) ** 2, (21, 21), 0))

    # Local standard deviation of a* (redness blotchiness)
    a_blur = cv2.GaussianBlur(a_chan, (21, 21), 0)
    a_std = np.sqrt(cv2.GaussianBlur((a_chan - a_blur) ** 2, (21, 21), 0))

    # Combine ITA variance and chromaticity variance
    unevenness = (ita_std * 0.6) + (a_std * 0.4)
    unevenness_map = cv2.GaussianBlur(unevenness, (9, 9), 2)

    face_vals = unevenness_map[face_mask]
    if len(face_vals) > 0 and face_vals.max() > 1e-6:
        p95 = np.percentile(face_vals, 95)
        p5 = np.percentile(face_vals, 5)
        if p95 > p5:
            unevenness_map = np.clip((unevenness_map - p5) / (p95 - p5), 0, 1)
        else:
            unevenness_map = unevenness_map / (face_vals.max() + 1e-6)

    unevenness_map[~face_mask] = 0
    return np.clip(unevenness_map, 0, 1).astype(np.float32)
