import 'dart:typed_data';

import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// A fake [ImagePickerPlatform] so `PhotoImportScreen` can be tested without
/// a real camera/photo-library platform channel.
class FakeImagePickerPlatform extends ImagePickerPlatform {
  FakeImagePickerPlatform.returningImage(Uint8List bytes)
      : _file = XFile.fromData(bytes, name: 'worksheet.jpg', mimeType: 'image/jpeg');
  FakeImagePickerPlatform.cancelled() : _file = null;

  final XFile? _file;

  /// The source (camera/gallery) most recently requested.
  ImageSource? lastSource;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    lastSource = source;
    return _file;
  }
}
