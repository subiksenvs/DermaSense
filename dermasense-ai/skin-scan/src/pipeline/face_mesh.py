"""Face mesh detection using MediaPipe and region mask generation with fail-safe fallback."""
import cv2
import numpy as np
import mediapipe as mp
from typing import Optional, Dict
import os
import urllib.request


class FaceMeshDetector:
    """MediaPipe face mesh detector using modern Tasks API."""

    def __init__(self):
        model_path = os.path.join(os.path.dirname(__file__), 'face_landmarker.task')
        if not os.path.exists(model_path):
            print("Downloading face_landmarker.task...")
            urllib.request.urlretrieve(
                'https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task',
                model_path
            )

        BaseOptions = mp.tasks.BaseOptions
        FaceLandmarker = mp.tasks.vision.FaceLandmarker
        FaceLandmarkerOptions = mp.tasks.vision.FaceLandmarkerOptions
        VisionRunningMode = mp.tasks.vision.RunningMode

        options = FaceLandmarkerOptions(
            base_options=BaseOptions(model_asset_path=model_path),
            running_mode=VisionRunningMode.IMAGE,
            num_faces=1,
            output_face_blendshapes=False,
            output_facial_transformation_matrixes=False
        )
        self.detector = FaceLandmarker.create_from_options(options)

    def detect(self, img_bgr: np.ndarray) -> Optional[np.ndarray]:
        """
        Detect face landmarks.

        Args:
            img_bgr: Input BGR image

        Returns:
            Landmarks as (N, 2) array of (x, y) pixel coordinates, or None
        """
        img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=img_rgb)

        results = self.detector.detect(mp_image)

        if not results.face_landmarks:
            return None

        face_landmarks = results.face_landmarks[0]
        h, w = img_bgr.shape[:2]
        landmarks = []
        for landmark in face_landmarks:
            x = int(landmark.x * w)
            y = int(landmark.y * h)
            landmarks.append([x, y])

        return np.array(landmarks, dtype=np.int32)

    def __del__(self):
        if hasattr(self, "detector"):
            try:
                self.detector.close()
            except Exception:
                pass


def make_region_masks(landmarks: np.ndarray, img_shape: tuple) -> Dict[str, np.ndarray]:
    """
    Create region masks for anatomical facial areas.
    """
    h, w = img_shape[:2]
    masks = {}

    def create_mask_from_indices(indices, shape):
        mask = np.zeros(shape, dtype=np.uint8)
        if len(indices) == 0:
            return mask
        valid_indices = [i for i in indices if i < len(landmarks)]
        if len(valid_indices) < 3:
            return mask
        points = landmarks[valid_indices]
        hull = cv2.convexHull(points)
        cv2.fillConvexPoly(mask, hull, 255)
        return mask

    # Anatomical index definitions
    forehead_indices = [10, 338, 297, 332, 284, 251, 389, 356, 454, 323, 361, 288,
                        397, 365, 379, 378, 400, 377, 152, 148, 176, 149, 150, 136,
                        172, 58, 132, 93, 234, 127, 162, 21, 54, 103, 67, 109]

    nose_indices = [168, 6, 197, 195, 5, 4, 1, 19, 94, 2, 164, 0, 11, 12,
                    13, 14, 15, 16, 17, 18, 200, 199, 175, 152]

    chin_indices = [152, 175, 200, 201, 18, 421, 406, 335, 273, 377, 400, 378]

    # Under-eye / infraorbital regions for dark circles & eye bags
    left_eye_indices = [33, 7, 163, 144, 145, 153, 154, 155, 133, 230, 229, 228, 116, 111, 117]
    right_eye_indices = [362, 382, 381, 380, 374, 373, 390, 249, 263, 450, 449, 448, 345, 340, 346]

    # Crow's feet / outer eye corners
    crows_feet_indices = [33, 130, 247, 30, 29, 27, 28, 56, 190, 243,
                          263, 359, 467, 260, 259, 257, 258, 286, 414, 463]

    # Nasolabial fold / smile line indices
    nasolabial_indices = [205, 206, 207, 192, 214, 212, 186, 425, 426, 427, 416, 434, 432, 410]

    masks["forehead"] = create_mask_from_indices(forehead_indices[:20], (h, w))
    masks["nose"] = create_mask_from_indices(nose_indices, (h, w))
    masks["chin"] = create_mask_from_indices(chin_indices, (h, w))
    
    # Under eye mask
    left_under_eye = create_mask_from_indices(left_eye_indices, (h, w))
    right_under_eye = create_mask_from_indices(right_eye_indices, (h, w))
    masks["under_eyes"] = cv2.bitwise_or(left_under_eye, right_under_eye)
    
    masks["crows_feet"] = create_mask_from_indices(crows_feet_indices, (h, w))
    masks["nasolabial"] = create_mask_from_indices(nasolabial_indices, (h, w))

    # Cheeks
    left_side = landmarks[landmarks[:, 0] < w // 2]
    right_side = landmarks[landmarks[:, 0] >= w // 2]
    left_cheek = np.zeros((h, w), dtype=np.uint8)
    right_cheek = np.zeros((h, w), dtype=np.uint8)
    if len(left_side) > 3:
        hull = cv2.convexHull(left_side)
        cv2.fillConvexPoly(left_cheek, hull, 255)
    if len(right_side) > 3:
        hull = cv2.convexHull(right_side)
        cv2.fillConvexPoly(right_cheek, hull, 255)

    masks["cheeks"] = cv2.bitwise_or(left_cheek, right_cheek)

    # Full face oval mask
    face_hull = cv2.convexHull(landmarks)
    full_face = np.zeros((h, w), dtype=np.uint8)
    cv2.fillConvexPoly(full_face, face_hull, 255)
    masks["full_face"] = full_face

    # Non-skin feature exclusion (eyes, eyebrows, lips) to eliminate false positives
    left_eye_hull = create_mask_from_indices([33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158, 159, 160, 161, 246], (h, w))
    right_eye_hull = create_mask_from_indices([362, 382, 381, 380, 374, 373, 390, 249, 263, 466, 388, 387, 386, 385, 384, 398], (h, w))
    eyes_mask = cv2.bitwise_or(left_eye_hull, right_eye_hull)

    lips_mask = create_mask_from_indices([61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291, 308, 324, 318, 402, 317, 14, 87, 178, 88, 95], (h, w))

    left_brow = create_mask_from_indices([70, 63, 105, 66, 107, 55, 65, 52, 53, 46], (h, w))
    right_brow = create_mask_from_indices([336, 296, 334, 293, 300, 276, 283, 282, 295, 285], (h, w))
    brows_mask = cv2.bitwise_or(left_brow, right_brow)

    exclusion_mask = cv2.bitwise_or(eyes_mask, lips_mask)
    exclusion_mask = cv2.bitwise_or(exclusion_mask, brows_mask)
    # Dilate slightly to avoid boundary artifacting
    exclusion_mask = cv2.dilate(exclusion_mask, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5)))

    # Subtract non-skin features from active skin zones
    for key in ["forehead", "nose", "chin", "cheeks", "full_face"]:
        if key in masks:
            masks[key] = cv2.bitwise_and(masks[key], cv2.bitwise_not(exclusion_mask))

    return masks


def make_fallback_skin_masks(img_bgr: np.ndarray) -> Dict[str, np.ndarray]:
    """
    Intelligent fail-safe fallback when 468-point face mesh is not detected
    (e.g., macro skin shot, close-up cheek/forehead, or angled selfie).
    
    Segments skin using combined YCrCb and HSV chromaticity models,
    then generates functional anatomical proxy regions so analysis NEVER fails.
    """
    h, w = img_bgr.shape[:2]

    # Skin color segmentation
    ycrcb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2YCrCb)
    skin_ycrcb = cv2.inRange(ycrcb, np.array([0, 133, 77]), np.array([255, 173, 127]))

    hsv = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2HSV)
    skin_hsv1 = cv2.inRange(hsv, np.array([0, 15, 30]), np.array([55, 250, 255]))
    skin_hsv2 = cv2.inRange(hsv, np.array([160, 15, 30]), np.array([180, 250, 255]))
    skin_hsv = cv2.bitwise_or(skin_hsv1, skin_hsv2)

    skin_mask = cv2.bitwise_and(skin_ycrcb, skin_hsv)

    # Clean morphological noise
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (9, 9))
    skin_mask = cv2.morphologyEx(skin_mask, cv2.MORPH_CLOSE, kernel)
    skin_mask = cv2.morphologyEx(skin_mask, cv2.MORPH_OPEN, kernel)

    # If skin mask is too sparse, fall back to center elliptical ROI
    if np.count_nonzero(skin_mask) < (0.05 * h * w):
        skin_mask = np.zeros((h, w), dtype=np.uint8)
        cv2.ellipse(skin_mask, (w // 2, h // 2), (int(w * 0.42), int(h * 0.42)), 0, 0, 360, 255, -1)

    masks = {"full_face": skin_mask.copy()}

    # Upper zone (Forehead proxy)
    forehead_mask = skin_mask.copy()
    forehead_mask[int(h * 0.35):, :] = 0
    masks["forehead"] = forehead_mask

    # Middle zone (Cheeks proxy)
    cheeks_mask = skin_mask.copy()
    cheeks_mask[:int(h * 0.25), :] = 0
    cheeks_mask[int(h * 0.75):, :] = 0
    masks["cheeks"] = cheeks_mask

    # Central zone (Nose proxy)
    nose_mask = np.zeros((h, w), dtype=np.uint8)
    cv2.ellipse(nose_mask, (w // 2, int(h * 0.5)), (int(w * 0.16), int(h * 0.22)), 0, 0, 360, 255, -1)
    masks["nose"] = cv2.bitwise_and(nose_mask, skin_mask)

    # Lower zone (Chin proxy)
    chin_mask = skin_mask.copy()
    chin_mask[:int(h * 0.70), :] = 0
    masks["chin"] = chin_mask

    # Under-eye proxy zone
    under_eye_mask = np.zeros((h, w), dtype=np.uint8)
    cv2.ellipse(under_eye_mask, (int(w * 0.35), int(h * 0.38)), (int(w * 0.12), int(h * 0.08)), 0, 0, 360, 255, -1)
    cv2.ellipse(under_eye_mask, (int(w * 0.65), int(h * 0.38)), (int(w * 0.12), int(h * 0.08)), 0, 0, 360, 255, -1)
    masks["under_eyes"] = cv2.bitwise_and(under_eye_mask, skin_mask)

    # Crow's feet proxy zone
    crows_feet_mask = np.zeros((h, w), dtype=np.uint8)
    cv2.ellipse(crows_feet_mask, (int(w * 0.20), int(h * 0.36)), (int(w * 0.08), int(h * 0.08)), 0, 0, 360, 255, -1)
    cv2.ellipse(crows_feet_mask, (int(w * 0.80), int(h * 0.36)), (int(w * 0.08), int(h * 0.08)), 0, 0, 360, 255, -1)
    masks["crows_feet"] = cv2.bitwise_and(crows_feet_mask, skin_mask)

    # Nasolabial proxy zone
    nasolabial_mask = np.zeros((h, w), dtype=np.uint8)
    cv2.ellipse(nasolabial_mask, (int(w * 0.38), int(h * 0.62)), (int(w * 0.08), int(h * 0.12)), -25, 0, 360, 255, -1)
    cv2.ellipse(nasolabial_mask, (int(w * 0.62), int(h * 0.62)), (int(w * 0.08), int(h * 0.12)), 25, 0, 360, 255, -1)
    masks["nasolabial"] = cv2.bitwise_and(nasolabial_mask, skin_mask)

    return masks

