import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart'
    as domain;
import 'package:carepaw/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_event.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_preferences_cubit.dart';
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
import 'package:carepaw/core/widgets/neomorphism/neu_state.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_feedback.dart';
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

  static const _loadErrorMessage = 'Check your connection and try again.';

  /// Last list the bloc delivered. The bloc emits one-off states (marked as
  /// read, unread count, deleted) between loads; without this the tabs would
  /// flash empty each time.
  NotificationsLoaded? _lastLoaded;

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
          backgroundColor: ThemeColors.background(context),
          appBar: _buildAppBar(),
          body: BlocListener<NotificationBloc, NotificationState>(
            listener: _onBlocState,
            child: Column(
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
          ),
          floatingActionButton: isVetOrStaff
              ? _buildFloatingActionButton()
              : null,
        );
      },
    );
  }

  void _onBlocState(BuildContext context, NotificationState state) {
    if (state is NotificationsLoaded) {
      _lastLoaded = state;
    } else if (state is NotificationError && _lastLoaded != null) {
      NeuToast.error(context, 'That did not work. $_loadErrorMessage');
    } else if (state is NotificationMarkedAsRead ||
        state is AllNotificationsMarkedAsRead ||
        state is NotificationDeleted ||
        state is NotificationCreated) {
      context.read<NotificationBloc>().add(const RefreshNotifications());
    }
  }

  NotificationsLoaded? _loadedFrom(NotificationState state) =>
      state is NotificationsLoaded ? state : _lastLoaded;

  Widget _errorView(VoidCallback onRetry) => NeuErrorState(
    title: "Couldn't load notifications",
    message: _loadErrorMessage,
    svgAsset: SvgIcons.error,
    onRetry: onRetry,
  );

  Widget _list(
    List<domain.Notification> items, {
    bool showMoreSpinner = false,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: NeuTokens.maxContentWidth),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            NeuTokens.pagePadding,
            NeuTokens.spaceMd,
            NeuTokens.pagePadding,
            100,
          ),
          itemCount: items.length + (showMoreSpinner ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= items.length) {
              return const Padding(
                padding: EdgeInsets.all(NeuTokens.spaceMd),
                child: Center(child: NeuCircularProgress(size: 24)),
              );
            }
            final notification = items[index];
            return NotificationCard(
              notification: notification,
              typeColor: _getTypeColor(notification.type),
              typeSvg: _getTypeSvg(notification.type),
              onViewDetails: () => _navigateToDetail(notification),
              onDelete: () => _showDeleteConfirmation(notification.id!),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 96,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: NeuTokens.pagePadding,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'Notifications',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: ThemeColors.textPrimary(context),
                  ),
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
            'Updates from PILA VET HUB',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: ThemeColors.textSecondary(context),
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
          tooltip: 'Notification settings',
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
                tooltip: 'Mark all as read',
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
      padding: const EdgeInsets.symmetric(
        horizontal: NeuTokens.tightGap,
        vertical: NeuTokens.spaceXs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ListenableBuilder(
          listenable: _tabController,
          builder: (context, _) => Row(
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              return Padding(
                padding: const EdgeInsets.only(right: NeuTokens.spaceXs),
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

        final loaded = _loadedFrom(state);
        if (state is NotificationError && loaded == null) {
          return _errorView(
            () => context.read<NotificationBloc>().add(
              type == null
                  ? const LoadNotifications()
                  : LoadNotificationsByType(type),
            ),
          );
        }

        var notifications = <domain.Notification>[];
        var hasReachedMax = false;

        if (loaded != null) {
          notifications = loaded.notifications;
          hasReachedMax = loaded.hasReachedMax;
        } else if (state is NotificationsByTypeLoaded) {
          notifications = state.notifications;
        }

        // PAPER-ONLY: All tab shows appointment + queue notifications.
        // prescription/inventory/system stay stored but hidden in demo UI.
        notifications = notifications
            .where(
              (n) =>
                  n.type == domain.NotificationType.appointmentReminder ||
                  n.type == domain.NotificationType.queueUpdate,
            )
            .toList();

        if (notifications.isEmpty) {
          return NotificationEmptyState(
            svgAsset: SvgIcons.notifications,
            title: 'No notifications yet',
            message:
                'Booking changes and queue calls from the clinic show up here.',
            actionLabel: 'Refresh',
            onAction: () => context.read<NotificationBloc>().add(
              const RefreshNotifications(),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<NotificationBloc>().add(const RefreshNotifications());
          },
          child: _list(notifications, showMoreSpinner: !hasReachedMax),
        );
      },
    );
  }

  Widget _buildUnreadList() {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        if (state is NotificationLoading) return const NeuSkeletonList();
        final loaded = _loadedFrom(state);
        if (loaded == null) {
          if (state is NotificationError) {
            return _errorView(
              () => context.read<NotificationBloc>().add(
                const LoadNotifications(),
              ),
            );
          }
          return const NeuSkeletonList();
        }
        // PAPER-ONLY: unread tab shows appointment + queue only.
        final unread = loaded.notifications
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
            title: 'All read',
            message: 'You have read everything.',
            actionLabel: 'Show all',
            onAction: () => _tabController.animateTo(0),
          );
        }
        return _list(unread);
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
              title: 'No ${type.displayName.toLowerCase()} updates',
              message: 'Nothing here yet.',
            );
          }
          return _list(notifications);
        }
        if (state is NotificationLoading) {
          return const NeuSkeletonList();
        }
        if (state is NotificationError) {
          return _errorView(
            () => context.read<NotificationBloc>().add(
              LoadNotificationsByType(type),
            ),
          );
        }
        return NotificationEmptyState(
          svgAsset: _getTypeSvg(type),
          title: 'No ${type.displayName.toLowerCase()} updates',
          message: 'Pull down to refresh.',
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
        return ThemeColors.textSecondary(context);
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
    // Reload on every visit, so the switches show what Firestore holds.
    final preferences = context.read<NotificationPreferencesCubit>()..load();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: bloc),
            BlocProvider.value(value: preferences),
          ],
          child: const NotificationSettingsPage(),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(int notificationId) {
    NeuConfirmDialog.show(
      context: context,
      title: 'Delete notification',
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
