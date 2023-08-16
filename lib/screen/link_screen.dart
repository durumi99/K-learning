import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:k_learning/screen/learning_screen.dart';

import '../const/key.dart';

class LinkScreen extends StatefulWidget {
  final int userID;
  const LinkScreen({super.key, required this.userID});

  @override
  State<LinkScreen> createState() => _LinkScreenState();
}

class _LinkScreenState extends State<LinkScreen> {
  int userID = 1;
  int videoID = 1;
  final _formKey = GlobalKey<FormState>();
  String _youtubeLink = '';

  Dio dio = Dio()..httpClientAdapter = IOHttpClientAdapter();

  void uploadLink(context) async {
    // print(_youtubeLink);
    FormData formData = FormData.fromMap({
      "userId": userID,
      "link": _youtubeLink,
    });

    final response = await dio.post(
      'upload',
      data: formData,
      options: Options(
        headers: {"Content-Type": "multipart/form-data"},
        // contentType: Headers.multipartFormDataContentType,
      ),
    );
    // print(response.data['data']['videoId']);
    videoID = response.data['data']['videoId'];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => LearningScreen(
          userID: userID,
          link: _youtubeLink,
          videoID: videoID,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    dio.options.baseUrl = baseURL;
    dio.options.headers = {"userId": 1};
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (
        RequestOptions options,
        RequestInterceptorHandler handler,
      ) {
        if (options.contentType == null) {
          final dynamic data = options.data;
          final String? contentType;
          if (data is FormData) {
            contentType = Headers.multipartFormDataContentType;
          } else if (data is Map) {
            contentType = Headers.formUrlEncodedContentType;
          } else if (data is String) {
            contentType = Headers.jsonContentType;
          } else if (data != null) {
            contentType =
                Headers.textPlainContentType; // Can be removed if unnecessary.
          } else {
            contentType = null;
          }
          options.contentType = contentType;
        }
        handler.next(options);
      },
    ));
    userID = widget.userID;
  }

  @override
  Widget build(BuildContext context) {
    final linkController = TextEditingController();

    void onPressed() {
      final formKeyState = _formKey.currentState;
      if (formKeyState!.validate()) {
        formKeyState.save();
        uploadLink(context);
      }
    }

    String? validator(String? value) {
      if (value == null || value.isEmpty) {
        return '유튜브 링크를 입력해주세요.';
      }

      // 유튜브 링크 검증
      bool isYoutubeLink =
          value.startsWith("https://www.youtube.com/watch?v=") ||
              value.startsWith("https://youtu.be/");

      if (!isYoutubeLink) {
        return '유효한 유튜브 링크가 아닙니다.';
      }

      return null;
    }

    void onSaved(String? value) {
      _youtubeLink = value!.substring(value.indexOf('=') + 1);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Form(
            key: _formKey,
            child: TextFormField(
              validator: validator,
              onSaved: onSaved,
              controller: linkController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(color: Colors.blue),
                ),
                labelText: 'Input Youtube Link',
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (String value) {
                onPressed();
              },
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onPressed,
          child: const Text('Start Learning'),
        ),
      ],
    );
  }
}
