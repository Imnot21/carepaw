import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart' as domain;
import 'package:carepaw/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_event.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_state.dart';
import 'package:carepaw/features/notifications/presentation/pages/notification_detail_page.dart';
import 'package:carepaw/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_avatar.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_skeleton.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/utils/formatters.dart';

/// Notification list page with neumorphic design
class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<NotificationBloc>().add(const LoadNotifications());
    context.read<NotificationBloc>().add(const LoadUnreadCount());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<NotificationBloc>().state;
      if (state is NotificationsLoaded && !state.hasReachedMax) {
        context.read<NotificationBloc>().add(
          LoadNotifications(limit: 20, offset: state.notifications.length),
        );
      }
    }
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const _NotLoggedInView();
        }

        final user = authState.user;
        final isVetOrStaff = user.role == UserRole.veterinarian ||
                            user.role == UserRole.staff ||
                            user.role == UserRole.admin;

        return Scaffold(
          backgroundColor: _isDark ? AppColors.backgroundDark : AppColors.background,
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(),
              _buildTabBar(),
              _buildTabContent(),
            ],
          ),
          floatingActionButton: isVetOrStaff ? _buildFloatingActionButton() : null,
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
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
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
                    color: _isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
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
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${state.count}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textOnPrimary,
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
                color: _isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        NeuIconButton(
          icon: Icons.tune_rounded,
          onPressed: _navigateToSettings,
          tooltip: 'Notification Settings',
        ),
        const SizedBox(width: 8),
        BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationsLoaded &&
                state.notifications.any((n) => !n.isRead)) {
              return NeuIconButton(
                icon: Icons.done_all_rounded,
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
    return SliverPersistentHeader(
      pinned: true,
      delegate: _NotificationTabBarDelegate(
        tabController: _tabController,
      ),
    );
  }

  Widget _buildTabContent() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(null),
          _buildUnreadList(),
          _buildNotificationsByType(domain.NotificationType.appointmentReminder),
          _buildNotificationsByType(domain.NotificationType.queueUpdate),
        ],
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
          return _EmptyState(
            icon: Icons.error_outline_rounded,
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
          notifications = notifications
              .where((n) => n.type == type)
              .toList();
        }

        if (notifications.isEmpty) {
          return _EmptyState(
            icon: _getTypeIcon(type ?? domain.NotificationType.system),
            title: type != null
                ? 'No ${type.displayName} Notifications'
                : 'No Notifications Yet',
            message: type != null
                ? 'You\'re all caught up on ${type.displayName.toLowerCase()} notifications'
                : 'Notifications will appear here when you receive them',
            actionLabel: type == null ? 'Refresh' : null,
            onAction: type == null
                ? () => context.read<NotificationBloc>().add(const RefreshNotifications())
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
              return _buildNotificationCard(notification);
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
          final unread = state.notifications.where((n) => !n.isRead).toList();
          if (unread.isEmpty) {
            return _EmptyState(
              icon: Icons.mark_email_read_rounded,
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
              return _buildNotificationCard(unread[index], highlightUnread: true);
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
            return _EmptyState(
              icon: _getTypeIcon(type),
              title: 'No ${type.displayName} Notifications',
              message: 'Notifications of this type will appear here',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationCard(notifications[index]);
            },
          );
        }
        if (state is NotificationLoading) {
          return const NeuSkeletonList();
        }
        return _EmptyState(
          icon: _getTypeIcon(type),
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

  Widget _buildNotificationCard(
    domain.Notification notification, {
    bool highlightUnread = false,
  }) {
    final isUnread = !notification.isRead;
    final typeColor = _getTypeColor(notification.type);

    return NeuCard(
      padding: const EdgeInsets.all(16),
      variant: NeuVariant.raised,
      borderColor: isUnread ? typeColor.withValues(alpha: 0.3) : null,
      borderWidth: isUnread ? 1 : 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon with background
              Stack(
                alignment: Alignment.center,
                children: [
                  NeuAvatar(
                    radius: 22,
                    icon: _getTypeIcon(notification.type),
                    backgroundColor: typeColor,
                    foregroundColor: AppColors.textOnPrimary,
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Title and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                              color: _isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRelativeTime(notification.createdAt),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Unread indicator
              if (isUnread)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Body preview
          Text(
            notification.message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isUnread
                  ? (_isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary)
                  : (_isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Data preview if available
          if (notification.referenceType != null) ...[
            const SizedBox(height: 8),
            NeuCard(
              padding: const EdgeInsets.all(10),
              variant: NeuVariant.inset,
              borderRadius: 8,
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: _isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${notification.referenceType}: ${notification.referenceId}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              if (isUnread)
                Expanded(
                  child: NeuButton(
                    text: 'Mark Read',
                    variant: NeuButtonVariant.primary,
                    icon: Icons.mark_email_read_rounded,
                    size: NeuButtonSize.medium,
                    onPressed: () {
                      context.read<NotificationBloc>().add(
                        MarkAsRead(notification.id!),
                      );
                    },
                    expanded: true,
                  ),
                )
              else
                Expanded(
                  child: NeuButton(
                    text: 'View Details',
                    variant: NeuButtonVariant.secondary,
                    icon: Icons.visibility_rounded,
                    size: NeuButtonSize.medium,
                    onPressed: () => _navigateToDetail(notification),
                    expanded: true,
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: NeuButton(
                  text: isUnread ? 'Dismiss' : 'Delete',
                  variant: isUnread ? NeuButtonVariant.outline : NeuButtonVariant.outline,
                  icon: isUnread ? Icons.close_rounded : Icons.delete_outline_rounded,
                  size: NeuButtonSize.medium,
                  onPressed: () {
                    if (isUnread) {
                      context.read<NotificationBloc>().add(
                        MarkAsRead(notification.id!),
                      );
                    } else {
                      _showDeleteConfirmation(notification.id!);
                    }
                  },
                  expanded: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateNotificationDialog(),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Test Notification'),
    );
  }

  Color _getTypeColor(domain.NotificationType type) {
    switch (type) {
      case domain.NotificationType.appointmentReminder:
        return ThemeColors.primary(context);
      case domain.NotificationType.queueUpdate:
        return _isDark ? AppColors.warningOnDark : AppColors.warning;
      case domain.NotificationType.prescriptionReady:
        return AppColors.categorySupply;
      case domain.NotificationType.inventoryLow:
        return _isDark ? AppColors.successOnDark : AppColors.success;
      case domain.NotificationType.system:
        return _isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary;
    }
  }

  IconData _getTypeIcon(domain.NotificationType type) {
    switch (type) {
      case domain.NotificationType.appointmentReminder:
        return Icons.calendar_today_rounded;
      case domain.NotificationType.queueUpdate:
        return Icons.queue_rounded;
      case domain.NotificationType.prescriptionReady:
        return Icons.medication_rounded;
      case domain.NotificationType.inventoryLow:
        return Icons.inventory_rounded;
      case domain.NotificationType.system:
        return Icons.settings_rounded;
    }
  }

  void _navigateToDetail(domain.Notification notification) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationDetailPage(notification: notification),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationSettingsPage(),
      ),
    );
  }

  void _showDeleteConfirmation(int notificationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<NotificationBloc>().add(DeleteNotification(notificationId));
            },
            child: Text('Delete', style: TextStyle(color: ThemeColors.error(context))),
          ),
        ],
      ),
    );
  }

  void _showCreateNotificationDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateNotificationDialog(),
    );
  }
}

class _CreateNotificationDialog extends StatefulWidget {
  @override
  State<_CreateNotificationDialog> createState() => _CreateNotificationDialogState();
}

class _CreateNotificationDialogState extends State<_CreateNotificationDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  domain.NotificationType _selectedType = domain.NotificationType.system;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Test Notification'),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Notification title',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Body',
                  hintText: 'Notification message',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<domain.NotificationType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: domain.NotificationType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty && _bodyController.text.isNotEmpty) {
              Navigator.pop(context);
              context.read<NotificationBloc>().add(
                CreateNotification(
                  title: _titleController.text,
                  body: _bodyController.text,
                  type: _selectedType,
                ),
              );
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _NotificationTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;

  _NotificationTabBarDelegate({
    required this.tabController,
  });

  @override
  Widget build(
    BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.surfaceContainerDark : AppColors.surface,
      child: TabBar(
        controller: tabController,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Unread'),
          Tab(text: 'Appointments'),
          Tab(text: 'Queue'),
        ],
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelColor: isDark ? AppColors.primaryOnDark : AppColors.primary,
        unselectedLabelColor: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
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

/// Empty state shown when a notification tab has no content.
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: NeuCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeuContainer(
                borderRadius: 90,
                padding: const EdgeInsets.all(22),
                color: AppColors.primary,
                boxShadow: NeuShadow.color(
                  context,
                  AppColors.primary,
                  blur: 24,
                  opacity: 0.32,
                ),
                child: Icon(icon, size: 48, color: AppColors.textOnPrimary),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                NeuButton(
                  text: actionLabel!,
                  onPressed: onAction,
                  variant: NeuButtonVariant.primary,
                  size: NeuButtonSize.medium,
                  icon: Icons.refresh_rounded,
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

  bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDark(context) ? AppColors.backgroundDark : AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: NeuContainer(
                  borderRadius: 80,
                  variant: NeuVariant.raised,
                  color: AppColors.primary,
                  child: const Icon(
                    Icons.notifications_rounded,
                    size: 80,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Please log in to view notifications',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _isDark(context) ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to stay updated with your clinic',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: _isDark(context) ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              NeuButton(
                text: 'Log In',
                onPressed: () => Navigator.of(context).pushNamed('/login'),
                icon: Icons.login_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
