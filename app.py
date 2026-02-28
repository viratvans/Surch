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
        self.index = {}    # { word: { url: count } }
        self.titles = {}   # { url: { title: str, summary: str } }
        self.images = {}   # { url: [img_urls] }
        self.messages = [] # List of { user: str, text: str }
        self.owner = "Vansh"
        self.load_from_file()

    def _clean_text(self, text):
        return re.findall(r'\w+', text.lower())

    def save_to_file(self):
        data = {
            "index": self.index, 
            "titles": self.titles, 
            "images": self.images, 
            "messages": self.messages
        }
        with open(self.filename, 'w') as f:
            json.dump(data, f, indent=4)

    def load_from_file(self):
        if os.path.exists(self.filename):
            try:
                with open(self.filename, 'r') as f:
                    data = json.load(f)
                    self.index = data.get("index", {})
                    self.titles = data.get("titles", {})
                    self.images = data.get("images", {})
                    self.messages = data.get("messages", [])
            except:
                pass

    def get_summary(self, text):
        clean_text = ' '.join(text.split())
        return clean_text[:150] + "..." if len(clean_text) > 150 else clean_text

    def crawl(self, url):
        try:
            headers = {'User-Agent': 'VanshBot/1.0'}
            response = requests.get(url, timeout=5, headers=headers)
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # 1. Text & Title
            title = soup.title.string if soup.title else url
            text = soup.get_text()
            self.titles[url] = {"title": title, "summary": self.get_summary(text)}
            
            # 2. Indexing for Search
            words = self._clean_text(text)
            for word in words:
                if word not in self.index: self.index[word] = {}
                self.index[word][url] = self.index[word].get(url, 0) + 1
            
            # 3. Image Crawling
            imgs = [img['src'] for img in soup.find_all('img', src=True) if img['src'].startswith('http')]
            self.images[url] = imgs[:5] 
            
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
        # Return results with images if available
        return [
            {
                "url": r[0], 
                "title": self.titles[r[0]]['title'], 
                "summary": self.titles[r[0]]['summary'],
                "images": self.images.get(r[0], [])
            } for r in results[:10]
        ]

vse = VanshAIEngine()

# --- WEB ROUTES ---

@app.route('/')
def home():
    return jsonify({
        "status": "online",
        "engine": "Vansh Hacker Engine",
        "owner": "Vansh",
        "chat_active": True
    })

@app.route('/search', methods=['GET'])
def api_search():
    query = request.args.get('q', '')
    if not query: return jsonify({"type": "error", "content": "No query"})
        
    result = vse.search(query)
    if result == "HI_USER":
        return jsonify({"type": "chat", "content": f"Hello {vse.owner}! Matrix initialized."})
    if result == "IDENTITY":
        return jsonify({"type": "chat", "content": f"I am Vansh-AI v2. Created by {vse.owner}."})
    
    return jsonify({"type": "results", "data": result})

@app.route('/chat', methods=['GET', 'POST'])
def global_chat():
    if request.method == 'POST':
        data = request.get_json()
        msg = data.get('msg')
        user = data.get('user', 'Guest')
        if msg:
            vse.messages.append({"user": user, "text": msg})
            if len(vse.messages) > 20: vse.messages.pop(0)
            vse.save_to_file()
    return jsonify(vse.messages)

@app.route('/crawl', methods=['POST'])
def api_crawl():
    url = request.get_json().get('url')
    success = vse.crawl(url)
    return jsonify({"status": "success" if success else "failed"})

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)