
# 🎬 AI Recommendation System

An advanced AI-powered movie & TV show recommendation system built using modern Machine Learning and NLP techniques.

🌐 **Live Web App:** https://ai-recommender-ef211.web.app/

---

## 🚀 Overview

This project uses a **dual-layer hybrid recommendation engine** combining:

- 🧠 **60% SBERT Semantic Embeddings**
- 📄 **40% TF-IDF Content Similarity**

The system understands both semantic meaning and keyword relationships to deliver highly relevant recommendations.

It supports:

✅ Smart Recommendations  
✅ Real-time Search Autocomplete  
✅ Movie / TV Filtering  
✅ User Activity Logging  
✅ Fast API Responses  
✅ Production Deployment

---

## 🧠 Recommendation Engine Logic

Final recommendation score uses:

```python
0.7 * Hybrid Similarity
+ 0.2 * Popularity Score
+ 0.1 * Genre Overlap
```

This improves practical recommendation quality over plain cosine similarity systems.

---

## 🛠️ Tech Stack

### Backend
- FastAPI
- Python
- Scikit-learn
- NumPy
- Pandas
- RapidFuzz

### Machine Learning / NLP
- SBERT Embeddings
- TF-IDF Vectorization
- Cosine Similarity

### Database / Analytics
- Firebase Firestore

### Frontend
- Firebase Hosting
- Web UI

---

## 📂 Project Structure

```bash
project/
│── main.py
│── artifacts/
│   ├── data.pkl
│   ├── tfidf.pkl
│   ├── tfidf_matrix.pkl
│   ├── embeddings.npy
│   ├── title_to_index.pkl
│   └── alias_map.pkl
│── requirements.txt
```

---

## 🔥 API Endpoints

### Root Health Check

```http
GET /
```

Response:

```json
{
  "message": "Recommendation API running 🚀"
}
```

### Search Autocomplete

```http
GET /autocomplete?query=bat
```

### Get Recommendations

```http
GET /recommend?title=Inception
```

Optional Parameters:

- `content_type=movie`
- `user_id=123`

---

## ▶️ Run Locally

```bash
git clone https://github.com/yourusername/ai-recommendation-system.git
cd ai-recommendation-system
pip install -r requirements.txt
uvicorn main:app --reload
```

---

## 🔐 Environment Variables

```env
FIREBASE_KEY=your_json_key_here
```

---

## 📈 Future Improvements

- Personalized recommendations
- User watchlists
- Trending section
- Deep learning reranking model
- Mobile app with Flutter
- Multi-language recommendations

---

## 👨‍💻 Author

**Saransh Sharma**

Machine Learning Engineer | AI Developer | Full Stack Builder

---

## ⭐ If you like this project

Give it a star on GitHub ⭐
