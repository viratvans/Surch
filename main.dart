import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MaterialApp(home: VanshSearchScreen(), debugShowCheckedModeBanner: false));

class VanshSearchScreen extends StatefulWidget {
  @override
  _VanshSearchScreenState createState() => _VanshSearchScreenState();
}

class _VanshSearchScreenState extends State<VanshSearchScreen> {
  TextEditingController _searchController = TextEditingController();
  TextEditingController _crawlController = TextEditingController();
  List results = [];
  String chatResponse = "";

  final String baseUrl = "https://surch.onrender.com";

  Future<void> search(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/search?q=$query'));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        if (data['type'] == 'chat') {
          chatResponse = data['content'];
          results = [];
        } else {
          chatResponse = "";
          results = data['data'];
        }
      });
    }
  }

  Future<void> crawl(String url) async {
    await http.post(
      Uri.parse('$baseUrl/crawl'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"url": url}),
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Crawling $url...")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("VANSH AI"), backgroundColor: Colors.black87),
      body: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search anything...",
                suffixIcon: IconButton(icon: Icon(Icons.send), onPressed: () => search(_searchController.text)),
                border: OutlineInputBorder(),
              ),
            ),
            if (chatResponse.isNotEmpty) Padding(
              padding: EdgeInsets.all(10),
              child: Text(chatResponse, style: TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, i) => Card(
                  child: ListTile(
                    title: Text(results[i]['title']),
                    subtitle: Text(results[i]['summary']),
                    onTap: () => print("Open ${results[i]['url']}"),
                  ),
                ),
              ),
            ),
            Divider(),
            TextField(
              controller: _crawlController,
              decoration: InputDecoration(
                hintText: "Paste URL to index...",
                suffixIcon: IconButton(icon: Icon(Icons.add_link), onPressed: () => crawl(_crawlController.text)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}