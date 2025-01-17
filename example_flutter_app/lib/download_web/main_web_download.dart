import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'download_blob.dart';

late Dio dio;

void main() {
  dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(hours: 3),
    ),
  );

  dio.interceptors.add(LogInterceptor());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter web download blob Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter web download blob Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({
    super.key,
    this.title = '',
  });

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var url =
      'https://jsoncompare.org/LearningContainer/SampleFiles/Video/MP4/sample-mp4-file.mp4';

  CancelToken cancelToken = CancelToken();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          spacing: 20,
          children: [
            ElevatedButton(
              child: const Text('Request'),
              onPressed: () async {
                if (cancelToken.isCancelled) {
                  cancelToken = CancelToken();
                }

                try {
                  // Fetch blob
                  final Response res = await dio.download(
                    url,
                    '',
                    onReceiveProgress: (count, total) {
                      print((count / total) * 100);
                    },
                    cancelToken: cancelToken,
                  );

                  // Download blob
                  downloadBlob(res.data, url.split('/').last);
                  print('fin');
                } catch (e) {
                  print('error');
                }
              },
            ),
            ElevatedButton(
              child: const Text('Cancel'),
              onPressed: () async {
                cancelToken.cancel();
              },
            ),
          ],
        ),
      ),
    );
  }
}
