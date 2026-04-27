import pickle
import numpy as np
import pandas as pd
import re
import os
import json

from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware

from sklearn.metrics.pairwise import cosine_similarity
from rapidfuzz import process, fuzz

# -----------------------------
# 🔥 LOAD ARTIFACTS
# -----------------------------
df = pd.read_pickle("artifacts/data.pkl")

with open("artifacts/tfidf.pkl", "rb") as f:
    tfidf = pickle.load(f)

with open("artifacts/tfidf_matrix.pkl", "rb") as f:
    tfidf_matrix = pickle.load(f)

embeddings = np.load("artifacts/embeddings.npy")

with open("artifacts/title_to_index.pkl", "rb") as f:
    title_to_index = pickle.load(f)

with open("artifacts/alias_map.pkl", "rb") as f:
    alias_map = pickle.load(f)

# -----------------------------
# 🔥 FASTAPI INIT
# -----------------------------
app = FastAPI()

# -----------------------------
# 🔥 CORS (Flutter Ready)
# -----------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # restrict in production later
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -----------------------------
# 🔥 TEXT UTILS
# -----------------------------
def clean_text(text):
    text = text.lower()
    text = re.sub(r'[^a-zA-Z0-9\s]', ' ', text)
    text = re.sub(r'\s+', ' ', text)
    return text.strip()

def preprocess_query(query):
    query = clean_text(query)
    query = re.sub(r'\d+', '', query)

    stop_words = ["movie", "film", "show", "series", "tv"]
    tokens = [t for t in query.split() if t not in stop_words]

    return " ".join(tokens)

# -----------------------------
# 🔥 TITLE RESOLUTION
# -----------------------------
def resolve_title(user_input):
    user_input = preprocess_query(user_input)

    if user_input in alias_map:
        for alias in alias_map[user_input]:
            alias = clean_text(alias)

            match, score, _ = process.extractOne(
                alias,
                df['clean_title'],
                scorer=fuzz.token_set_ratio
            )

            if score >= 70:
                return title_to_index[match]

    if user_input in title_to_index:
        return title_to_index[user_input]

    match, score, _ = process.extractOne(
        user_input,
        df['clean_title'],
        scorer=fuzz.token_set_ratio
    )

    if score >= 70:
        return title_to_index[match]

    return None

# -----------------------------
# 🔥 AUTOCOMPLETE
# -----------------------------
titles = df['clean_title'].tolist()
original_titles = df['title'].tolist()

def autocomplete(query, limit=10):
    query = preprocess_query(query)

    matches = process.extract(
        query,
        titles,
        scorer=fuzz.partial_ratio,
        limit=limit
    )

    results = []
    for match, score, idx in matches:
        if score > 60:
            results.append({
                "title": original_titles[idx],
                "score": score
            })

    return results

# -----------------------------
# 🔥 RECOMMENDER
# -----------------------------
def get_recommendations(title, content_type=None, top_k=10):

    idx = resolve_title(title)
    if idx is None:
        return []

    sbert_scores = cosine_similarity(
        embeddings[idx].reshape(1, -1),
        embeddings
    )[0]

    tfidf_scores = cosine_similarity(
        tfidf_matrix[idx],
        tfidf_matrix
    )[0]

    scores = (0.6 * sbert_scores) + (0.4 * tfidf_scores)

    results = []
    input_genres = set(df.iloc[idx]['genres'].split())

    for i, score in enumerate(scores):

        if i == idx:
            continue

        if content_type and df.iloc[i]['content_type'] != content_type:
            continue

        candidate_genres = set(df.iloc[i]['genres'].split())
        if len(input_genres.intersection(candidate_genres)) == 0:
            continue

        popularity = df.iloc[i]['popularity']

        final_score = (
            0.7 * score +
            0.2 * (popularity / df['popularity'].max()) +
            0.1 * len(input_genres.intersection(candidate_genres))
        )

        results.append((i, final_score))

    results = sorted(results, key=lambda x: x[1], reverse=True)[:top_k]

    return [
        {
            "title": df.iloc[i]['title'],
            "type": df.iloc[i]['content_type'],
            "score": float(score)
        }
        for i, score in results
    ]

# -----------------------------
# 🔥 FIREBASE (ENV SAFE)
# -----------------------------
FIREBASE_ENABLED = False

try:
    import firebase_admin
    from firebase_admin import credentials, firestore

    firebase_key_str = os.getenv("FIREBASE_KEY")

    if firebase_key_str:
        firebase_key_dict = json.loads(firebase_key_str)

        cred = credentials.Certificate(firebase_key_dict)
        firebase_admin.initialize_app(cred)
        db = firestore.client()

        FIREBASE_ENABLED = True
        print("🔥 Firebase Connected")
    else:
        print("⚠️ Firebase key not found in ENV")

except Exception as e:
    print("⚠️ Firebase init failed:", e)

# -----------------------------
# 🔥 ROUTES
# -----------------------------
@app.get("/")
def root():
    return {"message": "Recommendation API running 🚀"}

@app.get("/autocomplete")
def autocomplete_api(query: str):
    return {"results": autocomplete(query)}

@app.get("/recommend")
def recommend_api(
    title: str = Query(...),
    content_type: str = Query(None),
    user_id: str = Query(None)
):

    results = get_recommendations(title, content_type)

    if FIREBASE_ENABLED and user_id:
        db.collection("user_activity").add({
            "user_id": user_id,
            "query": title,
            "content_type": content_type,
            "results": [r["title"] for r in results]
        })

    return {
        "query": title,
        "results": results
    }