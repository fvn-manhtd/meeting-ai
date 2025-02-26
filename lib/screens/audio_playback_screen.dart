import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:io';

class AudioPlaybackScreen extends StatefulWidget {
  final File file;

  const AudioPlaybackScreen({super.key, required this.file});

  @override
  _AudioPlaybackScreenState createState() => _AudioPlaybackScreenState();
}

class _AudioPlaybackScreenState extends State<AudioPlaybackScreen> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player.openPlayer();
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }

  void _togglePlayback() async {
    if (_isPlaying) {
      await _player.stopPlayer();
    } else {
      await _player.startPlayer(fromURI: widget.file.path);
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Playback: ${widget.file.path.split('/').last}'),
      ),
      body: Center(
        child: IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: _togglePlayback,
          iconSize: 64.0,
        ),
      ),
    );
  }
} 