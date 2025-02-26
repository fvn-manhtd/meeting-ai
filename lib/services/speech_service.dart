import 'dart:async';
import 'package:googleapis/speech/v1.dart' as speech;
import 'package:sound_stream/sound_stream.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart';

/// Service to handle Speech-to-Text conversion using Google Cloud Speech API
class SpeechService {
  final RecorderStream _recorder = RecorderStream();
  StreamSubscription<List<int>>? _audioSubscription;
  StreamController<String>? _textController;
  bool _isListening = false;
  speech.SpeechApi? _speechApi;

  // Initialize the service
  Future<void> initialize() async {
    await _recorder.initialize();
    await _initializeSpeechApi();
  }

  // Initialize Google Cloud Speech API client
  Future<void> _initializeSpeechApi() async {
    try {
      final credentials = await rootBundle.loadString(
          'assets/meeting-assistant-452104-88bb62fa4786.json');
      final client = await clientViaServiceAccount(
        ServiceAccountCredentials.fromJson(credentials),
        [speech.SpeechApi.cloudPlatformScope],
      );
      _speechApi = speech.SpeechApi(client);
    } catch (e) {
      print('Failed to initialize Speech API: $e');
      rethrow;
    }
  }

  // Start speech recognition
  Stream<String> startListening() {
    if (_isListening) return _textController!.stream;
    if (_speechApi == null) throw Exception('Speech API not initialized');

    _textController = StreamController<String>.broadcast();
    _isListening = true;

    // Start audio recording and recognition
    _startRecognition();
    _recorder.start();

    return _textController!.stream;
  }

  void _startRecognition() async {
    try {
      final recognizeRequest = speech.RecognizeRequest(
        config: speech.RecognitionConfig(
          encoding: 'LINEAR16',
          sampleRateHertz: 16000,
          languageCode: 'en-US',
          enableAutomaticPunctuation: true,
          model: 'default',
        ),
      );

      // Set up audio stream
      _audioSubscription = _recorder.audioStream.listen(
        (audio) async {
          try {
            final response = await _speechApi!.speech.recognize(recognizeRequest);
            if (response.results?.isNotEmpty ?? false) {
              final transcript = response.results!.first.alternatives?.first.transcript;
              if (transcript != null) {
                _textController?.add(transcript);
              }
            }
          } catch (e) {
            print('Recognition error: $e');
          }
        },
        onError: (error) {
          print('Audio stream error: $error');
          stopListening();
        },
      );
    } catch (e) {
      print('Failed to start recognition: $e');
      stopListening();
    }
  }

  // Stop speech recognition
  Future<void> stopListening() async {
    _isListening = false;
    await _audioSubscription?.cancel();
    await _recorder.stop();
    await _textController?.close();
  }

  // Clean up resources
  void dispose() {
    stopListening();
    _recorder.stop();
  }
} 