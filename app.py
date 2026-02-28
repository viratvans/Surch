import os
import re
import json
import requests
from bs4 import BeautifulSoup
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

class VanshAIEngine:
    def __init__(self, filename="vansh_ai_data.json"):
        self.filename = filename
        self.index = {}
        self.titles = {}
        self.owner = "Vansh"
        self.load_from_file()

    def _clean_text(self, text):
        return re.findall(r'\w+', text.lower())

    def save_to_file(self):
        data = {"index": self.index, "titles": self.titles}
        with open(self.filename, 'w') as f:
            json.dump(data, f, indent=4)

    def load_from_file(self):
        if os.path.exists(self.filename):
            try:
                with open(self.filename, 'r') as f:
                    data = json.load(f)
                    self.index = data.get("index", {})
                    self.titles = data.get("titles", {})
            except:
                self.index, self.titles = {}, {}

    def get_summary(self, text):
        clean_text = ' '.join(text.split())
        return clean_text[:150] + "..." if len(clean_text) > 150 else clean_text

    def crawl(self, url):
        try:
            response = requests.get(url, timeout=5, headers={'User-Agent': 'VanshBot/1.0'})
            soup = BeautifulSoup(response.text, 'html.parser')
            title = soup.title.string if soup.title else url
            text = soup.get_text()
            self.titles[url] = {"title": title, "summary": self.get_summary(text)}
            
            words = self._clean_text(text)
            for word in words:
                if word not in self.index: self.index[word] = {}
                self.index[word][url] = self.index[word].get(url, 0) + 1
            self.save_to_file()
            return True
        except Exception as e:
            print(f"Crawl Error: {e}")
            return False

    def search(self, query):
        q = query.lower().strip()
        if q in ["hi", "hello", "hey"]: return "HI_USER"
        if "who are you" in q or "who am i" in q: return "IDENTITY"

        query_words = self._clean_text(query)
        scores = {}
        for word in query_words:
            if word in self.index:
                for url, count in self.index[word].items():
                    scores[url] = scores.get(url, 0) + count
        
        results = sorted(scores.items(), key=lambda x: x[1], reverse=True)
        return [{"url": r[0], **self.titles[r[0]]} for r in results[:10]]

vse = VanshAIEngine()

# --- ROUTES ---

@app.route('/')
def home():
    return jsonify({
        "status": "online",
        "engine": "Vansh AI Engine",
        "owner": "Vansh",
        "endpoints": ["/search?q=query", "/crawl (POST)"]
    })

@app.route('/search', methods=['GET'])
def api_search():
    query = request.args.get('q', '')
    if not query:
        return jsonify({"type": "error", "content": "Please provide a query."})
        
    result = vse.search(query)
    
    if result == "HI_USER":
        return jsonify({"type": "chat", "content": f"Hello {vse.owner}! I'm ready to search."})
    if result == "IDENTITY":
        return jsonify({"type": "chat", "content": f"I am the Vansh AI Engine, built by {vse.owner}."})
    
    return jsonify({"type": "results", "data": result})

@app.route('/crawl', methods=['POST'])
def api_crawl():
    data = request.get_json()
    url = data.get('url')
    if not url:
        return jsonify({"status": "error", "message": "No URL provided"}), 400
    
    success = vse.crawl(url)
    return jsonify({"status": "success" if success else "failed"})

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)