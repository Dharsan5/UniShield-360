"""
UniShield 360 - Configuration Settings
"""

from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # API Settings
    API_TITLE: str = "UniShield 360 API"
    API_VERSION: str = "1.0.0"
    DEBUG: bool = True
    
    # Firebase Settings
    FIREBASE_CREDENTIALS_PATH: Optional[str] = None
    FIREBASE_PROJECT_ID: Optional[str] = None
    
    # AI Model Settings
    VOICE_MODEL_CONFIDENCE_THRESHOLD: float = 0.7
    TOXICITY_THRESHOLD: float = 0.5
    YOLO_MODEL_PATH: str = "yolov8n.pt"
    
    # Security
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    class Config:
        env_file = ".env"

settings = Settings()
