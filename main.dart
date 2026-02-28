import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MaterialApp(
  theme: ThemeData.dark().copyWith(
    scaffoldBackgroundColor: Colors.black,
    primaryColor: Colors.greenAccent,
  ),
  home: HackerSearchScreen(),
  debugShowCheckedModeBanner: false,
));

class HackerSearchScreen extends StatefulWidget {
  @override
  _HackerSearchScreenState createState() => _HackerSearchScreenState();
}

class _HackerSearchScreenState extends State<HackerSearchScreen> {
  final String baseUrl = "https://surch.onrender.com";
  List results = [];
  List chatMsgs = [];
  TextEditingController _searchCtrl = TextEditingController();
  TextEditingController _chatCtrl = TextEditingController();

  void search(String q) async {
    var res = await http.get(Uri.parse('$baseUrl/search?q=$q'));
    if (res.statusCode == 200) setState(() => results = json.decode(res.body)['data']);
  }

  void sendChat(String msg) async {
    await http.post(Uri.parse('$baseUrl/chat'), 
      headers: {"Content-Type": "application/json"},
      body: json.encode({"user": "Vansh_User", "msg": msg}));
    _chatCtrl.clear();
    getChat();
  }

  void getChat() async {
    var res = await http.get(Uri.parse('$baseUrl/chat'));
    if (res.statusCode == 200) setState(() => chatMsgs = json.decode(res.body));
  }

  @override
  void initState() { super.initState(); getChat(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("> VANSH_AI_v2.0", style: TextStyle(fontFamily: 'Courier', color: Colors.greenAccent)),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // SEARCH BAR (MATRIX STYLE)
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(color: Colors.greenAccent),
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                hintText: "SYSTEM_SEARCH_QUERY...",
                hintStyle: TextStyle(color: Colors.green.withOpacity(0.5)),
                suffixIcon: IconButton(icon: Icon(Icons.terminal, color: Colors.green), onPressed: () => search(_searchCtrl.text)),
              ),
            ),
          ),
          
          // RESULTS AREA
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, i) => Card(
                color: Colors.grey[900],
                child: ListTile(
                  title: Text(results[i]['title'], style: TextStyle(color: Colors.greenAccent)),
                  subtitle: Text(results[i]['summary'], style: TextStyle(color: Colors.white70)),
                ),
              ),
            ),
          ),

          // GLOBAL CHAT BOX (NEON STYLE)
          Container(
            height: 150,
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.greenAccent, width: 2))),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: chatMsgs.length,
                    itemBuilder: (context, i) => Text("[${chatMsgs[i]['user']}]: ${chatMsgs[i]['text']}", 
                      style: TextStyle(color: Colors.green, fontSize: 12, fontFamily: 'Courier')),
                  ),
                ),
                TextField(
                  controller: _chatCtrl,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "SAY_SOMETHING...",
                    suffixIcon: IconButton(icon: Icon(Icons.send, color: Colors.greenAccent), onPressed: () => sendChat(_chatCtrl.text)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}