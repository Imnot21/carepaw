import 'package:flutter/material.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/core/constants/app_constants.dart';

/// The privacy notice shown before sign-up and from Profile.
///
/// Written for the Data Privacy Act of 2012 (RA 10173): it tells the person
/// what is collected, why, who sees it, where it is stored, how long it is
/// kept and what rights they have. Registration records which version of
/// this notice the person accepted ([AppConstants.privacyNoticeVersion]), so
/// bump that constant whenever this text changes.
///
/// Reachable without signing in (the router lets `/privacy` through).
class PrivacyNoticePage extends StatelessWidget {
  const PrivacyNoticePage({super.key});

  static const String _clinic = AppConstants.clinicName;

  static const List<(String, List<String>)> _sections = [
    (
      'Who is responsible for your information',
      [
        '$_clinic in ${AppConstants.clinicLocation} runs CarePaw and decides '
            'how your information is used. For any privacy question or '
            'request, talk to the clinic at the front desk.',
      ],
    ),
    (
      'What we collect',
      [
        'About you: your full name, email address, and, if you give them, '
            'your phone number and address. Your password is handled by the '
            'sign-in service and the clinic never sees it.',
        'About your pets: name, species, breed, sex, birth date, weight, '
            'colour, markings and microchip number.',
        'Bookings and visits: the date, time, service, the reason you give, '
            'your notes for the vet, and the address for home visits.',
        'Health records the clinic writes: visits, findings, vaccines and '
            'medicines given to your pet.',
        'Your place in the clinic line and the notifications sent to you.',
      ],
    ),
    (
      'Why we use it',
      [
        'To book and confirm visits, call your pet in when it is their turn, '
            'keep your pet\'s health history in one place, and tell you about '
            'changes to your bookings.',
        'We do not sell your information, show you ads, or use it for '
            'anything unrelated to your pet\'s care at the clinic.',
      ],
    ),
    (
      'Who can see it',
      [
        'Only you and the clinic\'s staff accounts. Other pet owners cannot '
            'see your details, your pets or their records.',
        'We share information outside the clinic only when the law '
            'requires it.',
      ],
    ),
    (
      'Where it is stored',
      [
        'CarePaw keeps its data on Google Firebase. The database is in '
            'Google\'s Singapore data centre, and the sign-in service may '
            'store your email address in other countries. Google processes '
            'it for the clinic and may not use it for its own purposes.',
      ],
    ),
    (
      'How we protect it',
      [
        'You must sign in to see anything. Every request is checked on the '
            'server, so an account can only open its own pets and records. '
            'Data travels over an encrypted connection, and important '
            'clinic actions are logged.',
      ],
    ),
    (
      'How long we keep it',
      [
        'Your account stays while you use the clinic. If you ask, the clinic '
            'turns your account off and you can no longer sign in.',
        'Health records are part of your pet\'s medical history. They are '
            'never deleted, but a wrong entry can be corrected with a new one '
            'that replaces it.',
      ],
    ),
    (
      'Your rights',
      [
        'Under the Data Privacy Act of 2012 you have the right to be '
            'informed, to see the information we hold about you, to have '
            'wrong information corrected, to object, to have your '
            'information blocked or removed where the law allows, to get a '
            'copy of it, and to be paid for damages if it is misused.',
        'You can take back your consent at any time by asking the clinic to '
            'turn off your account. This does not undo what was done before.',
        'If you think your information was mishandled, you can complain to '
            'the National Privacy Commission at privacy.gov.ph.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final body = AppTextStyles.bodyMedium.copyWith(
      color: ThemeColors.textSecondary(context),
      height: 1.55,
    );
    final heading = AppTextStyles.titleMedium.copyWith(
      color: ThemeColors.textPrimary(context),
      fontWeight: FontWeight.w700,
    );

    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      appBar: AppBar(
        title: Text(
          'Privacy notice',
          style: AppTextStyles.appBarTitle.copyWith(
            color: ThemeColors.textPrimary(context),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            // Keep lines readable on tablets and the web build.
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                NeuTokens.pagePadding,
                NeuTokens.spaceSm,
                NeuTokens.pagePadding,
                NeuTokens.spaceXl,
              ),
              children: [
                Text(
                  'This explains what CarePaw keeps about you and your pets, '
                  'and what you can ask the clinic to do with it.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: ThemeColors.textPrimary(context),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: NeuTokens.spaceXs),
                Text(
                  'Version ${AppConstants.privacyNoticeVersion}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: ThemeColors.textTertiary(context),
                  ),
                ),
                for (final (title, paragraphs) in _sections) ...[
                  const SizedBox(height: NeuTokens.spaceLg),
                  Semantics(
                    header: true,
                    child: Text(title, style: heading),
                  ),
                  for (final p in paragraphs) ...[
                    const SizedBox(height: NeuTokens.spaceXs),
                    Text(p, style: body),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
