import 'package:flutter/material.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_feedback.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_bloc.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_event.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_state.dart';
import 'package:carepaw/features/queue/presentation/widgets/queue_widgets.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_state.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_skeleton.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';

/// Queue page for pet owners - shows their position and wait time
class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  @override
  void initState() {
    super.initState();

    // Load queue when page initializes
    context.read<QueueBloc>().add(QueueLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const NotLoggedInView();
        }

        final user = authState.user;
        final isPetOwner = user.role == UserRole.petOwner;

        if (!isPetOwner) {
          return const AccessDeniedView();
        }

        return Scaffold(
          backgroundColor: ThemeColors.background(context),
          appBar: AppBar(
            title: Text(
              'Queue status',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            // Reload happens via pull-to-refresh (RefreshIndicator) instead of a button.
          ),
          body: BlocConsumer<QueueBloc, QueueState>(
            listener: (context, state) {
              if (state is QueueOperationSuccess) {
                NeuToast.success(context, state.message);
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

              if (state is QueueLoaded) {
                return _buildQueueView(state);
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NeuContainer(
            variant: NeuVariant.inset,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(NeuTokens.spaceLg),
            child: NeuSvgIcon(SvgIcons.queue, size: 48),
          ),
          const SizedBox(height: NeuTokens.sectionGap),
          Text(
            'Queue Status',
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Pull to refresh or wait for updates',
            style: AppTextStyles.bodyLarge
                .subtleOf(Theme.of(context).brightness)
                .copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQueueView(QueueLoaded state) {
    final hasQueueEntries = state.queueEntries.isNotEmpty;
    final userPosition = state.userPosition;
    final petsAhead = state.petsAhead;
    final isInQueue = userPosition != null && userPosition > 0;

    Future<void> refresh() async {
      context.read<QueueBloc>().add(QueueLoadRequested());
    }

    // No pets in the queue (and the user isn't currently queued): center the
    // empty state vertically, consistent with the other pages, instead of
    // pinning it under the app bar. Still scrollable + pull-to-refresh.
    if (!hasQueueEntries && !isInQueue) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: NeuTokens.maxContentWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      NeuTokens.pagePadding,
                      NeuTokens.spaceMd,
                      NeuTokens.pagePadding,
                      NeuTokens.spaceXl,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EmptyQueueCard(),
                        const SizedBox(height: NeuTokens.spaceMd),
                        UpcomingCheckInSection(
                          queueEntries: state.queueEntries,
                        ),
                        const SizedBox(height: NeuTokens.spaceMd),
                        QueueInfoCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          NeuTokens.pagePadding,
          NeuTokens.spaceMd,
          NeuTokens.pagePadding,
          NeuTokens.spaceXl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: NeuTokens.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Position Card
                if (isInQueue) ...[
                  PositionCard(
                    position: userPosition,
                    // No minutes estimate: visit length varies, and a guessed
                    // number would mislead owners. "Pets ahead" is exact.
                    petsAhead: petsAhead,
                  ),
                  const SizedBox(height: NeuTokens.sectionGap),
                ] else ...[
                  NotInQueueCard(),
                  const SizedBox(height: NeuTokens.sectionGap),
                ],

                // Your Pets in Queue
                if (hasQueueEntries) ...[
                  Text(
                    'Your Pets in Queue',
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: NeuTokens.spaceMd),
                  ...state.queueEntries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: NeuTokens.tightGap,
                      ),
                      child: QueueEntryCard(entry: entry, isCurrentUser: true),
                    ),
                  ),
                  const SizedBox(height: NeuTokens.sectionGap),
                ],

                // Queue Info
                QueueInfoCard(),
              ],
            ),
          ),
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
      onRetry: () => context.read<QueueBloc>().add(QueueLoadRequested()),
    );
  }
}
