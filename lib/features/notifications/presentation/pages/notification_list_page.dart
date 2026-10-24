import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart'
    as domain;
import 'package:carepaw/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_event.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_state.dart';
import 'package:carepaw/features/notifications/presentation/pages/notification_detail_page.dart';
import 'package:carepaw/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:carepaw/features/notifications/presentation/widgets/notification_list_widgets.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_chip.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_dialog.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_fab.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_skeleton.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';

/// Notification list page with the CarePaw surface system
class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<NotificationBloc>().add(const LoadNotifications());
    context.read<NotificationBloc>().add(const LoadUnreadCount());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const NotificationNotLoggedInView();
        }

        final user = authState.user;
        final isVetOrStaff = user.isOwnerAdmin;

        return Scaffold(
          backgroundColor: _isDark
              ? AppColors.backgroundDark
              : AppColors.background,
          appBar: _buildAppBar(),
          body: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNotificationList(null),
                    _buildUnreadList(),
                    _buildNotificationsByType(
                      domain.NotificationType.appointmentReminder,
                    ),
                    _buildNotificationsByType(
                      domain.NotificationType.queueUpdate,
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: isVetOrStaff
              ? _buildFloatingActionButton()
              : null,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 96,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Notifications',
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _isDark
                      ? AppColors.textPrimaryOnDark
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  if (state is UnreadCountLoaded && state.count > 0) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: ThemeColors.primary(context),
                        borderRadius: BorderRadius.circular(NeuTokens.radiusSm),
                      ),
                      child: Text(
                        '${state.count}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: ThemeColors.onPrimary(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Stay updated with your clinic',
            style: AppTextStyles.bodySmall.copyWith(
              color: _isDark
                  ? AppColors.textSecondaryOnDark
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        NeuIconButton(
          plain: true,
          icon: Icons.settings_rounded,
          svgAsset: SvgIcons.settings,
          onPressed: _navigateToSettings,
          tooltip: 'Notification Settings',
        ),
        const SizedBox(width: 8),
        BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationsLoaded &&
                state.notifications.any((n) => !n.isRead)) {
              return NeuIconButton(
                plain: true,
                icon: Icons.done_all_rounded,
                svgAsset: SvgIcons.doneAll,
                onPressed: () {
                  context.read<NotificationBloc>().add(const MarkAllAsRead());
                },
                tooltip: 'Mark All as Read',
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      {'label': 'All', 'svg': SvgIcons.notifications},
      {'label': 'Unread', 'svg': SvgIcons.email},
      {'label': 'Appointments', 'svg': SvgIcons.calendar},
      {'label': 'Queue', 'svg': SvgIcons.queue},
    ];

    return Container(
      color: _isDark ? AppColors.surfaceContainerDark : AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ListenableBuilder(
          listenable: _tabController,
          builder: (context, _) => Row(
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: NeuChip(
                  label: tab['label'] as String,
                  svgAsset: tab['svg'] as String,
                  selected: _tabController.index == index,
                  onTap: () => _tabController.animateTo(index),
                  selectedColor: ThemeColors.primary(context),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList(domain.NotificationType? type) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        if (state is NotificationLoading) {
          return const NeuSkeletonList();
        }

        if (state is NotificationError) {
          return NotificationEmptyState(
            svgAsset: SvgIcons.error,
            title: 'Error Loading Notifications',
            message: state.failure.message,
            actionLabel: 'Retry',
            onAction: () {
              context.read<NotificationBloc>().add(
                type == null
                    ? const LoadNotifications()
                    : LoadNotificationsByType(type),
              );
            },
          );
        }

        List<domain.Notification> notifications = [];
        bool hasReachedMax = false;

        if (state is NotificationsLoaded) {
          notifications = state.notifications;
          hasReachedMax = state.hasReachedMax;
        } else if (state is NotificationsByTypeLoaded) {
          notifications = state.notifications;
        }

        if (type != null) {
          notifications = notifications.where((n) => n.type == type).toList();
        } else {
          // PAPER-ONLY: All tab shows appointment + queue notifications.
          // prescription/inventory/system stay stored but hidden in demo UI.
          notifications = notifications
              .where(
                (n) =>
                    n.type == domain.NotificationType.appointmentReminder ||
                    n.type == domain.NotificationType.queueUpdate,
              )
              .toList();
        }

        if (notifications.isEmpty) {
          return NotificationEmptyState(
            svgAsset: type != null ? _getTypeSvg(type) : SvgIcons.notifications,
            title: type != null
                ? 'No ${type.displayName} Notifications'
                : 'No Notifications Yet',
            message: type != null
                ? 'You\'re all caught up on ${type.displayName.toLowerCase()} notifications'
                : 'Notifications will appear here when you receive them',
            actionLabel: type == null ? 'Refresh' : null,
            onAction: type == null
                ? () => context.read<NotificationBloc>().add(
                    const RefreshNotifications(),
                  )
                : null,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<NotificationBloc>().add(const RefreshNotifications());
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: notifications.length + (hasReachedMax ? 0 : 1),
            itemBuilder: (context, index) {
              if (index >= notifications.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: NeuCircularProgress(size: 24)),
                );
              }
              final notification = notifications[index];
              return NotificationCard(
                notification: notification,
                typeColor: _getTypeColor(notification.type),
                typeSvg: _getTypeSvg(notification.type),
                onViewDetails: () => _navigateToDetail(notification),
                onDelete: () => _showDeleteConfirmation(notification.id!),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUnreadList() {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        if (state is NotificationsLoaded) {
          // PAPER-ONLY: unread tab shows appointment + queue only.
          final unread = state.notifications
              .where(
                (n) =>
                    !n.isRead &&
                    (n.type == domain.NotificationType.appointmentReminder ||
                        n.type == domain.NotificationType.queueUpdate),
              )
              .toList();
          if (unread.isEmpty) {
            return NotificationEmptyState(
              svgAsset: SvgIcons.email,
              title: 'All Caught Up!',
              message: 'No unread notifications',
              actionLabel: 'View All',
              onAction: () => _tabController.animateTo(0),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: unread.length,
            itemBuilder: (context, index) {
              final notification = unread[index];
              return NotificationCard(
                notification: notification,
                typeColor: _getTypeColor(notification.type),
                typeSvg: _getTypeSvg(notification.type),
                onViewDetails: () => _navigateToDetail(notification),
                onDelete: () => _showDeleteConfirmation(notification.id!),
              );
            },
          );
        }
        return const NeuSkeletonList();
      },
    );
  }

  Widget _buildNotificationsByType(domain.NotificationType type) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        if (state is NotificationsByTypeLoaded) {
          final notifications = state.notifications;
          if (notifications.isEmpty) {
            return NotificationEmptyState(
              svgAsset: _getTypeSvg(type),
              title: 'No ${type.displayName} Notifications',
              message: 'Notifications of this type will appear here',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationCard(
                notification: notification,
                typeColor: _getTypeColor(notification.type),
                typeSvg: _getTypeSvg(notification.type),
                onViewDetails: () => _navigateToDetail(notification),
                onDelete: () => _showDeleteConfirmation(notification.id!),
              );
            },
          );
        }
        if (state is NotificationLoading) {
          return const NeuSkeletonList();
        }
        return NotificationEmptyState(
          svgAsset: _getTypeSvg(type),
          title: 'No ${type.displayName} Notifications',
          message: 'Pull to refresh',
          actionLabel: 'Refresh',
          onAction: () => context.read<NotificationBloc>().add(
            LoadNotificationsByType(type),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return NeuFAB.extended(
      onPressed: () => _showCreateNotificationDialog(),
      icon: Icons.add_rounded,
      svgAsset: SvgIcons.add,
      extendedText: 'Test Notification',
      variant: NeuButtonVariant.primary,
    );
  }

  Color _getTypeColor(domain.NotificationType type) {
    switch (type) {
      case domain.NotificationType.appointmentReminder:
        return ThemeColors.primary(context);
      case domain.NotificationType.queueUpdate:
        return ThemeColors.warning(context);
      case domain.NotificationType.prescriptionReady:
        return AppColors.categorySupply;
      case domain.NotificationType.inventoryLow:
        return ThemeColors.success(context);
      case domain.NotificationType.system:
        return _isDark
            ? AppColors.textSecondaryOnDark
            : AppColors.textSecondary;
    }
  }

  String _getTypeSvg(domain.NotificationType type) {
    switch (type) {
      case domain.NotificationType.appointmentReminder:
        return SvgIcons.calendar;
      case domain.NotificationType.queueUpdate:
        return SvgIcons.queue;
      case domain.NotificationType.prescriptionReady:
        return SvgIcons.medication;
      case domain.NotificationType.inventoryLow:
        return SvgIcons.inventory;
      case domain.NotificationType.system:
        return SvgIcons.settings;
    }
  }

  void _navigateToDetail(domain.Notification notification) {
    final bloc = context.read<NotificationBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: NotificationDetailPage(notification: notification),
        ),
      ),
    );
  }

  void _navigateToSettings() {
    final bloc = context.read<NotificationBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const NotificationSettingsPage(),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(int notificationId) {
    NeuConfirmDialog.show(
      context: context,
      title: 'Delete Notification',
      message: 'Are you sure you want to delete this notification?',
      confirmText: 'Delete',
      confirmVariant: NeuButtonVariant.destructive,
    ).then((confirmed) {
      if (!mounted) return;
      if (confirmed == true) {
        context.read<NotificationBloc>().add(
          DeleteNotification(notificationId),
        );
      }
    });
  }

  void _showCreateNotificationDialog() {
    final bloc = context.read<NotificationBloc>();
    showDialog(
      context: context,
      // The dialog hosts NeuTextFields, which need a Material ancestor that
      // the NeuDialog shell doesn't provide on its own. It also needs the
      // route-scoped NotificationBloc, which the dialog route can't see.
      builder: (context) => BlocProvider.value(
        value: bloc,
        child: Material(
          type: MaterialType.transparency,
          child: NotificationCreateDialog(),
        ),
      ),
    );
  }
}
