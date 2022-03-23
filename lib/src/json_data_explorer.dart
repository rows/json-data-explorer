import 'package:data_explorer/src/data_explorer_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'data_explorer_store.dart';

/// Signature for a function that creates a widget based on a
/// [NodeViewModelState] state.
///
/// Used by [_JsonAttribute.rootInformationBuilder].
///
typedef NodeBuilder = Widget Function(
    BuildContext context, NodeViewModelState node);

class JsonDataExplorer extends StatelessWidget {
  final Iterable<NodeViewModelState> nodes;
  final ItemScrollController? itemScrollController;
  final ItemPositionsListener? itemPositionsListener;
  final DataExplorerTheme theme;

  /// A builder to add a widget as a suffix for root nodes.
  ///
  /// This can be used to display useful information such as the number of
  /// children nodes, or to indicate if the node is class or an array
  /// for example.
  final NodeBuilder? rootInformationBuilder;

  /// Build the expand/collapse icons in root nodes.
  ///
  /// If this builder is null, a material [Icons.arrow_right] is displayed for
  /// collapsed nodes and [Icons.arrow_drop_down] for expanded nodes.
  final NodeBuilder? collapsableToggleBuilder;

  const JsonDataExplorer({
    Key? key,
    required this.nodes,
    this.itemScrollController,
    this.itemPositionsListener,
    this.rootInformationBuilder,
    this.collapsableToggleBuilder,
    DataExplorerTheme? theme,
  })  : theme = theme ?? DataExplorerTheme.defaultTheme,
        super(key: key);

  @override
  Widget build(BuildContext context) => ScrollablePositionedList.builder(
        itemCount: nodes.length,
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
        itemBuilder: (context, index) => AnimatedBuilder(
          animation: nodes.elementAt(index),
          builder: (context, child) => DecoratedBox(
            decoration: BoxDecoration(
              color: nodes.elementAt(index).isHighlighted
                  ? theme.highlightColor
                  : null,
            ),
            child: child,
          ),
          child: _JsonAttribute(
            node: nodes.elementAt(index),
            rootInformationBuilder: rootInformationBuilder,
            collapsableToggleBuilder: collapsableToggleBuilder,
            valueStyle: theme.valueTextStyle ??
                DataExplorerTheme.defaultTheme.valueTextStyle!,
            attributeKeyStyle: theme.keyTextStyle ??
                DataExplorerTheme.defaultTheme.keyTextStyle!,
            indentationLineColor: theme.indentationLineColor,
          ),
        ),
      );
}

class _JsonAttribute extends StatelessWidget {
  final NodeViewModelState node;
  final double indentationPadding;
  final TextStyle attributeKeyStyle;
  final TextStyle valueStyle;

  /// A builder to add a widget as a suffix for root nodes.
  ///
  /// This can be used to display useful information such as the number of
  /// children nodes, or to indicate if the node is class or an array
  /// for example.
  final NodeBuilder? rootInformationBuilder;

  /// Build the expand/collapse icons in root nodes.
  ///
  /// If this builder is null, a material [Icons.arrow_right] is displayed for
  /// collapsed nodes and [Icons.arrow_drop_down] for expanded nodes.
  final NodeBuilder? collapsableToggleBuilder;

  /// Color of the indentation guide lines.
  final Color indentationLineColor;

  const _JsonAttribute({
    Key? key,
    required this.node,
    required this.attributeKeyStyle,
    required this.valueStyle,
    this.indentationPadding = 8.0,
    this.rootInformationBuilder,
    this.collapsableToggleBuilder,
    this.indentationLineColor = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final searchTerm =
        context.select<DataExplorerStore, String>((store) => store.searchTerm);
    final isSearchFocused = context.select<DataExplorerStore, bool>((store) =>
        store.searchResults.isNotEmpty
            ? store.searchResults.elementAt(store.searchNodeFocusIndex) == node
            : false);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (event) => node.highlight(true),
      onExit: (event) => node.highlight(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTap(context),
        child: AnimatedBuilder(
          animation: node,

          /// IntrinsicHeight is not the best solution for this, the performance
          /// hit that we measured is ok for now. We will revisit this in the
          /// future if we fill that we need to improve the node rendering
          /// performance.
          builder: (context, child) => IntrinsicHeight(
            child: Row(
              crossAxisAlignment: node.isRoot
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                _Indentation(
                  node: node,
                  indentationPadding: indentationPadding,
                  lineColor: indentationLineColor,
                ),
                if (node.isRoot)
                  SizedBox(
                    width: 24,
                    child: collapsableToggleBuilder?.call(context, node) ??
                        _defaultCollapsableToggleBuilder(context, node),
                  ),
                _HighlightedText(
                  text: '${node.key}: ',
                  highlightedText: searchTerm,
                  style: attributeKeyStyle,
                  highlightedStyle: attributeKeyStyle.copyWith(
                    backgroundColor:
                        isSearchFocused ? Colors.deepPurpleAccent : Colors.grey,
                  ),
                ),
                if (node.isRoot)
                  rootInformationBuilder?.call(context, node) ??
                      const SizedBox()
                else
                  Expanded(
                    child: _HighlightedText(
                      text: node.value.toString(),
                      highlightedText: searchTerm,
                      style: valueStyle,
                      highlightedStyle: valueStyle.copyWith(
                        backgroundColor: isSearchFocused
                            ? Colors.deepPurpleAccent
                            : Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future _onTap(BuildContext context) async {
    final dataExplorerStore = Provider.of<DataExplorerStore>(
      context,
      listen: false,
    );
    if (node.isCollapsed) {
      dataExplorerStore.expandNode(node);
    } else {
      dataExplorerStore.collapseNode(node);
    }
  }

  /// Default value for [collapsableToggleBuilder]
  ///
  /// A material [Icons.arrow_right] is displayed for collapsed nodes and
  /// [Icons.arrow_drop_down] for expanded nodes.
  static Widget _defaultCollapsableToggleBuilder(
          BuildContext context, NodeViewModelState node) =>
      node.isCollapsed
          ? const Icon(
              Icons.arrow_right,
            )
          : const Icon(
              Icons.arrow_drop_down,
            );
}

/// Creates the indentation lines and padding of each node depending on its
/// [node.treeDepth] and whether or not the node is a root node.
class _Indentation extends StatelessWidget {
  /// Current node view model
  final NodeViewModelState node;

  /// The padding of each indentation, this change the spacing between each
  /// [node.treeDepth] and the spacing between lines.
  final double indentationPadding;

  /// Color used to render the indentation lines.
  final Color lineColor;

  /// A padding factor to be applied on non root nodes, so its properties have
  /// extra padding steps.
  final double propertyPaddingFactor;

  const _Indentation({
    Key? key,
    required this.node,
    required this.indentationPadding,
    this.lineColor = Colors.grey,
    this.propertyPaddingFactor = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const lineWidth = 1.0;
    return Row(
      children: [
        for (int i = 0; i < node.treeDepth; i++)
          Container(
            margin: EdgeInsets.only(
              right: indentationPadding,
            ),
            width: lineWidth,
            color: lineColor,
          ),
        if (!node.isRoot)
          SizedBox(
            width: indentationPadding * propertyPaddingFactor,
          ),
        if (node.isRoot && !node.isCollapsed) ...[
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.52,
              child: Container(
                width: 1,
                color: lineColor,
              ),
            ),
          ),
          Container(
            height: lineWidth,
            width: (indentationPadding / 2) - lineWidth,
            color: lineColor,
          ),
        ],
        if (node.isRoot && node.isCollapsed)
          SizedBox(
            width: indentationPadding / 2,
          ),
      ],
    );
  }
}

/// Highlights found occurrences of [highlightedText] with [highlightedStyle]
/// in [text].
class _HighlightedText extends StatelessWidget {
  final String text;
  final String highlightedText;
  final TextStyle style;
  final TextStyle highlightedStyle;
  final TextAlign textAlign;

  const _HighlightedText({
    Key? key,
    required this.text,
    required this.highlightedText,
    required this.style,
    required this.highlightedStyle,
    this.textAlign = TextAlign.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lowerCaseText = text.toLowerCase();
    final lowerCaseQuery = highlightedText.toLowerCase();
    if (highlightedText.isEmpty || !lowerCaseText.contains(lowerCaseQuery)) {
      return Text(text, style: style);
    }

    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      var index = lowerCaseText.indexOf(lowerCaseQuery, start);
      index = index >= 0 ? index : text.length;

      if (start != index) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: style,
          ),
        );
      }

      if (index >= text.length) {
        break;
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + highlightedText.length),
          style: highlightedStyle,
        ),
      );
      start = index + highlightedText.length;
    }

    return RichText(
      text: TextSpan(
        children: spans,
      ),
      textAlign: textAlign,
    );
  }
}