import 'package:flutter/material.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_feedback.dart';
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
import 'package:carepaw/core/widgets/neomorphism/neu_skeleton.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_state.dart';
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
              'Line',
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
                padding: const EdgeInsets.only(right: NeuTokens.spaceMd),
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
                NeuToast.success(context, state.message);
                // Reload queue after successful operation
                context.read<QueueBloc>().add(QueueStaffLoadRequested());
              } else if (state is QueueError) {
                NeuToast.error(context, _friendlyError);
              }
            },
            builder: (context, state) {
              if (state is QueueLoading) {
                return const NeuSkeletonList();
              }

              if (state is QueueError) {
                return _buildErrorState();
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
              padding: const EdgeInsets.all(32),
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

  static const _friendlyError =
      'We could not update the queue. Check your connection and try again.';

  Widget _buildErrorState() {
    return NeuErrorState(
      title: 'Could not load the queue',
      message: _friendlyError,
      svgAsset: SvgIcons.error,
      onRetry: () => context.read<QueueBloc>().add(QueueStaffLoadRequested()),
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
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: NeuTokens.maxContentWidth,
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          NeuTokens.pagePadding,
                          NeuTokens.spaceXs,
                          NeuTokens.pagePadding,
                          100,
                        ),
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
                            // "Call" runs callNext, which calls the head of
                            // the waiting line, so only that card offers it.
                            onCall:
                                entry.queueEntry.id != null &&
                                    entry.queueEntry.id ==
                                        _nextWaitingId(queueEntries)
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
                                entry.queueEntry.status ==
                                        QueueStatus.waiting ||
                                    entry.queueEntry.status ==
                                        QueueStatus.called
                                ? () => _showSkipDialog(entry)
                                : null,
                            onCancel:
                                entry.queueEntry.status ==
                                        QueueStatus.waiting ||
                                    entry.queueEntry.status ==
                                        QueueStatus.called
                                ? () => _showCancelDialog(entry)
                                : null,
                          );
                        },
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyQueue() {
    return const NeuEmptyState(
      icon: Icons.people_outline,
      svgAsset: SvgIcons.people,
      title: 'No one is waiting',
      message:
          'Pets appear here once they check in at the desk. Pull down to refresh.',
    );
  }

  /// Id of the entry `callNext` will call: the first waiting entry in queue
  /// order (the same sort the repository uses).
  int? _nextWaitingId(List<QueueEntryWithDetails> entries) {
    final waiting = entries.map((e) => e.queueEntry).where((e) => e.isWaiting)
        .toList()
      ..sort(QueueEntry.byQueueOrder);
    return waiting.isEmpty ? null : waiting.first.id;
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
            if (room.isEmpty) return;
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
