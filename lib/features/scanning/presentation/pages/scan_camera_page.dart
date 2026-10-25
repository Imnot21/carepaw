import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:carepaw/core/di/dependency_injection.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/features/inventory/domain/services/stock_intake_service.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_event.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:carepaw/features/scanning/domain/services/scan_reader.dart';
import 'package:carepaw/features/scanning/domain/services/scan_text_parser.dart';
import 'package:carepaw/features/scanning/presentation/bloc/scan_bloc.dart';
import 'package:carepaw/features/scanning/presentation/bloc/scan_event.dart';
import 'package:carepaw/features/scanning/presentation/bloc/scan_state.dart';
import 'package:carepaw/features/scanning/presentation/utils/scan_type_colors.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/features/scanning/domain/entities/scan_record.dart';
import 'package:carepaw/core/widgets/neomorphism/index.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';

/// Take or pick a photo of a medicine box or supplier receipt, let the AI
/// read it, then review and edit every value before adding it to stock.
///
/// Needs a [ScanBloc] and an [InventoryBloc] above it. Pops with `true`
/// once the medicines are in the inventory.
class ScanCameraPage extends StatefulWidget {
  /// [ScanType.medicineBox] or [ScanType.receipt].
  final ScanType type;
  final ScanReader? reader;

  const ScanCameraPage({super.key, required this.type, this.reader});

  @override
  State<ScanCameraPage> createState() => _ScanCameraPageState();
}

/// One editable row on the review screen.
class _LineDraft {
  final name = TextEditingController();
  final quantity = TextEditingController();
  final unit = TextEditingController();
  final lot = TextEditingController();
  final expiry = TextEditingController();
  String? nameError;
  String? quantityError;
  String? expiryError;

  _LineDraft({ScannedLine? from, required String defaultUnit}) {
    name.text = from?.name ?? '';
    final q = from?.quantity;
    quantity.text = q == null
        ? '1'
        : q == q.roundToDouble()
        ? q.toInt().toString()
        : q.toString();
    unit.text = from?.unit ?? defaultUnit;
    lot.text = from?.lot ?? '';
    expiry.text = from?.expiry ?? '';
  }

  void dispose() {
    for (final c in [name, quantity, unit, lot, expiry]) {
      c.dispose();
    }
  }
}

class _ScanCameraPageState extends State<ScanCameraPage>
    with SingleTickerProviderStateMixin {
  late final ScanReader _reader = widget.reader ?? getIt<ScanReader>();
  final _picker = ImagePicker();
  final _supplier = TextEditingController();
  final _lines = <_LineDraft>[];
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isReading = false;
  bool _isSaving = false;
  String? _imagePath;
  String _rawText = '';

  /// Set once the scan record is saved, so a retry after a failed stock
  /// write does not save the scan twice.
  int? _savedScanId;
  List<StockLine> _pendingLines = const [];

  ScanType get _type => widget.type;
  bool get _isReceipt => _type == ScanType.receipt;
  String get _defaultUnit => _isReceipt ? 'pcs' : 'box';

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
    _supplier.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Color get _typeColor => scanTypeColor(context, _type);
  String get _typeSvg => _isReceipt ? SvgIcons.receipt : SvgIcons.medication;

  /// Medicines already in stock, used to show what each row adds to.
  List<InventoryItem> get _stocked {
    final state = context.read<InventoryBloc>().state;
    return state is InventoryItemsLoaded ? state.items : const [];
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ScanBloc, ScanState>(listener: _onScanState),
        BlocListener<InventoryBloc, InventoryState>(
          listener: _onInventoryState,
        ),
      ],
      child: Scaffold(
        backgroundColor: ThemeColors.background(context),
        body: SafeArea(
          child: _imagePath == null ? _buildScannerView() : _buildReview(),
        ),
      ),
    );
  }

  // ── Before the photo ───────────────────────────────────────

  Widget _buildScannerView() {
    return Column(
      children: [
        _buildHeader(
          title: 'Scan ${_isReceipt ? 'Supplier Receipt' : 'Medicine Box'}',
          subtitle: _isReceipt
              ? 'The AI lists every medicine on the receipt'
              : 'The AI reads the name, lot and expiry',
          onClose: () => Navigator.pop(context),
        ),
        Expanded(child: _buildGuide()),
        _buildBottomControls(),
      ],
    );
  }

  Widget _buildHeader({
    required String title,
    required String subtitle,
    required VoidCallback? onClose,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        children: [
          NeuIconButton(
            plain: true,
            icon: Icons.close_rounded,
            svgAsset: SvgIcons.close,
            onPressed: onClose,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: ThemeColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
            color: _typeColor.withValues(alpha: 0.12),
            child: NeuSvgIcon(_typeSvg, size: 28),
          ),
        ],
      ),
    );
  }

  /// Framing tips shown before a photo is taken.
  Widget _buildGuide() {
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
                width: _isReceipt ? 150 : 240,
                height: _isReceipt ? 220 : 150,
                child: CustomPaint(
                  painter: _FrameGuidePainter(_typeColor),
                  child: Center(child: NeuSvgIcon(_typeSvg, size: 48)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isReceipt
                  ? 'Lay the receipt flat and fit the whole page'
                  : 'Fill the frame, use good light, avoid glare',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: ThemeColors.textPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'The photo is sent to Gemini to read it. You can fix '
              'anything it gets wrong before it is added to the inventory.',
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

  // ── Review ─────────────────────────────────────────────────

  Widget _buildReview() {
    final busy = _isReading || _isSaving;
    return Column(
      children: [
        _buildHeader(
          title: 'Review Scan',
          subtitle: 'Check every value and fix what the AI misread',
          onClose: busy ? null : _retake,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            children: [
              NeuCard(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: NeuShape.card,
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: Image.file(
                      File(_imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Center(child: NeuSvgIcon(_typeSvg, size: 64)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_isReading) _buildReading() else ..._buildForm(),
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
                  onPressed: busy ? null : _retake,
                  expanded: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: NeuButton(
                  text: _isSaving ? 'Adding…' : 'Add to Inventory',
                  variant: NeuButtonVariant.primary,
                  icon: Icons.inventory_2_rounded,
                  svgAsset: SvgIcons.inventory,
                  isDisabled: busy || _lines.isEmpty,
                  onPressed: _submit,
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
                      _typeColor.withValues(
                        alpha: 0.3 - _animationController.value * 0.2,
                      ),
                    ),
                  ),
                ),
                NeuContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: NeuTokens.radiusPill,
                  color: _typeColor,
                  child: NeuSvgIcon(SvgIcons.scan, size: 36),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isReceipt ? 'Reading the receipt…' : 'Reading the label…',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: ThemeColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildForm() {
    return [
      if (_rawText.isEmpty && _lines.every((l) => l.name.text.isEmpty))
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Nothing could be read from this photo. Type the details in, '
            'or retake it closer and in better light.',
            style: AppTextStyles.bodySmall.copyWith(
              color: ThemeColors.warning(context),
            ),
          ),
        ),
      if (_isReceipt) ...[
        NeuTextField(
          label: 'Supplier',
          hint: 'Who sold the medicines',
          controller: _supplier,
          enabled: !_isSaving,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 20),
      ],
      for (var i = 0; i < _lines.length; i++) _buildLine(i),
      NeuButton(
        text: 'Add another medicine',
        variant: NeuButtonVariant.outline,
        icon: Icons.add_rounded,
        svgAsset: SvgIcons.add,
        size: NeuButtonSize.medium,
        onPressed: _isSaving
            ? null
            : () => setState(
                () => _lines.add(_LineDraft(defaultUnit: _defaultUnit)),
              ),
        expanded: true,
      ),
    ];
  }

  Widget _buildLine(int index) {
    final line = _lines[index];
    final match = StockIntakeService.match(_stocked, line.name.text);
    // Stock is counted in the item's own unit, so 20 "box" would be added
    // as 20 "tablets". Flag it so the owner converts the quantity first.
    final unit = line.unit.text.trim();
    final unitDiffers =
        match != null &&
        unit.isNotEmpty &&
        unit.toLowerCase() != match.unit.trim().toLowerCase();
    final hint = line.name.text.trim().isEmpty
        ? null
        : match == null
        ? 'New medicine'
        : unitDiffers
        ? 'Adds to ${match.name}, counted in ${match.unit}. '
              'Enter the quantity in ${match.unit}.'
        : 'Adds to ${match.name} (${_amount(match.currentStock)} '
              '${match.unit} in stock)';

    return NeuCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Medicine ${index + 1}',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ThemeColors.textPrimary(context),
                  ),
                ),
              ),
              NeuIconButton(
                plain: true,
                icon: Icons.delete_outline_rounded,
                svgAsset: SvgIcons.delete,
                onPressed: _isSaving
                    ? null
                    : () => setState(() => _lines.removeAt(index).dispose()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          NeuTextField(
            label: 'Name',
            hint: 'e.g. Amoxicillin 250mg',
            controller: line.name,
            error: line.nameError,
            enabled: !_isSaving,
            onChanged: (_) => setState(() => line.nameError = null),
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                hint,
                style: AppTextStyles.labelSmall.copyWith(
                  color: match == null
                      ? ThemeColors.textTertiary(context)
                      : unitDiffers
                      ? ThemeColors.warning(context)
                      : ThemeColors.success(context),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: NeuTextField(
                  label: 'Quantity',
                  controller: line.quantity,
                  error: line.quantityError,
                  enabled: !_isSaving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() => line.quantityError = null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeuTextField(
                  label: 'Unit',
                  hint: _defaultUnit,
                  controller: line.unit,
                  enabled: !_isSaving,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: NeuTextField(
                  label: 'Lot',
                  hint: 'Optional',
                  controller: line.lot,
                  enabled: !_isSaving,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeuTextField(
                  label: 'Expiry',
                  hint: 'MM/YYYY',
                  controller: line.expiry,
                  error: line.expiryError,
                  enabled: !_isSaving,
                  onChanged: (_) => setState(() => line.expiryError = null),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────

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
      _clearForm();
    });

    ScanReading reading;
    try {
      reading = await _reader.read(path, _type);
    } catch (e) {
      debugPrint('[scan_camera] read failed: $e');
      reading = const ScanReading();
    }
    if (!mounted) return;
    setState(() {
      _rawText = reading.rawText;
      // Only a receipt shows the supplier field, so only a receipt keeps
      // what the AI read there.
      _supplier.text = _isReceipt ? reading.supplier ?? '' : '';
      _lines.addAll(
        reading.lines.map(
          (l) => _LineDraft(from: l, defaultUnit: _defaultUnit),
        ),
      );
      if (_lines.isEmpty) _lines.add(_LineDraft(defaultUnit: _defaultUnit));
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

  void _clearForm() {
    _rawText = '';
    _supplier.clear();
    _savedScanId = null;
    for (final line in _lines) {
      line.dispose();
    }
    _lines.clear();
  }

  void _retake() => setState(() {
    _imagePath = null;
    _clearForm();
  });

  /// Checks every row and returns the lines to add, or null when a row
  /// needs fixing (its errors are shown under the fields).
  List<StockLine>? _validate() {
    var ok = true;
    final out = <StockLine>[];
    for (final line in _lines) {
      final name = line.name.text.trim();
      final quantity = double.tryParse(line.quantity.text.trim());
      final expiryText = line.expiry.text.trim();
      final expiry = expiryText.isEmpty
          ? null
          : ScanTextParser.parseDate(expiryText);

      line.nameError = name.isEmpty ? 'Enter the medicine name' : null;
      line.quantityError = quantity == null || quantity <= 0
          ? 'Enter a number above 0'
          : null;
      line.expiryError = expiryText.isNotEmpty && expiry == null
          ? 'Use MM/YYYY or YYYY-MM-DD'
          : null;
      if (line.nameError != null ||
          line.quantityError != null ||
          line.expiryError != null) {
        ok = false;
        continue;
      }
      out.add(
        StockLine(
          name: name,
          quantity: quantity!,
          unit: line.unit.text.trim(),
          lot: line.lot.text.trim(),
          expiresAt: expiry,
        ),
      );
    }
    setState(() {});
    return ok ? out : null;
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final lines = _validate();
    if (lines == null) {
      NeuToast.error(context, 'Fix the highlighted fields first');
      return;
    }
    final auth = context.read<AuthBloc>().state;
    final userId = auth is AuthAuthenticated ? auth.user.id : null;
    if (userId == null) {
      NeuToast.error(context, 'Sign in again to add stock');
      return;
    }

    setState(() {
      _isSaving = true;
      _pendingLines = lines;
    });
    if (_savedScanId != null) {
      _receive(userId);
      return;
    }
    context.read<ScanBloc>().add(
      SaveReviewedScan(
        scanType: _type,
        imagePath: _imagePath!,
        rawOcrText: _rawText.isEmpty ? null : _rawText,
        extractedData: _summary(lines),
        confirmedBy: userId,
      ),
    );
  }

  void _receive(int userId) {
    final supplier = _supplier.text.trim();
    context.read<InventoryBloc>().add(
      ReceiveStock(
        lines: _pendingLines,
        performedBy: userId,
        supplier: supplier.isEmpty ? null : supplier,
        scanRecordId: _savedScanId,
      ),
    );
  }

  void _onScanState(BuildContext context, ScanState state) {
    if (!_isSaving) return;
    if (state is ScanRecordSaved) {
      _savedScanId = state.record.id;
      final auth = context.read<AuthBloc>().state;
      if (auth is AuthAuthenticated && auth.user.id != null) {
        _receive(auth.user.id!);
      }
    } else if (state is ScanError) {
      setState(() => _isSaving = false);
      NeuToast.error(context, state.failure.message);
    }
  }

  void _onInventoryState(BuildContext context, InventoryState state) {
    if (!_isSaving) return;
    if (state is InventoryOperationSuccess) {
      NeuToast.success(context, state.message);
      Navigator.pop(context, true);
    } else if (state is InventoryError) {
      setState(() => _isSaving = false);
      NeuToast.error(context, state.failure.message);
    }
  }

  /// What was added, kept on the scan record in a readable form.
  String _summary(List<StockLine> lines) {
    final supplier = _supplier.text.trim();
    return [
      if (supplier.isNotEmpty) 'Supplier: $supplier',
      for (final l in lines)
        '${l.name}: ${_amount(l.quantity)} '
            '${l.unit.isEmpty ? _defaultUnit : l.unit}'
            '${l.lot == null || l.lot!.isEmpty ? '' : ', lot ${l.lot}'}'
            '${l.expiresAt == null ? '' : ', exp ${_date(l.expiresAt!)}'}',
    ].join('\n');
  }

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _amount(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
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

/// Draws the pulsing ring around the reading indicator.
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
