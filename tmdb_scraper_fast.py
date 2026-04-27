import requests
import pandas as pd
import time
import os
from tqdm import tqdm
from concurrent.futures import ThreadPoolExecutor, as_completed
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

API_KEY = "Please Inster Your Tmdb Key Here"
BASE_URL = "https://api.themoviedb.org/3"
OUTPUT_FILE = "tmdb_dataset.csv"
BACKUP_FILE = "tmdb_backup.csv"

# --------------------------
# SESSION SETUP
# --------------------------
session = requests.Session()

retry_strategy = Retry(
    total=5,
    backoff_factor=1.5,
    status_forcelist=[429, 500, 502, 503, 504],
    allowed_methods=["GET"]
)

adapter = HTTPAdapter(max_retries=retry_strategy)
session.mount("https://", adapter)
session.mount("http://", adapter)

HEADERS = {"accept": "application/json"}


# --------------------------
# SAFE FETCH
# --------------------------
def fetch(url, params=None):
    if params is None:
        params = {}

    params["api_key"] = API_KEY

    try:
        response = session.get(url, params=params, headers=HEADERS, timeout=10)
        response.raise_for_status()
        return response.json()
    except:
        return None


# --------------------------
# MASSIVE DISCOVER
# --------------------------
def massive_discover(media_type="movie"):
    results = []

    genres = [
        28, 12, 16, 35, 80, 99, 18,
        10751, 14, 36, 27, 10402,
        9648, 10749, 878, 10770, 53, 10752
    ]

    years = list(range(2000, 2026, 2))

    sort_options = [
        "popularity.desc",
        "vote_average.desc",
        "vote_count.desc"
    ]

    for genre in genres:
        for year in years:
            for sort in sort_options:
                for page in range(1, 6):

                    url = f"{BASE_URL}/discover/{media_type}"

                    params = {
                        "with_genres": genre,
                        "sort_by": sort,
                        "vote_count.gte": 20,
                        "page": page
                    }

                    if media_type == "movie":
                        params["primary_release_year"] = year
                    else:
                        params["first_air_date_year"] = year

                    # Anime boost
                    if genre == 16:
                        params["with_original_language"] = "ja"

                    data = fetch(url, params)

                    if not data:
                        continue

                    for item in data.get("results", []):
                        item["media_type"] = media_type

                    results.extend(data.get("results", []))
                    time.sleep(0.2)

    return results


# --------------------------
# GET DETAILS
# --------------------------
def get_details(item):
    media_id = item["id"]
    media_type = item["media_type"]

    url = f"{BASE_URL}/{media_type}/{media_id}"
    params = {"append_to_response": "credits,keywords"}

    data = fetch(url, params)
    if not data:
        return None

    try:
        genres = [g["name"] for g in data.get("genres", [])]

        keywords_data = data.get("keywords", {})
        if media_type == "movie":
            keywords = [k["name"] for k in keywords_data.get("keywords", [])]
        else:
            keywords = [k["name"] for k in keywords_data.get("results", [])]

        cast = [c["name"] for c in data.get("credits", {}).get("cast", [])[:10]]
        crew = data.get("credits", {}).get("crew", [])
        directors = [c["name"] for c in crew if c["job"] == "Director"]

        # 🚫 Filter garbage
        if not data.get("overview") or data.get("vote_count", 0) < 20:
            return None

        return {
            "id": data.get("id"),
            "title": data.get("title") or data.get("name"),
            "overview": data.get("overview"),
            "genres": " ".join(genres),
            "keywords": " ".join(keywords),
            "cast": " ".join(cast),
            "director": " ".join(directors),
            "production_companies": " ".join([c["name"] for c in data.get("production_companies", [])]),
            "release_date": data.get("release_date") or data.get("first_air_date"),
            "vote_average": data.get("vote_average"),
            "vote_count": data.get("vote_count"),
            "popularity": data.get("popularity"),
            "language": data.get("original_language"),
            "poster_path": data.get("poster_path"),
            "backdrop_path": data.get("backdrop_path"),
            "media_type": media_type
        }

    except:
        return None


# --------------------------
# LOAD BACKUP
# --------------------------
def load_backup():
    if os.path.exists(BACKUP_FILE):
        df = pd.read_csv(BACKUP_FILE)
        return df.to_dict("records")
    return []


# --------------------------
# BUILD DATASET
# --------------------------
def build_dataset():
    print(" Starting massive dataset generation...")

    all_items = []
    all_items += massive_discover("movie")
    all_items += massive_discover("tv")

    # Remove duplicates
    unique = {(i["id"], i["media_type"]): i for i in all_items}
    items = list(unique.values())

    print(f" Unique collected: {len(items)}")

    dataset = load_backup()
    done_ids = set((d["id"], d["media_type"]) for d in dataset)

    items = [i for i in items if (i["id"], i["media_type"]) not in done_ids]
    print(f" Remaining: {len(items)}")

    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = [executor.submit(get_details, item) for item in items]

        for i, future in enumerate(tqdm(as_completed(futures), total=len(futures))):
            result = future.result()

            if result:
                dataset.append(result)

            if i % 100 == 0:
                pd.DataFrame(dataset).to_csv(BACKUP_FILE, index=False)

    df = pd.DataFrame(dataset)

    # --------------------------
    # FEATURE ENGINEERING
    # --------------------------
    df["tags"] = (
        df["overview"] + " " +
        (df["genres"] * 3) + " " +
        (df["keywords"] * 5) + " " +
        (df["cast"] * 2) + " " +
        df["director"]
    )

    df.to_csv(OUTPUT_FILE, index=False)

    print(" DONE — Dataset ready for recommender!")


if __name__ == "__main__":
    build_dataset()

#2addbc2bf90cc62db27bf11d93d670f6
