import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/assistant_session_service.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ImagePicker _picker = ImagePicker();
  final _sessionService = AssistantSessionService();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('No Supabase user session found.');
      return;
    }

    await _sessionService.getOrCreateSession();

    final history = await _sessionService.loadMessages();

    if (mounted) {
      setState(() {
        _messages
          ..clear()
          ..addAll(history);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }
 
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      );
    }
  }

  // Upload image to bucket and return public URL
  Future<String?> _uploadImageToSupabase(File imageFile) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final fileExt = imageFile.path.split('.').last;
    final fileName =
        'user_${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = 'uploads/$fileName';

    try {
      await supabase.storage.from('assistant_page').upload(filePath, imageFile);
      final publicUrl =
          supabase.storage.from('assistant_page').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Attach an Image",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.deepPurple),
                  title: const Text("Take a photo"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.teal),
                  title: const Text("Upload image"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> _sendMessage() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty && _selectedImage == null) return;

    final now =
        DateFormat('MMM d, yyyy • hh:mm a').format(DateTime.now()); 
    File? imageToSend = _selectedImage;
    String? uploadedImageUrl;

    setState(() => _isLoading = true);

    if (imageToSend != null) {
      uploadedImageUrl = await _uploadImageToSupabase(imageToSend);
    }

    setState(() {
      _messages.add({
        'sender': 'user',
        'text': userInput.isNotEmpty ? userInput : '[Image]',
        'time': now,
        'image': uploadedImageUrl,
      });
      _controller.clear();
      _selectedImage = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    final url = Uri.parse(dotenv.env['CHAT_BACKEND_URL']!);
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];

    String? base64Image;
    if (imageToSend != null) {
      final bytes = await imageToSend.readAsBytes();
      base64Image = base64Encode(bytes);
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $supabaseKey',
        },
        body: jsonEncode({
          'message': userInput,
          'imageBase64': base64Image,
          'history': _messages.map((msg) {
            return {
              'role': msg['sender'] == 'user' ? 'user' : 'assistant',
              'content': [
                {'type': 'text', 'text': msg['text'] ?? ''},
              ],
            };
          }).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['assistant'] ?? 'No response';
        setState(() {
          _messages.add({'sender': 'ai', 'text': reply, 'time': now});
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        await _sessionService.saveMessages(_messages);
      } else {
        setState(() {
          _messages.add({
            'sender': 'ai',
            'text': 'Error: ${response.statusCode}',
            'time': now,
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'ai',
          'text': 'Error sending message: $e',
          'time': now,
        });
      });
    } finally {
      await _sessionService.saveMessages(_messages);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearChat() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text('Are you sure you want to delete all chat history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('assistant_session')
          .update({'messages': [], 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', user.id);

      setState(() => _messages.clear());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat history cleared successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to clear chat: $e')));
    }
  }

  Widget _buildSuggestedPrompts() {
    final suggestions = [
      "What is bmr and tdee?",
      "What foods can I eat to manage my diabetes?",
      "How many minimum daily calories for man and woman",
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: suggestions.map((text) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () => _controller.text = text,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                        color: const Color.fromARGB(255, 116, 16, 107), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBackground = Color(0xFFF9FBFF);

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'AI Health Assistant',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onSelected: (value) async {
              if (value == 'clear') await _clearChat();
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'clear',
                child: Text('Clear Chat'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg['sender'] == 'user';
                    final imageUrl = msg['image'];

                    return Column(
                      crossAxisAlignment:
                          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (index == 0)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                msg['time']!.split('•').first,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment:
                              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            if (!isUser)
                              const CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0xFF6C63FF),
                                child: Icon(Icons.android, color: Colors.white),
                              ),
                            if (!isUser) const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? const Color(0xFF6C63FF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: isUser
                                        ? const Radius.circular(16)
                                        : const Radius.circular(4),
                                    bottomRight: isUser
                                        ? const Radius.circular(4)
                                        : const Radius.circular(16),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (imageUrl != null)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                            imageUrl,
                                            width: 180,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image,
                                                    color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    Text(
                                      msg['text'] ?? '',
                                      style: TextStyle(
                                        color: isUser
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 16,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              left: isUser ? 0 : 44, right: isUser ? 8 : 0),
                          child: Text(
                            msg['time']!.split('•').last.trim(),
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                ),

              _buildSuggestedPrompts(),

              if (_selectedImage != null)
                Container(
                  margin:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _selectedImage!,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImage = null),
                          child: const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.white,
                            child:
                                Icon(Icons.close, size: 18, color: Colors.redAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Container(
                margin: const EdgeInsets.all(8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Transform.translate(
                      offset: const Offset(-10, 0),
                      child: IconButton(
                        icon:
                            const Icon(Icons.attach_file, color: Colors.grey),
                        onPressed: _showImageSourceOptions,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: "Type your message here...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: const Color(0xFF6C63FF),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded,
                            color: Colors.white),
                        onPressed: _isLoading ? null : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
            Positioned(
              right: 16,
              bottom: 150, 
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white, 
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_downward,
                    size: 20,
                    color: Color(0xFF6C63FF),
                  ),
                  onPressed: _scrollToBottom,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
