import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import 'editable_text_line.dart';
import 'editor.dart';
import 'embed_proxy.dart';
import 'rich_text_proxy.dart';
import 'theme.dart';

/// Line of text in Zefyr editor.
///
/// This widget allows to render non-editable line of rich text, but can be
/// wrapped with [EditableTextLine] which adds editing features.
class TextLine extends StatelessWidget {
  /// Line of text represented by this widget.
  final LineNode node;
  final ZefyrEmbedBuilder embedBuilder;

  const TextLine({
    Key? key,
    required this.node,
    required this.embedBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    if (node.hasEmbed) {
      final embed = node.children.single as EmbedNode;
      return EmbedProxy(child: embedBuilder(context, embed));
    }
    final text = buildText(context, node);
    final strutStyle =
        StrutStyle.fromTextStyle(text.style!, forceStrutHeight: true);
    return RichTextProxy(
      textStyle: text.style!,
      strutStyle: strutStyle,
      locale: Localizations.maybeLocaleOf(context),
      child: RichText(
        text: buildText(context, node),
        strutStyle: strutStyle,
        textScaleFactor: MediaQuery.textScaleFactorOf(context),
      ),
    );
  }

  TextSpan buildText(BuildContext context, LineNode node) {
    final theme = ZefyrTheme.of(context)!;
    final children = node.children
        .map((node) => _segmentToTextSpan(node, theme))
        .toList(growable: false);
    return TextSpan(
      style: _getParagraphTextStyle(node.style, theme),
      children: children,
    );
  }

  TextSpan _segmentToTextSpan(Node segment, ZefyrThemeData theme) {
    final text = segment as TextNode;
    final attrs = text.style;

    return TextSpan(
      text: text.value,
      style: _getInlineTextStyle(attrs, node.style, theme),
    );
  }

  TextStyle _getParagraphTextStyle(NotusStyle style, ZefyrThemeData theme) {
    var textStyle = const TextStyle();
    final heading = node.style.get(NotusAttribute.heading);
    if (heading == NotusAttribute.heading.level1) {
      textStyle = textStyle.merge(theme.heading1.style);
    } else if (heading == NotusAttribute.heading.level2) {
      textStyle = textStyle.merge(theme.heading2.style);
    } else if (heading == NotusAttribute.heading.level3) {
      textStyle = textStyle.merge(theme.heading3.style);
    } else {
      textStyle = textStyle.merge(theme.paragraph.style);
    }

    final block = style.get(NotusAttribute.block);
    if (block == NotusAttribute.block.quote) {
      textStyle = textStyle.merge(theme.quote.style);
    } else if (block == NotusAttribute.block.code) {
      textStyle = textStyle.merge(theme.code.style);
    } else if (block != null) {
      // lists
      textStyle = textStyle.merge(theme.lists.style);
    }

    return textStyle;
  }

  TextStyle _getInlineTextStyle(
      NotusStyle nodeStyle, NotusStyle lineStyle, ZefyrThemeData theme) {
    var result = const TextStyle();
    if (nodeStyle.containsSame(NotusAttribute.bold)) {
      result = _mergeTextStyleWithDecoration(result, theme.bold);
    }
    if (nodeStyle.containsSame(NotusAttribute.italic)) {
      result = _mergeTextStyleWithDecoration(result, theme.italic);
    }
    if (nodeStyle.contains(NotusAttribute.link)) {
      result = _mergeTextStyleWithDecoration(result, theme.link);
    }
    if (nodeStyle.contains(NotusAttribute.underline)) {
      result = _mergeTextStyleWithDecoration(result, theme.underline);
    }
    if (nodeStyle.contains(NotusAttribute.strikethrough)) {
      result = _mergeTextStyleWithDecoration(result, theme.strikethrough);
    }
    if (nodeStyle.contains(NotusAttribute.inlineCode)) {
      result = _mergeTextStyleWithDecoration(
          result, theme.inlineCode.styleFor(lineStyle));
    }
    return result;
  }

  TextStyle _mergeTextStyleWithDecoration(TextStyle a, TextStyle? b) {
    var decorations = <TextDecoration>[];
    if (a.decoration != null) {
      decorations.add(a.decoration!);
    }
    if (b?.decoration != null) {
      decorations.add(b!.decoration!);
    }
    return a.merge(b).apply(decoration: TextDecoration.combine(decorations));
  }
}
