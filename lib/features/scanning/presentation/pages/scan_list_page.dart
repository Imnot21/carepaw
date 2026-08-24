import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/scanning/domain/entities/scan_record.dart';
import 'package:carepaw/features/scanning/presentation/bloc/scan_bloc.dart';
import 'package:carepaw/features/scanning/presentation/bloc/scan_event.dart';
import 'package:carepaw/features/scanning/presentation/bloc/scan_state.dart';
import 'package:carepaw/features/scanning/presentation/pages/scan_detail_page.dart';
import 'package:carepaw/features/scanning/presentation/pages/scan_camera_page.dart';
import 'package:carepaw/core/widgets/common/cp_button.dart';
import 'package:carepaw/core/widgets/common/cp_loader.dart';
import 'package:carepaw/core/widgets/common/cp_empty_state.dart';
import 'package:carepaw/core/widgets/effects/animated_gradient.dart';
import 'package:carepaw/core/widgets/effects/glass_container.dart';
import 'package:carepaw/core/widgets/effects/floating_animation.dart';
import 'package:carepaw/core/widgets/effects/pulsing_glow.dart';
import 'package:carepaw/core/widgets/effects/premium_shadows.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/di/dependency_injection.dart';
import 'package:carepaw/core/utils/formatters.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';

/// Scan list page with premium design
class ScanListPage extends StatefulWidget {
  const ScanListPage({super.key});

  @override
  State<ScanListPage> createState() => _ScanListPageState();
}

class _ScanListPageState extends State<ScanListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ScanType? _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    context.read<ScanBloc>().add(const LoadScanRecords());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const _NotLoggedInView();
        }

        // Check if user is vet, staff, or admin - only these roles can scan/process OCR
        final user = authState.user;
        final isVetOrStaff = user.role == UserRole.veterinarian ||
                            user.role == UserRole.staff ||
                            user.role == UserRole.admin;

        if (!isVetOrStaff) {
          return const _AccessDeniedView();
        }

        return Scaffold(
          body: AnimatedGradientBackground(
            colors: [
              AppColors.primary.withValues(alpha: 0.06),
              AppColors.secondary.withValues(alpha: 0.04),
              AppColors.surface,
            ],
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                _buildTabBar(),
                _buildTabContent(),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToCamera(),
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('New Scan'),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ).animate().fadeIn(delay: const Duration(milliseconds: 600)).slideY(begin: 0.3, end: 0),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Scan & OCR',
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Scan receipts, medicine boxes & more',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface.withValues(alpha: 0.9),
                AppColors.surface.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history_rounded),
          onPressed: () {
            // Show scan history
          },
          tooltip: 'History',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _ScanTabBarDelegate(
        tabController: _tabController,
        tabs: [
          const Tab(text: 'All'),
          const Tab(text: 'Receipts'),
          const Tab(text: 'Medicine'),
          const Tab(text: 'Pending'),
          const Tab(text: 'Confirmed'),
        ],
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTabContent() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildScanList(null),
          _buildScanList(ScanType.receipt),
          _buildScanList(ScanType.medicineBox),
          _buildPendingScans(),
          _buildScanListByStatus(ScanStatus.confirmed),
        ],
      ),
    );
  }

  Widget _buildScanList(ScanType? type) {
    return BlocBuilder<ScanBloc, ScanState>(
      builder: (context, state) {
        if (state is ScanLoading) {
          return const Center(child: CpLoader(size: 48));
        }

        if (state is ScanError) {
          return CpEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Error Loading Scans',
            message: state.failure.message,
            actionLabel: 'Retry',
            onAction: () {
              if (type == null) {
                context.read<ScanBloc>().add(const LoadScanRecords());
              } else {
                context.read<ScanBloc>().add(LoadScanRecordsByType(type));
              }
            },
          );
        }

        List<ScanRecord> records = [];
        if (state is ScanRecordsLoaded) {
          records = state.records;
        } else if (state is ScanRecordsByTypeLoaded) {
          records = state.records;
        }

        if (type != null) {
          records = records.where((r) => r.scanType == type).toList();
        }

        if (records.isEmpty) {
          return CpEmptyState(
            icon: _getTypeIcon(type ?? ScanType.other),
            title: type != null ? 'No ${type.displayName} Scans' : 'No Scans Yet',
            message: type != null
                ? 'Scan your first ${type.displayName.toLowerCase()}'
                : 'Start by scanning a document',
            actionLabel: 'Start Scanning',
            onAction: _navigateToCamera,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return _buildScanCard(record, index);
          },
        );
      },
    );
  }

  Widget _buildPendingScans() {
    return BlocBuilder<ScanBloc, ScanState>(
      builder: (context, state) {
        if (state is PendingScansLoaded) {
          final records = state.records;
          if (records.isEmpty) {
            return CpEmptyState(
              icon: Icons.pending_actions_rounded,
              title: 'No Pending Scans',
              message: 'All scans have been processed',
              actionLabel: 'New Scan',
              onAction: _navigateToCamera,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return _buildScanCard(record, index, highlightPending: true);
            },
          );
        }
        return const Center(child: CpLoader(size: 48));
      },
    );
  }

  Widget _buildScanListByStatus(ScanStatus status) {
    return BlocBuilder<ScanBloc, ScanState>(
      builder: (context, state) {
        if (state is ScanRecordsLoaded) {
          final records = state.records
              .where((r) => r.status == status)
              .toList();
          if (records.isEmpty) {
            return CpEmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'No Confirmed Scans',
              message: 'Confirmed scans will appear here',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return _buildScanCard(record, index);
            },
          );
        }
        return const Center(child: CpLoader(size: 48));
      },
    );
  }

  Widget _buildScanCard(ScanRecord record, int index, {bool highlightPending = false}) {
    final isPending = record.status == ScanStatus.pending;
    final isConfirmed = record.status == ScanStatus.confirmed;
    final isRejected = record.status == ScanStatus.rejected;
    final hasHighConfidence = record.hasHighConfidence;

    return FloatingAnimation(
      delay: Duration(milliseconds: 50 * (index % 10)),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        blur: 10,
        borderColor: isPending && highlightPending
            ? AppColors.warning.withValues(alpha: 0.3)
            : isConfirmed
                ? AppColors.success.withValues(alpha: 0.2)
                : isRejected
                    ? AppColors.error.withValues(alpha: 0.2)
                    : _getTypeColor(record.scanType).withValues(alpha: 0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToDetail(record),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: _getTypeGradient(record.scanType),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getTypeIcon(record.scanType),
                          size: 24,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                      if (isPending && highlightPending)
                        PulsingGlow(
                          glowColor: AppColors.warning,
                          maxRadius: 28,
                          duration: const Duration(seconds: 2),
                          child: Container(),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.scanType.displayName,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          formatDateTime(record.createdAt),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  _buildStatusBadge(record.status),
                  const SizedBox(width: 8),
                  // Confidence indicator
                  if (record.confidenceScore != null)
                    _buildConfidenceIndicator(record.confidenceScore!),
                ],
              ),
              const SizedBox(height: 12),

              // OCR preview
              if (record.rawOcrText != null && record.rawOcrText!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.text_fields_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          record.rawOcrText!.length > 80
                              ? '${record.rawOcrText!.substring(0, 80)}...'
                              : record.rawOcrText!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Action buttons for pending scans
              if (isPending) ...[
                Row(
                  children: [
                    Expanded(
                      child: CpButton(
                        text: 'Process OCR',
                        variant: ButtonVariant.primary,
                        icon: Icons.psychology_rounded,
                        size: ButtonSize.small,
                        onPressed: () =>
                            context.read<ScanBloc>().add(ProcessScanOcr(record.id!)),
                        expanded: true,
                        gradient: AppColors.gradientPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CpButton(
                        text: 'Review',
                        variant: ButtonVariant.secondary,
                        icon: Icons.visibility_rounded,
                        size: ButtonSize.small,
                        onPressed: () => _navigateToDetail(record),
                        expanded: true,
                      ),
                    ),
                  ],
                ),
              ] else if (isConfirmed) ...[
                Row(
                  children: [
                    Expanded(
                      child: CpButton(
                        text: 'View Details',
                        variant: ButtonVariant.secondary,
                        icon: Icons.visibility_rounded,
                        size: ButtonSize.small,
                        onPressed: () => _navigateToDetail(record),
                        expanded: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CpButton(
                        text: 'Use Data',
                        variant: ButtonVariant.primary,
                        icon: Icons.check_circle_rounded,
                        size: ButtonSize.small,
                        onPressed: () => _useScanData(record),
                        expanded: true,
                        gradient: AppColors.gradientSuccess,
                      ),
                    ),
                  ],
                ),
              ] else if (isRejected) ...[
                CpButton(
                  text: 'Retry Scan',
                  variant: ButtonVariant.outline,
                  icon: Icons.refresh_rounded,
                  size: ButtonSize.small,
                  onPressed: () => _navigateToCamera(),
                  expanded: true,
                  foregroundColor: AppColors.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ScanStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case ScanStatus.pending:
        color = AppColors.warning;
        text = 'Pending';
        icon = Icons.pending_rounded;
        break;
      case ScanStatus.confirmed:
        color = AppColors.success;
        text = 'Confirmed';
        icon = Icons.check_circle_rounded;
        break;
      case ScanStatus.rejected:
        color = AppColors.error;
        text = 'Rejected';
        icon = Icons.cancel_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(double confidence) {
    Color color;
    if (confidence >= 0.8) {
      color = AppColors.success;
    } else if (confidence >= 0.6) color = AppColors.warning;
    else color = AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '${(confidence * 100).toInt()}%',
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getTypeGradient(ScanType type) {
    switch (type) {
      case ScanType.receipt:
        return const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        );
      case ScanType.medicineBox:
        return AppColors.gradientPrimary;
      case ScanType.prescription:
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        );
      case ScanType.labReport:
        return const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
        );
    }
  }

  Color _getTypeColor(ScanType type) {
    switch (type) {
      case ScanType.receipt:
        return const Color(0xFF10B981);
      case ScanType.medicineBox:
        return AppColors.primary;
      case ScanType.prescription:
        return const Color(0xFF8B5CF6);
      case ScanType.labReport:
        return const Color(0xFF06B6D4);
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

  void _navigateToCamera() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScanCameraPage()),
    ).then((_) {
      context.read<ScanBloc>().add(const LoadScanRecords());
    });
  }

  void _navigateToDetail(ScanRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScanDetailPage(record: record),
      ),
    ).then((_) {
      context.read<ScanBloc>().add(const LoadScanRecords());
    });
  }

  void _useScanData(ScanRecord record) {
    // Navigate to appropriate feature based on scan type
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Using ${record.scanType.displayName} data...'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ScanTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<Tab> tabs;
  final Color color;

  _ScanTabBarDelegate({
    required this.tabController,
    required this.tabs,
    required this.color,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.surface.withValues(alpha: 0.95),
      child: TabBar(
        controller: tabController,
        tabs: tabs,
        indicatorColor: color,
        indicatorWeight: 3,
        labelColor: color,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.labelLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.labelLarge.copyWith(
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
        isScrollable: true,
      ),
    );
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

/// Not logged in view
class _NotLoggedInView extends StatelessWidget {
  const _NotLoggedInView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradientBackground(
        colors: [
          AppColors.primary.withValues(alpha: 0.06),
          AppColors.secondary.withValues(alpha: 0.04),
          AppColors.surface,
        ],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PulsingGlow(
                  glowColor: AppColors.primary,
                  maxRadius: 40,
                  duration: const Duration(seconds: 3),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(80),
                      boxShadow: PremiumShadows.primary,
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 80,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Please log in to use scanning',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sign in to scan receipts, medicine boxes & more',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CpButton(
                  text: 'Log In',
                  onPressed: () => context.go(Routes.login),
                  icon: Icons.login_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Access denied view for pet owners
class _AccessDeniedView extends StatelessWidget {
  const _AccessDeniedView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradientBackground(
        colors: [
          AppColors.error.withValues(alpha: 0.06),
          AppColors.warning.withValues(alpha: 0.04),
          AppColors.surface,
        ],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PulsingGlow(
                  glowColor: AppColors.error,
                  maxRadius: 40,
                  duration: const Duration(seconds: 3),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientError,
                      borderRadius: BorderRadius.circular(80),
                      boxShadow: PremiumShadows.glow(context, AppColors.error, intensity: 0.3),
                    ),
                    child: Icon(
                      Icons.block_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Access Denied',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Only veterinarians and clinic staff can use scanning and OCR features.\n\nThis feature is for clinic operations only.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CpButton(
                  text: 'Go Back',
                  onPressed: () => context.pop(),
                  icon: Icons.arrow_back_rounded,
                  variant: ButtonVariant.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}