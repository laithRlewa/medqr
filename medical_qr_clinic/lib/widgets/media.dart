import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zxing2/qrcode.dart';
import 'package:zxing2/zxing2.dart';

import '../api/api_config.dart';
import '../state/clinic_store.dart';
import 'clinic_icon.dart';
import 'ui.dart';

/// يفتح أداة اختيار الصور النظامية دون صلاحية معرض كاملة.
Future<XFile?> pickGalleryImage({int imageQuality = 85, double? maxWidth}) {
  return ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: imageQuality,
    maxWidth: maxWidth,
    requestFullMetadata: false,
  );
}

Future<String?> pickAndUpload(ClinicStore store, {bool imagesOnly = false}) async {
  if (imagesOnly) {
    final file = await pickGalleryImage();
    if (file == null) return null;
    return store.uploadPath(file.path);
  }
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'doc', 'docx'],
    withData: false,
  );
  final path = result?.files.single.path;
  if (path == null) return null;
  return store.uploadPath(path);
}

Future<List<String>> pickAndUploadMany(ClinicStore store) async {
  final files = await ImagePicker().pickMultiImage(
    imageQuality: 85,
    requestFullMetadata: false,
  );
  final urls = <String>[];
  for (final file in files) {
    final url = await store.uploadPath(file.path);
    if (url != null && url.isNotEmpty) urls.add(url);
  }
  return urls;
}

Future<String?> pickImageAndUpload(ClinicStore store, {bool camera = false}) async {
  final file = camera
      ? await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85)
      : await pickGalleryImage();
  if (file == null) return null;
  return store.uploadPath(file.path);
}

Future<String?> decodeQrFromPath(String path) async {
  final bytes = await File(path).readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  String? tryDecode(img.Image image) {
    final pixels = Int32List(image.width * image.height);
    var i = 0;
    for (final pixel in image) {
      pixels[i++] = (pixel.a.toInt() << 24) | (pixel.r.toInt() << 16) | (pixel.g.toInt() << 8) | pixel.b.toInt();
    }
    try {
      final source = RGBLuminanceSource(image.width, image.height, pixels);
      final bitmap = BinaryBitmap(HybridBinarizer(source));
      return QRCodeReader().decode(bitmap).text;
    } catch (_) {
      try {
        final source = RGBLuminanceSource(image.width, image.height, pixels);
        final bitmap = BinaryBitmap(GlobalHistogramBinarizer(source));
        return QRCodeReader().decode(bitmap).text;
      } catch (_) {
        return null;
      }
    }
  }

  // جرّب عدة أحجام لتحسين القراءة من صور الهاتف.
  for (final width in <int?>[null, 1200, 800, 1600]) {
    final image = width == null || decoded.width <= width
        ? decoded
        : img.copyResize(decoded, width: width, interpolation: img.Interpolation.average);
    final text = tryDecode(image);
    if (text != null && text.isNotEmpty) return text;
  }
  return null;
}

Future<String?> scanQrFromDevice({bool camera = false}) async {
  final file = camera
      ? await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 95, maxWidth: 2000)
      : await pickGalleryImage(imageQuality: 95, maxWidth: 2000);
  if (file == null) return null;
  return decodeQrFromPath(file.path);
}

Future<void> openMedia(String url) async {
  final resolved = ApiConfig.mediaUrl(url);
  if (resolved.isEmpty) return;
  final uri = Uri.parse(resolved);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> saveOrShareQr(String data, {String name = 'medical-qr'}) async {
  final painter = QrPainter(data: data, version: QrVersions.auto, gapless: true, eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: ClinicColors.primaryDeep));
  final pic = await painter.toImageData(900, format: ui.ImageByteFormat.png);
  if (pic == null) return;
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$name.png');
  await file.writeAsBytes(pic.buffer.asUint8List());
  await Share.shareXFiles([XFile(file.path)], text: 'رمزي الطبي');
}

class NetworkPhoto extends StatelessWidget {
  const NetworkPhoto(this.url, {super.key, this.width, this.height, this.fit = BoxFit.cover, this.radius = 12});
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConfig.mediaUrl(url);
    if (resolved.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(resolved, width: width, height: height, fit: fit, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined)),
    );
  }
}

class FileTile extends StatelessWidget {
  const FileTile({super.key, required this.name, required this.type, required this.subtitle, this.url = '', this.description = ''});
  final String name;
  final String type;
  final String subtitle;
  final String url;
  final String description;

  @override
  Widget build(BuildContext context) {
    final image = url.isNotEmpty && RegExp(r'\.(png|jpg|jpeg|webp|heic)$', caseSensitive: false).hasMatch(url);
    final pdf = url.isNotEmpty && RegExp(r'\.pdf$', caseSensitive: false).hasMatch(url);
    return Card(
      child: ListTile(
        leading: image
            ? NetworkPhoto(url, width: 48, height: 48)
            : ClinicIcon(
                pdf ? ClinicIcons.prescription : ClinicIcons.medicalRecord,
                size: 36,
              ),
        title: Text(name),
        subtitle: Text([subtitle, if (description.isNotEmpty) description].join('\n')),
        isThreeLine: description.isNotEmpty,
        trailing: Wrap(children: [
          StatusChip(label: type, color: Colors.blueGrey),
          if (url.isNotEmpty) IconButton(onPressed: () => openMedia(url), icon: const Icon(Icons.open_in_new)),
        ]),
        onTap: url.isEmpty ? null : () => openMedia(url),
      ),
    );
  }
}

Future<void> showReviewDialog(BuildContext context, ClinicStore store, {required doctor, required patient, visit}) async {
  var rating = store.reviewForVisit(visit?.id ?? '')?.rating ?? 0;
  final comment = TextEditingController(text: store.reviewForVisit(visit?.id ?? '')?.comment ?? '');
  const labels = ['', 'سيء', 'مقبول', 'جيد', 'جيد جداً', 'ممتاز'];
  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: const Text('تقييم الزيارة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('كيف كانت تجربتك مع د. ${doctor.fullName}؟'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    onPressed: () => setLocal(() => rating = i),
                    icon: Icon(i <= rating ? Icons.star : Icons.star_border, color: Colors.amber),
                  ),
              ],
            ),
            if (rating > 0) Text(labels[rating], style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w700)),
            TextField(controller: comment, maxLines: 3, decoration: const InputDecoration(labelText: 'تعليق (اختياري)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              if (rating == 0) return;
              await store.submitReview(doctor: doctor, patient: patient, rating: rating, comment: comment.text, visit: visit);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    ),
  );
  comment.dispose();
}
