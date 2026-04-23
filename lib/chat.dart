import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final gemini = Gemini.instance;

  List<Map<String, dynamic>> messages = [
    {'text': 'Hello! How can I help you today?', 'isBot': true},
  ];

  Future<String> getBotResponseGemini(String userInput) async {
    try {
      final response = await gemini.text(
        "You are AquaBot, a friendly assistant for the Aquacatch app. "
        "You help users with rooftop rainwater harvesting, artificial recharge, "
        "calculating rainwater harvesting potential, recommending tanks, and "
        "answering related queries. Always respond clearly, concisely, and kindly.\n\n"
        "User: $userInput",
      );

      return response?.output ?? "No response from Aquabot.";
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

    getBotResponseGemini(text).then((botReply) {
      setState(() {
        messages.add({'text': botReply, 'isBot': true});
      });

      // scroll to bottom
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  /// Build a widget for a message that may contain multiple math segments.
  /// Math is recognized as $$...$$ (display) or $...$ (inline).
  /// Non-math segments are rendered with MarkdownBody.
  Widget _buildMessage(Map<String, dynamic> msg) {
    final String text = msg['text'] as String;
    final bool isBot = msg['isBot'] as bool;

    // If it's a user message, just return plain text (no markdown/math parsing)
    if (!isBot) {
      return Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      );
    }

    // Regex: match either $$...$$ (multiline) OR $...$ (non-greedy single-dollar)
    final regex = RegExp(r'(\${2}[\s\S]*?\${2}|\$[^$]*\$)');

    final matches = regex.allMatches(text).toList();

    // If no math matches, render entire text as Markdown
    if (matches.isEmpty) {
      return MarkdownBody(
        data: text,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(color: Colors.black, fontSize: 14),
          strong: const TextStyle(fontWeight: FontWeight.bold),
          em: const TextStyle(fontStyle: FontStyle.italic),
          code: TextStyle(
            backgroundColor: Colors.grey[300],
            fontFamily: 'monospace',
          ),
          listBullet: const TextStyle(color: Colors.black, fontSize: 14),
        ),
      );
    }

    // Otherwise, split into alternating non-math and math parts
    final List<Widget> parts = [];
    int lastIndex = 0;

    for (final m in matches) {
      if (m.start > lastIndex) {
        final nonMath = text.substring(lastIndex, m.start);
        if (nonMath.trim().isNotEmpty) {
          parts.add(
            MarkdownBody(
              data: nonMath,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: Colors.black, fontSize: 14),
                strong: const TextStyle(fontWeight: FontWeight.bold),
                em: const TextStyle(fontStyle: FontStyle.italic),
                code: TextStyle(
                  backgroundColor: Colors.grey[300],
                  fontFamily: 'monospace',
                ),
                listBullet: const TextStyle(color: Colors.black, fontSize: 14),
              ),
            ),
          );
        }
      }

      final matchText = m.group(0)!;

      // Determine if display ($$) or inline ($)
      bool isDisplay = matchText.startsWith(r'$$') && matchText.endsWith(r'$$');
      String mathContent;
      if (isDisplay) {
        mathContent = matchText.substring(2, matchText.length - 2);
      } else {
        // strip single leading/trailing $
        mathContent = matchText.substring(1, matchText.length - 1);
      }

      // Trim math content
      mathContent = mathContent.trim();

      // Add math widget. Wrap in horizontal scroll to avoid overflow for long formula.
      try {
        parts.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                mathContent,
                textStyle: const TextStyle(fontSize: 14),
                mathStyle: isDisplay ? MathStyle.display : MathStyle.text,
              ),
            ),
          ),
        );
      } catch (e) {
        // If Math parsing fails, show the raw match as Markdown fallback
        parts.add(
          MarkdownBody(
            data: matchText,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(color: Colors.black, fontSize: 14),
            ),
          ),
        );
      }

      lastIndex = m.end;
    }

    // trailing non-math
    if (lastIndex < text.length) {
      final trailing = text.substring(lastIndex);
      if (trailing.trim().isNotEmpty) {
        parts.add(
          MarkdownBody(
            data: trailing,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(color: Colors.black, fontSize: 14),
              strong: const TextStyle(fontWeight: FontWeight.bold),
              em: const TextStyle(fontStyle: FontStyle.italic),
              code: TextStyle(
                backgroundColor: Colors.grey[300],
                fontFamily: 'monospace',
              ),
              listBullet: const TextStyle(color: Colors.black, fontSize: 14),
            ),
          ),
        );
      }
    }

    // If only one part, return it directly
    if (parts.length == 1) return parts.first;

    // Otherwise stack parts vertically (preserves message box layout)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: parts,
    );
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
            child: Scrollbar(
              controller: _scroll_controller_safe(),
              thumbVisibility: true,
              thickness: 6,
              radius: const Radius.circular(10),
              child: ListView.builder(
                controller: _scroll_controller_safe(),
                itemCount: messages.length,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return Align(
                    alignment: msg['isBot'] ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      child: _buildMessage(msg),
                    ),
                  );
                },
              ),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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

  // Helper to safely return the ScrollController (prevents using a null controller in two places).
  ScrollController _scroll_controller_safe() => _scrollController;
}
