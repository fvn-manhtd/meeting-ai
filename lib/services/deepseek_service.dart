import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepSeekService {
  static const String _baseUrl = 'https://api.deepseek.com/v1';
  final String _apiKey;

  DeepSeekService(this._apiKey);

  /// Generate meeting summary using DeepSeek API
  Future<String> generateSummary(String transcript) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'Generate a concise meeting summary with: '
                  '- Action items '
                  '- Key decisions '
                  '- Speaker identification'
            },
            {
              'role': 'user',
              'content': transcript
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1000
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      }
      throw Exception('API request failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('DeepSeek API error: $e');
    }
  }
} 