import 'package:image_picker/image_picker.dart';

class ImagePickService {
  ImagePickService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<String?> pickFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );
    return file?.path;
  }

  Future<String?> pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    return file?.path;
  }
}
