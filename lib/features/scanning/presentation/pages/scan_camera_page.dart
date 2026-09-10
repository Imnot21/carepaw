import 'package:flutter/material.dart';
import 'package:carepaw/features/scanning/domain/entities/scan_record.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';

/// Scan camera page with premium design
class ScanCameraPage extends StatefulWidget {
  const ScanCameraPage({super.key});

  @override
  State<ScanCameraPage> createState() => _ScanCameraPageState();
}

class _ScanCameraPageState extends State<ScanCameraPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  ScanType _selectedType = ScanType.medicineBox;
  bool _isScanning = false;
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getTypeColor(ScanType type) {
    switch (type) {
      case ScanType.receipt:
        return const Color(0xFF10B981);
      case ScanType.medicineBox:
        return AppColors.categoryMedicine;
      case ScanType.prescription:
        return AppColors.categorySupply;
      case ScanType.labReport:
        return AppColors.categoryVaccine;
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getTypeIcon(ScanType type) {
    switch (type) {
      case ScanType.receipt:
        return Icons.receipt_long_rounded;
      case ScanType.medicineBox:
        return Icons.medication_rounded;
      case ScanType.prescription:
        return Icons.description_rounded;
      case ScanType.labReport:
        return Icons.science_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _getTypeDescription(ScanType type) {
    switch (type) {
      case ScanType.receipt:
        return 'Scan pharmacy receipts to track purchases and expenses';
      case ScanType.medicineBox:
        return 'Scan medicine boxes to auto-fill inventory details';
      case ScanType.prescription:
        return 'Scan prescriptions to create medication records';
      case ScanType.labReport:
        return 'Scan lab reports to add to medical records';
      default:
        return 'Scan any document';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: _capturedImagePath == null
            ? _buildScannerView()
            : _buildPreviewView(),
      ),
    );
  }

  Widget _buildScannerView() {
    return Column(
      children: [
        // Header
        _buildHeader(),

        // Type Selector
        _buildTypeSelector(),

        // Camera View
        Expanded(
          child: _buildCameraView(),
        ),

        // Bottom Controls
        _buildBottomControls(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          NeuCard(
            padding: const EdgeInsets.all(10),
            borderRadius: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.close_rounded, color: ThemeColors.textPrimary(context)),
            ),
          ),
          const SizedBox(width: 12),
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
                Text(
                  _getTypeDescription(_selectedType),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: ThemeColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          NeuContainer(
            padding: const EdgeInsets.all(12),
            borderRadius: 14,
            color: _getTypeColor(_selectedType).withValues(alpha: 0.12),
            child: Icon(
              _getTypeIcon(_selectedType),
              size: 28,
              color: _getTypeColor(_selectedType),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: NeuCard(
        padding: const EdgeInsets.all(4),
        borderRadius: 16,
        child: Row(
          children: ScanType.values.map((type) {
            final isSelected = _selectedType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedType = type),
                child: NeuContainer(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  borderRadius: 12,
                  variant: isSelected ? NeuVariant.pressed : NeuVariant.transparent,
                  color: isSelected ? _getTypeColor(_selectedType).withValues(alpha: 0.18) : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTypeIcon(type),
                        size: 20,
                        color: isSelected
                            ? _getTypeColor(type)
                            : ThemeColors.textSecondary(context),
                      ),
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

  Widget _buildCameraView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Camera placeholder
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getTypeColor(_selectedType).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _isScanning
                  ? _buildScanningOverlay()
                  : _buildCameraPlaceholder(),
            ),
          ),

          // Scan frame guide
          if (!_isScanning)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 280,
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _getTypeColor(_selectedType),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // Corner indicators
                      ..._buildCorners(_getTypeColor(_selectedType)),

                      // Center text
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_rounded,
                              size: 48,
                              color: _getTypeColor(_selectedType)
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Position ${_selectedType.displayName} in frame',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: _getTypeColor(_selectedType)
                                    .withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners(Color color) {
    const double size = 30;
    const double thickness = 4;
    return [
      // Top-left
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
            ),
          ),
        ),
      ),
      // Top-right
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
            ),
          ),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
            ),
          ),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(16),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildCameraPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NeuContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: 90,
            color: _getTypeColor(_selectedType),
            child: Icon(
              Icons.camera_alt_rounded,
              size: 48,
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Camera Preview',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: ThemeColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Camera integration would go here',
            style: AppTextStyles.bodySmall.copyWith(
              color: ThemeColors.textTertiary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Simulated camera feed
        Container(
          decoration: BoxDecoration(
            color: _getTypeColor(_selectedType).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
          ),
        ),

        // Scanning animation
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing ring
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) => Container(
                      width: 120 + _animationController.value * 40,
                      height: 120 + _animationController.value * 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getTypeColor(_selectedType)
                              .withValues(alpha: 0.3 - _animationController.value * 0.2),
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                  NeuContainer(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 60,
                    color: _getTypeColor(_selectedType),
                    child: Icon(
                      Icons.psychology_rounded,
                      size: 48,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Processing OCR...',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Extracting text from ${_selectedType.displayName.toLowerCase()}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: ThemeColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(_getTypeColor(_selectedType)),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Row(
        children: [
          // Gallery button
          Expanded(
            child: NeuButton(
              text: 'Gallery',
              variant: NeuButtonVariant.secondary,
              icon: Icons.photo_library_rounded,
              onPressed: _pickFromGallery,
              expanded: true,
            ),
          ),
          const SizedBox(width: 16),

          // Capture button
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) => Transform.scale(
              scale: _isScanning ? 1.0 : _pulseAnimation.value,
              child: FloatingActionButton(
                onPressed: _isScanning ? null : _capturePhoto,
                backgroundColor: _getTypeColor(_selectedType),
                foregroundColor: AppColors.textOnPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _isScanning
                    ? SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation(AppColors.textOnPrimary),
                        ),
                      )
                    : Icon(Icons.camera_alt_rounded, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Flash button
          Expanded(
            child: NeuButton(
              text: 'Flash',
              variant: NeuButtonVariant.secondary,
              icon: Icons.flash_on_rounded,
              onPressed: _toggleFlash,
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
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              NeuCard(
                padding: const EdgeInsets.all(10),
                borderRadius: 12,
                child: GestureDetector(
                  onTap: () => setState(() => _capturedImagePath = null),
                  child: Icon(Icons.close_rounded, color: ThemeColors.textPrimary(context)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview Scan',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: ThemeColors.textPrimary(context),
                      ),
                    ),
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

        // Image Preview
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: NeuCard(
              padding: EdgeInsets.zero,
              borderRadius: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _capturedImagePath != null
                    ? Image.asset(
                        _capturedImagePath!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, _, _) => _buildPreviewPlaceholder(),
                      )
                    : _buildPreviewPlaceholder(),
              ),
            ),
          ),
        ),

        // Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Row(
            children: [
              Expanded(
                child: NeuButton(
                  text: 'Retake',
                  variant: NeuButtonVariant.secondary,
                  icon: Icons.refresh_rounded,
                  onPressed: () => setState(() => _capturedImagePath = null),
                  expanded: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: NeuButton(
                  text: 'Use Scan',
                  variant: NeuButtonVariant.primary,
                  icon: Icons.check_rounded,
                  onPressed: _useScan,
                  expanded: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewPlaceholder() {
    return Container(
      width: double.infinity,
      color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getTypeIcon(_selectedType),
              size: 64,
              color: ThemeColors.textTertiary(context),
            ),
            const SizedBox(height: 12),
            Text(
              'Captured Image Preview',
              style: AppTextStyles.bodyMedium.copyWith(
                color: ThemeColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _capturePhoto() async {
    setState(() => _isScanning = true);

    // Simulate capture
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock captured image path
    setState(() {
      _capturedImagePath = 'assets/images/scan_${_selectedType.name}.jpg';
      _isScanning = false;
    });
  }

  void _pickFromGallery() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Gallery picker would open here'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _toggleFlash() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Flash toggled'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _useScan() {
    // Create scan record and navigate to detail
    Navigator.pop(context, {
      'scanType': _selectedType,
      'imagePath': _capturedImagePath,
    });
  }
}
