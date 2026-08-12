# DermaSense AI

**Intelligent Skin Health, Disease Detection & Personalized Beauty Care Assistant**

DermaSense AI is an AI-assisted healthcare and skincare platform designed as a comprehensive full-stack mobile application. It combines cutting-edge AI skin analysis, personalized routines, environmental insights, and seamless dermatologist consultations.

> **MEDICAL DISCLAIMER:** This application provides AI-assisted preliminary screening and does not replace professional medical diagnosis. Please consult a qualified dermatologist for clinical evaluation.

---

## 🌟 Features

- **AI Skin Analysis:** Upload or capture photos to detect skin conditions (e.g., Acne, Pigmentation) and measure skin quality (Hydration, Pores, Wrinkles).
- **Skin Health Score:** A dynamic 0-100 score evaluating overall skin health.
- **Explainable AI:** Demo heatmap overlays demonstrating the model's focus areas.
- **Personalized Skincare Routines:** Morning and evening product recommendations based on analysis.
- **AI Chat Assistant:** Get intelligent, context-aware answers to skincare questions.
- **Dermatologist Consultation:** Discover specialists, view ratings, and book appointments.
- **Progress Tracking (Digital Journal):** Track improvements over time using charts and comparisons.

---

## 🏛️ Architecture

DermaSense AI consists of three core components:

1. **Frontend:** Flutter Mobile App (Dart, Material 3)
2. **Backend:** Java Spring Boot REST API
3. **AI Service:** Python FastAPI

**Data Flow:**
User Mobile App ➡️ Spring Boot API ➡️ FastAPI Model Inference ➡️ Spring Boot Database ➡️ User Dashboard

---

## 🛠️ Technology Stack

| Component | Technology |
|---|---|
| **Mobile App** | Flutter 3.x, Dart, Material 3, Provider, HTTP |
| **Backend API** | Java 17, Spring Boot 3, Spring Security, JWT, JPA/Hibernate |
| **AI Inference API** | Python 3, FastAPI, Uvicorn, OpenCV, Pillow (TensorFlow/PyTorch) |
| **Database** | MySQL |

---

## 📁 Project Structure

```text
/dermasense-ai
├── frontend/             # Flutter App
│   ├── lib/
│   │   ├── screens/      # UI Screens (Auth, Home, Analysis, Routine, Chat, Doctors)
│   │   ├── theme/        # Premium Material 3 Healthcare Theme
│   │   └── main.dart     # Entry point
├── backend/              # Spring Boot Java Application
│   ├── src/main/java/    # Java Sources
│   ├── src/main/resources# application.yml Configuration
│   └── pom.xml           # Maven Dependencies
├── ai-service/           # Python FastAPI Application
│   ├── app/main.py       # Inference API Endpoints
│   └── requirements.txt  # Python Dependencies
├── database/             # Database Schemas & Seed Data
│   └── schema/01_init.sql
└── docs/                 # Documentation (API etc.)
```

---

## 🚀 Setup & Installation

### 1. Database Setup
1. Install and start a **MySQL** server.
2. Execute the schema script located at `database/schema/01_init.sql` to generate tables.

### 2. Backend Setup (Spring Boot)
1. Ensure **Java 17** and **Maven** are installed.
2. Navigate to `/backend`.
3. Update database credentials in `src/main/resources/application.yml` if necessary.
4. Run the application:
   ```bash
   mvn spring-boot:run
   ```
*(Note: If Maven is unavailable, use your IDE's run configuration).*

### 3. AI Service Setup (FastAPI)
1. Ensure **Python 3.10+** is installed.
2. Navigate to `/ai-service`.
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Run the inference server:
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

### 4. Frontend Setup (Flutter)
1. Ensure **Flutter 3.x** is installed (`flutter doctor`).
2. Navigate to `/frontend`.
3. Fetch packages:
   ```bash
   flutter pub get
   ```
4. Run the app on an emulator or connected device:
   ```bash
   flutter run
   ```

---

## 🧪 Demo Mode

The current version ships with a **Demo Mode** for AI Inference.
Instead of requiring a massive pre-trained PyTorch/TensorFlow model, the `ai-service/app/main.py` returns a deterministic mock payload. 
This allows the entire UI/UX flow (from Camera Capture -> Analysis Animation -> Health Score Report -> AI Explainability) to be fully evaluated without needing gigabytes of ML weights.

## 🔮 Future ML Model Integration

When integrating the real model:
1. Place your trained `.pt` or `.h5` files in `ai-service/models/`.
2. Update `ai-service/app/main.py` to replace the mock response block with real inference code (using PyTorch/TensorFlow and OpenCV).
3. Ensure the return JSON schema perfectly matches the existing `AnalysisResponse` Pydantic model. The frontend will require zero changes!

---

## 🔒 Security
- Use **Environment Variables** (`.env`) for secrets in production.
- Do not commit JWT secrets or database passwords.
- Currently, the API connections are configured for local development (`http://localhost:8080`). Ensure CORS and HTTPS are configured for production deployment.
