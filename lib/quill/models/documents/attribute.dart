import 'package:quiver/core.dart';

enum AttributeScope {
  INLINE, // refer to https://quilljs.com/docs/formats/#inline
  BLOCK, // refer to https://quilljs.com/docs/formats/#block
}

class Attribute<T> {
  Attribute(this.key, this.scope, this.value);

  final String key;
  final AttributeScope scope;
  final T value;

  static final Map<String, Attribute> _registry = {
    Attribute.bold.key: Attribute.bold,
    Attribute.italic.key: Attribute.italic,
    Attribute.underline.key: Attribute.underline,
    Attribute.strikeThrough.key: Attribute.strikeThrough,
    Attribute.font.key: Attribute.font,
    Attribute.size.key: Attribute.size,
    Attribute.color.key: Attribute.color,
    Attribute.background.key: Attribute.background,
    Attribute.placeholder.key: Attribute.placeholder,
    Attribute.header.key: Attribute.header,
    Attribute.indent.key: Attribute.indent,
    Attribute.align.key: Attribute.align,
    Attribute.list.key: Attribute.list,
    Attribute.codeBlock.key: Attribute.codeBlock,
    Attribute.markdownBlock.key: Attribute.markdownBlock,
    Attribute.blockQuote.key: Attribute.blockQuote,
  };

  static final BoldAttribute bold = BoldAttribute();

  static final ItalicAttribute italic = ItalicAttribute();

  static final UnderlineAttribute underline = UnderlineAttribute();

  static final StrikeThroughAttribute strikeThrough = StrikeThroughAttribute();

  static final FontAttribute font = FontAttribute(null);

  static final SizeAttribute size = SizeAttribute(null);

  static final ColorAttribute color = ColorAttribute(null);

  static final BackgroundAttribute background = BackgroundAttribute(null);

  static final PlaceholderAttribute placeholder = PlaceholderAttribute();

  static final HeaderAttribute header = HeaderAttribute();

  static final IndentAttribute indent = IndentAttribute();

  static final AlignAttribute align = AlignAttribute(null);

  static final ListAttribute list = ListAttribute(null);

  static final CodeBlockAttribute codeBlock = CodeBlockAttribute();

  static final MarkdownBlockAttribute markdownBlock = MarkdownBlockAttribute();

  static final BlockQuoteAttribute blockQuote = BlockQuoteAttribute();

  static final Set<String> inlineKeys = {
    Attribute.bold.key,
    Attribute.italic.key,
    Attribute.underline.key,
    Attribute.strikeThrough.key,
    Attribute.color.key,
    Attribute.background.key,
    Attribute.placeholder.key,
    Attribute.font.key,
  };

  static final Set<String> blockKeys = {
    Attribute.header.key,
    Attribute.indent.key,
    Attribute.align.key,
    Attribute.list.key,
    Attribute.codeBlock.key,
    Attribute.markdownBlock.key,
    Attribute.blockQuote.key,
  };

  static final Set<String> blockKeysExceptHeader = {
    Attribute.list.key,
    Attribute.indent.key,
    Attribute.align.key,
    Attribute.codeBlock.key,
    Attribute.markdownBlock.key,
    Attribute.blockQuote.key,
  };

  static Attribute<int?> get h1 => HeaderAttribute(level: 1);

  static Attribute<int?> get h2 => HeaderAttribute(level: 2);

  static Attribute<int?> get h3 => HeaderAttribute(level: 3);

  static Attribute<String?> get font1 => FontAttribute('style1');

  static Attribute<String?> get font2 => FontAttribute('style2');

  static Attribute<String?> get font3 => FontAttribute('style3');

  // "attributes":{"align":"left"}
  static Attribute<String?> get leftAlignment => AlignAttribute('left');

  // "attributes":{"align":"center"}
  static Attribute<String?> get centerAlignment => AlignAttribute('center');

  // "attributes":{"align":"right"}
  static Attribute<String?> get rightAlignment => AlignAttribute('right');

  // "attributes":{"align":"justify"}
  static Attribute<String?> get justifyAlignment => AlignAttribute('justify');

  // "attributes":{"list":"bullet"}
  static Attribute<String?> get ul => ListAttribute('bullet');

  // "attributes":{"list":"ordered"}
  static Attribute<String?> get ol => ListAttribute('ordered');

  // "attributes":{"list":"checked"}
  static Attribute<String?> get checked => ListAttribute('checked');

  // "attributes":{"list":"unchecked"}
  static Attribute<String?> get unchecked => ListAttribute('unchecked');

  // "attributes":{"indent":1"}
  static Attribute<int?> get indentL1 => IndentAttribute(level: 1);

  // "attributes":{"indent":2"}
  static Attribute<int?> get indentL2 => IndentAttribute(level: 2);

  // "attributes":{"indent":3"}
  static Attribute<int?> get indentL3 => IndentAttribute(level: 3);

  static Attribute<int?> getIndentLevel(int? level) {
    if (level == 1) {
      return indentL1;
    }
    if (level == 2) {
      return indentL2;
    }
    return indentL3;
  }

  bool get isInline => scope == AttributeScope.INLINE;

  bool get isBlockExceptHeader => blockKeysExceptHeader.contains(key);

  Map<String, dynamic> toJson() => <String, dynamic>{key: value};

  static Attribute fromKeyValue(String key, dynamic value) {
    if (!_registry.containsKey(key)) {
      throw ArgumentError.value(key, 'key "$key" not found.');
    }
    final origin = _registry[key]!;
    final attribute = clone(origin, value);
    return attribute;
  }

  static Attribute clone(Attribute origin, dynamic value) {
    return Attribute(origin.key, origin.scope, value);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Attribute<T>) return false;
    final typedOther = other;
    return key == typedOther.key &&
        scope == typedOther.scope &&
        value == typedOther.value;
  }

  @override
  int get hashCode => hash3(key, scope, value);

  @override
  String toString() {
    return 'Attribute{key: $key, scope: $scope, value: $value}';
  }
}

class BoldAttribute extends Attribute<bool> {
  BoldAttribute() : super('bold', AttributeScope.INLINE, true);
}

class ItalicAttribute extends Attribute<bool> {
  ItalicAttribute() : super('italic', AttributeScope.INLINE, true);
}

class UnderlineAttribute extends Attribute<bool> {
  UnderlineAttribute() : super('underline', AttributeScope.INLINE, true);
}

class StrikeThroughAttribute extends Attribute<bool> {
  StrikeThroughAttribute() : super('strike', AttributeScope.INLINE, true);
}

class FontAttribute extends Attribute<String?> {
  FontAttribute(String? val) : super('font', AttributeScope.INLINE, val);
}

class SizeAttribute extends Attribute<String?> {
  SizeAttribute(String? val) : super('size', AttributeScope.INLINE, val);
}

class ColorAttribute extends Attribute<String?> {
  ColorAttribute(String? val) : super('color', AttributeScope.INLINE, val);
}

class BackgroundAttribute extends Attribute<String?> {
  BackgroundAttribute(String? val)
      : super('background', AttributeScope.INLINE, val);
}

/// This is custom attribute for hint
class PlaceholderAttribute extends Attribute<bool> {
  PlaceholderAttribute() : super('placeholder', AttributeScope.INLINE, true);
}

class HeaderAttribute extends Attribute<int?> {
  HeaderAttribute({int? level}) : super('header', AttributeScope.BLOCK, level);
}

class IndentAttribute extends Attribute<int?> {
  IndentAttribute({int? level}) : super('indent', AttributeScope.BLOCK, level);
}

class AlignAttribute extends Attribute<String?> {
  AlignAttribute(String? val) : super('align', AttributeScope.BLOCK, val);
}

class ListAttribute extends Attribute<String?> {
  ListAttribute(String? val) : super('list', AttributeScope.BLOCK, val);
}

class CodeBlockAttribute extends Attribute<bool> {
  CodeBlockAttribute() : super('code-block', AttributeScope.BLOCK, true);
}

class MarkdownBlockAttribute extends Attribute<bool> {
  MarkdownBlockAttribute()
      : super('markdown-block', AttributeScope.BLOCK, true);
}

class BlockQuoteAttribute extends Attribute<bool> {
  BlockQuoteAttribute() : super('blockquote', AttributeScope.BLOCK, true);
}
