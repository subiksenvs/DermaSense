"""Sun damage and UV spot detection via blue-channel differential absorption."""
import cv2
import numpy as np
from typing import Dict


def sun_damage_map(img_bgr: np.ndarray, masks: Dict[str, np.ndarray]) -> np.ndarray:
    """
    Compute sub-surface sun damage and UV spot intensity map.

    Emulates clinical dermatological UV photography by analyzing
    differential blue-spectrum melanin absorption vs red reflectance.

    Args:
        img_bgr: Input BGR image
        masks: Dict of region masks

    Returns:
        Normalized sun damage / UV spot severity map [0, 1]
    """
    h, w = img_bgr.shape[:2]
    b = img_bgr[..., 0].astype(np.float32)
    g = img_bgr[..., 1].astype(np.float32)
    r = img_bgr[..., 2].astype(np.float32)

    face_mask = np.zeros((h, w), dtype=bool)
    for m in masks.values():
        face_mask |= m > 0

    if not face_mask.any():
        return np.zeros((h, w), dtype=np.float32)

    # Melanin absorption ratio: high R with low B indicates heavy melanin clusters
    melanin_absorption = (r - b) / (r + b + 1.0)
    melanin_absorption = np.clip(melanin_absorption, 0, None)

    # High-pass filter to isolate clustered actinic spots vs broad skin tone
    blur = cv2.GaussianBlur(melanin_absorption, (15, 15), 0)
    spot_contrast = np.clip(melanin_absorption - blur, 0, None)

    # Emphasize sun-exposed areas (forehead, nose, upper cheeks)
    sun_zone_weight = np.ones((h, w), dtype=np.float32)
    if "nose" in masks:
        sun_zone_weight += (masks["nose"] > 0) * 0.4
    if "forehead" in masks:
        sun_zone_weight += (masks["forehead"] > 0) * 0.3
    if "cheeks" in masks:
        sun_zone_weight += (masks["cheeks"] > 0) * 0.2

    damage_raw = (melanin_absorption * 0.4 + spot_contrast * 0.6) * sun_zone_weight
    damage_map = cv2.GaussianBlur(damage_raw, (7, 7), 2)

    face_vals = damage_map[face_mask]
    if len(face_vals) > 0 and face_vals.max() > 1e-6:
        p95 = np.percentile(face_vals, 95)
        damage_map = damage_map / (p95 + 1e-6)

    damage_map[~face_mask] = 0
    return np.clip(damage_map, 0, 1).astype(np.float32)
