import 'package:supabase_flutter/supabase_flutter.dart';

class AssistantSessionService {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getOrCreateSession() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final res = await supabase
        .from('assistant_session')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (res != null) return res;

    final newSession = await supabase.from('assistant_session').insert({
      'user_id': user.id,
      'messages': [],
    }).select().single();

    return newSession;
  }

  Future<void> saveMessages(List<Map<String, dynamic>> messages) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final existing = await supabase
        .from('assistant_session')
        .select('user_id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing == null) {
      await supabase.from('assistant_session').insert({
        'user_id': user.id,
        'messages': messages,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } else {
      await supabase.from('assistant_session').update({
        'messages': messages,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', user.id);
    }
  }

 Future<List<Map<String, dynamic>>> loadMessages() async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final res = await supabase
      .from('assistant_session')
      .select('messages')
      .eq('user_id', user.id)
      .maybeSingle();

  if (res == null) return [];
  final messagesData = res['messages'] ?? res['data']?['messages'];
  if (messagesData == null) return [];

  return List<Map<String, dynamic>>.from(messagesData);
}
}
