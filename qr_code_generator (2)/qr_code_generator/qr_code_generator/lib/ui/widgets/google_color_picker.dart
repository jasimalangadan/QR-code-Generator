import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GoogleColorPicker extends StatefulWidget {
  final String initialColorHex;
  final ValueChanged<String> onColorChanged;
  final VoidCallback? onShareOrCopy;

  const GoogleColorPicker({
    super.key,
    required this.initialColorHex,
    required this.onColorChanged,
    this.onShareOrCopy,
  });

  @override
  State<GoogleColorPicker> createState() => _GoogleColorPickerState();
}

class _GoogleColorPickerState extends State<GoogleColorPicker> {
  late double _hue; // 0.0 to 360.0
  late double _saturation; // 0.0 to 1.0
  late double _value; // 0.0 to 1.0

  late TextEditingController _hexController;
  bool _isManualTyping = false;

  @override
  void initState() {
    super.initState();
    _initFromHex(widget.initialColorHex);
    _hexController = TextEditingController(text: _currentHex);
  }

  @override
  void didUpdateWidget(covariant GoogleColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isManualTyping &&
        oldWidget.initialColorHex != widget.initialColorHex) {
      _initFromHex(widget.initialColorHex);
      _hexController.text = _currentHex;
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _initFromHex(String hex) {
    Color color = _hexToColor(hex) ?? const Color(0xFF6C5CE7);
    final hsv = HSVColor.fromColor(color);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  Color get _currentColor {
    return HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
  }

  String get _currentHex {
    final c = _currentColor;
    final r = (c.r * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final g = (c.g * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final b = (c.b * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  Color? _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '').replaceAll(' ', '').trim();
    if (clean.length == 6) {
      final val = int.tryParse('FF$clean', radix: 16);
      if (val != null) return Color(val);
    }
    return null;
  }

  void _updateColorFromGesture() {
    final hex = _currentHex;
    _isManualTyping = true;
    _hexController.text = hex;
    _isManualTyping = false;
    widget.onColorChanged(hex);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF202124), // Google dark palette
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Header Bar: Title and Share/Copy Icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Colour picker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _currentHex));
                    if (widget.onShareOrCopy != null) {
                      widget.onShareOrCopy!();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Color $_currentHex copied!'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.share_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Main Color Box: Left preview block + Right Saturation/Value gradient canvas
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: SizedBox(
              height: 150,
              child: Row(
                children: [
                  // Left: Live Color Preview Block
                  Expanded(
                    flex: 3,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 50),
                      color: _currentColor,
                    ),
                  ),

                  // Right: 2D HSV Gradient Canvas
                  Expanded(
                    flex: 7,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final height = constraints.maxHeight;

                        final thumbX = (_saturation * width).clamp(0.0, width);
                        final thumbY = ((1.0 - _value) * height).clamp(
                          0.0,
                          height,
                        );

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanDown: (details) {
                            final local = details.localPosition;
                            setState(() {
                              _saturation = (local.dx / width).clamp(0.0, 1.0);
                              _value = (1.0 - (local.dy / height)).clamp(
                                0.0,
                                1.0,
                              );
                            });
                            _updateColorFromGesture();
                          },
                          onPanUpdate: (details) {
                            final local = details.localPosition;
                            setState(() {
                              _saturation = (local.dx / width).clamp(0.0, 1.0);
                              _value = (1.0 - (local.dy / height)).clamp(
                                0.0,
                                1.0,
                              );
                            });
                            _updateColorFromGesture();
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Layer 1: Base Hue
                              Container(
                                color: HSVColor.fromAHSV(
                                  1.0,
                                  _hue,
                                  1.0,
                                  1.0,
                                ).toColor(),
                              ),

                              // Layer 2: White to Transparent horizontal gradient (Saturation)
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [Colors.white, Color(0x00FFFFFF)],
                                  ),
                                ),
                              ),

                              // Layer 3: Transparent to Black vertical gradient (Value / Brightness)
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0x00000000), Colors.black],
                                  ),
                                ),
                              ),

                              // Draggable Thumb Circle
                              Positioned(
                                left: thumbX - 11,
                                top: thumbY - 11,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentColor,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black45,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // 3. Rainbow Hue Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final thumbX = ((_hue / 360.0) * width).clamp(0.0, width);

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanDown: (details) {
                    final dx = details.localPosition.dx;
                    setState(() {
                      _hue = ((dx / width).clamp(0.0, 1.0) * 360.0).clamp(
                        0.0,
                        360.0,
                      );
                    });
                    _updateColorFromGesture();
                  },
                  onPanUpdate: (details) {
                    final dx = details.localPosition.dx;
                    setState(() {
                      _hue = ((dx / width).clamp(0.0, 1.0) * 360.0).clamp(
                        0.0,
                        360.0,
                      );
                    });
                    _updateColorFromGesture();
                  },
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    clipBehavior: Clip.none,
                    children: [
                      // Rainbow spectrum bar
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF0000), // Red 0°
                              Color(0xFFFFA500), // Orange
                              Color(0xFFFFFF00), // Yellow 60°
                              Color(0xFF00FF00), // Green 120°
                              Color(0xFF00FFFF), // Cyan 180°
                              Color(0xFF0000FF), // Blue 240°
                              Color(0xFFFF00FF), // Magenta 300°
                              Color(0xFFFF0000), // Red 360°
                            ],
                          ),
                        ),
                      ),

                      // Draggable Hue Thumb Circle
                      Positioned(
                        left: (thumbX - 11).clamp(-1.0, width - 21.0),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: HSVColor.fromAHSV(
                              1.0,
                              _hue,
                              1.0,
                              1.0,
                            ).toColor(),
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          // 4. HEX Input & Format Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF303134),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'HEX',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 1,
                    height: 20,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _hexController,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: '#000000',
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                      onChanged: (val) {
                        final parsed = _hexToColor(val);
                        if (parsed != null) {
                          _isManualTyping = true;
                          final hsv = HSVColor.fromColor(parsed);
                          setState(() {
                            _hue = hsv.hue;
                            _saturation = hsv.saturation;
                            _value = hsv.value;
                          });
                          _isManualTyping = false;
                          widget.onColorChanged(_currentHex);
                        }
                      },
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _currentHex));
                      if (widget.onShareOrCopy != null) {
                        widget.onShareOrCopy!();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            color: Colors.white70,
                            size: 13,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Copy',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
