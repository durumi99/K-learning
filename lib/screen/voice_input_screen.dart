import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:k_learning/const/color.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

import '../const/key.dart';

class VoiceInputScreen extends StatefulWidget {
  final String currentTranscript;
  final int videoID;
  final int transcriptID;

  const VoiceInputScreen({
    super.key,
    required this.currentTranscript,
    required this.videoID,
    required this.transcriptID,
  });

  @override
  State<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends State<VoiceInputScreen> {
  late Record audioRecord;
  late AudioPlayer audioPlayer;
  bool isRecording = false;
  bool neverRecorded = true;
  String audioPath = '';

  String _transcript = '';

  late int _transcriptID;
  late int _videoID;

  @override
  void initState() {
    audioPlayer = AudioPlayer();
    audioRecord = Record();

    _transcript = widget.currentTranscript;
    _transcriptID = widget.transcriptID;
    _videoID = widget.videoID;

    super.initState();
  }

  @override
  void dispose() {
    audioRecord.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<dynamic> getTranslation() async {
    final dio = await authDio(context);

    final response = await dio.get('translations/$_transcriptID');

    dynamic responseBody = response.data['data'];

    return responseBody[0]['text'];
  }

  Future<void> readFile() async {
    try {
      final dio = await authDio(context);
      final file = File.fromUri(Uri.parse(audioPath));
      final bytes = await file.readAsBytes();

      FormData formData = FormData.fromMap({
        "audio": MultipartFile.fromBytes(bytes, filename: "$_transcript.m4a"),
      });

      final response = await dio.post(
        'videos/$_videoID/transcripts/$_transcriptID/audio',
        data: formData,
        options: Options(
          headers: {"Content-Type": "multipart/form-data"},
        ),
      );
      if (kDebugMode) {
        print(response);
      }

      Navigator.of(context).pop();
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

          neverRecorded = false;
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
      final path = await audioRecord.stop();
      setState(() {
        isRecording = false;
        audioPath = path!;
      });
    } catch (e) {
      if (kDebugMode) {
        print('stopRecording Error : $e');
      }
    }
  }

  Future<void> playRecording() async {
    try {
      Source urlSource = UrlSource(audioPath);

      if (kDebugMode) {
        print(audioPath);
      }

      await audioPlayer.play(urlSource);
    } catch (e) {
      if (kDebugMode) {
        print('playRecording Error : $e');
      }
    }
  }

  Widget recordingButton(func, icon) {
    return Padding(
      padding: const EdgeInsets.all(50.0),
      child: InkWell(
        // InkWell 위젯을 사용하여 터치 효과를 추가합니다.
        borderRadius: BorderRadius.circular(50.0),
        child: Container(
          width: 100, // 원형 버튼의 너비
          height: 100, // 원형 버튼의 높이
          decoration: BoxDecoration(
            shape: BoxShape.circle, // 원형 모양 설정
            color: isRecording ? Colors.white : blueColor, // 버튼 배경색
          ),
          child: Center(
            child: icon,
          ),
        ),
      ),
    );
  }

  Container button(text, func, icon, backgroundColor, textColor) {
    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.height * 0.01),
      width: MediaQuery.of(context).size.width,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: 15,
          ),
          backgroundColor: backgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: func,
        icon: icon,
        label: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.50,
      color: isRecording
          ? blueColor
          : getPlatformDependentColor(context, Colors.white, Colors.grey[850]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 56.0,
                child: Center(
                    child: Text(
                  "Practice Pronunciation",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ) // Your desired title
                    ),
              ),
              Positioned(
                left: 0.0,
                top: 0.0,
                child: IconButton(
                  icon: Icon(Icons.close), // Your desired icon
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 20.0,
              bottom: 5.0,
            ),
            child: Text(
              _transcript,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isRecording
                    ? Colors.white
                    : getPlatformDependentColor(
                        context, Colors.black, Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              bottom: 0.0,
            ),
            child: FutureBuilder(
              future: getTranslation(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  final data = snapshot.data;

                  return Text(data,
                      style: TextStyle(
                        fontSize: 15,
                        color: isRecording
                            ? Colors.white
                            : getPlatformDependentColor(
                                context, Color(0xFF999999), Colors.white),
                      ));
                }
              },
            ),
          ),
          if (neverRecorded)
            Center(
              child: recordingButton(
                  startRecording,
                  Icon(
                    Icons.mic,
                    color: Colors.white, // 아이콘 색상
                    size: 40.0, // ),
                  )),
            ),
          if (!neverRecorded && isRecording)
            Center(
                child: recordingButton(
                    stopRecording,
                    Icon(
                      Icons.stop,
                      //  아이콘 색상
                      color: blueColor,
                      size: 60.0,
                    ))),
          if (!neverRecorded && !isRecording)
            Center(
              child: Column(
                children: [
                  button(
                    'Listen to the recording',
                    playRecording,
                    Icon(Icons.replay, color: Colors.white),
                    blueColor,
                    Colors.white,
                  ),
                  button(
                    'Check the results',
                    readFile,
                    Icon(Icons.check, color: Colors.white),
                    blueColor,
                    Colors.white,
                  ),
                  button(
                    'Practice Again',
                    startRecording,
                    Icon(Icons.mic, color: blueColor),
                    blueColor.withOpacity(0.1),
                    blueColor,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
