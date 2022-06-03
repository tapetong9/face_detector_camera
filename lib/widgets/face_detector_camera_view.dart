import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../helpers/camera_helper.dart';

class FaceDetectorCameraView extends StatefulWidget {
  final double eyeOpenThreshold;
  final double eyeCloseThreshold;
  final int autoCaptureWhenBlinked;
  final CameraLensDirection cameraLens;
  final ResolutionPreset resolution;
  final Duration captureDelay;
  final Function(XFile) onCapturedImage;
  final Function(int)? onBlinking;
  final Function(CameraController)? onCreated;

  const FaceDetectorCameraView({
    Key? key,
    this.eyeOpenThreshold = 0.85,
    this.eyeCloseThreshold = 0.15,
    this.autoCaptureWhenBlinked = 3,
    this.cameraLens = CameraLensDirection.front,
    this.resolution = ResolutionPreset.max,
    this.captureDelay = const Duration(milliseconds: 500),
    required this.onCapturedImage,
    this.onBlinking,
    this.onCreated,
  }) : super(key: key);

  @override
  State<FaceDetectorCameraView> createState() => _FaceDetectorCameraViewState();
}

class _FaceDetectorCameraViewState extends State<FaceDetectorCameraView> {
  CameraController? controller;
  bool _isDetecting = false;
  int _eyeState = 0;
  int _eyeBlinkedCount = 0;

  @override
  void initState() {
    super.initState();
    _configureCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: (controller?.value.isInitialized ?? false) ? CameraPreview(controller!) : const SizedBox(),
    );
  }

  Future<void> _configureCamera() async {
    final description = (await availableCameras()).firstWhere((cam) => cam.lensDirection == widget.cameraLens);
    controller = CameraController(description, widget.resolution);
    controller?.initialize().then((_) {
      _streamCamera();

      setState(() {});

      if (widget.onCreated != null) {
        widget.onCreated!(controller!);
      }
    }).catchError(
      (Object e) {
        if (e is CameraException) {
          switch (e.code) {
            case 'CameraAccessDenied':
              log('User denied camera access.');
              break;
            default:
              log('Handle other errors.');
              break;
          }
        }
      },
    );
  }

  Future<void> _streamCamera() async {
    if (controller?.value.isInitialized == false) {
      return;
    }

    controller?.startImageStream(
      (CameraImage rawImage) async {
        if (_isDetecting) {
          return;
        }

        _isDetecting = true;
        final face = await getFaceFromCameraImage(rawImage);
        _isDetecting = false;

        if (face != null) {
          final left = face.leftEyeOpenProbability ?? 0;
          final right = face.rightEyeOpenProbability ?? 0;

          switch (_eyeState) {
            case 0:
              // Both eyes are initially open
              if ((left > widget.eyeOpenThreshold) && (right > widget.eyeOpenThreshold)) {
                _eyeState = 1;
              }
              break;
            case 1:
              // Both eyes become closed
              if ((left < widget.eyeCloseThreshold) && (right < widget.eyeCloseThreshold)) {
                _eyeState = 2;
              }
              break;
            case 2:
              // Both eyes are open again
              if ((left > widget.eyeOpenThreshold) && (right > widget.eyeOpenThreshold)) {
                _eyeState = 0;
                _eyeBlinkedCount++;

                if (widget.onBlinking != null) {
                  widget.onBlinking!(_eyeBlinkedCount);
                }

                if (_eyeBlinkedCount == widget.autoCaptureWhenBlinked) {
                  _eyeBlinkedCount = 0;

                  Future.delayed(widget.captureDelay).then((_) {
                    controller?.stopImageStream().then((_) {
                      controller?.takePicture().then((file) {
                        widget.onCapturedImage(file);
                        _streamCamera();
                      });
                    });
                  });
                }
              }

              break;
            default:
              break;
          }
        }
      },
    );
  }
}
