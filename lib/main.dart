import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'services/audio_recorder.dart';
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
  final List<String> _transcript = [];
  String _selectedLanguage = 'en';
  bool _isLoading = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    try {
      await _recorder.initialize();
    } on Exception catch (e) {
      _logger.e('Recorder initialization error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone access required for recording')),
      );
    }
  }

  Future<void> _toggleRecording() async {
    try {
      if (_recorder.isRecording) {
        final path = await _recorder.stop();
        setState(() {});
        await _processRecording(path);
      } else {
        // Add more detailed permission checking
        _logger.i("Checking microphone permission...");
        
        // Check initial status
        final initialStatus = await AppPermissions.checkMicrophoneStatus();
        _logger.i("Initial permission status: $initialStatus");
        
        final hasPermission = await AppPermissions.requestMicrophoneAccess();
        _logger.i("Permission request result: $hasPermission");
        
        // Check final status
        final currentStatus = await AppPermissions.checkMicrophoneStatus();
        _logger.i("Current permission status: $currentStatus");
        
        if (hasPermission) {
          _logger.i("Permission granted, attempting to initialize recorder");
          
          // Ensure recorder is properly initialized
          if (!_recorder.isInitialized) {
            _logger.i("Initializing recorder...");
            await _initializeRecorder();
          }
          
          _logger.i("Starting recording...");
          await _recorder.start();
          setState(() {});
          
          // Add delay to catch startup errors
          await Future.delayed(Duration(milliseconds: 100));
          if (!_recorder.isRecording) {
            throw Exception("Recorder failed to start despite permissions");
          }
          _logger.i("Recording started successfully");
        } else {
          _logger.w('Permission denied. Status: $currentStatus');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone access required. Please grant permission in Settings'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      _logger.e('Recording failure: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _processRecording(String? path) async {
    if (path == null) return;
    
    setState(() => _isLoading = true);
    try {
      // TODO: Implement speech recognition and translation
      // final transcript = await SpeechToTextService().transcribeAudio(path);
      // final translation = await TranslationService().translateText(transcript, _selectedLanguage);
      // setState(() {
      //   _transcript.add(transcript);
      //   _translation = translation;
      // });
    } catch (e) {
      _logger.e('Processing error: $e');
    } finally {
      setState(() => _isLoading = false);
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
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'es', child: Text('Spanish')),
                  DropdownMenuItem(value: 'fr', child: Text('French')),
                  DropdownMenuItem(value: 'de', child: Text('German')),
                ],
                onChanged: (value) => setState(() => _selectedLanguage = value!),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _transcript.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(_transcript[index]),
              subtitle: Text('Speaker ${index + 1}'),
            ),
          ),
        ),
        if (_isLoading) const LinearProgressIndicator(),
      ],
    );
  }

  @override
  void dispose() {
    _recorder.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
