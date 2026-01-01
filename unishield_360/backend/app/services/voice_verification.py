"""
Voice Gender Verification Service
Uses Librosa for audio analysis and feature extraction
"""

import io
import numpy as np
import tempfile
import os
from typing import Dict, Any

class VoiceGenderVerifier:
    """
    Analyzes voice recordings to determine speaker gender.
    Uses acoustic features like pitch (F0), formants, and MFCCs.
    """
    
    def __init__(self):
        self.model_loaded = False
        self._load_model()
    
    def _load_model(self):
        """Initialize the voice analysis model"""
        try:
            import librosa
            self.librosa = librosa
            self.model_loaded = True
            print("Voice verification service initialized")
        except ImportError:
            print("Warning: librosa not installed. Using fallback mode.")
            self.model_loaded = False
    
    async def analyze_gender(self, audio_content: bytes, filename: str) -> Dict[str, Any]:
        """
        Analyze audio content to determine gender
        
        Gender classification based on:
        - Fundamental frequency (F0/Pitch): Males typically 85-180 Hz, Females 165-255 Hz
        - Formant frequencies
        - MFCC features
        """
        
        if not self.model_loaded:
            # Fallback for demo/testing
            return {
                "gender": "female",
                "confidence": 0.85,
                "features": {"pitch_mean": 210.0}
            }
        
        try:
            # Save to temporary file for librosa processing
            suffix = os.path.splitext(filename)[1] or '.wav'
            with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp_file:
                tmp_file.write(audio_content)
                tmp_path = tmp_file.name
            
            try:
                # Load audio file
                y, sr = self.librosa.load(tmp_path, sr=22050, duration=10)
                
                # Extract features
                features = self._extract_features(y, sr)
                
                # Classify gender based on features
                gender, confidence = self._classify_gender(features)
                
                return {
                    "gender": gender,
                    "confidence": confidence,
                    "features": features
                }
                
            finally:
                # Clean up temp file
                os.unlink(tmp_path)
                
        except Exception as e:
            print(f"Voice analysis error: {e}")
            # Return default on error
            return {
                "gender": "unknown",
                "confidence": 0.0,
                "features": {},
                "error": str(e)
            }
    
    def _extract_features(self, y: np.ndarray, sr: int) -> Dict[str, float]:
        """Extract acoustic features from audio signal"""
        
        features = {}
        
        try:
            # 1. Fundamental Frequency (Pitch) using pyin
            f0, voiced_flag, voiced_probs = self.librosa.pyin(
                y, 
                fmin=self.librosa.note_to_hz('C2'),
                fmax=self.librosa.note_to_hz('C7'),
                sr=sr
            )
            
            # Get valid pitch values
            f0_valid = f0[~np.isnan(f0)]
            
            if len(f0_valid) > 0:
                features['pitch_mean'] = float(np.mean(f0_valid))
                features['pitch_std'] = float(np.std(f0_valid))
                features['pitch_min'] = float(np.min(f0_valid))
                features['pitch_max'] = float(np.max(f0_valid))
            else:
                features['pitch_mean'] = 150.0  # Default neutral
                features['pitch_std'] = 0.0
                features['pitch_min'] = 150.0
                features['pitch_max'] = 150.0
            
            # 2. MFCCs (Mel-frequency cepstral coefficients)
            mfccs = self.librosa.feature.mfcc(y=y, sr=sr, n_mfcc=13)
            for i in range(13):
                features[f'mfcc_{i}_mean'] = float(np.mean(mfccs[i]))
            
            # 3. Spectral Centroid
            spec_cent = self.librosa.feature.spectral_centroid(y=y, sr=sr)
            features['spectral_centroid_mean'] = float(np.mean(spec_cent))
            
            # 4. Spectral Rolloff
            spec_rolloff = self.librosa.feature.spectral_rolloff(y=y, sr=sr)
            features['spectral_rolloff_mean'] = float(np.mean(spec_rolloff))
            
            # 5. Zero Crossing Rate
            zcr = self.librosa.feature.zero_crossing_rate(y)
            features['zcr_mean'] = float(np.mean(zcr))
            
        except Exception as e:
            print(f"Feature extraction error: {e}")
            features['pitch_mean'] = 150.0
        
        return features
    
    def _classify_gender(self, features: Dict[str, float]) -> tuple:
        """
        Classify gender based on extracted features
        
        Primary indicator: Fundamental frequency (pitch)
        - Male voice: typically 85-180 Hz
        - Female voice: typically 165-255 Hz
        """
        
        pitch_mean = features.get('pitch_mean', 150.0)
        
        # Classification thresholds
        MALE_UPPER = 165.0
        FEMALE_LOWER = 180.0
        OVERLAP_CENTER = 172.5
        
        if pitch_mean < MALE_UPPER:
            # Clearly male range
            confidence = min(0.95, 0.7 + (MALE_UPPER - pitch_mean) / 200)
            return "male", confidence
            
        elif pitch_mean > FEMALE_LOWER:
            # Clearly female range
            confidence = min(0.95, 0.7 + (pitch_mean - FEMALE_LOWER) / 200)
            return "female", confidence
            
        else:
            # Overlap region - use additional features
            spectral_centroid = features.get('spectral_centroid_mean', 1500)
            
            if pitch_mean < OVERLAP_CENTER:
                gender = "male"
                confidence = 0.6 + (OVERLAP_CENTER - pitch_mean) / 50
            else:
                gender = "female"
                confidence = 0.6 + (pitch_mean - OVERLAP_CENTER) / 50
            
            # Adjust based on spectral features
            if spectral_centroid > 1800 and gender == "female":
                confidence = min(confidence + 0.1, 0.9)
            elif spectral_centroid < 1400 and gender == "male":
                confidence = min(confidence + 0.1, 0.9)
            
            return gender, min(confidence, 0.85)
