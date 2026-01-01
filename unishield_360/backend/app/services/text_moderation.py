"""
Text Moderation Service
Uses NLTK and Transformers for toxicity detection
"""

from typing import Dict, Any, List
import re

class TextModerator:
    """
    Analyzes text for toxicity, hate speech, and harmful content.
    Used to moderate anonymous chat messages in the Locker Room.
    """
    
    def __init__(self):
        self.model_loaded = False
        self._load_model()
        self._load_bad_words()
    
    def _load_model(self):
        """Initialize the text moderation model"""
        try:
            from transformers import pipeline
            # Load a toxicity classification model
            self.classifier = pipeline(
                "text-classification",
                model="unitary/toxic-bert",
                return_all_scores=True
            )
            self.model_loaded = True
            print("Text moderation service initialized with transformer model")
        except Exception as e:
            print(f"Warning: Could not load transformer model: {e}")
            print("Using rule-based fallback for text moderation")
            self.model_loaded = False
    
    def _load_bad_words(self):
        """Load list of inappropriate words for rule-based filtering"""
        # Basic list - in production, use a comprehensive database
        self.toxic_patterns = [
            r'\b(hate|kill|die|stupid|idiot|dumb|loser)\b',
            r'\b(ugly|fat|worthless|pathetic)\b',
            r'\b(shut\s*up|go\s*away)\b',
        ]
        
        self.severe_patterns = [
            r'\b(suicide|self.?harm|cut\s*myself)\b',
            r'\b(threat|bomb|attack|weapon)\b',
        ]
        
        self.supportive_patterns = [
            r'\b(support|help|here\s*for\s*you|understand)\b',
            r'\b(proud|strong|brave|resilient)\b',
            r'\b(talk|listen|share|together)\b',
        ]
    
    async def analyze_text(self, text: str) -> Dict[str, Any]:
        """
        Analyze text for toxicity and harmful content
        
        Returns:
            - is_toxic: Whether the text should be blocked
            - toxicity_score: 0.0 to 1.0 score
            - categories: List of detected issue categories
            - message: Human-readable result
        """
        
        if not text or not text.strip():
            return {
                "is_toxic": False,
                "toxicity_score": 0.0,
                "categories": [],
                "message": "Empty text is safe"
            }
        
        text_lower = text.lower()
        categories = []
        
        # Check for severe content first (crisis detection)
        for pattern in self.severe_patterns:
            if re.search(pattern, text_lower):
                categories.append("crisis_content")
                return {
                    "is_toxic": True,
                    "toxicity_score": 1.0,
                    "categories": categories,
                    "message": "Content flagged for review. If you're struggling, please reach out to campus counseling services.",
                    "needs_support": True
                }
        
        if self.model_loaded:
            # Use transformer model
            result = await self._analyze_with_model(text)
        else:
            # Use rule-based analysis
            result = self._analyze_with_rules(text_lower)
        
        # Add supportive content detection
        supportive_score = self._check_supportive(text_lower)
        if supportive_score > 0.5:
            result["toxicity_score"] = max(0, result["toxicity_score"] - 0.2)
            if result["toxicity_score"] < 0.5:
                result["is_toxic"] = False
        
        return result
    
    async def _analyze_with_model(self, text: str) -> Dict[str, Any]:
        """Use transformer model for toxicity detection"""
        try:
            results = self.classifier(text)[0]
            
            toxicity_score = 0.0
            categories = []
            
            for item in results:
                label = item['label'].lower()
                score = item['score']
                
                if 'toxic' in label and score > 0.5:
                    toxicity_score = max(toxicity_score, score)
                    categories.append('toxic')
                elif 'obscene' in label and score > 0.5:
                    toxicity_score = max(toxicity_score, score * 0.8)
                    categories.append('obscene')
                elif 'insult' in label and score > 0.5:
                    toxicity_score = max(toxicity_score, score * 0.7)
                    categories.append('insult')
                elif 'threat' in label and score > 0.5:
                    toxicity_score = max(toxicity_score, score)
                    categories.append('threat')
            
            is_toxic = toxicity_score > 0.5
            
            if is_toxic:
                message = "This message may be hurtful. Consider rephrasing to be more supportive."
            else:
                message = "Message is appropriate for posting"
            
            return {
                "is_toxic": is_toxic,
                "toxicity_score": float(toxicity_score),
                "categories": list(set(categories)),
                "message": message
            }
            
        except Exception as e:
            print(f"Model analysis error: {e}")
            return self._analyze_with_rules(text.lower())
    
    def _analyze_with_rules(self, text_lower: str) -> Dict[str, Any]:
        """Rule-based toxicity detection as fallback"""
        
        toxicity_score = 0.0
        categories = []
        
        # Check toxic patterns
        for pattern in self.toxic_patterns:
            matches = re.findall(pattern, text_lower)
            if matches:
                toxicity_score += 0.3 * len(matches)
                categories.append('potentially_harmful')
        
        # Cap the score
        toxicity_score = min(toxicity_score, 1.0)
        is_toxic = toxicity_score > 0.5
        
        if is_toxic:
            message = "This message contains potentially harmful language. Please be kind and supportive."
        else:
            message = "Message is appropriate for posting"
        
        return {
            "is_toxic": is_toxic,
            "toxicity_score": float(toxicity_score),
            "categories": list(set(categories)),
            "message": message
        }
    
    def _check_supportive(self, text_lower: str) -> float:
        """Check if text contains supportive language"""
        score = 0.0
        for pattern in self.supportive_patterns:
            if re.search(pattern, text_lower):
                score += 0.3
        return min(score, 1.0)
