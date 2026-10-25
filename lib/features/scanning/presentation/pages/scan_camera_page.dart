import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:carepaw/core/di/dependency_injection.dart';
import 'package:carepaw/features/scanning/domain/services/ocr_service.dart';
import 'package:carepaw/features/scanning/domain/services/scan_text_parser.dart';
import 'package:carepaw/features/scanning/presentation/utils/scan_type_colors.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/features/scanning/domain/entities/scan_record.dart';
import 'package:carepaw/core/widgets/neomorphism/index.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';

/// What the camera page hands back when the user saves a scan. Every value
/// is an OCR suggestion; the scan is stored as pending until confirmed.
class ScanCapture {
  final ScanType scanType;
  final String imagePath;
  final String rawText;
  final ScanFields fields;

  const ScanCapture({
    required this.scanType,
    required this.imagePath,
    required this.rawText,
    required this.fields,
  });
}

/// Take or pick a photo, read its text on the device, and review the
/// suggested fields before saving the scan for confirmation.
class ScanCameraPage extends StatefulWidget {
  final OcrService? ocrService;

  const ScanCameraPage({super.key, this.ocrService});

  @override
  State<ScanCameraPage> createState() => _ScanCameraPageState();
}

class _ScanCameraPageState extends State<ScanCameraPage>
    with SingleTickerProviderStateMixin {
  late final OcrService _ocr = widget.ocrService ?? getIt<OcrService>();
  final _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  ScanType _selectedType = ScanType.medicineBox;
  bool _isReading = false;
  String? _imagePath;
  String _rawText = '';
  ScanFields _fields = const ScanFields({}, 0);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getTypeColor(ScanType type) => scanTypeColor(context, type);

  String _getTypeSvg(ScanType type) {
    switch (type) {
      case ScanType.receipt:
        return SvgIcons.receipt;
      case ScanType.medicineBox:
        return SvgIcons.medication;
      case ScanType.prescription:
        return SvgIcons.note;
      case ScanType.labReport:
        return SvgIcons.lab;
      default:
        return SvgIcons.note;
    }
  }

  String _getTypeDescription(ScanType type) {
    switch (type) {
      case ScanType.receipt:
        return 'Read the store, date and total from a receipt';
      case ScanType.medicineBox:
        return 'Read the name, expiry and lot from a medicine box';
      case ScanType.prescription:
        return 'Read the title and date from a prescription';
      case ScanType.labReport:
        return 'Read the title and date from a lab report';
      default:
        return 'Read the text from any document';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      body: SafeArea(
        child: _imagePath == null ? _buildScannerView() : _buildPreviewView(),
      ),
    );
  }

  Widget _buildScannerView() {
    return Column(
      children: [
        _buildHeader(),
        _buildTypeSelector(),
        Expanded(child: _buildGuide()),
        _buildBottomControls(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        children: [
          NeuIconButton(
            plain: true,
            icon: Icons.close_rounded,
            svgAsset: SvgIcons.close,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan ${_selectedType.displayName}',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: ThemeColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getTypeDescription(_selectedType),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: ThemeColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          NeuContainer(
            padding: const EdgeInsets.all(12),
            borderRadius: NeuTokens.radiusSm,
            color: _getTypeColor(_selectedType).withValues(alpha: 0.12),
            child: NeuSvgIcon(_getTypeSvg(_selectedType), size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: NeuCard(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: ScanType.values.map((type) {
            final isSelected = _selectedType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedType = type),
                child: NeuContainer(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  borderRadius: NeuTokens.radiusSm,
                  variant: isSelected
                      ? NeuVariant.pressed
                      : NeuVariant.transparent,
                  color: isSelected
                      ? _getTypeColor(_selectedType).withValues(alpha: 0.18)
                      : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NeuSvgIcon(_getTypeSvg(type), size: 20),
                      const SizedBox(height: 4),
                      Text(
                        type.displayName,
                        style: AppTextStyles.labelSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? _getTypeColor(type)
                              : ThemeColors.textSecondary(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Framing tips shown before a photo is taken.
  Widget _buildGuide() {
    final color = _getTypeColor(_selectedType);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: NeuContainer(
        variant: NeuVariant.inset,
        borderRadius: NeuTokens.radiusMd,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) =>
                  Transform.scale(scale: _pulseAnimation.value, child: child),
              child: SizedBox(
                width: 240,
                height: 150,
                child: CustomPaint(
                  painter: _FrameGuidePainter(color),
                  child: Center(
                    child: NeuSvgIcon(_getTypeSvg(_selectedType), size: 48),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Fill the frame, use good light, avoid glare',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: ThemeColors.textPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'The photo is sent to Gemini to read the text. You check '
              'every value before the scan is trusted.',
              style: AppTextStyles.bodySmall.copyWith(
                color: ThemeColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: NeuButton(
              text: 'Gallery',
              variant: NeuButtonVariant.secondary,
              icon: Icons.photo_library_rounded,
              svgAsset: SvgIcons.image,
              onPressed: () => _pick(ImageSource.gallery),
              expanded: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: NeuButton(
              text: 'Take Photo',
              variant: NeuButtonVariant.primary,
              icon: Icons.camera_alt_rounded,
              svgAsset: SvgIcons.camera,
              onPressed: () => _pick(ImageSource.camera),
              expanded: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(
            children: [
              NeuIconButton(
                plain: true,
                icon: Icons.close_rounded,
                svgAsset: SvgIcons.close,
                onPressed: _isReading ? null : _retake,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review Scan',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: ThemeColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedType.displayName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: ThemeColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            children: [
              NeuCard(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: NeuShape.card,
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: Image.file(
                      File(_imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: NeuSvgIcon(
                          _getTypeSvg(_selectedType),
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _isReading ? _buildReading() : _buildFields(),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: NeuButton(
                  text: 'Retake',
                  variant: NeuButtonVariant.secondary,
                  icon: Icons.refresh_rounded,
                  svgAsset: SvgIcons.refresh,
                  onPressed: _isReading ? null : _retake,
                  expanded: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: NeuButton(
                  text: 'Save for Review',
                  variant: NeuButtonVariant.primary,
                  icon: Icons.check_rounded,
                  svgAsset: SvgIcons.check,
                  isDisabled: _isReading || _rawText.isEmpty,
                  onPressed: _save,
                  expanded: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReading() {
    final color = _getTypeColor(_selectedType);
    return NeuCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, _) => Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 96 + _animationController.value * 24,
                  height: 96 + _animationController.value * 24,
                  child: CustomPaint(
                    painter: _RingPainter(
                      color.withValues(
                        alpha: 0.3 - _animationController.value * 0.2,
                      ),
                    ),
                  ),
                ),
                NeuContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: NeuTokens.radiusPill,
                  color: color,
                  child: NeuSvgIcon(SvgIcons.scan, size: 36),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Reading text…',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: ThemeColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFields() {
    if (_rawText.isEmpty) {
      return NeuCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            NeuSvgIcon(SvgIcons.alert, size: 32),
            const SizedBox(height: 12),
            Text(
              'No text found',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: ThemeColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Retake the photo closer and in better light.',
              style: AppTextStyles.bodySmall.copyWith(
                color: ThemeColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final found = _fields.values.length;
    return NeuCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeuSvgIcon(SvgIcons.textField, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Suggested values',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ThemeColors.textPrimary(context),
                  ),
                ),
              ),
              NeuStatusBadge(
                label: '$found found',
                tone: _fields.confidence >= 0.8
                    ? NeuStatusTone.success
                    : NeuStatusTone.warning,
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final e in _fields.values.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      e.key,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: ThemeColors.textSecondary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e.value,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: ThemeColors.textPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (found == 0)
            Text(
              'Text was found but no fields matched. The full text is '
              'saved so the clinic can still read it.',
              style: AppTextStyles.bodySmall.copyWith(
                color: ThemeColors.textSecondary(context),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            'Suggestions only — confirm or reject the scan after saving.',
            style: AppTextStyles.labelSmall.copyWith(
              color: ThemeColors.textTertiary(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(ImageSource source) async {
    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('[scan_camera] pick failed: $e');
      if (mounted) {
        NeuToast.error(
          context,
          source == ImageSource.camera
              ? 'Could not open the camera'
              : 'Could not open the gallery',
        );
      }
      return;
    }
    if (picked == null || !mounted) return;

    final path = await _keep(picked);
    if (!mounted) return;
    setState(() {
      _imagePath = path;
      _isReading = true;
      _rawText = '';
      _fields = const ScanFields({}, 0);
    });

    String text;
    try {
      text = await _ocr.readText(path);
    } catch (e) {
      debugPrint('[scan_camera] OCR failed: $e');
      text = '';
    }
    if (!mounted) return;
    setState(() {
      _rawText = text;
      _fields = ScanTextParser.parse(text, _selectedType);
      _isReading = false;
    });
  }

  /// Copy the photo out of the picker's temp cache so the scan keeps it.
  Future<String> _keep(XFile picked) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final scans = Directory('${dir.path}/scans');
      await scans.create(recursive: true);
      final dest =
          '${scans.path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(picked.path).copy(dest);
      return dest;
    } catch (e) {
      debugPrint('[scan_camera] keep failed: $e');
      return picked.path;
    }
  }

  void _retake() {
    setState(() {
      _imagePath = null;
      _rawText = '';
      _fields = const ScanFields({}, 0);
    });
  }

  void _save() {
    Navigator.pop(
      context,
      ScanCapture(
        scanType: _selectedType,
        imagePath: _imagePath!,
        rawText: _rawText,
        fields: _fields,
      ),
    );
  }
}

/// Draws the viewfinder frame — a rounded border with accentuated corners.
class _FrameGuidePainter extends CustomPainter {
  final Color color;

  const _FrameGuidePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(NeuTokens.radiusSm),
      ),
      border,
    );

    final corners = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const s = 30.0;
    final paths = [
      Path()
        ..moveTo(0, s)
        ..lineTo(0, 0)
        ..lineTo(s, 0),
      Path()
        ..moveTo(size.width - s, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, s),
      Path()
        ..moveTo(0, size.height - s)
        ..lineTo(0, size.height)
        ..lineTo(s, size.height),
      Path()
        ..moveTo(size.width - s, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, size.height - s),
    ];
    for (final path in paths) {
      canvas.drawPath(path, corners);
    }
  }

  @override
  bool shouldRepaint(covariant _FrameGuidePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Draws the pulsing ring around the OCR indicator.
class _RingPainter extends CustomPainter {
  final Color color;

  const _RingPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(size.center(Offset.zero), size.width / 2, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.color != color;
}
