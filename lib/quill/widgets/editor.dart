import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../models/documents/attribute.dart';
import '../models/documents/document.dart';
import '../models/documents/nodes/container.dart' as container_node;
import '../models/documents/nodes/leaf.dart' as leaf;
import '../models/documents/nodes/line.dart';
import 'box.dart';
import 'controller.dart';
import 'cursor.dart';
import 'default_styles.dart';
import 'delegate.dart';
import 'raw_editor.dart';
import 'text_selection.dart';

const linkPrefixes = [
  'mailto:', // email
  'tel:', // telephone
  'sms:', // SMS
  'callto:',
  'wtai:',
  'market:',
  'geopoint:',
  'ymsgr:',
  'msnim:',
  'gtalk:', // Google Talk
  'skype:',
  'sip:', // Lync
  'whatsapp:',
  'http'
];

abstract class EditorState extends State<RawEditor> {
  TextEditingValue getTextEditingValue();

  void setTextEditingValue(TextEditingValue value);

  RenderEditor? getRenderEditor();

  EditorTextSelectionOverlay? getSelectionOverlay();

  bool showToolbar();

  void hideToolbar();

  void requestKeyboard();
}

abstract class RenderAbstractEditor {
  TextSelection selectWordAtPosition(TextPosition position);

  TextSelection selectLineAtPosition(TextPosition position);

  double preferredLineHeight(TextPosition position);

  TextPosition getPositionForOffset(Offset offset);

  List<TextSelectionPoint> getEndpointsForSelection(
      TextSelection textSelection);

  void handleTapDown(TapDownDetails details);

  void selectWordsInRange(
    Offset from,
    Offset to,
    SelectionChangedCause cause,
  );

  void selectWordEdge(SelectionChangedCause cause);

  void selectPositionAt(Offset from, Offset to, SelectionChangedCause cause);

  void selectWord(SelectionChangedCause cause);

  void selectPosition(SelectionChangedCause cause);
}

class QuillEditor extends StatefulWidget {
  const QuillEditor({
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.scrollable,
    required this.padding,
    required this.autoFocus,
    required this.readOnly,
    required this.expands,
    this.showCursor,
    this.placeholder,
    this.enableInteractiveSelection = true,
    this.minHeight,
    this.maxHeight,
    this.customStyles,
    this.textCapitalization = TextCapitalization.sentences,
    this.keyboardAppearance = Brightness.light,
    this.scrollPhysics,
    this.onLaunchUrl,
  });

  factory QuillEditor.basic({
    required QuillController controller,
    required bool readOnly,
  }) {
    return QuillEditor(
        controller: controller,
        scrollController: ScrollController(),
        scrollable: true,
        focusNode: FocusNode(),
        autoFocus: true,
        readOnly: readOnly,
        expands: false,
        padding: EdgeInsets.zero);
  }

  final QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final bool scrollable;
  final EdgeInsetsGeometry padding;
  final bool autoFocus;
  final bool? showCursor;
  final bool readOnly;
  final String? placeholder;
  final bool enableInteractiveSelection;
  final double? minHeight;
  final double? maxHeight;
  final DefaultStyles? customStyles;
  final bool expands;
  final TextCapitalization textCapitalization;
  final Brightness keyboardAppearance;
  final ScrollPhysics? scrollPhysics;
  final ValueChanged<String>? onLaunchUrl;

  @override
  _QuillEditorState createState() => _QuillEditorState();
}

class _QuillEditorState extends State<QuillEditor>
    implements EditorTextSelectionGestureDetectorBuilderDelegate {
  final GlobalKey<EditorState> _editorKey = GlobalKey<EditorState>();
  late EditorTextSelectionGestureDetectorBuilder
      _selectionGestureDetectorBuilder;

  @override
  void initState() {
    super.initState();
    _selectionGestureDetectorBuilder =
        _QuillEditorSelectionGestureDetectorBuilder(this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectionTheme = TextSelectionTheme.of(context);

    TextSelectionControls textSelectionControls;
    bool paintCursorAboveText;
    bool cursorOpacityAnimates;
    Offset? cursorOffset;
    Color? cursorColor;
    Color selectionColor;
    Radius? cursorRadius;

    switch (theme.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        textSelectionControls = materialTextSelectionControls;
        paintCursorAboveText = false;
        cursorOpacityAnimates = false;
        cursorColor ??= selectionTheme.cursorColor ?? theme.colorScheme.primary;
        selectionColor = selectionTheme.selectionColor ??
            theme.colorScheme.primary.withOpacity(0.40);
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        final cupertinoTheme = CupertinoTheme.of(context);
        textSelectionControls = cupertinoTextSelectionControls;
        paintCursorAboveText = true;
        cursorOpacityAnimates = true;
        cursorColor ??=
            selectionTheme.cursorColor ?? cupertinoTheme.primaryColor;
        selectionColor = selectionTheme.selectionColor ??
            cupertinoTheme.primaryColor.withOpacity(0.40);
        cursorRadius ??= const Radius.circular(2);
        cursorOffset = Offset(
            iOSHorizontalOffset / MediaQuery.of(context).devicePixelRatio, 0);
        break;
      default:
        throw UnimplementedError();
    }

    return _selectionGestureDetectorBuilder.build(
      HitTestBehavior.translucent,
      RawEditor(
        _editorKey,
        widget.controller,
        widget.focusNode,
        widget.scrollController,
        widget.scrollable,
        widget.padding,
        widget.readOnly,
        widget.placeholder,
        widget.onLaunchUrl,
        ToolbarOptions(
          copy: widget.enableInteractiveSelection,
          cut: widget.enableInteractiveSelection,
          paste: widget.enableInteractiveSelection,
          selectAll: widget.enableInteractiveSelection,
        ),
        theme.platform == TargetPlatform.iOS ||
            theme.platform == TargetPlatform.android,
        widget.showCursor,
        CursorStyle(
          color: cursorColor,
          backgroundColor: Colors.grey,
          width: 2,
          radius: cursorRadius,
          offset: cursorOffset,
          paintAboveText: paintCursorAboveText,
          opacityAnimates: cursorOpacityAnimates,
        ),
        widget.textCapitalization,
        widget.maxHeight,
        widget.minHeight,
        widget.customStyles,
        widget.expands,
        widget.autoFocus,
        selectionColor,
        'B',
        textSelectionControls,
        widget.keyboardAppearance,
        widget.enableInteractiveSelection,
        widget.scrollPhysics,
      ),
    );
  }

  @override
  GlobalKey<EditorState> getEditableTextKey() {
    return _editorKey;
  }

  @override
  bool getForcePressEnabled() {
    return false;
  }

  @override
  bool getSelectionEnabled() {
    return widget.enableInteractiveSelection;
  }

  void _requestKeyboard() {
    _editorKey.currentState!.requestKeyboard();
  }
}

class _QuillEditorSelectionGestureDetectorBuilder
    extends EditorTextSelectionGestureDetectorBuilder {
  _QuillEditorSelectionGestureDetectorBuilder(this._state) : super(_state);

  final _QuillEditorState _state;

  @override
  void onForcePressStart(ForcePressDetails details) {
    super.onForcePressStart(details);
    if (delegate.getSelectionEnabled() && shouldShowSelectionToolbar) {
      getEditor()!.showToolbar();
    }
  }

  @override
  void onForcePressEnd(ForcePressDetails details) {}

  @override
  void onSingleLongTapMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!delegate.getSelectionEnabled()) {
      return;
    }
    switch (Theme.of(_state.context).platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        getRenderEditor()!.selectPositionAt(
          details.globalPosition,
          null,
          SelectionChangedCause.longPress,
        );
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        getRenderEditor()!.selectWordsInRange(
          details.globalPosition - details.offsetFromOrigin,
          details.globalPosition,
          SelectionChangedCause.longPress,
        );
        break;
      default:
        throw 'Invalid platform';
    }
  }

  bool _onTapping(TapUpDetails details) {
    if (_state.widget.controller.document.isEmpty()) {
      return false;
    }
    final pos = getRenderEditor()!.getPositionForOffset(details.globalPosition);
    final result =
        getEditor()!.widget.controller.document.queryChild(pos.offset);
    if (result.node == null) {
      return false;
    }
    final line = result.node as Line;
    final segmentResult = line.queryChild(result.offset, false);
    if (segmentResult.node == null) {
      if (line.length == 1) {
        // tapping when no text yet on this line
        _flipListCheckbox(pos, line, segmentResult);
        getEditor()!.widget.controller.updateSelection(
            TextSelection.collapsed(offset: pos.offset), ChangeSource.LOCAL);
        return true;
      }
      return false;
    }
    final segment = segmentResult.node as leaf.Leaf;
    if (_flipListCheckbox(pos, line, segmentResult)) {
      return true;
    }
    return false;
  }

  bool _flipListCheckbox(
      TextPosition pos, Line line, container_node.ChildQuery segmentResult) {
    if (getEditor()!.widget.readOnly ||
        !line.style.containsKey(Attribute.list.key) ||
        segmentResult.offset != 0) {
      return false;
    }
    // segmentResult.offset == 0 means tap at the beginning of the TextLine
    final String? listVal = line.style.attributes[Attribute.list.key]!.value;
    if (listVal == Attribute.unchecked.value) {
      getEditor()!
          .widget
          .controller
          .formatText(pos.offset, 0, Attribute.checked);
    } else if (listVal == Attribute.checked.value) {
      getEditor()!
          .widget
          .controller
          .formatText(pos.offset, 0, Attribute.unchecked);
    }
    getEditor()!.widget.controller.updateSelection(
        TextSelection.collapsed(offset: pos.offset), ChangeSource.LOCAL);
    return true;
  }

  @override
  void onSingleTapUp(TapUpDetails details) {
    getEditor()!.hideToolbar();

    final positionSelected = _onTapping(details);

    if (delegate.getSelectionEnabled() && !positionSelected) {
      switch (Theme.of(_state.context).platform) {
        case TargetPlatform.iOS:
          switch (details.kind) {
            case PointerDeviceKind.mouse:
            case PointerDeviceKind.stylus:
            case PointerDeviceKind.invertedStylus:
              getRenderEditor()!.selectPosition(SelectionChangedCause.tap);
              break;
            case PointerDeviceKind.touch:
            case PointerDeviceKind.unknown:
              getRenderEditor()!.selectWordEdge(SelectionChangedCause.tap);
              break;
          }
          break;
        case TargetPlatform.android:
          getRenderEditor()!.selectPosition(SelectionChangedCause.tap);
          break;
      }
    }
    _state._requestKeyboard();
  }

  @override
  void onSingleLongTapStart(LongPressStartDetails details) {
    if (delegate.getSelectionEnabled()) {
      switch (Theme.of(_state.context).platform) {
        case TargetPlatform.iOS:
          getRenderEditor()!.selectPositionAt(
            details.globalPosition,
            null,
            SelectionChangedCause.longPress,
          );
          break;
        case TargetPlatform.android:
          getRenderEditor()!.selectWord(SelectionChangedCause.longPress);
          Feedback.forLongPress(_state.context);
          break;
        default:
          throw 'Invalid platform';
      }
    }
  }
}

typedef TextSelectionChangedHandler = void Function(
    TextSelection selection, SelectionChangedCause cause);

class RenderEditor extends RenderEditableContainerBox
    implements RenderAbstractEditor {
  RenderEditor(
    List<RenderEditableBox>? children,
    TextDirection textDirection,
    EdgeInsetsGeometry padding,
    this.document,
    this.selection,
    this._hasFocus,
    this.onSelectionChanged,
    this._startHandleLayerLink,
    this._endHandleLayerLink,
    EdgeInsets floatingCursorAddedMargin,
  ) : super(
          children,
          document.root,
          textDirection,
          padding,
        );

  Document document;
  TextSelection selection;
  bool _hasFocus = false;
  LayerLink _startHandleLayerLink;
  LayerLink _endHandleLayerLink;
  TextSelectionChangedHandler onSelectionChanged;
  final ValueNotifier<bool> _selectionStartInViewport =
      ValueNotifier<bool>(true);

  ValueListenable<bool> get selectionStartInViewport =>
      _selectionStartInViewport;

  ValueListenable<bool> get selectionEndInViewport => _selectionEndInViewport;
  final ValueNotifier<bool> _selectionEndInViewport = ValueNotifier<bool>(true);

  void setDocument(Document doc) {
    if (document == doc) {
      return;
    }
    document = doc;
    markNeedsLayout();
  }

  void setHasFocus(bool h) {
    if (_hasFocus == h) {
      return;
    }
    _hasFocus = h;
    markNeedsSemanticsUpdate();
  }

  void setSelection(TextSelection t) {
    if (selection == t) {
      return;
    }
    selection = t;
    markNeedsPaint();
  }

  void setStartHandleLayerLink(LayerLink value) {
    if (_startHandleLayerLink == value) {
      return;
    }
    _startHandleLayerLink = value;
    markNeedsPaint();
  }

  void setEndHandleLayerLink(LayerLink value) {
    if (_endHandleLayerLink == value) {
      return;
    }
    _endHandleLayerLink = value;
    markNeedsPaint();
  }

  @override
  List<TextSelectionPoint> getEndpointsForSelection(
      TextSelection textSelection) {
    if (textSelection.isCollapsed) {
      final child = childAtPosition(textSelection.extent);
      final localPosition = TextPosition(
          offset: textSelection.extentOffset - child.getContainer().offset);
      final localOffset = child.getOffsetForCaret(localPosition);
      final parentData = child.parentData as BoxParentData;
      return <TextSelectionPoint>[
        TextSelectionPoint(
            Offset(0, child.preferredLineHeight(localPosition)) +
                localOffset +
                parentData.offset,
            null)
      ];
    }

    final baseNode = _container.queryChild(textSelection.start, false).node;

    var baseChild = firstChild;
    while (baseChild != null) {
      if (baseChild.getContainer() == baseNode) {
        break;
      }
      baseChild = childAfter(baseChild);
    }
    assert(baseChild != null);

    final baseParentData = baseChild!.parentData as BoxParentData;
    final baseSelection =
        localSelection(baseChild.getContainer(), textSelection, true);
    var basePoint = baseChild.getBaseEndpointForSelection(baseSelection);
    basePoint = TextSelectionPoint(
        basePoint.point + baseParentData.offset, basePoint.direction);

    final extentNode = _container.queryChild(textSelection.end, false).node;
    RenderEditableBox? extentChild = baseChild;
    while (extentChild != null) {
      if (extentChild.getContainer() == extentNode) {
        break;
      }
      extentChild = childAfter(extentChild);
    }
    assert(extentChild != null);

    final extentParentData = extentChild!.parentData as BoxParentData;
    final extentSelection =
        localSelection(extentChild.getContainer(), textSelection, true);
    var extentPoint =
        extentChild.getExtentEndpointForSelection(extentSelection);
    extentPoint = TextSelectionPoint(
        extentPoint.point + extentParentData.offset, extentPoint.direction);

    return <TextSelectionPoint>[basePoint, extentPoint];
  }

  Offset? _lastTapDownPosition;

  @override
  void handleTapDown(TapDownDetails details) {
    _lastTapDownPosition = details.globalPosition;
  }

  @override
  void selectWordsInRange(
    Offset from,
    Offset? to,
    SelectionChangedCause cause,
  ) {
    final firstPosition = getPositionForOffset(from);
    final firstWord = selectWordAtPosition(firstPosition);
    final lastWord =
        to == null ? firstWord : selectWordAtPosition(getPositionForOffset(to));

    _handleSelectionChange(
      TextSelection(
        baseOffset: firstWord.base.offset,
        extentOffset: lastWord.extent.offset,
        affinity: firstWord.affinity,
      ),
      cause,
    );
  }

  void _handleSelectionChange(
    TextSelection nextSelection,
    SelectionChangedCause cause,
  ) {
    final focusingEmpty = nextSelection.baseOffset == 0 &&
        nextSelection.extentOffset == 0 &&
        !_hasFocus;
    if (nextSelection == selection &&
        cause != SelectionChangedCause.keyboard &&
        !focusingEmpty) {
      return;
    }
    onSelectionChanged(nextSelection, cause);
  }

  @override
  void selectWordEdge(SelectionChangedCause cause) {
    assert(_lastTapDownPosition != null);
    final position = getPositionForOffset(_lastTapDownPosition!);
    final child = childAtPosition(position);
    final nodeOffset = child.getContainer().offset;
    final localPosition = TextPosition(
      offset: position.offset - nodeOffset,
      affinity: position.affinity,
    );
    final localWord = child.getWordBoundary(localPosition);
    final word = TextRange(
      start: localWord.start + nodeOffset,
      end: localWord.end + nodeOffset,
    );
    if (position.offset - word.start <= 1) {
      _handleSelectionChange(
        TextSelection.collapsed(offset: word.start),
        cause,
      );
    } else {
      _handleSelectionChange(
        TextSelection.collapsed(
            offset: word.end, affinity: TextAffinity.upstream),
        cause,
      );
    }
  }

  @override
  void selectPositionAt(
    Offset from,
    Offset? to,
    SelectionChangedCause cause,
  ) {
    final fromPosition = getPositionForOffset(from);
    final toPosition = to == null ? null : getPositionForOffset(to);

    var baseOffset = fromPosition.offset;
    var extentOffset = fromPosition.offset;
    if (toPosition != null) {
      baseOffset = math.min(fromPosition.offset, toPosition.offset);
      extentOffset = math.max(fromPosition.offset, toPosition.offset);
    }

    final newSelection = TextSelection(
      baseOffset: baseOffset,
      extentOffset: extentOffset,
      affinity: fromPosition.affinity,
    );
    _handleSelectionChange(newSelection, cause);
  }

  @override
  void selectWord(SelectionChangedCause cause) {
    selectWordsInRange(_lastTapDownPosition!, null, cause);
  }

  @override
  void selectPosition(SelectionChangedCause cause) {
    selectPositionAt(_lastTapDownPosition!, null, cause);
  }

  @override
  TextSelection selectWordAtPosition(TextPosition position) {
    final child = childAtPosition(position);
    final nodeOffset = child.getContainer().offset;
    final localPosition = TextPosition(
        offset: position.offset - nodeOffset, affinity: position.affinity);
    final localWord = child.getWordBoundary(localPosition);
    final word = TextRange(
      start: localWord.start + nodeOffset,
      end: localWord.end + nodeOffset,
    );
    if (position.offset >= word.end) {
      return TextSelection.fromPosition(position);
    }
    return TextSelection(baseOffset: word.start, extentOffset: word.end);
  }

  @override
  TextSelection selectLineAtPosition(TextPosition position) {
    final child = childAtPosition(position);
    final nodeOffset = child.getContainer().offset;
    final localPosition = TextPosition(
        offset: position.offset - nodeOffset, affinity: position.affinity);
    final localLineRange = child.getLineBoundary(localPosition);
    final line = TextRange(
      start: localLineRange.start + nodeOffset,
      end: localLineRange.end + nodeOffset,
    );

    if (position.offset >= line.end) {
      return TextSelection.fromPosition(position);
    }
    return TextSelection(baseOffset: line.start, extentOffset: line.end);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
    _paintHandleLayers(context, getEndpointsForSelection(selection));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  void _paintHandleLayers(
      PaintingContext context, List<TextSelectionPoint> endpoints) {
    var startPoint = endpoints[0].point;
    startPoint = Offset(
      startPoint.dx.clamp(0.0, size.width),
      startPoint.dy.clamp(0.0, size.height),
    );
    context.pushLayer(
      LeaderLayer(link: _startHandleLayerLink, offset: startPoint),
      super.paint,
      Offset.zero,
    );
    if (endpoints.length == 2) {
      var endPoint = endpoints[1].point;
      endPoint = Offset(
        endPoint.dx.clamp(0.0, size.width),
        endPoint.dy.clamp(0.0, size.height),
      );
      context.pushLayer(
        LeaderLayer(link: _endHandleLayerLink, offset: endPoint),
        super.paint,
        Offset.zero,
      );
    }
  }

  @override
  double preferredLineHeight(TextPosition position) {
    final child = childAtPosition(position);
    return child.preferredLineHeight(
        TextPosition(offset: position.offset - child.getContainer().offset));
  }

  @override
  TextPosition getPositionForOffset(Offset offset) {
    final local = globalToLocal(offset);
    final child = childAtOffset(local)!;

    final parentData = child.parentData as BoxParentData;
    final localOffset = local - parentData.offset;
    final localPosition = child.getPositionForOffset(localOffset);
    return TextPosition(
      offset: localPosition.offset + child.getContainer().offset,
      affinity: localPosition.affinity,
    );
  }

  /// Returns the y-offset of the editor at which [selection] is visible.
  ///
  /// The offset is the distance from the top of the editor and is the minimum
  /// from the current scroll position until [selection] becomes visible.
  /// Returns null if [selection] is already visible.
  double? getOffsetToRevealCursor(
      double viewportHeight, double scrollOffset, double offsetInViewport) {
    final endpoints = getEndpointsForSelection(selection);
    final endpoint = endpoints.first;
    final child = childAtPosition(selection.extent);
    const kMargin = 8.0;

    final caretTop = endpoint.point.dy -
        child.preferredLineHeight(TextPosition(
            offset: selection.extentOffset - child.getContainer().offset)) -
        kMargin +
        offsetInViewport;
    final caretBottom = endpoint.point.dy + kMargin + offsetInViewport;
    double? dy;
    if (caretTop < scrollOffset) {
      dy = caretTop;
    } else if (caretBottom > scrollOffset + viewportHeight) {
      dy = caretBottom - viewportHeight;
    }
    if (dy == null) {
      return null;
    }
    return math.max(dy, 0);
  }
}

class EditableContainerParentData
    extends ContainerBoxParentData<RenderEditableBox> {}

class RenderEditableContainerBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderEditableBox,
            EditableContainerParentData>,
        RenderBoxContainerDefaultsMixin<RenderEditableBox,
            EditableContainerParentData> {
  RenderEditableContainerBox(
    List<RenderEditableBox>? children,
    this._container,
    this.textDirection,
    this._padding,
  ) : assert(_padding.isNonNegative) {
    addAll(children);
  }

  container_node.Container _container;
  TextDirection textDirection;
  EdgeInsetsGeometry _padding;
  EdgeInsets? _resolvedPadding;

  container_node.Container getContainer() {
    return _container;
  }

  void setContainer(container_node.Container c) {
    if (_container == c) {
      return;
    }
    _container = c;
    markNeedsLayout();
  }

  EdgeInsetsGeometry getPadding() => _padding;

  void setPadding(EdgeInsetsGeometry value) {
    assert(value.isNonNegative);
    if (_padding == value) {
      return;
    }
    _padding = value;
    _markNeedsPaddingResolution();
  }

  EdgeInsets? get resolvedPadding => _resolvedPadding;

  void _resolvePadding() {
    if (_resolvedPadding != null) {
      return;
    }
    _resolvedPadding = _padding.resolve(textDirection);
    _resolvedPadding = _resolvedPadding!.copyWith(left: _resolvedPadding!.left);

    assert(_resolvedPadding!.isNonNegative);
  }

  RenderEditableBox childAtPosition(TextPosition position) {
    assert(firstChild != null);

    final targetNode = _container.queryChild(position.offset, false).node;

    var targetChild = firstChild;
    while (targetChild != null) {
      if (targetChild.getContainer() == targetNode) {
        break;
      }
      targetChild = childAfter(targetChild);
    }
    if (targetChild == null) {
      throw 'targetChild should not be null';
    }
    return targetChild;
  }

  void _markNeedsPaddingResolution() {
    _resolvedPadding = null;
    markNeedsLayout();
  }

  RenderEditableBox? childAtOffset(Offset offset) {
    assert(firstChild != null);
    _resolvePadding();

    if (offset.dy <= _resolvedPadding!.top) {
      return firstChild;
    }
    if (offset.dy >= size.height - _resolvedPadding!.bottom) {
      return lastChild;
    }

    var child = firstChild;
    final dx = -offset.dx;
    var dy = _resolvedPadding!.top;
    while (child != null) {
      if (child.size.contains(offset.translate(dx, -dy))) {
        return child;
      }
      dy += child.size.height;
      child = childAfter(child);
    }
    throw 'No child';
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is EditableContainerParentData) {
      return;
    }

    child.parentData = EditableContainerParentData();
  }

  @override
  void performLayout() {
    assert(!constraints.hasBoundedHeight);
    assert(constraints.hasBoundedWidth);
    _resolvePadding();
    assert(_resolvedPadding != null);

    var mainAxisExtent = _resolvedPadding!.top;
    var child = firstChild;
    final innerConstraints =
        BoxConstraints.tightFor(width: constraints.maxWidth)
            .deflate(_resolvedPadding!);
    while (child != null) {
      child.layout(innerConstraints, parentUsesSize: true);
      final childParentData = (child.parentData as EditableContainerParentData)
        ..offset = Offset(_resolvedPadding!.left, mainAxisExtent);
      mainAxisExtent += child.size.height;
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
    mainAxisExtent += _resolvedPadding!.bottom;
    size = constraints.constrain(Size(constraints.maxWidth, mainAxisExtent));

    assert(size.isFinite);
  }

  double _getIntrinsicCrossAxis(double Function(RenderBox child) childSize) {
    var extent = 0.0;
    var child = firstChild;
    while (child != null) {
      extent = math.max(extent, childSize(child));
      final childParentData = child.parentData as EditableContainerParentData;
      child = childParentData.nextSibling;
    }
    return extent;
  }

  double _getIntrinsicMainAxis(double Function(RenderBox child) childSize) {
    var extent = 0.0;
    var child = firstChild;
    while (child != null) {
      extent += childSize(child);
      final childParentData = child.parentData as EditableContainerParentData;
      child = childParentData.nextSibling;
    }
    return extent;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    _resolvePadding();
    return _getIntrinsicCrossAxis((child) {
      final childHeight = math.max<double>(
          0, height - _resolvedPadding!.top + _resolvedPadding!.bottom);
      return child.getMinIntrinsicWidth(childHeight) +
          _resolvedPadding!.left +
          _resolvedPadding!.right;
    });
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _resolvePadding();
    return _getIntrinsicCrossAxis((child) {
      final childHeight = math.max<double>(
          0, height - _resolvedPadding!.top + _resolvedPadding!.bottom);
      return child.getMaxIntrinsicWidth(childHeight) +
          _resolvedPadding!.left +
          _resolvedPadding!.right;
    });
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    _resolvePadding();
    return _getIntrinsicMainAxis((child) {
      final childWidth = math.max<double>(
          0, width - _resolvedPadding!.left + _resolvedPadding!.right);
      return child.getMinIntrinsicHeight(childWidth) +
          _resolvedPadding!.top +
          _resolvedPadding!.bottom;
    });
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    _resolvePadding();
    return _getIntrinsicMainAxis((child) {
      final childWidth = math.max<double>(
          0, width - _resolvedPadding!.left + _resolvedPadding!.right);
      return child.getMaxIntrinsicHeight(childWidth) +
          _resolvedPadding!.top +
          _resolvedPadding!.bottom;
    });
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    _resolvePadding();
    return defaultComputeDistanceToFirstActualBaseline(baseline)! +
        _resolvedPadding!.top;
  }
}
