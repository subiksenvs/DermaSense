"""Hydration map - proxy via texture and specular response."""
import cv2
import numpy as np


def hydration_map(img_bgr: np.ndarray, masks: dict[str, np.ndarray], context=None) -> np.ndarray:
    """
    Compute hydration map (proxy metric).
    """
    if context is not None:
        gray = context.gray
        face_mask = context.face_mask
        v_channel = context.hsv[..., 2].astype(np.float32)
    else:
        gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
        face_mask = np.zeros(img_bgr.shape[:2], dtype=bool)
        for region_mask in masks.values():
            face_mask |= region_mask > 0
        hsv = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2HSV)
        v_channel = hsv[..., 2].astype(np.float32)

    if not face_mask.any():
        return np.zeros(img_bgr.shape[:2], dtype=np.float32)

    # Feature 1: Smoothness (inverse of high-frequency content)
    # Compute local variance
    laplacian = cv2.Laplacian(gray, cv2.CV_32F, ksize=3)
    roughness = cv2.GaussianBlur(np.abs(laplacian), (9, 9), 0)

    # Invert: high roughness = low hydration
    smoothness = 1.0 / (roughness + 1e-6)
    smoothness = smoothness / (smoothness[face_mask].max() + 1e-6)

    # Compute local standard deviation of brightness
    v_blur = cv2.GaussianBlur(v_channel, (15, 15), 0)
    v_std = cv2.GaussianBlur((v_channel - v_blur) ** 2, (15, 15), 0)
    evenness = 1.0 / (np.sqrt(v_std) + 1e-6)
    evenness = evenness / (evenness[face_mask].max() + 1e-6)

    # Feature 3: Absence of dry flaky patches (low texture variance)
    # Compute gradient magnitude
    grad_x = cv2.Sobel(gray, cv2.CV_32F, 1, 0, ksize=3)
    grad_y = cv2.Sobel(gray, cv2.CV_32F, 0, 1, ksize=3)
    grad_mag = np.sqrt(grad_x**2 + grad_y**2)

    # Low gradient = smooth = hydrated
    grad_smooth = 1.0 / (grad_mag + 1e-6)
    grad_smooth = grad_smooth / (grad_smooth[face_mask].max() + 1e-6)

    # Combine features (weighted average)
    hydration = 0.4 * smoothness + 0.3 * evenness + 0.3 * grad_smooth

    # Normalize to [0, 1]
    if face_mask.any():
        face_vals = hydration[face_mask]
        h_min, h_max = face_vals.min(), face_vals.max()
        if h_max - h_min > 1e-6:
            hydration = (hydration - h_min) / (h_max - h_min)

    hydration = np.clip(hydration, 0, 1)
    hydration[~face_mask] = 0

    # Invert to match convention: higher value = more hydrated
    # (our features measure dryness, so invert)
    return hydration.astype(np.float32)
