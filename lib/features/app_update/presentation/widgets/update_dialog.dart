import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/theme_colors.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_dialog.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/features/app_update/presentation/bloc/app_update_cubit.dart';

/// Shows the update dialog bound to [cubit]: the new version, its notes, and
/// an Update button that downloads and opens the installer (or reloads web).
Future<void> showUpdateDialog(BuildContext context, AppUpdateCubit cubit) {
  return NeuDialog.show<void>(
    context: context,
    title: 'Update available',
    barrierDismissible: false,
    content: BlocProvider.value(value: cubit, child: const _UpdateBody()),
    actions: [
      BlocProvider.value(value: cubit, child: const _UpdateActions()),
    ],
  );
}

class _UpdateBody extends StatelessWidget {
  const _UpdateBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppUpdateCubit, AppUpdateState>(
      builder: (context, state) {
        final textStyle = AppTextStyles.bodyMedium.copyWith(
          color: ThemeColors.textPrimary(context),
        );
        final subtle = AppTextStyles.bodySmall.subtleOf(
          Theme.of(context).brightness,
        );
        final notes = state.release?.notes ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CarePaw ${state.release?.version ?? ''} is ready. '
              'You have ${state.currentVersion ?? 'an older version'}.',
              style: textStyle,
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(child: Text(notes, style: subtle)),
              ),
            ],
            if (state.status == AppUpdateStatus.downloading) ...[
              const SizedBox(height: 16),
              NeuProgress(value: state.progress.clamp(0, 1).toDouble()),
              const SizedBox(height: 6),
              Text(
                'Downloading… ${(state.progress * 100).round()}%',
                style: subtle,
              ),
            ],
            if (state.status == AppUpdateStatus.installing) ...[
              const SizedBox(height: 16),
              Text(
                'Tap Install on the next screen to finish.',
                style: textStyle,
              ),
            ],
            if (state.status == AppUpdateStatus.failed &&
                state.message != null) ...[
              const SizedBox(height: 16),
              Text(
                state.message!,
                style: subtle.copyWith(color: ThemeColors.error(context)),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _UpdateActions extends StatelessWidget {
  const _UpdateActions();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppUpdateCubit, AppUpdateState>(
      builder: (context, state) {
        final busy = state.status == AppUpdateStatus.downloading;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NeuButton(
              text: kIsWeb
                  ? 'Reload now'
                  : state.status == AppUpdateStatus.failed
                  ? 'Try again'
                  : state.status == AppUpdateStatus.installing
                  ? 'Open installer again'
                  : 'Update now',
              variant: NeuButtonVariant.primary,
              isLoading: busy,
              onPressed: busy ? null : context.read<AppUpdateCubit>().install,
            ),
            const SizedBox(height: 8),
            NeuButton(
              text: 'Later',
              variant: NeuButtonVariant.ghost,
              isDisabled: busy,
              onPressed: busy ? null : () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
