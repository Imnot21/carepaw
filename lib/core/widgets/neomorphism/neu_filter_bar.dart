import 'package:flutter/material.dart';
import '../../../app/theme/design_tokens.dart';
import 'neu_page.dart';

/// A search field plus a scrolling row of filter chips.
///
/// List screens each assembled this differently — some had a search field and no
/// filters, some had filters and a plain header, some put the search inside the
/// card grid. This is the one arrangement, and it floats: a filter bar that
/// scrolls away with the content forces the user to scroll back up to change
/// what they are looking at.
///
/// The chips scroll horizontally rather than wrapping. A wrapping filter row
/// changes height as filters are added and removed, which reflows the list
/// underneath it mid-interaction.
class NeuFilterBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;

  /// Rendered when [onSearchChanged] is null, which disables the field rather
  /// than showing a control that does nothing.
  final bool readOnlySearch;

  final List<Widget> chips;
  final VoidCallback? onClear;

  const NeuFilterBar({
    super.key,
    this.controller,
    this.onSearchChanged,
    this.searchHint = 'Search',
    this.readOnlySearch = false,
    this.chips = const [],
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return NeuFloatingBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            onChanged: onSearchChanged,
            readOnly: readOnlySearch,
            textInputAction: TextInputAction.search,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: searchHint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: NeuTokens.spaceMd,
                vertical: NeuTokens.spaceSm + 2,
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon:
                  (controller?.text.isNotEmpty ?? false) || onClear != null
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: 'Clear search',
                      onPressed: onClear,
                    )
                  : null,
            ),
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: NeuTokens.tightGap),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: chips.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: NeuTokens.spaceXs),
                itemBuilder: (_, index) => chips[index],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A row of the page's own filters, when a page has filters but no search.
///
/// Same scroll-not-wrap reasoning as [NeuFilterBar] — a filter row that changes
/// height reflows the list beneath it while the user is tapping it.
class NeuChipRow extends StatelessWidget {
  final List<Widget> chips;
  final EdgeInsetsGeometry padding;

  const NeuChipRow({
    super.key,
    required this.chips,
    this.padding = const EdgeInsets.symmetric(
      horizontal: NeuTokens.pagePadding,
      vertical: NeuTokens.spaceXs,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: padding,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: NeuTokens.spaceXs),
        itemBuilder: (_, index) => chips[index],
      ),
    );
  }
}
