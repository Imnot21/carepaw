import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:carepaw/core/di/dependency_injection.dart';
import 'package:carepaw/features/app_update/presentation/bloc/app_update_cubit.dart';
import 'package:carepaw/features/app_update/presentation/widgets/update_dialog.dart';

/// Checks for a newer build once per app start and, when one exists, offers
/// it in a dialog. Wraps the signed-in shell so it runs after login.
class UpdatePrompt extends StatefulWidget {
  final Widget child;

  const UpdatePrompt({super.key, required this.child});

  @override
  State<UpdatePrompt> createState() => _UpdatePromptState();
}

class _UpdatePromptState extends State<UpdatePrompt> {
  AppUpdateCubit? _cubit;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    if (getIt.isRegistered<AppUpdateCubit>()) {
      _cubit = getIt<AppUpdateCubit>();
      // Let the first frame settle before reaching out.
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _cubit?.checkOnLaunch();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) return widget.child;
    return BlocListener<AppUpdateCubit, AppUpdateState>(
      bloc: cubit,
      listenWhen: (_, s) =>
          s.fromLaunch && s.status == AppUpdateStatus.available,
      listener: (context, _) {
        if (_shown) return;
        _shown = true;
        showUpdateDialog(context, cubit);
      },
      child: widget.child,
    );
  }
}
