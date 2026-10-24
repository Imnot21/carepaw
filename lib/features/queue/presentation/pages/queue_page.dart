import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_bloc.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_event.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_state.dart';
import 'package:carepaw/features/queue/presentation/widgets/queue_widgets.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_skeleton.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: ThemeColors.success(context),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(NeuTokens.radiusSm),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              } else if (state is QueueError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: ThemeColors.error(context),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(NeuTokens.radiusSm),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is QueueLoading) {
                return const NeuSkeletonList();
              }

              if (state is QueueError) {
                return _buildErrorState(state.message);
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
          const SizedBox(height: 28),
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

    // Calculate estimated wait time
    final estimatedWait = _calculateEstimatedWait(state);

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
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 96, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EmptyQueueCard(),
                      const SizedBox(height: 28),
                      UpcomingCheckInSection(queueEntries: state.queueEntries),
                      const SizedBox(height: 28),
                      QueueInfoCard(),
                    ],
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
        padding: const EdgeInsets.fromLTRB(20, 96, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Position Card
            if (isInQueue) ...[
              PositionCard(
                position: userPosition,
                petsAhead: petsAhead,
                estimatedWaitMinutes: estimatedWait,
              ),
              const SizedBox(height: 28),
            ] else ...[
              NotInQueueCard(),
              const SizedBox(height: 28),
            ],

            // Your Pets in Queue
            if (hasQueueEntries) ...[
              Text(
                'Your Pets in Queue',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...state.queueEntries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: QueueEntryCard(entry: entry, isCurrentUser: true),
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Queue Info
            QueueInfoCard(),
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
              padding: const EdgeInsets.all(28),
              color: ThemeColors.error(context),
              boxShadow: NeuShadow.color(
                context,
                ThemeColors.error(context),
                blur: 24,
                opacity: 0.32,
              ),
              child: NeuSvgIcon(SvgIcons.error, size: 70),
            ),
            const SizedBox(height: 28),
            Text(
              'Failed to Load Queue',
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.bodyMedium.subtleOf(
                Theme.of(context).brightness,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            NeuButton(
              text: 'Retry',
              onPressed: () {
                context.read<QueueBloc>().add(QueueLoadRequested());
              },
              icon: Icons.refresh_rounded,
              svgAsset: SvgIcons.refresh,
              variant: NeuButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }

  int? _calculateEstimatedWait(QueueLoaded state) {
    if (state.petsAhead == null || state.petsAhead! <= 0) {
      return null;
    }
    // Rough estimate: 15 minutes per pet ahead
    return state.petsAhead! * 15;
  }
}
