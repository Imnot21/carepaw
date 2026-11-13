import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_avatar.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_dialog.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_feedback.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_motion.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_row.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_section.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_skeleton.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_state.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_switch.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_event.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_preferences_cubit.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_state.dart';
import 'package:carepaw/features/notifications/presentation/notification_alerts.dart';

/// Notification settings: which device alerts the signed-in user gets.
///
/// Needs a [NotificationPreferencesCubit] (the switches) and a
/// [NotificationBloc] (the clear action) above it.
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  /// True from the moment the user confirms the clear action until the bloc
  /// reports how it went.
  bool _clearing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      appBar: _buildAppBar(),
      body: MultiBlocListener(
        listeners: [
          BlocListener<
            NotificationPreferencesCubit,
            NotificationPreferencesState
          >(
            listenWhen: (previous, current) =>
                current.saveFailures > previous.saveFailures,
            listener: (context, _) => NeuToast.error(
              context,
              "Couldn't save that change. Check your connection and try again.",
            ),
          ),
          BlocListener<NotificationBloc, NotificationState>(
            listenWhen: (_, _) => _clearing,
            listener: _onClearResult,
          ),
        ],
        child:
            BlocBuilder<
              NotificationPreferencesCubit,
              NotificationPreferencesState
            >(
              builder: (context, state) {
                final preferences = state.preferences;
                if (state.status == NotificationPreferencesStatus.loadFailed ||
                    (preferences == null &&
                        state.status !=
                            NotificationPreferencesStatus.loading)) {
                  return Padding(
                    padding: const EdgeInsets.all(NeuTokens.pagePadding),
                    child: NeuErrorState(
                      message:
                          "Your notification settings didn't load. "
                          'Check your connection and try again.',
                      onRetry: context
                          .read<NotificationPreferencesCubit>()
                          .load,
                    ),
                  );
                }
                if (preferences == null) {
                  return const NeuSkeletonDetail(
                    padding: EdgeInsets.all(NeuTokens.pagePadding),
                  );
                }
                return _buildSettings(preferences);
              },
            ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 88,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leadingWidth: 64,
      titleSpacing: 0,
      leading: NeuIconButton(
        plain: true,
        icon: Icons.arrow_back_rounded,
        svgAsset: SvgIcons.back,
        tooltip: 'Back',
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Notification Settings',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: ThemeColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Choose which alerts reach this device',
            style: AppTextStyles.bodySmall.copyWith(
              color: ThemeColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(NotificationPreferences preferences) {
    final cubit = context.read<NotificationPreferencesCubit>();
    final alertsOn = NotificationAlerts.alertsEnabled(preferences);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        NeuTokens.pagePadding,
        NeuTokens.spaceMd,
        NeuTokens.pagePadding,
        120,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: NeuTokens.maxContentWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NeuListGroup(
                children: [
                  _SwitchRow(
                    svgAsset: SvgIcons.notifications,
                    avatarColor: ThemeColors.primary(context),
                    avatarForeground: ThemeColors.onPrimary(context),
                    title: 'Device Alerts',
                    subtitle: 'Show a banner when something new arrives',
                    value: alertsOn,
                    // The master switch writes both stored flags, so they
                    // cannot disagree.
                    onChanged: (value) => cubit.change(
                      (current) => current.copyWith(
                        inAppEnabled: value,
                        pushEnabled: value,
                      ),
                    ),
                  ),
                ],
              ),
              NeuSection(
                title: 'Notification Categories',
                child: NeuListGroup(
                  children: [
                    _SwitchRow(
                      svgAsset: SvgIcons.calendar,
                      title: 'Appointment Reminders',
                      subtitle: 'Booking confirmations, reminders, and changes',
                      value: preferences.appointmentReminders,
                      enabled: alertsOn,
                      showDivider: true,
                      onChanged: (value) => cubit.change(
                        (current) =>
                            current.copyWith(appointmentReminders: value),
                      ),
                    ),
                    _SwitchRow(
                      svgAsset: SvgIcons.queue,
                      title: 'Queue Updates',
                      subtitle: 'Position changes and your turn',
                      value: preferences.queueUpdates,
                      enabled: alertsOn,
                      onChanged: (value) => cubit.change(
                        (current) => current.copyWith(queueUpdates: value),
                      ),
                    ),
                    // PAPER-ONLY: inventory, prescription, and system
                    // categories stay in code/back-end but are hidden from
                    // the thesis demo UI.
                  ],
                ),
              ),
              const SizedBox(height: NeuTokens.tightGap),
              Text(
                alertsOn
                    ? 'A muted category still appears in your notification '
                          'list.'
                    : 'Device alerts are off. New notifications still appear '
                          'in your notification list.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: ThemeColors.textSecondary(context),
                ),
              ),
              NeuSection(
                title: 'Data Management',
                child: Semantics(
                  button: true,
                  child: NeuCard(
                    padding: EdgeInsets.zero,
                    onTap: _confirmClearOld,
                    child: _RowBody(
                      svgAsset: SvgIcons.delete,
                      avatarColor: ThemeColors.warning(
                        context,
                      ).withValues(alpha: 0.12),
                      avatarForeground: ThemeColors.warning(context),
                      title: 'Clear Old Notifications',
                      subtitle: 'Delete notifications older than 30 days',
                      trailing: NeuSvgIcon(SvgIcons.chevronRight, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClearOld() async {
    final confirmed = await NeuConfirmDialog.show(
      context: context,
      title: 'Clear Old Notifications',
      message:
          'Delete every notification older than 30 days? '
          'You cannot undo this.',
      confirmText: 'Clear',
      confirmVariant: NeuButtonVariant.destructive,
    );
    if (!mounted || confirmed != true) return;
    _clearing = true;
    context.read<NotificationBloc>().add(const DeleteAllReadNotifications());
  }

  /// Report the clear action only after the bloc says how it went.
  void _onClearResult(BuildContext context, NotificationState state) {
    if (state is AllReadNotificationsDeleted) {
      _clearing = false;
      NeuToast.success(context, 'Old notifications cleared');
    } else if (state is NotificationError) {
      _clearing = false;
      NeuToast.error(
        context,
        "Couldn't clear old notifications. Check your connection and try "
        'again.',
      );
    }
  }
}

/// A settings row with a switch. A tap anywhere on the row flips it.
class _SwitchRow extends StatelessWidget {
  final String svgAsset;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// False when a switch above this one makes it irrelevant. The row keeps its
  /// saved value and shows it dimmed.
  final bool enabled;
  final bool showDivider;
  final Color? avatarColor;
  final Color? avatarForeground;

  const _SwitchRow({
    required this.svgAsset,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.showDivider = false,
    this.avatarColor,
    this.avatarForeground,
  });

  @override
  Widget build(BuildContext context) {
    final VoidCallback? toggle = enabled
        ? () {
            HapticFeedback.selectionClick();
            onChanged(!value);
          }
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          container: true,
          toggled: value,
          enabled: enabled,
          label: '$title. $subtitle',
          onTap: toggle,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: toggle,
            behavior: HitTestBehavior.opaque,
            child: AnimatedOpacity(
              opacity: enabled ? 1 : NeuTokens.opacityDisabled,
              duration: NeuMotion.duration(context, NeuTokens.durationMedium),
              curve: NeuTokens.curveDefault,
              child: _RowBody(
                svgAsset: svgAsset,
                avatarColor: avatarColor,
                avatarForeground: avatarForeground,
                title: title,
                subtitle: subtitle,
                // The row owns the dimming, so the switch is only made inert.
                trailing: NeuSwitch(
                  value: value,
                  onChanged: enabled ? onChanged : null,
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: _RowBody.textIndent,
            color: ThemeColors.divider(context),
          ),
      ],
    );
  }
}

/// Icon disc, title, subtitle, and a trailing control: the shape every row on
/// this screen shares.
class _RowBody extends StatelessWidget {
  static const double _avatarRadius = 18;

  /// Where the text starts, so a divider can line up with it.
  static const double textIndent =
      NeuTokens.spaceMd + _avatarRadius * 2 + NeuTokens.tightGap;

  final String svgAsset;
  final String title;
  final String subtitle;
  final Widget trailing;
  final Color? avatarColor;
  final Color? avatarForeground;

  const _RowBody({
    required this.svgAsset,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.avatarColor,
    this.avatarForeground,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NeuTokens.spaceMd,
          vertical: NeuTokens.spaceSm,
        ),
        child: Row(
          children: [
            NeuAvatar(
              radius: _avatarRadius,
              svgAsset: svgAsset,
              backgroundColor:
                  avatarColor ?? ThemeColors.surfaceVariant(context),
              foregroundColor:
                  avatarForeground ?? ThemeColors.primary(context),
            ),
            const SizedBox(width: NeuTokens.tightGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: ThemeColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: NeuTokens.spaceXs),
            trailing,
          ],
        ),
      ),
    );
  }
}
