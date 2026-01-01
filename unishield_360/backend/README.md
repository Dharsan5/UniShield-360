# UniShield 360 - Backend API

## Setup Instructions

### 1. Create Virtual Environment
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 2. Install Dependencies
```bash
pip install -r requirements.txt
```

### 3. Download NLTK Data (for text moderation)
```python
import nltk
nltk.download('punkt')
nltk.download('stopwords')
nltk.download('wordnet')
```

### 4. Configure Environment
```bash
cp .env.example .env
# Edit .env with your Firebase credentials
```

### 5. Run the Server
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## API Endpoints

### Health Check
- `GET /` - Basic health check
- `GET /health` - Detailed service status

### Voice Gender Verification (Module A)
- `POST /verify-voice` - Upload audio file for gender detection
  - Input: Audio file (wav, mp3, m4a, ogg, webm)
  - Output: `{ gender, confidence, message }`

### Text Moderation (Module C)
- `POST /moderate-chat` - Check text for toxicity
  - Input: `{ text, user_id? }`
  - Output: `{ is_toxic, toxicity_score, categories, message, safe_to_post }`

### Crowd Analysis (Module D)
- `POST /analyze-crowd` - Analyze image for gender statistics
  - Input: Image file (jpg, jpeg, png, webp)
  - Output: `{ total_people, male_count, female_count, male_percentage, female_percentage, safety_insight, risk_level }`

### Safety Alerts (Module B)
- `POST /send-alert` - Send safety alert
  - Input: `{ user_id, alert_type, latitude, longitude, message? }`
  - Output: `{ success, alert_id, message }`

## API Documentation
Once running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
