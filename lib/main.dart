import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'services/audio_recorder.dart';
import 'services/speech_text2.dart';
import 'utils/permissions.dart';
import 'screens/recording_history_screen.dart';

void main() => runApp(MeetingAssistantApp());

class MeetingAssistantApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meeting Assistant',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: RecordingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RecordingScreen extends StatefulWidget {
  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final Logger _logger = Logger();
  final SpeechTextService _speechService = SpeechTextService();
  final List<TranscriptEntry> _transcript = [];
  String _selectedLanguage = 'en';
  bool _isLoading = false;
  StreamSubscription<String>? _transcriptionSubscription;
  int _selectedSpeaker = 1;

  late TabController _tabController;

  // Update language map
  final Map<String, String> _languageCodes = {
    'en': 'en_US',
    'ja': 'ja_JP',
    'zh': 'zh_CN',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _recorder.initialize();
      await _speechService.initialize();
      _transcriptionSubscription = _speechService.transcriptionStream.listen(
        (transcript) {
          final now = DateTime.now();
          setState(() {
            if (_transcript.isNotEmpty && !transcript.endsWith('.')) {
              _transcript.last = TranscriptEntry(
                text: transcript,
                speakerNumber: _selectedSpeaker,
                timestamp: now,
              );
            } else {
              _transcript.add(TranscriptEntry(
                text: transcript,
                speakerNumber: _selectedSpeaker,
                timestamp: now,
              ));
            }
          });
          print('New transcript: $transcript'); // Debugging output
        },
        onError: (error) {
          _logger.e('Transcription error: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Transcription error: $error')),
          );
        }
      );
    } catch (e) {
      _logger.e('Service initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing services: $e')),
        );
      }
    }
  }

  Future<void> _toggleRecording() async {
    try {
      if (_recorder.isRecording) {
        await _recorder.stop();
        await _speechService.stopListening();
        _transcriptionSubscription?.cancel();
        setState(() {});
      } else {
        final hasPermission = await AppPermissions.requestMicrophoneAccess();
        if (hasPermission) {
          // Pass selected language when starting
          await _speechService.startListening(
            language: _languageCodes[_selectedLanguage],
          );
          _transcriptionSubscription = _speechService.transcriptionStream.listen(
            (transcript) {
              final now = DateTime.now();
              setState(() {
                if (_transcript.isNotEmpty && !transcript.endsWith('.')) {
                  _transcript.last = TranscriptEntry(
                    text: transcript,
                    speakerNumber: _selectedSpeaker,
                    timestamp: now,
                  );
                } else {
                  _transcript.add(TranscriptEntry(
                    text: transcript,
                    speakerNumber: _selectedSpeaker,
                    timestamp: now,
                  ));
                }
              });
            },
            onError: (error) {
              _logger.e('Transcription error: $error');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Transcription error: $error')),
              );
            }
          );
          
          await _recorder.start();
          setState(() {});
        } else {
          _logger.w('Permission denied');
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required')),
          );
        }
      }
    } catch (e) {
      _logger.e('Recording error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Assistant'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.text_snippet), text: 'Summary'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RecordingHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecordingInterface(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleRecording,
        child: Icon(_recorder.isRecording ? Icons.stop : Icons.mic),
      ),
    );
  }

  Widget _buildRecordingInterface() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recording Status: ${_recorder.isRecording ? 'ON' : 'OFF'}'),
              DropdownButton<String>(
                value: _selectedLanguage,
                items: _languageCodes.keys.map((String key) {
                  return DropdownMenuItem<String>(
                    value: key,
                    child: Text(_getLanguageName(key)),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() => _selectedLanguage = value);
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _transcript.length,
            itemBuilder: (context, index) => Card(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Speaker ${_transcript[index].speakerNumber} is speaking:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _transcript[index].text,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _transcript[index].timestamp.toString().substring(11, 19),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isLoading) const LinearProgressIndicator(),
      ],
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ja':
        return 'Japanese';
      case 'zh':
        return 'Chinese';
      default:
        return 'Unknown';
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    _speechService.dispose();
    _transcriptionSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }
}

class TranscriptEntry {
  final String text;
  final int speakerNumber;
  final DateTime timestamp;

  TranscriptEntry({
    required this.text,
    required this.speakerNumber,
    required this.timestamp,
  });
}
