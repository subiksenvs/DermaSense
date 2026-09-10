"""Texture map using vectorized micro-roughness gradient analysis."""
import cv2
import numpy as np


def texture_map(img_bgr: np.ndarray, masks: dict[str, np.ndarray], context=None) -> np.ndarray:
    """
    Compute texture/roughness map.
    Uses high-speed vectorized Scharr gradient and Laplacian variance.
    Higher values indicate rougher texture.
    """
    gray = context.gray if context is not None else cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    face_mask = context.face_mask if context is not None else None

    if face_mask is None:
        face_mask = np.zeros(img_bgr.shape[:2], dtype=bool)
        for region_mask in masks.values():
            face_mask |= region_mask > 0

    if not face_mask.any():
        return np.zeros(img_bgr.shape[:2], dtype=np.float32)

    # Method 1: Local Laplacian micro-contrast
    laplacian = cv2.Laplacian(gray, cv2.CV_32F, ksize=3)
    variance = cv2.GaussianBlur(laplacian**2, (7, 7), 0)

    # Method 2: Vectorized Scharr micro-roughness gradient tensor
    scharr_x = cv2.Scharr(gray, cv2.CV_32F, 1, 0)
    scharr_y = cv2.Scharr(gray, cv2.CV_32F, 0, 1)
    gradient_energy = cv2.GaussianBlur(scharr_x**2 + scharr_y**2, (7, 7), 0)

    # Combine both metrics
    var_norm = variance / (variance[face_mask].max() + 1e-6)
    grad_norm = gradient_energy / (gradient_energy[face_mask].max() + 1e-6)

    texture = 0.5 * var_norm + 0.5 * grad_norm

    # Normalize to [0, 1]
    face_vals = texture[face_mask]
    if len(face_vals) > 0 and face_vals.max() > 1e-6:
        p95 = np.percentile(face_vals, 95)
        p5 = np.percentile(face_vals, 5)
        if p95 > p5:
            texture = np.clip((texture - p5) / (p95 - p5), 0, 1)
        else:
            texture = texture / face_vals.max()

    texture = np.clip(texture, 0, 1)
    texture[~face_mask] = 0

    return texture.astype(np.float32)

