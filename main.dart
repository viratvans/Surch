import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() => runApp(MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.greenAccent,
      ),
      home: VanshUltimateEngine(),
      debugShowCheckedModeBanner: false,
    ));

class VanshUltimateEngine extends StatefulWidget {
  @override
  _VanshUltimateEngineState createState() => _VanshUltimateEngineState();
}

class _VanshUltimateEngineState extends State<VanshUltimateEngine> {
  final String baseUrl = "https://surch.onrender.com";
  List results = [];
  List chatMsgs = [];
  bool isLoading = false;
  bool isListening = false;
  
  stt.SpeechToText _speech = stt.SpeechToText();
  TextEditingController _searchCtrl = TextEditingController();
  TextEditingController _chatCtrl = TextEditingController();
  ScrollController _chatScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _initSpeech();
    Timer.periodic(Duration(seconds: 4), (t) => getChat());
  }

  void _initSpeech() async => await _speech.initialize();

  void _listen() async {
    if (!isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => isListening = true);
        _speech.listen(onResult: (val) {
          setState(() {
            _searchCtrl.text = val.recognizedWords;
            if (val.finalResult) {
              isListening = false;
              search(val.recognizedWords);
            }
          });
        });
      }
    } else {
      setState(() => isListening = false);
      _speech.stop();
    }
  }

  void search(String q) async {
    if (q.isEmpty) return;
    setState(() => isLoading = true);
    var res = await http.get(Uri.parse('$baseUrl/search?q=$q'));
    if (res.statusCode == 200) {
      setState(() {
        results = json.decode(res.body)['data'] ?? [];
        isLoading = false;
      });
    }
  }

  void getChat() async {
    var res = await http.get(Uri.parse('$baseUrl/chat'));
    if (res.statusCode == 200) setState(() => chatMsgs = json.decode(res.body));
  }

  void sendChat(String msg) async {
    if (msg.isEmpty) return;
    await http.post(Uri.parse('$baseUrl/chat'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"user": "VANSH_ADMIN", "msg": msg}));
    _chatCtrl.clear();
    getChat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("VANSH_AI_OS v3.0", style: TextStyle(fontFamily: 'Courier', color: Colors.greenAccent, letterSpacing: 2)),
        backgroundColor: Colors.black,
        elevation: 10,
        shadowColor: Colors.greenAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green.withOpacity(0.2), width: 0.5)
        ),
        child: Column(
          children: [
            // GLOWING SEARCH BAR
            Padding(
              padding: EdgeInsets.all(12),
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(color: Colors.greenAccent, fontFamily: 'Courier'),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.terminal, color: Colors.green),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(isListening ? Icons.mic : Icons.mic_none, color: isListening ? Colors.red : Colors.greenAccent),
                        onPressed: _listen,
                      ),
                      IconButton(icon: Icon(Icons.search, color: Colors.greenAccent), onPressed: () => search(_searchCtrl.text)),
                    ],
                  ),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent, width: 2)),
                  hintText: "SYSTEM_SCAN_REQUEST...",
                  hintStyle: TextStyle(color: Colors.green.withOpacity(0.3)),
                ),
              ),
            ),

            if (isLoading) LinearProgressIndicator(backgroundColor: Colors.black, color: Colors.greenAccent),

            // SEARCH RESULTS WITH IMAGES
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, i) {
                  var item = results[i];
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                      boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 5)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(item['title'].toUpperCase(), style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(item['summary'], style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ),
                        if (item['images'] != null && item['images'].isNotEmpty)
                          SizedBox(
                            height: 110,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: (item['images'] as List).length,
                              itemBuilder: (ctx, imgIdx) => Padding(
                                padding: EdgeInsets.all(5),
                                child: Image.network(item['images'][imgIdx], width: 150, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        Padding(
                          padding: EdgeInsets.only(left: 15, bottom: 8),
                          child: Text("LINK: ${item['url']}", style: TextStyle(color: Colors.green, fontSize: 10)),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),

            // NEON CHAT HUD
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Color(0xFF050505),
                border: Border(top: BorderSide(color: Colors.greenAccent, width: 2)),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.greenAccent.withOpacity(0.1),
                    child: Center(child: Text("LIVE_DATA_FEED", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold))),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _chatScroll,
                      padding: EdgeInsets.all(10),
                      itemCount: chatMsgs.length,
                      itemBuilder: (context, i) => Text(
                        "> [${chatMsgs[i]['user']}]: ${chatMsgs[i]['text']}",
                        style: TextStyle(color: Colors.green, fontFamily: 'Courier', fontSize: 12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: TextField(
                      controller: _chatCtrl,
                      style: TextStyle(color: Colors.white, fontFamily: 'Courier'),
                      decoration: InputDecoration(
                        hintText: "SEND_ENCRYPTED_MSG...",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                        suffixIcon: IconButton(icon: Icon(Icons.flash_on, color: Colors.greenAccent), onPressed: () => sendChat(_chatCtrl.text)),
                      ),
                      onSubmitted: (v) => sendChat(v),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}