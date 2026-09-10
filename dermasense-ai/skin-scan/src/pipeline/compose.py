"""Pipeline composition - orchestrates the comprehensive skin scan analysis."""
import cv2
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
    # Preprocess - optimal 512px analysis resolution
    img_processed = preprocess(img, max_size=512)

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
        logger.info("FaceMesh landmarks not found; engaging intelligent skin segmentation fallback.")
        masks = make_fallback_skin_masks(img_processed)

    # Clinical colormaps per category
    colormaps = {
        "redness": cv2.COLORMAP_HOT,
        "oiliness": cv2.COLORMAP_VIRIDIS,
        "texture": cv2.COLORMAP_BONE,
        "pores": cv2.COLORMAP_COOL,
        "blemishes": cv2.COLORMAP_AUTUMN,
        "hydration": cv2.COLORMAP_OCEAN,
        "pigment": cv2.COLORMAP_PINK,
        "wrinkles": cv2.COLORMAP_MAGMA,
        "dark_circles": cv2.COLORMAP_TWILIGHT,
        "eye_bags": cv2.COLORMAP_INFERNO,
        "firmness": cv2.COLORMAP_CIVIDIS,
        "radiance": cv2.COLORMAP_SUMMER,
        "tone_evenness": cv2.COLORMAP_TURBO,
        "sun_damage": cv2.COLORMAP_JET,
        "pore_dilation": cv2.COLORMAP_COOL,
        "barrier_health": cv2.COLORMAP_SPRING,
        "acne_severity": cv2.COLORMAP_HOT,
    }

    map_functions = {
        "redness": redness_map,
        "oiliness": oiliness_map,
        "texture": texture_map,
        "pores": pores_map,
        "blemishes": blemish_map,
        "hydration": hydration_map,
        "pigment": pigment_map,
        "wrinkles": wrinkles_map,
        "dark_circles": dark_circles_map,
        "eye_bags": eye_bags_map,
        "firmness": firmness_map,
        "radiance": radiance_map,
        "tone_evenness": tone_evenness_map,
        "sun_damage": sun_damage_map,
        "pore_dilation": pore_dilation_map,
        "barrier_health": barrier_health_map,
        "acne_severity": acne_severity_map,
    }

    scores = {}
    overlays = {}

    # Streamlined execution: compute one map at a time, score it, generate compressed overlay,
    # and immediately free raw arrays so peak memory never exceeds ~80MB!
    from .visualize import create_heatmap_overlay
    for name, func in map_functions.items():
        raw_map = func(img_processed, masks)
        scores[name] = score_from_map(raw_map, masks)

        # Downsample map to max 300px for mobile overlay preview
        mh, mw = raw_map.shape[:2]
        if max(mh, mw) > 300:
            scale = 300.0 / max(mh, mw)
            small_map = cv2.resize(raw_map, (int(mw * scale), int(mh * scale)), interpolation=cv2.INTER_AREA)
        else:
            small_map = raw_map

        cmap = colormaps.get(name, cv2.COLORMAP_JET)
        overlay_rgba = create_heatmap_overlay(small_map, cmap, alpha=0.6)
        overlays[name] = encode_png_base64(overlay_rgba)

        del raw_map
        del overlay_rgba

    regions = list(masks.keys())

    return {
        "scores": scores,
        "overlays": overlays,
        "regions": regions,
    }

