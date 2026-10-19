import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_bloc.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_event.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_state.dart';
import 'package:carepaw/features/queue/domain/entities/queue_entry.dart';
import 'package:carepaw/features/queue/presentation/widgets/staff_queue_widgets.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';

import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_dialog.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';

/// Staff queue page - full management view with action buttons
class StaffQueuePage extends StatefulWidget {
  const StaffQueuePage({super.key});

  @override
  State<StaffQueuePage> createState() => _StaffQueuePageState();
}

class _StaffQueuePageState extends State<StaffQueuePage> {
  @override
  void initState() {
    super.initState();
    // Load queue when page initializes
    context.read<QueueBloc>().add(QueueStaffLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const StaffNotLoggedInView();
        }

        final user = authState.user;
        final isVetOrStaff = user.isOwnerAdmin;

        if (!isVetOrStaff) {
          return const StaffAccessDeniedView();
        }

        return Scaffold(
          backgroundColor: ThemeColors.background(context),
          appBar: AppBar(
            title: Text(
              'Queue management',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: NeuIconButton(
                  plain: true,
                  icon: Icons.reorder_rounded,
                  svgAsset: SvgIcons.reorder,
                  onPressed: () {
                    context.read<QueueBloc>().add(
                      const QueueRepositionRequested(),
                    );
                  },
                  color: ThemeColors.textPrimary(context),
                  tooltip: 'Reposition Queue',
                ),
              ),
            ],
          ),
          body: BlocConsumer<QueueBloc, QueueState>(
            listener: (context, state) {
              if (state is QueueOperationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: ThemeColors.success(context),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
                // Reload queue after successful operation
                context.read<QueueBloc>().add(QueueStaffLoadRequested());
              } else if (state is QueueError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: ThemeColors.error(context),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is QueueLoading) {
                return const Center(child: NeuCircularProgress());
              }

              if (state is QueueError) {
                return _buildErrorState(state.message);
              }

              if (state is QueueStaffLoaded) {
                return _buildStaffQueueView(state);
              }

              return _buildInitialState();
            },
          ),
        );
      },
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeuContainer(
              borderRadius: 70,
              padding: const EdgeInsets.all(30),
              color: ThemeColors.primary(context),
              boxShadow: NeuShadow.color(
                context,
                ThemeColors.primary(context),
                blur: 24,
                opacity: 0.32,
              ),
              child: NeuSvgIcon(SvgIcons.people, size: 60),
            ),
            const SizedBox(height: 28),
            Text(
              'Queue Management',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Load the queue to see waiting patients',
              style: AppTextStyles.bodyLarge.copyWith(
                color: ThemeColors.textSecondary(context),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeuContainer(
              borderRadius: 70,
              padding: const EdgeInsets.all(30),
              color: ThemeColors.error(context),
              boxShadow: NeuShadow.color(
                context,
                ThemeColors.error(context),
                blur: 24,
                opacity: 0.32,
              ),
              child: NeuSvgIcon(SvgIcons.error, size: 60),
            ),
            const SizedBox(height: 28),
            Text(
              'Failed to Load Queue',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: ThemeColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            NeuButton(
              text: 'Retry',
              onPressed: () {
                context.read<QueueBloc>().add(QueueStaffLoadRequested());
              },
              icon: Icons.refresh_rounded,
              svgAsset: SvgIcons.refresh,
              variant: NeuButtonVariant.primary,
              expanded: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffQueueView(QueueStaffLoaded state) {
    final queueEntries = state.queueEntries;

    return Column(
      children: [
        // Stats bar
        StatsBar(
          currentServing: state.currentServing,
          totalWaiting: state.totalWaiting,
          totalInRoom: state.totalInRoom,
        ),

        // Queue list
        Expanded(
          child: queueEntries.isEmpty
              ? _buildEmptyQueue()
              : RefreshIndicator(
                  onRefresh: () async {
                    context.read<QueueBloc>().add(QueueStaffLoadRequested());
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: queueEntries.length,
                    itemBuilder: (context, index) {
                      final entry = queueEntries[index];
                      return StaffQueueEntryCard(
                        entry: entry,
                        onPriorityChanged: (priority) {
                          context.read<QueueBloc>().add(
                            QueueSetPriorityRequested(
                              entry.queueEntry.id!,
                              priority,
                            ),
                          );
                        },
                        onCall: entry.queueEntry.status == QueueStatus.waiting
                            ? () => _showCallDialog(entry)
                            : null,
                        onMoveToRoom:
                            entry.queueEntry.status == QueueStatus.called
                            ? () => _showMoveToRoomDialog(entry)
                            : null,
                        onComplete:
                            entry.queueEntry.status == QueueStatus.inRoom
                            ? () => _showCompleteDialog(entry)
                            : null,
                        onSkip:
                            entry.queueEntry.status == QueueStatus.waiting ||
                                entry.queueEntry.status == QueueStatus.called
                            ? () => _showSkipDialog(entry)
                            : null,
                        onCancel:
                            entry.queueEntry.status == QueueStatus.waiting ||
                                entry.queueEntry.status == QueueStatus.called
                            ? () => _showCancelDialog(entry)
                            : null,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyQueue() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeuContainer(
              borderRadius: 70,
              padding: const EdgeInsets.all(30),
              color: ThemeColors.primary(context),
              boxShadow: NeuShadow.color(
                context,
                ThemeColors.primary(context),
                blur: 24,
                opacity: 0.32,
              ),
              child: NeuSvgIcon(SvgIcons.people, size: 60),
            ),
            const SizedBox(height: 28),
            Text(
              'No Patients in Queue',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Patients will appear here when they check in.\nPull to refresh.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: ThemeColors.textSecondary(context),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCallDialog(QueueEntryWithDetails entry) {
    NeuConfirmDialog.show(
      context: context,
      title: 'Call Patient',
      message:
          'Call ${entry.pet.name} (#${entry.queueEntry.position}) for their appointment?',
      confirmText: 'Call Now',
      cancelText: 'Cancel',
      confirmVariant: NeuButtonVariant.primary,
      onConfirm: () => context.read<QueueBloc>().add(QueueCallNextRequested()),
    );
  }

  void _showMoveToRoomDialog(QueueEntryWithDetails entry) {
    final roomController = TextEditingController(
      text: entry.queueEntry.room ?? '1',
    );
    NeuDialog.show(
      context: context,
      title: 'Move to Room',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Move ${entry.pet.name} to a room:'),
          const SizedBox(height: 16),
          NeuTextField(
            controller: roomController,
            label: 'Room Number',
            hint: 'e.g., 1, 2, A, B',
            autofocus: true,
          ),
        ],
      ),
      actions: [
        NeuButton(
          text: 'Cancel',
          variant: NeuButtonVariant.ghost,
          onPressed: () => context.pop(),
        ),
        NeuButton(
          text: 'Move',
          variant: NeuButtonVariant.primary,
          onPressed: () {
            final room = roomController.text.trim();
            context.pop();
            context.read<QueueBloc>().add(
              QueueMoveToRoomRequested(entry.queueEntry.id!, room),
            );
          },
        ),
      ],
    );
  }

  void _showCompleteDialog(QueueEntryWithDetails entry) {
    NeuConfirmDialog.show(
      context: context,
      title: 'Complete Visit',
      message: 'Mark ${entry.pet.name}\'s visit as completed?',
      confirmText: 'Complete',
      cancelText: 'Cancel',
      confirmVariant: NeuButtonVariant.primary,
      onConfirm: () => context.read<QueueBloc>().add(
        QueueCompleteRequested(entry.queueEntry.id!),
      ),
    );
  }

  void _showSkipDialog(QueueEntryWithDetails entry) {
    NeuConfirmDialog.show(
      context: context,
      title: 'Skip Patient',
      message: 'Skip ${entry.pet.name}? They will be removed from the queue.',
      confirmText: 'Skip',
      cancelText: 'Cancel',
      confirmVariant: NeuButtonVariant.destructive,
      onConfirm: () => context.read<QueueBloc>().add(
        QueueSkipRequested(entry.queueEntry.id!),
      ),
    );
  }

  void _showCancelDialog(QueueEntryWithDetails entry) {
    NeuConfirmDialog.show(
      context: context,
      title: 'Cancel Queue Entry',
      message:
          'Cancel ${entry.pet.name}\'s queue entry? This visit will not happen.',
      confirmText: 'Cancel Entry',
      cancelText: 'Keep',
      confirmVariant: NeuButtonVariant.destructive,
      onConfirm: () => context.read<QueueBloc>().add(
        QueueCancelRequested(entry.queueEntry.id!),
      ),
    );
  }
}
