import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 图片相关能力：从相册选凭证图、把长图保存到系统相册。
class MediaService {
  MediaService._();

  static const String albumName = '个人成长';

  /// 从相册选择一张图片，并复制到应用私有目录，避免系统清理缓存后丢图。
  /// 返回 null 表示用户取消选择。
  static Future<String?> pickVoucherFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 88,
    );
    if (picked == null) return null;

    final documents = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(documents.path, 'vouchers'));
    if (!folder.existsSync()) {
      await folder.create(recursive: true);
    }

    final ext = p.extension(picked.path).isEmpty ? '.jpg' : p.extension(picked.path);
    final target = p.join(
      folder.path,
      'voucher_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    final copied = await File(picked.path).copy(target);
    return copied.path;
  }

  /// 把长图写入系统相册（Android 10+ 走 MediaStore，无需额外权限）
  static Future<void> saveImageToGallery(Uint8List bytes) async {
    var hasAccess = await Gal.hasAccess(toAlbum: true);
    if (!hasAccess) {
      hasAccess = await Gal.requestAccess(toAlbum: true);
    }
    if (!hasAccess) {
      throw StateError('没有相册写入权限');
    }
    await Gal.putImageBytes(bytes, album: albumName);
  }

  /// 把底层异常翻译成用户能看懂的一句话
  static String describeError(Object error) {
    if (error is StateError && error.message == '没有相册写入权限') {
      return '没有相册权限，请到系统设置中允许访问照片';
    }
    if (error is GalException) {
      switch (error.type.name) {
        case 'accessDenied':
          return '没有相册权限，请到系统设置中允许访问照片';
        case 'notEnoughSpace':
          return '存储空间不足，无法保存图片';
        case 'notSupportedFormat':
          return '图片格式不支持';
        default:
          return '保存失败，请稍后重试';
      }
    }
    return '保存失败：$error';
  }
}
