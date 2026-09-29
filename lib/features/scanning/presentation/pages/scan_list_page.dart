import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/scanning/domain/entities/scan_record.dart';
import 'package:carepaw/features/scanning/presentation/bloc/scan_bloc.dart';
import 'package:carepaw/features/scanning/presentation/bloc/scan_event.dart';
import 'package:carepaw/features/scanning/presentation/bloc/scan_state.dart';
import 'package:carepaw/features/scanning/presentation/pages/scan_detail_page.dart';
import 'package:carepaw/features/scanning/presentation/pages/scan_camera_page.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_skeleton.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/utils/formatters.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';

/// Scan list page with neumorphic design
class ScanListPage extends StatefulWidget {
  const ScanListPage({super.key});

  @override
  State<ScanListPage> createState() => _ScanListPageState();
}

class _ScanListPageState extends State<ScanListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
          backgroundColor: ThemeColors.background(context),
          body: CustomScrollView(
            slivers: [
              _buildAppBar(),
              _buildTabBar(),
              _buildTabContent(),
            ],
          ),
          floatingActionButton: NeuButton(
            text: 'New Scan',
            icon: Icons.camera_alt_rounded,
            onPressed: _navigateToCamera,
          ),
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
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Scan & OCR',
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: ThemeColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Scan receipts, medicine boxes & more',
              style: AppTextStyles.bodySmall.copyWith(
                color: ThemeColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
      actions: [
        NeuIconButton(
          icon: Icons.history_rounded,
          tooltip: 'History',
          onPressed: () {
            // Show scan history
          },
        ),
        const SizedBox(width: 12),
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
        color: ThemeColors.primary(context),
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
          return const NeuSkeletonList();
        }

        if (state is ScanError) {
          return _NeuEmptyState(
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
          return _NeuEmptyState(
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
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 110),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return _buildScanCard(record);
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
            return _NeuEmptyState(
              icon: Icons.pending_actions_rounded,
              title: 'No Pending Scans',
              message: 'All scans have been processed',
              actionLabel: 'New Scan',
              onAction: _navigateToCamera,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 110),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return _buildScanCard(record, highlightPending: true);
            },
          );
        }
        return const NeuSkeletonList();
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
            return _NeuEmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'No Confirmed Scans',
              message: 'Confirmed scans will appear here',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 110),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return _buildScanCard(record);
            },
          );
        }
        return const NeuSkeletonList();
      },
    );
  }

  Widget _buildScanCard(ScanRecord record, {bool highlightPending = false}) {
    final isPending = record.status == ScanStatus.pending;
    final isConfirmed = record.status == ScanStatus.confirmed;
    final isRejected = record.status == ScanStatus.rejected;

    return NeuCard(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      borderColor: isPending && highlightPending
          ? ThemeColors.warning(context).withValues(alpha: 0.4)
          : isConfirmed
              ? ThemeColors.success(context).withValues(alpha: 0.3)
              : isRejected
                  ? ThemeColors.error(context).withValues(alpha: 0.3)
                  : _getTypeColor(record.scanType).withValues(alpha: 0.15),
      borderWidth: 1,
      onTap: () => _navigateToDetail(record),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              NeuContainer(
                padding: const EdgeInsets.all(12),
                borderRadius: 14,
                color: _getTypeColor(record.scanType),
                child: Icon(
                  _getTypeIcon(record.scanType),
                  size: 24,
                  color: AppColors.textOnPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.scanType.displayName,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ThemeColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatDateTime(record.createdAt),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: ThemeColors.textSecondary(context),
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
          const SizedBox(height: 14),

          // OCR preview
          if (record.rawOcrText != null && record.rawOcrText!.isNotEmpty) ...[
            NeuContainer(
              padding: const EdgeInsets.all(14),
              borderRadius: 12,
              variant: NeuVariant.inset,
              child: Row(
                children: [
                  Icon(
                    Icons.text_fields_rounded,
                    size: 18,
                    color: ThemeColors.textSecondary(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      record.rawOcrText!.length > 80
                          ? '${record.rawOcrText!.substring(0, 80)}...'
                          : record.rawOcrText!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: ThemeColors.textSecondary(context),
                        fontFamily: 'monospace',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Action buttons for pending scans
          if (isPending) ...[
            Row(
              children: [
                Expanded(
                  child: NeuButton(
                    text: 'Process OCR',
                    variant: NeuButtonVariant.primary,
                    icon: Icons.psychology_rounded,
                    size: NeuButtonSize.medium,
                    onPressed: () =>
                        context.read<ScanBloc>().add(ProcessScanOcr(record.id!)),
                    expanded: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: NeuButton(
                    text: 'Review',
                    variant: NeuButtonVariant.secondary,
                    icon: Icons.visibility_rounded,
                    size: NeuButtonSize.medium,
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
                  child: NeuButton(
                    text: 'View Details',
                    variant: NeuButtonVariant.secondary,
                    icon: Icons.visibility_rounded,
                    size: NeuButtonSize.medium,
                    onPressed: () => _navigateToDetail(record),
                    expanded: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: NeuButton(
                    text: 'Use Data',
                    variant: NeuButtonVariant.primary,
                    icon: Icons.check_circle_rounded,
                    size: NeuButtonSize.medium,
                    onPressed: () => _useScanData(record),
                    expanded: true,
                  ),
                ),
              ],
            ),
          ] else if (isRejected) ...[
            NeuButton(
              text: 'Retry Scan',
              variant: NeuButtonVariant.outline,
              icon: Icons.refresh_rounded,
              size: NeuButtonSize.medium,
              onPressed: () => _navigateToCamera(),
              expanded: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ScanStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case ScanStatus.pending:
        color = ThemeColors.warning(context);
        text = 'Pending';
        icon = Icons.pending_rounded;
        break;
      case ScanStatus.confirmed:
        color = ThemeColors.success(context);
        text = 'Confirmed';
        icon = Icons.check_circle_rounded;
        break;
      case ScanStatus.rejected:
        color = ThemeColors.error(context);
        text = 'Rejected';
        icon = Icons.cancel_rounded;
        break;
    }

    return NeuContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      borderRadius: 10,
      variant: NeuVariant.flat,
      borderColor: color.withValues(alpha: 0.3),
      borderWidth: 1,
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
      color = ThemeColors.success(context);
    } else if (confidence >= 0.6) {
      color = ThemeColors.warning(context);
    } else {
      color = ThemeColors.error(context);
    }

    return NeuContainer(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      borderRadius: 10,
      variant: NeuVariant.flat,
      borderColor: color.withValues(alpha: 0.3),
      borderWidth: 1,
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

  Color _getTypeColor(ScanType type) {
    switch (type) {
      case ScanType.receipt:
        return const Color(0xFF10B981);
      case ScanType.medicineBox:
        return AppColors.categoryMedicine;
      case ScanType.prescription:
        return AppColors.categorySupply;
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
      if (mounted) context.read<ScanBloc>().add(const LoadScanRecords());
    });
  }

  void _navigateToDetail(ScanRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScanDetailPage(record: record),
      ),
    ).then((_) {
      if (mounted) context.read<ScanBloc>().add(const LoadScanRecords());
    });
  }

  void _useScanData(ScanRecord record) {
    // Navigate to appropriate feature based on scan type
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Using ${record.scanType.displayName} data...'),
        backgroundColor: ThemeColors.success(context),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: NeuContainer(
        variant: NeuVariant.flat,
        color: ThemeColors.background(context),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: TabBar(
          controller: tabController,
          tabs: tabs,
          indicatorColor: color,
          indicatorWeight: 3,
          labelColor: color,
          unselectedLabelColor: ThemeColors.textSecondary(context),
          labelStyle: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w500,
          ),
          dividerColor: Colors.transparent,
          isScrollable: true,
        ),
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

/// Neumorphic empty state used across the scan list tabs.
class _NeuEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _NeuEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final accent = ThemeColors.primary(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: NeuCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeuContainer(
                padding: const EdgeInsets.all(24),
                borderRadius: 24,
                variant: NeuVariant.flat,
                child: Icon(icon, size: 64, color: accent),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ThemeColors.textPrimary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: ThemeColors.textSecondary(context),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                NeuButton(
                  text: actionLabel!,
                  onPressed: onAction,
                  icon: Icons.add_rounded,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Not logged in view
class _NotLoggedInView extends StatelessWidget {
  const _NotLoggedInView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: NeuCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NeuContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: 80,
                    color: AppColors.primary,
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 80,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Please log in to use scanning',
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.textPrimary(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sign in to scan receipts, medicine boxes & more',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: ThemeColors.textSecondary(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  NeuButton(
                    text: 'Log In',
                    onPressed: () => context.go(Routes.login),
                    icon: Icons.login_rounded,
                  ),
                ],
              ),
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
      backgroundColor: ThemeColors.background(context),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: NeuCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NeuContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: 80,
                    color: AppColors.error,
                    child: Icon(
                      Icons.block_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Access Denied',
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.error(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Only veterinarians and clinic staff can use scanning and OCR features.\n\nThis feature is for clinic operations only.',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: ThemeColors.textSecondary(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  NeuButton(
                    text: 'Go Back',
                    onPressed: () => context.pop(),
                    icon: Icons.arrow_back_rounded,
                    variant: NeuButtonVariant.secondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
