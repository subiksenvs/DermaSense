"""Pipeline composition - orchestrates the comprehensive skin scan analysis."""
import numpy as np
import logging
from typing import Dict

from .preprocess import preprocess
from .face_mesh import FaceMeshDetector, make_region_masks, make_fallback_skin_masks

# Existing clinical maps
from .maps.redness import redness_map
from .maps.oiliness import oiliness_map
from .maps.texture import texture_map
from .maps.pores import pores_map
from .maps.blemishes import blemish_map
from .maps.hydration import hydration_map
from .maps.pigment import pigment_map

# 10 Vital Additional Diagnostic Maps
from .maps.wrinkles import wrinkles_map
from .maps.dark_circles import dark_circles_map
from .maps.eye_bags import eye_bags_map
from .maps.firmness import firmness_map
from .maps.radiance import radiance_map
from .maps.tone_evenness import tone_evenness_map
from .maps.sun_damage import sun_damage_map
from .maps.pore_dilation import pore_dilation_map
from .maps.barrier_health import barrier_health_map
from .maps.acne_severity import acne_severity_map

from .visualize import generate_all_overlays
from ..app.utils_io import encode_png_base64

logger = logging.getLogger(__name__)


def score_from_map(map_data: np.ndarray, masks: dict[str, np.ndarray]) -> float:
    """
    Compute single score from map using region-weighted average.

    Args:
        map_data: Normalized map [0, 1]
        masks: Region masks

    Returns:
        Score [0, 1]
    """
    # Create combined face mask
    face_mask = np.zeros(map_data.shape, dtype=bool)
    for region_mask in masks.values():
        face_mask |= region_mask > 0

    if not face_mask.any():
        return 0.0

    face_vals = map_data[face_mask]
    if len(face_vals) == 0:
        return 0.0
    return float(np.mean(face_vals))


# Global cached instance
_detector = None


def get_detector():
    global _detector
    if _detector is None:
        try:
            _detector = FaceMeshDetector()
        except Exception as e:
            logger.warning(f"Could not initialize MediaPipe FaceMeshDetector: {e}")
            _detector = None
    return _detector


def run_scan(img: np.ndarray) -> Dict:
    """
    Run complete 17-feature skin scan pipeline with dual-engine fail-safe fallback.

    Args:
        img: Input BGR image

    Returns:
        Dict with keys:
        - scores: dict[str, float] (17 normalized diagnostic scores)
        - overlays: dict[str, str] (base64 PNG heatmaps)
        - regions: list[str]
    """
    # Preprocess
    img_processed = preprocess(img, max_size=640)

    # Primary: Face landmarks detection
    detector = get_detector()
    landmarks = None
    if detector is not None:
        try:
            landmarks = detector.detect(img_processed)
        except Exception as e:
            logger.warning(f"Face landmark detection encountered error: {e}")
            landmarks = None

    if landmarks is not None:
        masks = make_region_masks(landmarks, img_processed.shape)
    else:
        # Fail-Safe Fallback: Automatic Skin Chromaticity Segmentation
        # Ensures analysis NEVER fails even for macro skin crops or angled selfies!
        logger.info("FaceMesh landmarks not found; engaging intelligent skin segmentation fallback.")
        masks = make_fallback_skin_masks(img_processed)

    # Execute all 17 clinical diagnostic maps
    maps = {
        # Core Clinical Markers
        "redness": redness_map(img_processed, masks),
        "oiliness": oiliness_map(img_processed, masks),
        "texture": texture_map(img_processed, masks),
        "pores": pores_map(img_processed, masks),
        "blemishes": blemish_map(img_processed, masks),
        "hydration": hydration_map(img_processed, masks),
        "pigment": pigment_map(img_processed, masks),

        # 10 Vital Additional Features
        "wrinkles": wrinkles_map(img_processed, masks),
        "dark_circles": dark_circles_map(img_processed, masks),
        "eye_bags": eye_bags_map(img_processed, masks),
        "firmness": firmness_map(img_processed, masks),
        "radiance": radiance_map(img_processed, masks),
        "tone_evenness": tone_evenness_map(img_processed, masks),
        "sun_damage": sun_damage_map(img_processed, masks),
        "pore_dilation": pore_dilation_map(img_processed, masks),
        "barrier_health": barrier_health_map(img_processed, masks),
        "acne_severity": acne_severity_map(img_processed, masks),
    }

    # Compute scores for each metric
    scores = {name: score_from_map(map_data, masks) for name, map_data in maps.items()}

    # Generate overlay heatmaps
    overlay_images = generate_all_overlays(maps, alpha=0.6)

    # Encode overlays to base64 PNG
    overlays = {
        name: encode_png_base64(overlay_rgba)
        for name, overlay_rgba in overlay_images.items()
    }

    regions = list(masks.keys())

    return {
        "scores": scores,
        "overlays": overlays,
        "regions": regions,
    }

