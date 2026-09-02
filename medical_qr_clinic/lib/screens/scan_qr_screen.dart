import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../state/clinic_store.dart';
import '../widgets/media.dart';
import '../widgets/mobile_kit.dart';
import '../widgets/ui.dart';

/// شاشة مسح QR للطبيب — كاميرا مباشرة مع بديل التقاط صورة لأجهزة Huawei.
class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final _manual = TextEditingController();
  MobileScannerController? _controller;
  bool _handling = false;
  bool _torch = false;
  bool _useLive = true;
  bool _liveFailed = false;
  String? _error;
  String? _lastCode;

  bool get _canLive {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    if (_canLive) {
      // بدون تحديد دقة مخصصة — أكثر توافقاً مع Huawei.
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        formats: const [BarcodeFormat.qrCode],
        autoStart: true,
      );
    } else {
      _useLive = false;
    }
  }

  @override
  void dispose() {
    _manual.dispose();
    // لا نستدعِ stop() يدوياً قبل dispose — يسبب Unsupported set of inputs/outputs على Huawei.
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onCode(ClinicStore store, String raw) async {
    final code = raw.trim();
    if (code.isEmpty || _handling) return;
    if (_lastCode == code) return;

    setState(() {
      _handling = true;
      _lastCode = code;
      _error = null;
      _manual.text = code;
    });

    try {
      final found = store.searchPatients(qr: code);
      if (!mounted) return;

      if (found.isEmpty) {
        setState(() {
          _error = 'لا يوجد مريض بهذا الرمز:\n$code';
          _handling = false;
        });
        // اسمح بإعادة مسح نفس الرمز بعد ثانيتين إذا لزم.
        await Future<void>.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _lastCode = null);
        return;
      }

      // افتح السجل فوراً — المزامنة مع الخادم تتم في الخلفية داخل الـ store.
      await store.openPatientAfterAccess(found.first, method: 'qr_scan');
      if (mounted) setState(() => _handling = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'تعذر فتح السجل. حاول مرة أخرى.';
          _handling = false;
          _lastCode = null;
        });
      }
    }
  }

  Future<void> _captureAndDecode(ClinicStore store) async {
    if (_handling) return;
    setState(() {
      _handling = true;
      _error = null;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 95,
        maxWidth: 2000,
      );
      if (file == null) {
        if (mounted) setState(() => _handling = false);
        return;
      }
      final code = await decodeQrFromPath(file.path);
      if (!mounted) return;
      if (code == null || code.isEmpty) {
        setState(() {
          _error = 'لم يُقرأ الرمز من الصورة. قرّب الكاميرا وأعد الالتقاط.';
          _handling = false;
        });
        return;
      }
      _handling = false;
      await _onCode(store, code);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'تعذر استخدام الكاميرا للالتقاط.';
          _handling = false;
        });
      }
    }
  }

  Future<void> _fromGallery(ClinicStore store) async {
    if (_handling) return;
    setState(() {
      _handling = true;
      _error = null;
    });
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 95, maxWidth: 2000);
      if (file == null) {
        if (mounted) setState(() => _handling = false);
        return;
      }
      final code = await decodeQrFromPath(file.path);
      if (!mounted) return;
      if (code == null || code.isEmpty) {
        setState(() {
          _error = 'تعذر قراءة QR من الصورة.';
          _handling = false;
        });
        return;
      }
      _handling = false;
      await _onCode(store, code);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'تعذر فتح الصورة.';
          _handling = false;
        });
      }
    }
  }

  void _switchToCaptureMode() {
    final old = _controller;
    setState(() {
      _useLive = false;
      _liveFailed = true;
      _controller = null;
      _error = 'المسح المباشر غير متوافق مع هذا الجهاز. استخدم التقاط صورة للرمز.';
    });
    // تأخير بسيط بعد إزالة الويدجت من الشجرة ثم التخلص من المتحكّم.
    Future<void>.delayed(const Duration(milliseconds: 50), () {
      try {
        old?.dispose();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final bottom = isMobileLayout(context) ? 96.0 : 16.0;

    if (store.doctorLocked) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: SoftCard(
            color: Color(0xFFFFF3E0),
            child: Text('فعّل الاشتراك أولاً لفتح سجلات المرضى', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // طبقة الكاميرا / البديل
        if (_canLive && _useLive && _controller != null)
          ColoredBox(
            color: Colors.black,
            child: MobileScanner(
              controller: _controller!,
              fit: BoxFit.cover,
              onDetect: (capture) {
                if (_handling) return;
                for (final b in capture.barcodes) {
                  final v = b.rawValue;
                  if (v != null && v.trim().isNotEmpty) {
                    _onCode(store, v);
                    return;
                  }
                }
              },
              errorBuilder: (context, error) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _useLive) _switchToCaptureMode();
                });
                return const ColoredBox(
                  color: Colors.black,
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                );
              },
            ),
          )
        else
          Container(
            color: ClinicColors.primaryDeep,
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ClinicIllustration(ClinicArt.patientSearch, height: 150),
                  const SizedBox(height: 14),
                  Text(
                    _liveFailed ? 'التقط صورة لرمز المريض' : 'مسح رمز المريض',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _liveFailed
                        ? 'اضغط الزر في الاسفل لفتح الكاميرا والتقاط الرمز'
                        : 'استخدم الكاميرا لقراءة الرمز',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

        // إطار التوجيه للمسح الحي
        if (_canLive && _useLive && _controller != null)
          IgnorePointer(child: CustomPaint(painter: _FramePainter())),

        // شريط علوي
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Row(
              children: [
                CircleIconBtn(
                  icon: Icons.arrow_forward,
                  color: Colors.black54,
                  iconColor: Colors.white,
                  onTap: () => store.goTo(ClinicPage.home),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'مسح رمز المريض',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, shadows: [Shadow(blurRadius: 8, color: Colors.black54)]),
                  ),
                ),
                if (_canLive && _useLive && _controller != null)
                  CircleIconBtn(
                    icon: _torch ? Icons.flash_on : Icons.flash_off,
                    color: Colors.black54,
                    iconColor: Colors.white,
                    onTap: () async {
                      await _controller?.toggleTorch();
                      if (mounted) setState(() => _torch = !_torch);
                    },
                  ),
              ],
            ),
          ),
        ),

        // لوحة سفلية
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, 14, 16, bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: softShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: ClinicColors.border, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 10),
                Text(
                  _useLive && _controller != null
                      ? 'وجّه الرمز داخل الإطار — يُقرأ تلقائياً'
                      : 'التقط صورة واضحة لرمز QR الخاص بالمريض',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ClinicColors.ink),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w700, fontSize: 12)),
                ],
                const SizedBox(height: 12),
                if (!_useLive || _controller == null) ...[
                  OrangeButton(
                    label: _handling ? 'جاري القراءة...' : 'فتح الكاميرا والتقاط الرمز',
                    icon: Icons.photo_camera,
                    loading: _handling,
                    onTap: _handling ? null : () => _captureAndDecode(store),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: GhostButton(
                        label: 'من المعرض',
                        onTap: () => _fromGallery(store),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_canLive && _useLive && _controller != null)
                      Expanded(
                        child: GhostButton(
                          label: 'التقاط بدلاً',
                          onTap: () => _captureAndDecode(store),
                        ),
                      )
                    else if (_canLive && !_useLive)
                      Expanded(
                        child: GhostButton(
                          label: 'مسح مباشر',
                          onTap: () {
                            setState(() {
                              _liveFailed = false;
                              _useLive = true;
                              _error = null;
                              _controller = MobileScannerController(
                                detectionSpeed: DetectionSpeed.noDuplicates,
                                facing: CameraFacing.back,
                                formats: const [BarcodeFormat.qrCode],
                                autoStart: true,
                              );
                            });
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _manual,
                  decoration: const InputDecoration(
                    labelText: 'أو أدخل الرمز يدوياً',
                    hintText: 'IQ-P-24081',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _handling ? null : () => _onCode(store, _manual.text),
                    child: const Text('فتح السجل'),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_handling && _useLive && _controller != null)
          const ColoredBox(
            color: Colors.black45,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 12),
                  Text('جاري فتح السجل...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final holeSize = size.shortestSide * 0.62;
    final hole = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.38), width: holeSize, height: holeSize),
      const Radius.circular(18),
    );
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(hole)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.45));
    canvas.drawRRect(
      hole,
      Paint()
        ..color = ClinicColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
