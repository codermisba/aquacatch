import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Sample chat data
  List<Map<String, dynamic>> messages = [
    {'text': 'Hello! How can I help you today?', 'isBot': true},
  ];

  Future<String> getBotResponseHF(String userInput) async {
    final String? hfToken = dotenv.env['HF_TOKEN'];
    final String hfModel = "deepseek-ai/DeepSeek-V3-0324";

    final url = Uri.parse("https://router.huggingface.co/v1/chat/completions");

    // Add a system message to define the bot's personality
    final payload = {
      "model": hfModel,
      "messages": [
        {
          "role": "system",
          "content":
              "You are AquaBot, a friendly assistant for the Aquacatch app. "
              "You help users with rooftop rainwater harvesting, artificial recharge, "
              "calculating rainwater harvesting potential, recommending tanks, and answering related queries. "
              "Always respond in a clear, concise, and friendly manner as AquaBot.",
        },
        {"role": "user", "content": userInput},
      ],
      "temperature": 0.7,
  "max_tokens": 200,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $hfToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["choices"] != null && data["choices"].isNotEmpty) {
          return data["choices"][0]["message"]["content"] ?? "No response.";
        }
      } else {
        print("HF API Error: ${response.statusCode} - ${response.body}");
      }

      return "Sorry, I couldn't get a response.";
    } catch (e) {
      return "Error: $e";
    }
  }

  void _sendMessage() {
    String text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({'text': text, 'isBot': false});
      _controller.clear();
    });

    getBotResponseHF(text).then((botReply) {
      setState(() {
        messages.add({'text': botReply, 'isBot': true});
      });

      // Scroll to bottom
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(1, 86, 112, 1),
        title: const Text(
          "AquaBot",
          style: TextStyle(color: Colors.white, fontSize: 28),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Align(
                  alignment: msg['isBot']
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: msg['isBot'] ? Colors.grey[200] : Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: Radius.circular(msg['isBot'] ? 0 : 12),
                        bottomRight: Radius.circular(msg['isBot'] ? 12 : 0),
                      ),
                    ),
                    child: MarkdownBody(
                      data: msg['text'],
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: msg['isBot'] ? Colors.black : Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
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
