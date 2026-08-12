from fastapi import FastAPI, UploadFile, File
from pydantic import BaseModel
from typing import List, Dict
import uvicorn

app = FastAPI(title="DermaSense AI Service", description="AI Service for skin analysis", version="1.0.0")

class AnalysisResponse(BaseModel):
    screening: List[Dict[str, float]]
    skin_metrics: Dict[str, float]
    health_score: int
    explanation: str

@app.get("/")
def read_root():
    return {"message": "DermaSense AI Service is running"}

@app.post("/predict", response_model=AnalysisResponse)
async def predict_skin(file: UploadFile = File(...)):
    # DEMO MODE: Mock deterministic response
    
    # Normally, you would read the file:
    # content = await file.read()
    # image = Image.open(io.BytesIO(content))
    # run inference...

    response = {
        "screening": [
            {"condition": "Acne", "confidence": 78.5},
            {"condition": "Pigmentation", "confidence": 35.2}
        ],
        "skin_metrics": {
            "Hydration": 72.0,
            "Pores": 42.0,
            "Wrinkles": 18.0
        },
        "health_score": 82,
        "explanation": "The highlighted regions in the T-zone and cheeks contributed to the model's prediction of mild acne and moderate hydration levels."
    }
    return response

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
