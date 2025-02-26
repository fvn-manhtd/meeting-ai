import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'audio_playback_screen.dart';

class RecordingHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording History'),
      ),
      body: FutureBuilder<List<FileSystemEntity>>(
        future: _getRecordingFiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No recordings found.'));
          } else {
            final files = snapshot.data!;
            return ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index] as File;
                final fileName = file.path.split('/').last;
                final fileStats = file.statSync();
                final fileDate = DateTime.fromMillisecondsSinceEpoch(
                    fileStats.modified.millisecondsSinceEpoch);

                return Dismissible(
                  key: Key(file.path),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    file.deleteSync();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$fileName deleted')),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.audio_file),
                      title: Text(
                        fileName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${fileDate.toString().split('.')[0]}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AudioPlaybackScreen(file: file),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<List<FileSystemEntity>> _getRecordingFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.listSync().where((file) => file.path.endsWith('.aac')).toList();
  }
} 