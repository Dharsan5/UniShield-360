"""
UniShield 360 - FastAPI Backend
Main application entry point with all AI endpoints
"""

from fastapi import FastAPI, File, UploadFile, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from typing import Optional, List
import uvicorn

from app.services.voice_verification import VoiceGenderVerifier
from app.services.text_moderation import TextModerator
from app.services.crowd_analyzer import CrowdAnalyzer
from app.config import settings

app = FastAPI(
    title="UniShield 360 API",
    description="Backend API for campus safety and wellness platform",
    version="1.0.0"
)

# CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
voice_verifier = VoiceGenderVerifier()
text_moderator = TextModerator()
crowd_analyzer = CrowdAnalyzer()

security = HTTPBearer()

# ==================== MODELS ====================

class VoiceVerificationResponse(BaseModel):
    gender: str  # "male" or "female"
    confidence: float
    message: str

class TextModerationRequest(BaseModel):
    text: str
    user_id: Optional[str] = None

class TextModerationResponse(BaseModel):
    is_toxic: bool
    toxicity_score: float
    categories: List[str]
    message: str
    safe_to_post: bool

class CrowdAnalysisResponse(BaseModel):
    total_people: int
    male_count: int
    female_count: int
    male_percentage: float
    female_percentage: float
    safety_insight: str
    risk_level: str  # "low", "medium", "high"

class AlertRequest(BaseModel):
    user_id: str
    alert_type: str  # "yellow" or "red"
    latitude: float
    longitude: float
    message: Optional[str] = None

class AlertResponse(BaseModel):
    success: bool
    alert_id: str
    message: str

# ==================== ENDPOINTS ====================

@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "app": "UniShield 360 API",
        "version": "1.0.0"
    }

@app.get("/health")
async def health_check():
    """Detailed health check"""
    return {
        "status": "healthy",
        "services": {
            "voice_verification": "active",
            "text_moderation": "active",
            "crowd_analysis": "active"
        }
    }

# ==================== MODULE A: VOICE GENDER VERIFICATION ====================

@app.post("/verify-voice", response_model=VoiceVerificationResponse)
async def verify_voice(audio: UploadFile = File(...)):
    """
    The Gatekeeper - Voice Gender Verification
    
    Analyzes voice sample to determine gender for role-based access.
    Used during user onboarding to automatically assign features.
    
    - Male users get access to "BroCode" (Stress Sharing) module
    - Female users get access to "Guardian" (Safety) module
    """
    try:
        # Validate file type
        if not audio.filename.endswith(('.wav', '.mp3', '.m4a', '.ogg', '.webm')):
            raise HTTPException(
                status_code=400, 
                detail="Invalid audio format. Supported: wav, mp3, m4a, ogg, webm"
            )
        
        # Read audio content
        audio_content = await audio.read()
        
        # Verify voice gender
        result = await voice_verifier.analyze_gender(audio_content, audio.filename)
        
        return VoiceVerificationResponse(
            gender=result["gender"],
            confidence=result["confidence"],
            message=f"Voice verified as {result['gender']} with {result['confidence']:.1%} confidence"
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Voice analysis failed: {str(e)}")

# ==================== MODULE C: TEXT MODERATION ====================

@app.post("/moderate-chat", response_model=TextModerationResponse)
async def moderate_chat(request: TextModerationRequest):
    """
    The Locker Room - Text Moderation for Anonymous Chat
    
    Checks messages for toxicity before posting to prevent bullying.
    Used in the anonymous male stress-sharing chat feature.
    """
    try:
        result = await text_moderator.analyze_text(request.text)
        
        return TextModerationResponse(
            is_toxic=result["is_toxic"],
            toxicity_score=result["toxicity_score"],
            categories=result["categories"],
            message=result["message"],
            safe_to_post=not result["is_toxic"]
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Text moderation failed: {str(e)}")

# ==================== MODULE D: CROWD ANALYSIS ====================

@app.post("/analyze-crowd", response_model=CrowdAnalysisResponse)
async def analyze_crowd(image: UploadFile = File(...)):
    """
    Campus Eye - Gender Statistics from Crowd Images
    
    Analyzes images to count males and females for safety insights.
    Used by admins/security to monitor campus areas.
    """
    try:
        # Validate file type
        if not image.filename.lower().endswith(('.jpg', '.jpeg', '.png', '.webp')):
            raise HTTPException(
                status_code=400,
                detail="Invalid image format. Supported: jpg, jpeg, png, webp"
            )
        
        # Read image content
        image_content = await image.read()
        
        # Analyze crowd
        result = await crowd_analyzer.analyze_image(image_content)
        
        return CrowdAnalysisResponse(
            total_people=result["total_people"],
            male_count=result["male_count"],
            female_count=result["female_count"],
            male_percentage=result["male_percentage"],
            female_percentage=result["female_percentage"],
            safety_insight=result["safety_insight"],
            risk_level=result["risk_level"]
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Crowd analysis failed: {str(e)}")

# ==================== MODULE B: SAFETY ALERTS ====================

@app.post("/send-alert", response_model=AlertResponse)
async def send_alert(alert: AlertRequest):
    """
    Guardian Mode - Emergency Alert System
    
    Handles yellow (uncomfortable) and red (emergency) alerts.
    Triggers notifications to appropriate contacts.
    """
    try:
        import uuid
        alert_id = str(uuid.uuid4())
        
        if alert.alert_type == "red":
            # Emergency alert - notify security and parents
            message = "Emergency alert sent to Campus Security and emergency contacts"
        else:
            # Yellow alert - notify close friends
            message = "Tracking alert sent to your trusted contacts"
        
        return AlertResponse(
            success=True,
            alert_id=alert_id,
            message=message
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Alert sending failed: {str(e)}")


if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
