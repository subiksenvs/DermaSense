"""Dark circles detection via infraorbital color difference (Delta E) and vascular pooling."""
import cv2
import numpy as np
from typing import Dict


def dark_circles_map(img_bgr: np.ndarray, masks: Dict[str, np.ndarray]) -> np.ndarray:
    """
    Compute dark circles intensity map.

    Compares infraorbital under-eye skin to reference cheek skin tone
    using CIELAB Delta E and lightness deficit (L*).

    Args:
        img_bgr: Input BGR image
        masks: Dict of region masks

    Returns:
        Normalized dark circle severity map [0, 1]
    """
    h, w = img_bgr.shape[:2]
    lab = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2LAB).astype(np.float32)
    l_chan, a_chan, b_chan = lab[..., 0], lab[..., 1], lab[..., 2]

    under_eye_mask = masks.get("under_eyes", None)
    cheek_mask = masks.get("cheeks", None)

    if under_eye_mask is None or np.count_nonzero(under_eye_mask) == 0:
        # Fallback under-eye zone
        under_eye_mask = np.zeros((h, w), dtype=np.uint8)
        cv2.ellipse(under_eye_mask, (int(w * 0.35), int(h * 0.40)), (int(w * 0.12), int(h * 0.08)), 0, 0, 360, 255, -1)
        cv2.ellipse(under_eye_mask, (int(w * 0.65), int(h * 0.40)), (int(w * 0.12), int(h * 0.08)), 0, 0, 360, 255, -1)

    # Reference cheek tone
    if cheek_mask is not None and np.count_nonzero(cheek_mask) > 100:
        ref_l = np.median(l_chan[cheek_mask > 0])
        ref_a = np.median(a_chan[cheek_mask > 0])
        ref_b = np.median(b_chan[cheek_mask > 0])
    else:
        ref_l = np.median(l_chan)
        ref_a = np.median(a_chan)
        ref_b = np.median(b_chan)

    # 1. Darkness deficit (under eye is darker than cheek)
    darkness_deficit = np.clip(ref_l - l_chan, 0, None)

    # 2. Vascular pooling (higher a* or lower b* indicates bluish-red/purple undertones)
    vascular_component = np.clip((a_chan - ref_a) + (ref_b - b_chan), 0, None)

    # 3. Overall CIELAB Delta E in under-eye region
    delta_e = np.sqrt(
        (l_chan - ref_l) ** 2 +
        (a_chan - ref_a) ** 2 +
        (b_chan - ref_b) ** 2
    )

    combined_intensity = darkness_deficit * 0.5 + vascular_component * 0.25 + delta_e * 0.25

    # Mask strictly to infraorbital region with soft edge transition
    dilated_under_eye = cv2.dilate(under_eye_mask, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15, 15)))
    soft_mask = cv2.GaussianBlur(dilated_under_eye.astype(np.float32) / 255.0, (15, 15), 0)

    circle_map = combined_intensity * soft_mask

    # Normalize map [0, 1]
    active_vals = circle_map[dilated_under_eye > 0]
    if len(active_vals) > 0 and active_vals.max() > 1e-6:
        circle_map = circle_map / (np.percentile(active_vals, 95) + 1e-6)

    return np.clip(circle_map, 0, 1).astype(np.float32)
