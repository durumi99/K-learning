import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

class VoiceInputScreen extends StatefulWidget {
  final String currentCaption;
  final int videoID;
  final int transcriptID;
  const VoiceInputScreen(
      {super.key,
      required this.currentCaption,
      required this.videoID,
      required this.transcriptID});

  @override
  State<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends State<VoiceInputScreen> {
  late Record audioRecord;
  late AudioPlayer audioPlayer;
  // var tst;
  bool isRecording = false;
  String audioPath = '';

  @override
  void initState() {
    audioPlayer = AudioPlayer();
    audioRecord = Record();
    super.initState();
  }

  @override
  void dispose() {
    audioRecord.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> readFile() async {
    try {
      final file = File.fromUri(Uri.parse(audioPath));
      final bytes = await file.readAsBytes();
      // tst = bytes;
      // print(file);
      log(bytes.toString());
    } catch (e) {
      if (kDebugMode) {
        print("readFile Error : $e");
      }
    }
  }

  Future<void> startRecording() async {
    try {
      if (await audioRecord.hasPermission()) {
        await audioRecord.start();

        setState(() {
          isRecording = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('startRecording Error : $e');
      }
    }
  }

  Future<void> stopRecording() async {
    try {
      String? path = await audioRecord.stop();
      setState(() {
        isRecording = false;
        audioPath = path!;
      });
      // readFile(audioPath);
    } catch (e) {
      if (kDebugMode) {
        print('stopRecording Error : $e');
      }
    }
  }

  Future<void> playRecording() async {
    try {
      Source urlSource = UrlSource(audioPath);
      // print(tst);
      // Source urlSource = BytesSource(tst);

      if (kDebugMode) {
        print(urlSource);
      }
      await audioPlayer.play(urlSource);
    } catch (e) {
      if (kDebugMode) {
        print('playRecording Error : $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(widget.currentCaption),
          if (isRecording)
            const Column(
              children: [
                CircularProgressIndicator(),
                Text(
                  "Recording in Progress",
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ElevatedButton(
            onPressed: isRecording ? stopRecording : startRecording,
            child:
                isRecording ? Text('Stop Recording') : Text('Start Recording'),
          ),
          const SizedBox(
            height: 25,
          ),
          if (!isRecording && audioPath != '')
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: readFile,
                  child: Text('submit'),
                ),
                ElevatedButton(
                  onPressed: playRecording,
                  child: Text('Play Recording'),
                )
              ],
            ),
        ],
      ),
    ));
  }
}
