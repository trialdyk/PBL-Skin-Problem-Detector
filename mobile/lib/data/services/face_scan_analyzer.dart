import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:pbl_skin_problem_detector/data/models/scan_session.dart';

class FaceScanStatus {
  const FaceScanStatus({
    required this.lightingOk,
    required this.facePresent,
    required this.angleOk,
    required this.brightness,
    this.headYaw,
  });

  final bool lightingOk;
  final bool facePresent;
  final bool angleOk;
  final double brightness;
  final double? headYaw;

  bool get ready => lightingOk && facePresent && angleOk;
}

class FaceScanAnalyzer {
  FaceScanAnalyzer()
      : _detector = FaceDetector(
          options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.fast,
            enableTracking: true,
          ),
        );

  final FaceDetector _detector;
  bool _busy = false;
  /// Sign of yaw used when capturing left profile (+1 / -1).
  int? leftYawSign;

  Future<FaceScanStatus> analyze({
    required CameraImage image,
    required CameraDescription camera,
    required SelfieAngle targetAngle,
    required int sensorOrientation,
  }) async {
    if (_busy) {
      return const FaceScanStatus(
        lightingOk: false,
        facePresent: false,
        angleOk: false,
        brightness: 0,
      );
    }
    _busy = true;
    try {
      final brightness = _averageLuma(image);
      final lightingOk = brightness >= 55 && brightness <= 210;

      final input = _toInputImage(
        image: image,
        sensorOrientation: sensorOrientation,
      );
      if (input == null) {
        return FaceScanStatus(
          lightingOk: lightingOk,
          facePresent: false,
          angleOk: false,
          brightness: brightness,
        );
      }

      final faces = await _detector.processImage(input);
      if (faces.isEmpty) {
        return FaceScanStatus(
          lightingOk: lightingOk,
          facePresent: false,
          angleOk: false,
          brightness: brightness,
        );
      }

      final face = faces.reduce(
        (a, b) => (a.boundingBox.width * a.boundingBox.height) >=
                (b.boundingBox.width * b.boundingBox.height)
            ? a
            : b,
      );

      final yaw = face.headEulerAngleY ?? 0;
      final pitch = face.headEulerAngleX ?? 0;
      final facePresent = pitch.abs() < 28;
      final angleOk = facePresent && _isAngleOk(targetAngle, yaw);

      return FaceScanStatus(
        lightingOk: lightingOk,
        facePresent: facePresent,
        angleOk: angleOk,
        brightness: brightness,
        headYaw: yaw,
      );
    } catch (_) {
      return FaceScanStatus(
        lightingOk: _averageLuma(image) >= 55,
        facePresent: false,
        angleOk: false,
        brightness: _averageLuma(image),
      );
    } finally {
      _busy = false;
    }
  }

  bool _isAngleOk(SelfieAngle target, double yaw) {
    final turned = yaw.abs() >= 16 && yaw.abs() <= 48;
    return switch (target) {
      SelfieAngle.front => yaw.abs() <= 14,
      SelfieAngle.left => turned,
      SelfieAngle.right =>
        turned &&
            (leftYawSign == null || yaw.sign != 0 && yaw.sign != leftYawSign),
    };
  }

  void rememberLeftYaw(double? yaw) {
    if (yaw == null || yaw == 0) return;
    leftYawSign = yaw.sign.toInt();
  }

  double _averageLuma(CameraImage image) {
    final bytes = image.planes.first.bytes;
    if (bytes.isEmpty) return 0;
    final step = math.max(1, bytes.length ~/ 4000);
    var sum = 0;
    var count = 0;
    for (var i = 0; i < bytes.length; i += step) {
      sum += bytes[i];
      count++;
    }
    return count == 0 ? 0 : sum / count;
  }

  InputImage? _toInputImage({
    required CameraImage image,
    required int sensorOrientation,
  }) {
    final rotation =
        InputImageRotationValue.fromRawValue(sensorOrientation) ??
            InputImageRotation.rotation0deg;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final bytes = image.planes.first.bytes;
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    }

    // Android: convert YUV_420_888 → NV21 for ML Kit.
    final nv21 = _yuv420ToNv21(image);
    return InputImage.fromBytes(
      bytes: nv21,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.width,
      ),
    );
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;

    final nv21 = Uint8List(width * height * 3 ~/ 2);
    var index = 0;

    final yRowStride = yPlane.bytesPerRow;
    for (var row = 0; row < height; row++) {
      final start = row * yRowStride;
      nv21.setRange(index, index + width, yBuffer, start);
      index += width;
    }

    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;

    for (var row = 0; row < height ~/ 2; row++) {
      for (var col = 0; col < width ~/ 2; col++) {
        final uvIndex = row * uvRowStride + col * uvPixelStride;
        final vIndex = row * vPlane.bytesPerRow + col * vPixelStride;
        nv21[index++] = vBuffer[vIndex];
        nv21[index++] = uBuffer[uvIndex];
      }
    }

    return nv21;
  }

  Future<void> dispose() => _detector.close();
}
