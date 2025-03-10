// lib/services/speech_text2.dart
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'dart:async';

class SpeechTextService {
  final SpeechToText _speechToText = SpeechToText();
  final StreamController<String> _transcriptionController = StreamController<String>.broadcast();
  bool _isSpeechAvailable = false;
  bool _isListening = false;
  String _selectedLanguage = 'en_US';

  // Initialize the speech recognition service
  Future<void> initialize() async {
    _isSpeechAvailable = await _speechToText.initialize(
      onStatus: _onStatus,
      onError: _onError,
    );
  }

  // Start listening for speech input with language selection
  Future<void> startListening({String? language}) async {
    if (_isSpeechAvailable && !_isListening) {
      _isListening = true;
      _selectedLanguage = language ?? 'en_US';
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: Duration(hours: 1),
        pauseFor: Duration(seconds: 10),
        localeId: _selectedLanguage,
      );
    }
  }

  // Stop listening for speech input
  Future<void> stopListening() async {
    if (_isListening) {
      _isListening = false;
      await _speechToText.stop();
    }
  }

  // Callback for speech recognition results
  void _onSpeechResult(SpeechRecognitionResult result) {
    // Send both partial and final results to stream
    _transcriptionController.add(result.recognizedWords);
  }

  // Callback for status changes
  void _onStatus(String status) {
    print('Speech status: $status');
    if (status == 'done') {
      if (_isListening) {
        startListening(language: _selectedLanguage);
      }
    }
  }

  // Callback for errors
  void _onError(SpeechRecognitionError error) {
    print('Speech error: ${error.errorMsg}');
  }

  // Stream of transcription results
  Stream<String> get transcriptionStream => _transcriptionController.stream;

  // Get the last recognized words
  Stream<String> get lastWords {
    return _transcriptionController.stream;
  }

  // Dispose the stream controller
  void dispose() {
    _transcriptionController.close();
  }
}