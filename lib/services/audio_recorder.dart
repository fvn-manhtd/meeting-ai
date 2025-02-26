import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecorder {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  bool _isInitialized = false;
  String? _currentFilePath;

  bool get isRecording => _isRecording;
  bool get isInitialized => _isInitialized;
  String? get currentFilePath => _currentFilePath;

  /// Initialize recorder with proper error handling
  Future<void> initialize() async {
    try {
      // Request microphone permission first
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw Exception('Microphone permission not granted');
      }

      if (!_isInitialized) {
        await _recorder.openRecorder();
        await _recorder.setSubscriptionDuration(const Duration(milliseconds: 10));
        _isInitialized = true;
        print("Recorder initialized successfully");
      }
    } on PlatformException catch (e) {
      print("Recorder initialization error: ${e.message}");
      rethrow;
    }
  }

  /// Start audio recording with timestamped filename
  Future<void> start() async {
    if (!_isInitialized) {
      print("Recorder not initialized - attempting recovery");
      await initialize();
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      _currentFilePath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';
      print("Starting recording at: $_currentFilePath");
      
      await _recorder.startRecorder(
        toFile: _currentFilePath,
        codec: Codec.aacADTS,
        sampleRate: 16000,
      );
      _isRecording = true;
      print("Recording successfully started");
    } catch (e) {
      _isRecording = false;
      print("Critical recording error: ${e.toString()}");
      throw Exception("Failed to start recording: ${e.toString()}");
    }
  }

  /// Stop recording and return file path
  Future<String?> stop() async {
    try {
      await _recorder.stopRecorder();
      _isRecording = false;
      print("Recording stopped");
      return _currentFilePath;
    } catch (e) {
      print("Error stopping recording: $e");
      rethrow;
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    if (_isInitialized) {
      await _recorder.closeRecorder();
      _isInitialized = false;
    }
  }
} 