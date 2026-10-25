import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/core/utils/formatters.dart';
import 'package:carepaw/core/widgets/neomorphism/index.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:carepaw/features/scanning/domain/entities/scan_record.dart';
import 'package:carepaw/features/scanning/presentation/bloc/scan_bloc.dart';
import 'package:carepaw/features/scanning/presentation/bloc/scan_event.dart';
import 'package:carepaw/features/scanning/presentation/bloc/scan_state.dart';
import 'package:carepaw/features/scanning/presentation/pages/scan_camera_page.dart';
import 'package:carepaw/features/scanning/presentation/utils/scan_type_colors.dart';

/// Scan tab: scan a medicine box or a supplier receipt, then see what
/// recent scans added to the inventory.
class ScanListPage extends StatelessWidget {
  const ScanListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const _NotLoggedInView();
        }
        // Only the clinic owner/admin scans stock in.
        if (!authState.user.isOwnerAdmin) {
          return const _AccessDeniedView();
        }

        return Scaffold(
          backgroundColor: ThemeColors.background(context),
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () async =>
                  context.read<ScanBloc>().add(const LoadScanRecords()),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
                children: [
                  Text(
                    'Scan',
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: ThemeColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'The AI reads the photo, you check it, and it is '
                    'added to the inventory',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: ThemeColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ScanAction(
                    type: ScanType.medicineBox,
                    title: 'Scan Medicine Box',
                    subtitle: 'One medicine: name, lot and expiry',
                    svgAsset: SvgIcons.medication,
                  ),
                  const SizedBox(height: 16),
                  _ScanAction(
                    type: ScanType.receipt,
                    title: 'Scan Supplier Receipt',
                    subtitle: 'Every medicine on the delivery',
                    svgAsset: SvgIcons.receipt,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Recent scans',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ThemeColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _RecentScans(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A large button that opens the camera for one kind of scan.
class _ScanAction extends StatelessWidget {
  final ScanType type;
  final String title;
  final String subtitle;
  final String svgAsset;

  const _ScanAction({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.svgAsset,
  });

  @override
  Widget build(BuildContext context) {
    final color = scanTypeColor(context, type);
    return NeuCard(
      padding: const EdgeInsets.all(20),
      borderColor: color.withValues(alpha: 0.2),
      borderWidth: 1,
      onTap: () => _open(context),
      child: Row(
        children: [
          NeuContainer(
            padding: const EdgeInsets.all(14),
            borderRadius: NeuTokens.radiusSm,
            color: color.withValues(alpha: 0.12),
            child: NeuSvgIcon(svgAsset, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
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
          NeuSvgIcon(SvgIcons.camera, size: 24),
        ],
      ),
    );
  }

  /// The camera page saves the scan and the stock through the blocs of
  /// this route, so hand both over.
  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<ScanBloc>()),
            BlocProvider.value(value: context.read<InventoryBloc>()),
          ],
          child: ScanCameraPage(type: type),
        ),
      ),
    );
  }
}

/// Read-only list of the latest scans and what each one added.
class _RecentScans extends StatelessWidget {
  const _RecentScans();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScanBloc, ScanState>(
      // Keep the list while a new scan is saving.
      buildWhen: (_, state) =>
          state is ScanRecordsLoaded ||
          state is ScanError ||
          state is ScanInitial,
      builder: (context, state) {
        if (state is ScanError) {
          return NeuEmptyState(
            icon: Icons.error_outline_rounded,
            svgAsset: SvgIcons.error,
            title: 'Could not load scans',
            message: state.failure.message,
            actionLabel: 'Retry',
            onAction: () =>
                context.read<ScanBloc>().add(const LoadScanRecords()),
          );
        }
        if (state is! ScanRecordsLoaded) {
          return const NeuSkeletonList(itemCount: 3, padding: EdgeInsets.zero);
        }
        final records = [...state.records]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (records.isEmpty) {
          return NeuEmptyState(
            icon: Icons.document_scanner_rounded,
            svgAsset: SvgIcons.scan,
            title: 'No scans yet',
            message:
                'Scan a medicine box or a supplier receipt to add '
                'stock.',
          );
        }
        return Column(
          children: [
            for (final record in records.take(20)) _ScanTile(record: record),
          ],
        );
      },
    );
  }
}

class _ScanTile extends StatelessWidget {
  final ScanRecord record;

  const _ScanTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final isReceipt = record.scanType == ScanType.receipt;
    final summary = (record.extractedData ?? '')
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    return NeuCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeuContainer(
            padding: const EdgeInsets.all(10),
            borderRadius: NeuTokens.radiusSm,
            color: scanTypeColor(
              context,
              record.scanType,
            ).withValues(alpha: 0.12),
            child: NeuSvgIcon(
              isReceipt ? SvgIcons.receipt : SvgIcons.medication,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.scanType.displayName,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ThemeColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatDateTime(record.createdAt),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: ThemeColors.textTertiary(context),
                  ),
                ),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    summary.take(3).join('\n') +
                        (summary.length > 3
                            ? '\n+${summary.length - 3} more'
                            : ''),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: ThemeColors.textSecondary(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
                    color: ThemeColors.primary(context),
                    child: NeuSvgIcon(SvgIcons.camera, size: 80),
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
                    svgAsset: SvgIcons.login,
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
                    color: ThemeColors.error(context),
                    child: NeuSvgIcon(SvgIcons.block, size: 80),
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
                    svgAsset: SvgIcons.back,
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
