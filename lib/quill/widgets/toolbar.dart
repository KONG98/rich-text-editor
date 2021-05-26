import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../models/documents/attribute.dart';
import '../models/documents/style.dart';
import '../utils/color.dart';
import 'controller.dart';

double iconSize = 18;
double kToolbarHeight = iconSize * 2;

typedef ToggleStyleButtonBuilder = Widget Function(
  BuildContext context,
  Attribute attribute,
  IconData icon,
  bool? isToggled,
  VoidCallback? onPressed,
);

class ToggleStyleButton extends StatefulWidget {
  const ToggleStyleButton({
    required this.attribute,
    required this.icon,
    required this.controller,
    this.childBuilder = defaultToggleStyleButtonBuilder,
    Key? key,
  }) : super(key: key);

  final Attribute attribute;

  final IconData icon;

  final QuillController controller;

  final ToggleStyleButtonBuilder childBuilder;

  @override
  _ToggleStyleButtonState createState() => _ToggleStyleButtonState();
}

class _ToggleStyleButtonState extends State<ToggleStyleButton> {
  bool? _isToggled;

  Style get _selectionStyle => widget.controller.getSelectionStyle();

  void _didChangeEditingValue() {
    setState(() {
      _isToggled =
          _getIsToggled(widget.controller.getSelectionStyle().attributes);
    });
  }

  @override
  void initState() {
    super.initState();
    _isToggled = _getIsToggled(_selectionStyle.attributes);
    widget.controller.addListener(_didChangeEditingValue);
  }

  bool _getIsToggled(Map<String, Attribute> attrs) {
    if (widget.attribute.key == Attribute.list.key) {
      final attribute = attrs[widget.attribute.key];
      if (attribute == null) {
        return false;
      }
      return attribute.value == widget.attribute.value;
    }
    return attrs.containsKey(widget.attribute.key);
  }

  @override
  void didUpdateWidget(covariant ToggleStyleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _isToggled = _getIsToggled(_selectionStyle.attributes);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInCodeBlock =
        _selectionStyle.attributes.containsKey(Attribute.codeBlock.key);
    final isEnabled =
        !isInCodeBlock || widget.attribute.key == Attribute.codeBlock.key;
    return widget.childBuilder(context, widget.attribute, widget.icon,
        _isToggled, isEnabled ? _toggleAttribute : null);
  }

  void _toggleAttribute() {
    widget.controller.formatSelection(_isToggled!
        ? Attribute.clone(widget.attribute, null)
        : widget.attribute);
  }
}

Widget defaultToggleStyleButtonBuilder(
  BuildContext context,
  Attribute attribute,
  IconData icon,
  bool? isToggled,
  VoidCallback? onPressed,
) {
  final theme = Theme.of(context);
  final isEnabled = onPressed != null;
  final iconColor = isEnabled
      ? isToggled == true
          ? theme.primaryIconTheme.color
          : theme.iconTheme.color
      : theme.disabledColor;
  final fillColor =
      isToggled == true ? theme.toggleableActiveColor : theme.canvasColor;
  return QuillIconButton(
    highlightElevation: 0,
    hoverElevation: 0,
    size: iconSize * 1.77,
    icon: Icon(icon, size: iconSize, color: iconColor),
    fillColor: fillColor,
    onPressed: onPressed,
  );
}

class SelectHeaderStyleButton extends StatefulWidget {
  const SelectHeaderStyleButton({required this.controller, Key? key})
      : super(key: key);

  final QuillController controller;

  @override
  _SelectHeaderStyleButtonState createState() =>
      _SelectHeaderStyleButtonState();
}

class _SelectHeaderStyleButtonState extends State<SelectHeaderStyleButton> {
  Attribute? _value;

  Style get _selectionStyle => widget.controller.getSelectionStyle();

  void _didChangeEditingValue() {
    setState(() {
      _value =
          _selectionStyle.attributes[Attribute.header.key] ?? Attribute.header;
      print(_value);
    });
  }

  void _selectAttribute(value) {
    widget.controller.formatSelection(value);
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _value =
          _selectionStyle.attributes[Attribute.header.key] ?? Attribute.header;
    });
    widget.controller.addListener(_didChangeEditingValue);
  }

  @override
  void didUpdateWidget(covariant SelectHeaderStyleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _value =
          _selectionStyle.attributes[Attribute.header.key] ?? Attribute.header;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _selectHeadingStyleButtonBuilder(context, _value, _selectAttribute);
  }
}

Widget _selectHeadingStyleButtonBuilder(BuildContext context, Attribute? value,
    ValueChanged<Attribute?> onSelected) {
  final _valueToText = <Attribute, String>{
    Attribute.header: 'N',
    Attribute.h1: 'H1',
    Attribute.h2: 'H2',
    Attribute.h3: 'H3',
  };

  final _valueAttribute = <Attribute>[
    Attribute.header,
    Attribute.h1,
    Attribute.h2,
    Attribute.h3
  ];
  final _valueString = <String>['N', 'H1', 'H2', 'H3'];

  final theme = Theme.of(context);
  final style = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: iconSize * 0.7,
  );

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(4, (index) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: !kIsWeb ? 1.0 : 5.0),
        child: ConstrainedBox(
          constraints: BoxConstraints.tightFor(
            width: iconSize * 1.77,
            height: iconSize * 1.77,
          ),
          child: RawMaterialButton(
            hoverElevation: 0,
            highlightElevation: 0,
            elevation: 0,
            visualDensity: VisualDensity.compact,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
            fillColor: _valueToText[value] == _valueString[index]
                ? theme.toggleableActiveColor
                : theme.canvasColor,
            onPressed: () {
              onSelected(_valueAttribute[index]);
            },
            child: Text(
              _valueString[index],
              style: style.copyWith(
                color: _valueToText[value] == _valueString[index]
                    ? theme.primaryIconTheme.color
                    : theme.iconTheme.color,
              ),
            ),
          ),
        ),
      );
    }),
  );
}

class ColorButton extends StatefulWidget {
  const ColorButton({
    required this.icon,
    required this.controller,
    required this.background,
    Key? key,
  }) : super(key: key);

  final IconData icon;
  final bool background;
  final QuillController controller;

  @override
  _ColorButtonState createState() => _ColorButtonState();
}

class _ColorButtonState extends State<ColorButton> {
  late bool _isToggledColor;
  late bool _isToggledBackground;
  late bool _isWhite;
  late bool _isWhitebackground;

  Style get _selectionStyle => widget.controller.getSelectionStyle();

  void _didChangeEditingValue() {
    setState(() {
      _isToggledColor =
          _getIsToggledColor(widget.controller.getSelectionStyle().attributes);
      _isToggledBackground = _getIsToggledBackground(
          widget.controller.getSelectionStyle().attributes);
      _isWhite = _isToggledColor &&
          _selectionStyle.attributes['color']!.value == '#ffffff';
      _isWhitebackground = _isToggledBackground &&
          _selectionStyle.attributes['background']!.value == '#ffffff';
    });
  }

  @override
  void initState() {
    super.initState();
    _isToggledColor = _getIsToggledColor(_selectionStyle.attributes);
    _isToggledBackground = _getIsToggledBackground(_selectionStyle.attributes);
    _isWhite = _isToggledColor &&
        _selectionStyle.attributes['color']!.value == '#ffffff';
    _isWhitebackground = _isToggledBackground &&
        _selectionStyle.attributes['background']!.value == '#ffffff';
    widget.controller.addListener(_didChangeEditingValue);
  }

  bool _getIsToggledColor(Map<String, Attribute> attrs) {
    return attrs.containsKey(Attribute.color.key);
  }

  bool _getIsToggledBackground(Map<String, Attribute> attrs) {
    return attrs.containsKey(Attribute.background.key);
  }

  @override
  void didUpdateWidget(covariant ColorButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _isToggledColor = _getIsToggledColor(_selectionStyle.attributes);
      _isToggledBackground =
          _getIsToggledBackground(_selectionStyle.attributes);
      _isWhite = _isToggledColor &&
          _selectionStyle.attributes['color']!.value == '#ffffff';
      _isWhitebackground = _isToggledBackground &&
          _selectionStyle.attributes['background']!.value == '#ffffff';
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = _isToggledColor && !widget.background && !_isWhite
        ? stringToColor(_selectionStyle.attributes['color']!.value)
        : theme.iconTheme.color;

    final iconColorBackground =
        _isToggledBackground && widget.background && !_isWhitebackground
            ? stringToColor(_selectionStyle.attributes['background']!.value)
            : theme.iconTheme.color;

    final fillColor = _isToggledColor && !widget.background && _isWhite
        ? stringToColor('#ffffff')
        : theme.canvasColor;
    final fillColorBackground =
        _isToggledBackground && widget.background && _isWhitebackground
            ? stringToColor('#ffffff')
            : theme.canvasColor;

    return QuillIconButton(
      highlightElevation: 0,
      hoverElevation: 0,
      size: iconSize * 1.77,
      icon: Icon(widget.icon,
          size: iconSize,
          color: widget.background ? iconColorBackground : iconColor),
      fillColor: widget.background ? fillColorBackground : fillColor,
      onPressed: _showColorPicker,
    );
  }

  void _changeColor(Color color) {
    var hex = color.value.toRadixString(16);
    if (hex.startsWith('ff')) {
      hex = hex.substring(2);
    }
    hex = '#$hex';
    widget.controller.formatSelection(
        widget.background ? BackgroundAttribute(hex) : ColorAttribute(hex));
    Navigator.of(context).pop();
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
          title: const Text('Select Color'),
          backgroundColor: Theme.of(context).canvasColor,
          content: SingleChildScrollView(
            child: MaterialPicker(
              pickerColor: const Color(0x00000000),
              onColorChanged: _changeColor,
            ),
          )),
    );
  }
}

class FontStyleButton extends StatefulWidget {
  final IconData icon;
  final QuillController controller;

  const FontStyleButton({
    required this.icon,
    required this.controller,
    Key? key,
  }) : super(key: key);

  @override
  _FontStyleButtonState createState() => _FontStyleButtonState();
}

class _FontStyleButtonState extends State<FontStyleButton> {
  Attribute? _value;

  Style get _selectionStyle => widget.controller.getSelectionStyle();

  void _didChangeEditingValue() {
    print("改变样式");
    setState(() {
      _value = _selectionStyle.attributes[Attribute.font.key] ?? Attribute.font;
      print(_value);
    });
  }

  void _selectAttribute(value) {
    widget.controller.formatSelection(value);
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _value = _selectionStyle.attributes[Attribute.font.key] ?? Attribute.font;
    });
    widget.controller.addListener(_didChangeEditingValue);
  }

  @override
  void didUpdateWidget(covariant FontStyleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _value = _selectionStyle.attributes[Attribute.font.key] ?? Attribute.font;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.iconTheme.color;
    final fillColor = theme.canvasColor;

    return QuillIconButton(
      highlightElevation: 0,
      hoverElevation: 0,
      size: iconSize * 1.77,
      icon: Icon(
        widget.icon,
        size: iconSize,
        color: iconColor,
      ),
      fillColor: fillColor,
      onPressed: _showFontStylePicker,
    );
  }

  List<Attribute> _valueAttribute = [
    Attribute.font1,
    Attribute.font2,
    Attribute.font3,
  ];

  List<String> fonts = ['A', 'B', 'C'];

  void _showFontStylePicker() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select font style'),
        backgroundColor: Theme.of(context).canvasColor,
        content: Container(
          height: 300,
          width: 280,
          child: ListView.builder(
            itemCount: 3,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                title: Text(
                  "样式ABC",
                  style: TextStyle(fontFamily: fonts[index], fontSize: 36),
                ),
                onTap: () {
                  print("选择了样式" + fonts[index].toString());

                  _selectAttribute(_valueAttribute[index]);

                  Navigator.of(context).pop(index);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class ClearFormatButton extends StatefulWidget {
  const ClearFormatButton({
    required this.icon,
    required this.controller,
    Key? key,
  }) : super(key: key);

  final IconData icon;

  final QuillController controller;

  @override
  _ClearFormatButtonState createState() => _ClearFormatButtonState();
}

class _ClearFormatButtonState extends State<ClearFormatButton> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.iconTheme.color;
    final fillColor = theme.canvasColor;
    return QuillIconButton(
        highlightElevation: 0,
        hoverElevation: 0,
        size: iconSize * 1.77,
        icon: Icon(widget.icon, size: iconSize, color: iconColor),
        fillColor: fillColor,
        onPressed: () {
          for (final k
              in widget.controller.getSelectionStyle().attributes.values) {
            widget.controller.formatSelection(Attribute.clone(k, null));
          }
        });
  }
}

class Toolbar extends StatefulWidget implements PreferredSizeWidget {
  const Toolbar({required this.children, Key? key}) : super(key: key);

  factory Toolbar.basic({
    required QuillController controller,
    double toolbarIconSize = 18.0,
    Key? key,
  }) {
    iconSize = toolbarIconSize;
    return Toolbar(key: key, children: [
      ToggleStyleButton(
        attribute: Attribute.bold,
        icon: Icons.format_bold,
        controller: controller,
      ),
      const SizedBox(width: 0.6),
      ToggleStyleButton(
        attribute: Attribute.italic,
        icon: Icons.format_italic,
        controller: controller,
      ),
      const SizedBox(width: 0.6),
      ToggleStyleButton(
        attribute: Attribute.underline,
        icon: Icons.format_underline,
        controller: controller,
      ),
      const SizedBox(width: 0.6),
      ToggleStyleButton(
        attribute: Attribute.strikeThrough,
        icon: Icons.format_strikethrough,
        controller: controller,
      ),
      const SizedBox(width: 0.6),
      ColorButton(
        icon: Icons.color_lens,
        controller: controller,
        background: false,
      ),
      const SizedBox(width: 0.6),
      FontStyleButton(
        icon: Icons.font_download,
        controller: controller,
        //background: true,
      ),
      const SizedBox(width: 0.6),
      ColorButton(
        icon: Icons.format_color_fill,
        controller: controller,
        background: true,
      ),
      const SizedBox(width: 0.6),
      ClearFormatButton(
        icon: Icons.format_clear,
        controller: controller,
      ),
      const SizedBox(width: 0.6),
      VerticalDivider(indent: 12, endIndent: 12, color: Colors.grey.shade400),
      SelectHeaderStyleButton(controller: controller),
      VerticalDivider(indent: 12, endIndent: 12, color: Colors.grey.shade400),
      ToggleStyleButton(
        attribute: Attribute.ol,
        controller: controller,
        icon: Icons.format_list_numbered,
      ),
      ToggleStyleButton(
        attribute: Attribute.ul,
        controller: controller,
        icon: Icons.format_list_bulleted,
      ),
      ToggleStyleButton(
        attribute: Attribute.codeBlock,
        controller: controller,
        icon: Icons.code,
      ),
      ToggleStyleButton(
        attribute: Attribute.markdownBlock,
        controller: controller,
        icon: Icons.museum,
      ),
      VerticalDivider(indent: 12, endIndent: 12, color: Colors.grey.shade400),
      ToggleStyleButton(
        attribute: Attribute.blockQuote,
        controller: controller,
        icon: Icons.format_quote,
      ),
    ]);
  }

  final List<Widget> children;

  @override
  _ToolbarState createState() => _ToolbarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _ToolbarState extends State<Toolbar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      constraints: BoxConstraints.tightFor(height: widget.preferredSize.height),
      color: Theme.of(context).canvasColor,
      child: CustomScrollView(
        scrollDirection: Axis.horizontal,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: widget.children,
            ),
          ),
        ],
      ),
    );
  }
}

class QuillIconButton extends StatelessWidget {
  const QuillIconButton({
    required this.onPressed,
    this.icon,
    this.size = 40,
    this.fillColor,
    this.hoverElevation = 1,
    this.highlightElevation = 1,
    Key? key,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final Widget? icon;
  final double size;
  final Color? fillColor;
  final double hoverElevation;
  final double highlightElevation;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(width: size, height: size),
      child: RawMaterialButton(
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        fillColor: fillColor,
        elevation: 0,
        hoverElevation: hoverElevation,
        highlightElevation: hoverElevation,
        onPressed: onPressed,
        child: icon,
      ),
    );
  }
}
