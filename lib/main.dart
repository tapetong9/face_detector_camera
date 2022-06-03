import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:face_detector_camera/widgets/face_detector_camera_view.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _openedEyeCount = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Detector Camera',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
        ),
        body: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              color: Colors.black,
              child: FaceDetectorCameraView(
                onCapturedImage: (XFile file) {
                  log("Captured Image:");
                  log(file.path);
                },
                onBlinking: (totalBlinked) {
                  setState(() {
                    _openedEyeCount = totalBlinked;
                  });
                },
              ),
            ),
            _buildTotalBlinkedView(),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBlinkedView() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.white,
      child: Text("Eye Blinked: $_openedEyeCount", style: const TextStyle(fontSize: 18)),
    );
  }
}
