"""Skin radiance and luminescence vs dullness estimation."""
import cv2
import numpy as np
from typing import Dict


def radiance_map(img_bgr: np.ndarray, masks: Dict[str, np.ndarray]) -> np.ndarray:
    """
    Compute skin dullness map (inverse of healthy radiance/glow).

    Analyzes diffuse reflectance, optical light scattering,
    and muddy/sallow micro-contrast deficits across facial zones.

    Args:
        img_bgr: Input BGR image
        masks: Dict of region masks

    Returns:
        Normalized dullness severity map [0, 1] (0 = radiant/glowing, 1 = dull/sallow)
    """
    h, w = img_bgr.shape[:2]
    lab = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2LAB).astype(np.float32)
    l_chan, a_chan, b_chan = lab[..., 0], lab[..., 1], lab[..., 2]

    face_mask = np.zeros((h, w), dtype=bool)
    for m in masks.values():
        face_mask |= m > 0

    if not face_mask.any():
        return np.zeros((h, w), dtype=np.float32)

    face_l = l_chan[face_mask]
    l_mean = np.mean(face_l)
    l_p85 = np.percentile(face_l, 85)

    # 1. Luminance deficiency (low diffuse glow)
    dull_lum = np.clip(l_p85 - l_chan, 0, None) / (l_p85 + 1e-6)

    # 2. Muddy/sallow undertones (high b* yellowish-brown without pinkish vitality)
    sallow_undertone = np.clip((b_chan - 128) - 0.5 * (a_chan - 128), 0, None) / 128.0

    # 3. Local contrast flatness (dead/flat light scattering)
    blur_l = cv2.GaussianBlur(l_chan, (21, 21), 0)
    flatness = 1.0 / (np.abs(l_chan - blur_l) + 1.0)

    dullness = (dull_lum * 0.45) + (sallow_undertone * 0.35) + (flatness * 0.20)
    dullness_map = cv2.GaussianBlur(dullness, (11, 11), 2)

    face_vals = dullness_map[face_mask]
    if len(face_vals) > 0 and face_vals.max() > 1e-6:
        p95 = np.percentile(face_vals, 95)
        dullness_map = dullness_map / (p95 + 1e-6)

    dullness_map[~face_mask] = 0
    return np.clip(dullness_map, 0, 1).astype(np.float32)
