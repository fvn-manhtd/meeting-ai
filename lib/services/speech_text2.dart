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
// Keep track of current transcript
  static const int PAUSE_THRESHOLD = 5; // 5 seconds pause threshold

  // Initialize the speech recognition service
  Future<void> initialize() async {
    _isSpeechAvailable = await _speechToText.initialize(
      onStatus: _onStatus,
      onError: _onError,
    );
  }

  // Start listening for speech input
  Future<void> startListening() async {
    if (_isSpeechAvailable && !_isListening) {
      _isListening = true;
      await _speechToText.listen(onResult: _onSpeechResult);
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