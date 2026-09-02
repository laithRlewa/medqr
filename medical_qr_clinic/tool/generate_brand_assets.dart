// يولّد أصول أيقونة التطبيق وشاشة البداية من شعار MED QR الأصلي.
// التشغيل: dart run tool/generate_brand_assets.dart
import 'dart:io';

import 'package:image/image.dart' as img;

const _brandDir = 'assets/brand';
const _markPath = '$_brandDir/logo_mark.png';
const _fullPath = '$_brandDir/logo_full.png';

/// أبيض نقي — يعطي أوضح تباين لشعار MED QR الداكن على شاشة الهاتف.
final _iconBackground = img.ColorRgba8(0xFF, 0xFF, 0xFF, 0xFF);

void main() {
  final mark = _trim(_read(_markPath));
  final full = _trim(_read(_fullPath));

  // أيقونة التطبيق التقليدية: خلفية مصمتة حتى لا تظهر شفافة على المشغّلات القديمة.
  _write('$_brandDir/app_icon.png', _compose(mark, 1024, 0.74, background: _iconBackground));

  // الطبقة الأمامية للأيقونة التكيّفية: يجب أن تبقى داخل المنطقة الآمنة (66%).
  _write('$_brandDir/app_icon_foreground.png', _compose(mark, 1024, 0.58));

  // شاشة البداية قبل أندرويد 12: الرمز وحده في المنتصف والكلمة تُضاف كتوقيع سفلي.
  // المصدر يُستعمل بكثافة xxxhdpi، أي أن 640 بكسل تعادل 160dp على الشاشة.
  _write('$_brandDir/splash_mark.png', _compose(mark, 640, 0.92));

  // الشعار الكامل — يستعمله الويب وأي عرض يحتاج القفل الكامل بدقة عالية.
  _write('$_brandDir/splash_center.png', _compose(full, 1152, 0.60));

  // أندرويد 12+: الرمز وحده داخل دائرة قطرها 768 بكسل من أصل 1152.
  _write('$_brandDir/splash_android12.png', _compose(mark, 1152, 0.52));

  _write('$_brandDir/wordmark.png', _wordmark(full));
}

img.Image _read(String path) {
  final decoded = img.decodePng(File(path).readAsBytesSync());
  if (decoded == null) throw StateError('تعذّر قراءة $path');
  return decoded.convert(numChannels: 4);
}

void _write(String path, img.Image image) {
  File(path).writeAsBytesSync(img.encodePng(image, level: 6));
  stdout.writeln('${image.width}x${image.height}  $path');
}

/// يقصّ الهوامش الشفافة حتى يصبح مقياس الشعار متوقعاً داخل أي مربع.
img.Image _trim(img.Image src, {int alphaThreshold = 8}) {
  var minX = src.width, minY = src.height, maxX = -1, maxY = -1;
  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      if (src.getPixel(x, y).a <= alphaThreshold) continue;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
  }
  if (maxX < minX || maxY < minY) return src;
  return img.copyCrop(src, x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1);
}

/// يضع [logo] في منتصف مربع [size] بحيث يشغل [scale] من ضلعه.
img.Image _compose(img.Image logo, int size, double scale, {img.Color? background}) {
  final canvas = img.Image(width: size, height: size, numChannels: 4);
  img.fill(canvas, color: background ?? img.ColorRgba8(0, 0, 0, 0));

  final box = (size * scale).round();
  final wide = logo.width >= logo.height;
  final width = wide ? box : (box * logo.width / logo.height).round();
  final height = wide ? (box * logo.height / logo.width).round() : box;

  final resized = img.copyResize(logo, width: width, height: height, interpolation: img.Interpolation.cubic);
  img.compositeImage(canvas, resized, dstX: (size - width) ~/ 2, dstY: (size - height) ~/ 2);
  return canvas;
}

/// يستخرج كلمة "MED QR" من الشعار الكامل لاستعمالها كتوقيع أسفل شاشة البداية.
/// يُقتطع آخر كتلة سطور متصلة، أي ما يقع تحت الفراغ الفاصل عن الرمز.
img.Image _wordmark(img.Image full) {
  bool rowHasContent(int y) {
    for (var x = 0; x < full.width; x++) {
      if (full.getPixel(x, y).a > 8) return true;
    }
    return false;
  }

  var bottom = full.height - 1;
  while (bottom > 0 && !rowHasContent(bottom)) {
    bottom--;
  }
  var top = bottom;
  while (top > 0 && rowHasContent(top - 1)) {
    top--;
  }

  final strip = img.copyCrop(full, x: 0, y: top, width: full.width, height: bottom - top + 1);
  final trimmed = _trim(strip);
  const width = 640;
  final height = (width * trimmed.height / trimmed.width).round();
  return img.copyResize(trimmed, width: width, height: height, interpolation: img.Interpolation.cubic);
}
