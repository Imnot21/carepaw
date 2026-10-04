import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_chip.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_divider.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/features/audit/domain/entities/audit_log.dart';
import 'package:carepaw/features/audit/presentation/bloc/audit_log_bloc.dart';
import 'package:carepaw/features/audit/presentation/bloc/audit_log_event.dart';
import 'package:carepaw/features/audit/presentation/bloc/audit_log_state.dart';

/// Admin audit log page - append-only trail of sensitive operations.
///
/// Shows the most-recent audit entries with action/entity filter chips.
/// Entries are read-only: there is no edit or delete surface here, matching
/// the append-only audit-trail requirement.
class AdminAuditPage extends StatelessWidget {
  const AdminAuditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('Audit Logs'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          NeuIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onPressed: () {
              final state = context.read<AuditLogBloc>().state;
              context.read<AuditLogBloc>().add(
                AuditLogLoadRequested(
                  actionFilter: state is AuditLogLoaded
                      ? state.actionFilter
                      : null,
                  entityTypeFilter: state is AuditLogLoaded
                      ? state.entityTypeFilter
                      : null,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<AuditLogBloc, AuditLogState>(
          builder: (context, state) {
            if (state is AuditLogLoading) {
              return const _AuditLoadingView();
            }
            if (state is AuditLogError) {
              return _AuditErrorView(message: state.failure.message);
            }
            final entries = state is AuditLogLoaded
                ? state.entries
                : const <AuditLog>[];
            final actionFilter = state is AuditLogLoaded
                ? state.actionFilter
                : null;
            final entityFilter = state is AuditLogLoaded
                ? state.entityTypeFilter
                : null;
            return _AuditContent(
              entries: entries,
              actionFilter: actionFilter,
              entityFilter: entityFilter,
            );
          },
        ),
      ),
    );
  }
}

class _AuditLoadingView extends StatelessWidget {
  const _AuditLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: NeuCircularProgress(size: 32, strokeWidth: 3));
  }
}

class _AuditErrorView extends StatelessWidget {
  final String message;

  const _AuditErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: ThemeColors.error(context),
            ),
            const SizedBox(height: 12),
            Text('Could not load audit logs', style: AppTextStyles.titleSmall),
            const SizedBox(height: 6),
            Text(
              message,
              style: AppTextStyles.bodySmall.subtleOf(
                Theme.of(context).brightness,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            NeuButton(
              text: 'Try again',
              variant: NeuButtonVariant.primary,
              size: NeuButtonSize.small,
              icon: Icons.refresh_rounded,
              onPressed: () => context.read<AuditLogBloc>().add(
                const AuditLogLoadRequested(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditContent extends StatelessWidget {
  final List<AuditLog> entries;
  final String? actionFilter;
  final String? entityFilter;

  const _AuditContent({
    required this.entries,
    required this.actionFilter,
    required this.entityFilter,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _AuditEmptyView();
    }
    return Column(
      children: [
        _AuditFilterBar(
          entries: entries,
          actionFilter: actionFilter,
          entityFilter: entityFilter,
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            physics: const BouncingScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const NeuDivider(thickness: 1),
            itemBuilder: (context, index) =>
                _AuditLogCard(entry: entries[index]),
          ),
        ),
      ],
    );
  }
}

class _AuditEmptyView extends StatelessWidget {
  const _AuditEmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: NeuCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeuContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(16),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: ThemeColors.primary(context),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text('No audit entries yet', style: AppTextStyles.titleSmall),
              const SizedBox(height: 6),
              Text(
                'Sensitive operations such as account creation, role changes, and '
                'activation toggles will appear here automatically.',
                style: AppTextStyles.bodySmall.subtleOf(
                  Theme.of(context).brightness,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuditFilterBar extends StatelessWidget {
  final List<AuditLog> entries;
  final String? actionFilter;
  final String? entityFilter;

  const _AuditFilterBar({
    required this.entries,
    required this.actionFilter,
    required this.entityFilter,
  });

  @override
  Widget build(BuildContext context) {
    final actions = entries.map((e) => e.action).toSet().toList()..sort();
    final entityTypes = entries.map((e) => e.entityType).toSet().toList()
      ..sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (actions.isNotEmpty) ...[
            Text('Action', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  NeuChip(
                    label: 'All',
                    selected: actionFilter == null,
                    onTap: () => context.read<AuditLogBloc>().add(
                      const AuditLogActionFilterChanged(null),
                    ),
                  ),
                  for (final action in actions) ...[
                    const SizedBox(width: 8),
                    NeuChip(
                      label: _actionLabel(action),
                      selected: actionFilter == action,
                      onTap: () => context.read<AuditLogBloc>().add(
                        AuditLogActionFilterChanged(action),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (entityTypes.isNotEmpty) ...[
            Text('Entity', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  NeuChip(
                    label: 'All',
                    selected: entityFilter == null,
                    onTap: () => context.read<AuditLogBloc>().add(
                      const AuditLogEntityTypeFilterChanged(null),
                    ),
                  ),
                  for (final entity in entityTypes) ...[
                    const SizedBox(width: 8),
                    NeuChip(
                      label: _entityLabel(entity),
                      selected: entityFilter == entity,
                      onTap: () => context.read<AuditLogBloc>().add(
                        AuditLogEntityTypeFilterChanged(entity),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _actionLabel(String action) {
    return switch (action) {
      'USER_CREATE' => 'Created',
      'USER_ROLE_CHANGE' => 'Role changed',
      'USER_ACTIVE_TOGGLE' => 'Activation',
      _ => action.replaceAll('_', ' ').toLowerCase(),
    };
  }

  static String _entityLabel(String entityType) {
    return switch (entityType) {
      'USER' => 'User',
      _ => entityType,
    };
  }
}

class _AuditLogCard extends StatelessWidget {
  final AuditLog entry;

  const _AuditLogCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final actionColor = _actionColor(context, entry.action);

    return NeuCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      borderColor: actionColor.withValues(alpha: 0.25),
      borderWidth: 1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: actionColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _actionIcon(entry.action),
              color: actionColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _actionLabel(entry.action),
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: actionColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(entry.createdAt),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: ThemeColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'User #${entry.userId} on ${_entityLabel(entry.entityType)} '
                  '${entry.entityId}',
                  style: AppTextStyles.bodySmall.subtleOf(
                    Theme.of(context).brightness,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _actionLabel(String action) {
    return switch (action) {
      'USER_CREATE' => 'Account created',
      'USER_ROLE_CHANGE' => 'Role changed',
      'USER_ACTIVE_TOGGLE' => 'Activation toggled',
      _ => action.replaceAll('_', ' ').toLowerCase(),
    };
  }

  static String _entityLabel(String entityType) {
    return switch (entityType) {
      'USER' => 'user',
      _ => entityType.toLowerCase(),
    };
  }

  static IconData _actionIcon(String action) {
    return switch (action) {
      'USER_CREATE' => Icons.person_add_alt_1_outlined,
      'USER_ROLE_CHANGE' => Icons.swap_horiz_rounded,
      'USER_ACTIVE_TOGGLE' => Icons.toggle_on_outlined,
      _ => Icons.fact_check_outlined,
    };
  }

  static Color _actionColor(BuildContext context, String action) {
    return switch (action) {
      'USER_CREATE' => ThemeColors.success(context),
      'USER_ROLE_CHANGE' => AppColors.tertiary,
      'USER_ACTIVE_TOGGLE' => ThemeColors.warning(context),
      _ => ThemeColors.primary(context),
    };
  }

  static String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final local = time.toLocal();
    return '${_two(local.month)}/${_two(local.day)} ${_two(local.hour)}:${_two(local.minute)}';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
