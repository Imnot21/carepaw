import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart' as domain;
import 'package:carepaw/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_event.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_state.dart';
import 'package:carepaw/features/notifications/presentation/pages/notification_detail_page.dart';
import 'package:carepaw/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/core/widgets/common/cp_button.dart';
import 'package:carepaw/core/widgets/common/cp_loader.dart';
import 'package:carepaw/core/widgets/common/cp_empty_state.dart';
import 'package:carepaw/core/widgets/effects/animated_gradient.dart';
import 'package:carepaw/core/widgets/effects/glass_container.dart';
import 'package:carepaw/core/widgets/effects/floating_animation.dart';
import 'package:carepaw/core/widgets/effects/pulsing_glow.dart';
import 'package:carepaw/core/widgets/effects/premium_shadows.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/utils/formatters.dart';

/// Notification list page with premium design
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
      // Load more notifications
      final state = context.read<NotificationBloc>().state;
      if (state is NotificationsLoaded && !state.hasReachedMax) {
        context.read<NotificationBloc>().add(
          LoadNotifications(limit: 20, offset: state.notifications.length),
        );
      }
    }
  }

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
          body: AnimatedGradientBackground(
            colors: [
              AppColors.primary.withValues(alpha: 0.06),
              AppColors.secondary.withValues(alpha: 0.04),
              AppColors.surface,
            ],
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildAppBar(),
                _buildTabBar(isVetOrStaff),
                _buildTabContent(isVetOrStaff),
              ],
            ),
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
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                BlocBuilder<NotificationBloc, NotificationState>(
                  builder: (context, state) {
                    if (state is UnreadCountLoaded && state.count > 0) {
                      return PulsingGlow(
                        glowColor: AppColors.primary,
                        maxRadius: 24,
                        duration: const Duration(seconds: 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientPrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${state.count}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textOnPrimary,
                              fontWeight: FontWeight.w700,
                            ),
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
          icon: const Icon(Icons.tune_rounded),
          onPressed: _navigateToSettings,
          tooltip: 'Notification Settings',
        ),
        const SizedBox(width: 8),
        BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationsLoaded &&
                state.notifications.any((n) => !n.isRead)) {
              return IconButton(
                icon: const Icon(Icons.done_all_rounded),
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

  Widget _buildTabBar(bool isVetOrStaff) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _NotificationTabBarDelegate(
        tabController: _tabController,
        tabs: isVetOrStaff
            ? const [
                Tab(text: 'All'),
                Tab(text: 'Unread'),
                Tab(text: 'Appointments'),
                Tab(text: 'Queue'),
                Tab(text: 'Inventory'),
                Tab(text: 'System'),
              ]
            : const [
                Tab(text: 'All'),
                Tab(text: 'Unread'),
                Tab(text: 'Appointments'),
                Tab(text: 'Queue'),
              ],
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTabContent(bool isVetOrStaff) {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: isVetOrStaff
            ? [
                _buildNotificationList(null),
                _buildUnreadList(),
                _buildNotificationsByType(domain.NotificationType.appointmentReminder),
                _buildNotificationsByType(domain.NotificationType.queueUpdate),
                _buildNotificationsByType(domain.NotificationType.inventoryLow),
                _buildNotificationsByType(domain.NotificationType.system),
              ]
            : [
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
          return const Center(child: CpLoader(size: 48));
        }

        if (state is NotificationError) {
          return CpEmptyState(
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
          return CpEmptyState(
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
                  child: Center(child: CpLoader(size: 24)),
                );
              }
              final notification = notifications[index];
              return _buildNotificationCard(notification, index);
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
            return CpEmptyState(
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
              return _buildNotificationCard(unread[index], index, highlightUnread: true);
            },
          );
        }
        return const Center(child: CpLoader(size: 48));
      },
    );
  }

  Widget _buildNotificationsByType(domain.NotificationType type) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        if (state is NotificationsByTypeLoaded) {
          final notifications = state.notifications;
          if (notifications.isEmpty) {
            return CpEmptyState(
              icon: _getTypeIcon(type),
              title: 'No ${type.displayName} Notifications',
              message: 'Notifications of this type will appear here',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationCard(notifications[index], index);
            },
          );
        }
        if (state is NotificationLoading) {
          return const Center(child: CpLoader(size: 48));
        }
        return CpEmptyState(
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
    domain.Notification notification,
    int index, {
    bool highlightUnread = false,
  }) {
    final isUnread = !notification.isRead;
    final typeColor = _getTypeColor(notification.type);

    return FloatingAnimation(
      delay: Duration(milliseconds: 50 * (index % 10)),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        blur: 10,
        borderColor: isUnread
            ? typeColor.withValues(alpha: 0.3)
            : AppColors.divider.withValues(alpha: 0.2),
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
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: _getTypeGradient(notification.type),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getTypeIcon(notification.type),
                        size: 22,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                    if (isUnread && highlightUnread)
                      PulsingGlow(
                        glowColor: AppColors.primary,
                        maxRadius: 52,
                        duration: const Duration(seconds: 2),
                        child: Container(),
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
                                color: AppColors.textPrimary,
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
                          color: AppColors.textSecondary,
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
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
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
                color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Data preview if available
            if (notification.referenceType != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${notification.referenceType}: ${notification.referenceId}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
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
                    child: CpButton(
                      text: 'Mark Read',
                      variant: ButtonVariant.primary,
                      icon: Icons.mark_email_read_rounded,
                      size: ButtonSize.small,
                      onPressed: () {
                        context.read<NotificationBloc>().add(
                          MarkAsRead(notification.id!),
                        );
                      },
                      expanded: true,
                      gradient: AppColors.gradientPrimary,
                    ),
                  )
                else
                  Expanded(
                    child: CpButton(
                      text: 'View Details',
                      variant: ButtonVariant.secondary,
                      icon: Icons.visibility_rounded,
                      size: ButtonSize.small,
                      onPressed: () => _navigateToDetail(notification),
                      expanded: true,
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: CpButton(
                    text: isUnread ? 'Dismiss' : 'Delete',
                    variant: ButtonVariant.outline,
                    icon: isUnread ? Icons.close_rounded : Icons.delete_outline_rounded,
                    size: ButtonSize.small,
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
                    foregroundColor: isUnread ? AppColors.textSecondary : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateNotificationDialog(),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Test Notification'),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  LinearGradient _getTypeGradient(domain.NotificationType type) {
    switch (type) {
      case domain.NotificationType.appointmentReminder:
        return const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]);
      case domain.NotificationType.queueUpdate:
        return const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]);
      case domain.NotificationType.prescriptionReady:
        return const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]);
      case domain.NotificationType.inventoryLow:
        return const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]);
      case domain.NotificationType.system:
        return const LinearGradient(colors: [Color(0xFF6B7280), Color(0xFF4B5563)]);
    }
  }

  Color _getTypeColor(domain.NotificationType type) {
    switch (type) {
      case domain.NotificationType.appointmentReminder:
        return const Color(0xFF3B82F6);
      case domain.NotificationType.queueUpdate:
        return const Color(0xFFF59E0B);
      case domain.NotificationType.prescriptionReady:
        return const Color(0xFF8B5CF6);
      case domain.NotificationType.inventoryLow:
        return const Color(0xFF10B981);
      case domain.NotificationType.system:
        return const Color(0xFF6B7280);
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
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
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
  final List<Tab> tabs;
  final Color color;

  _NotificationTabBarDelegate({
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
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sign in to stay updated with your clinic',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CpButton(
                  text: 'Log In',
                  onPressed: () => context.go('/login'),
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