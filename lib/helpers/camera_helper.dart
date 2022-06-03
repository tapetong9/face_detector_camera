import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as imglib;
import 'package:flutter/foundation.dart';

Future<List<int>?> convertImagetoPng(CameraImage image) async {
  try {
    imglib.Image? img;
    if (image.format.group == ImageFormatGroup.yuv420) {
      img = _convertToYUV420(image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      img = _convertToBGRA8888(image);
    }

    imglib.PngEncoder pngEncoder = imglib.PngEncoder();

    // Convert to png
    List<int> png = pngEncoder.encodeImage(img!);
    return png;
  } catch (e) {
    if (kDebugMode) {
      log(">>>>>>>>>>>> ERROR:" + e.toString());
    }
  }
  return null;
}

// CameraImage BGRA8888 -> PNG
// Color
imglib.Image _convertToBGRA8888(CameraImage image) {
  return imglib.Image.fromBytes(
    image.width,
    image.height,
    image.planes[0].bytes,
    format: imglib.Format.bgra,
  );
}

// CameraImage YUV420_888 -> PNG -> Image (compresion:0, filter: none)
// Black
imglib.Image _convertToYUV420(CameraImage image) {
  var img = imglib.Image(image.width, image.height); // Create Image buffer

  Plane plane = image.planes[0];
  const int shift = (0xFF << 24);

  // Fill image buffer with plane[0] from YUV420_888
  for (int x = 0; x < image.width; x++) {
    for (int planeOffset = 0; planeOffset < image.height * image.width; planeOffset += image.width) {
      final pixelColor = plane.bytes[planeOffset + x];
      // color: 0x FF  FF  FF  FF
      //           A   B   G   R
      // Calculate pixel color
      var newVal = shift | (pixelColor << 16) | (pixelColor << 8) | pixelColor;

      img.data[planeOffset + x] = newVal;
    }
  }

  return img;
}

Future<Face?> getFaceFromCameraImage(CameraImage image) async {
  final options = FaceDetectorOptions(
    performanceMode: FaceDetectorMode.fast,
    enableClassification: true,
    enableTracking: true,
    // // enableContours: true,
    // enableLandmarks: true,
  );

  final faceDetector = FaceDetector(options: options);
  final inputImage = convertToInputImage(image);
  final List<Face> faces = await faceDetector.processImage(inputImage);

  if (faces.isNotEmpty) {
    return faces.first;
  } else {
    return null;
  }
}

InputImage convertToInputImage(CameraImage cameraImage) {
  final WriteBuffer allBytes = WriteBuffer();

  for (final Plane plane in cameraImage.planes) {
    allBytes.putUint8List(plane.bytes);
  }

  final bytes = allBytes.done().buffer.asUint8List();
  final Size imageSize = Size(cameraImage.width.toDouble(), cameraImage.height.toDouble());
  final InputImageFormat inputImageFormat = InputImageFormatValue.fromRawValue(cameraImage.format.raw) ?? InputImageFormat.nv21;

  final planeData = cameraImage.planes.map(
    (Plane plane) {
      return InputImagePlaneMetadata(
        bytesPerRow: plane.bytesPerRow,
        height: plane.height,
        width: plane.width,
      );
    },
  ).toList();

  final inputImageData = InputImageData(size: imageSize, imageRotation: InputImageRotation.rotation0deg, inputImageFormat: inputImageFormat, planeData: planeData);

  final inputImage = InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
  return inputImage;
}
