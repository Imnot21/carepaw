import 'package:flutter/material.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../app/theme/theme_colors.dart';
import 'neu_shadows.dart';

/// The page shell every screen in CarePaw builds on.
///
/// Three things it fixes that were previously decided independently on all
/// thirty-eight pages:
///
/// 1. **One page padding.** [NeuTokens.pagePadding], everywhere.
/// 2. **One content width.** [NeuTokens.maxContentWidth], so a tablet or a
///    desktop window does not fling cards to opposite edges of the window.
/// 3. **One app bar.** [NeuPageAppBar], with the same height, the same title
///    scale, and actions that all hit the same 48dp target.
///
/// It also owns the safe area and the canvas colour, so a page never has to
/// remember either.
///
/// ```dart
/// NeuPage(
///   title: 'Pets',
///   actions: [NeuIconButton(icon: Icons.add_rounded, onPressed: _add)],
///   slivers: [ ... ],
/// )
/// ```
class NeuPage extends StatelessWidget {
  final String? title;
  final String? subtitle;

  /// Trailing app-bar controls. Keep these to two — a third belongs on the
  /// screen's own surface, not in the bar.
  final List<Widget>? actions;

  /// Rendered directly under the app bar, above the body. Used for filter bars
  /// and search fields that should scroll away with the content.
  final Widget? header;

  final Widget? body;
  final List<Widget>? slivers;

  /// Set false on a page that supplies its own bar — a greeting header, for
  /// instance, which is content rather than chrome.
  final bool showAppBar;

  /// Shown instead of [body] when [slivers] is null and [body] is null.
  final Widget? emptyState;

  final bool isLoading;

  final bool floatingAppBar;
  final Widget? bottomBar;
  final Widget? floatingActionButton;

  /// Allow the body to scroll. Set false when the body owns its own scrolling
  /// (a list, a form in a [SingleChildScrollView]).
  final bool scrollable;

  const NeuPage({
    super.key,
    this.title,
    this.subtitle,
    this.actions,
    this.header,
    this.body,
    this.slivers,
    this.emptyState,
    this.showAppBar = true,
    this.isLoading = false,
    this.floatingAppBar = false,
    this.bottomBar,
    this.floatingActionButton,
    this.scrollable = true,
  }) : assert(
         body != null || slivers != null || isLoading || emptyState != null,
         'NeuPage needs a body, slivers, an emptyState, or isLoading.',
       ),
       assert(
         slivers == null || !scrollable,
         'NeuPage takes either slivers or a scrollable body, not both.',
       );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      appBar: showAppBar && title != null
          ? NeuPageAppBar(
              title: title!,
              subtitle: subtitle,
              actions: actions,
              floating: floatingAppBar,
            )
          : null,
      body: SafeArea(top: !floatingAppBar, child: _buildBody(context)),
      bottomNavigationBar: bottomBar,
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildBody(BuildContext context) {
    Widget content;

    if (isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (slivers != null) {
      content = CustomScrollView(slivers: slivers!);
    } else if (body != null) {
      content = scrollable
          ? SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: body!,
            )
          : body!;
    } else {
      content = emptyState ?? const SizedBox.shrink();
    }

    if (header != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header!,
          Expanded(child: content),
        ],
      );
    }

    return _WidthConstrained(child: content);
  }
}

/// Caps content width and applies page padding exactly once.
///
/// A bare `Padding` here would also pad a [CustomScrollView]'s slivers, which
/// breaks `SliverAppBar` and sticky headers. Constraining width and letting each
/// sliver own its own padding is the arrangement that survives both.
class _WidthConstrained extends StatelessWidget {
  final Widget child;

  const _WidthConstrained({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: NeuTokens.maxContentWidth),
        child: child,
      ),
    );
  }
}

/// The app bar. One height, one title scale, one action target.
class NeuPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool floating;
  final Widget? leading;

  const NeuPageAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.floating = false,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(NeuTokens.appBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: floating
          ? ThemeColors.background(context)
          : ThemeColors.surface(context),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: NeuTokens.appBarHeight,
      automaticallyImplyLeading: false,
      leading: leading,
      titleSpacing: NeuTokens.pagePadding,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: AppTextStyles.bodySmall.subtleOf(
                Theme.of(context).brightness,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      actions: [
        for (final action in (actions ?? const <Widget>[]))
          Padding(
            padding: const EdgeInsets.only(right: NeuTokens.spaceXs),
            child: SizedBox(
              width: NeuTokens.minTapTarget,
              height: NeuTokens.minTapTarget,
              child: Center(child: action),
            ),
          ),
        const SizedBox(width: NeuTokens.spaceXxs),
      ],
    );
  }
}

/// A bar that genuinely floats over scrolling content.
///
/// Unlike [NeuPageAppBar] this one detaches: it takes a downward shadow once
/// content passes beneath it. Reserve it for screens where the bar genuinely
/// overlays a scrolling list and the separation earns the extra shadow.
class NeuFloatingBar extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const NeuFloatingBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: NeuTokens.spaceMd,
      vertical: NeuTokens.spaceXs,
    ),
    this.borderRadius = NeuTokens.radiusLg,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NeuTokens.spaceMd,
        NeuTokens.spaceXs,
        NeuTokens.spaceMd,
        NeuTokens.spaceSm,
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: ThemeColors.surface(context),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: NeuShadow.floating(context, distance: 6, blur: 18),
        ),
        child: child,
      ),
    );
  }
}
