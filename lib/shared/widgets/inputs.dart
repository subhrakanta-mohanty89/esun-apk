/// ESUN Input Components
/// 
/// Reusable input fields and form components.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/theme.dart';

/// Text Input Field
class FPTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final String? prefixText;
  final Widget? suffix;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  
  const FPTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.prefixText,
    this.suffix,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });
  
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onTap: onTap,
      onFieldSubmitted: onSubmitted,
      autofocus: autofocus,
      textCapitalization: textCapitalization,
      validator: validator,
      style: ESUNTypography.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        helperText: helperText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        prefixText: prefixText,
        suffix: suffix,
      ),
    );
  }
}

/// Password Input Field
class FPPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  
  const FPPasswordField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
  });
  
  @override
  State<FPPasswordField> createState() => _FPPasswordFieldState();
}

class _FPPasswordFieldState extends State<FPPasswordField> {
  bool _obscureText = true;
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscureText,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: ESUNTypography.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.label ?? 'Password',
        hintText: widget.hint,
        errorText: widget.errorText,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
    );
  }
}

/// Search Input Field
class FPSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  
  const FPSearchField({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.onClear,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
  });
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? ESUNColors.darkSurfaceVariant : ESUNColors.surfaceVariant,
        borderRadius: ESUNRadius.fullRadius,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        readOnly: readOnly,
        autofocus: autofocus,
        onChanged: onChanged,
        onTap: onTap,
        style: ESUNTypography.bodyMedium,
        decoration: InputDecoration(
          hintText: hint ?? 'Search',
          prefixIcon: Icon(
            Icons.search,
            color: colorScheme.onSurfaceVariant,
          ),
          suffixIcon: controller?.text.isNotEmpty == true
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller?.clear();
                    onClear?.call();
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: ESUNSpacing.lg,
            vertical: ESUNSpacing.md,
          ),
        ),
      ),
    );
  }
}

/// Amount Input Field (for financial inputs)
class FPAmountField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? errorText;
  final String currencySymbol;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool autofocus;
  
  const FPAmountField({
    super.key,
    this.controller,
    this.label,
    this.errorText,
    this.currencySymbol = '₹',
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: ESUNTypography.amountLarge,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        prefixText: '$currencySymbol ',
        prefixStyle: ESUNTypography.amountLarge.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );
  }
}

/// OTP Input Field
class FPOtpField extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final bool obscure;
  
  const FPOtpField({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
    this.obscure = false,
  });
  
  @override
  State<FPOtpField> createState() => _FPOtpFieldState();
}

class _FPOtpFieldState extends State<FPOtpField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  
  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }
  
  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
  
  String get _otp => _controllers.map((c) => c.text).join();
  
  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    
    widget.onChanged?.call(_otp);
    
    if (_otp.length == widget.length) {
      widget.onCompleted?.call(_otp);
    }
  }
  
  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate responsive box width based on screen size
    // Total width = (boxWidth * length) + (spacing * (length - 1)) + padding
    const horizontalPadding = ESUNSpacing.xl * 2; // 32 * 2 = 64
    final totalSpacing = ESUNSpacing.sm * (widget.length - 1);
    final availableWidth = screenWidth - horizontalPadding - totalSpacing;
    final boxWidth = (availableWidth / widget.length).clamp(40.0, 52.0);
    final boxHeight = boxWidth * 1.15;
    final fontSize = boxWidth * 0.46;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        final hasValue = _controllers[index].text.isNotEmpty;
        return Container(
          width: boxWidth,
          height: boxHeight,
          margin: EdgeInsets.only(
            right: index < widget.length - 1 ? ESUNSpacing.sm : 0,
          ),
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) => _onKeyEvent(index, event),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              maxLength: 1,
              obscureText: widget.obscure,
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) {
                setState(() {});
                _onChanged(index, value);
              },
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: isDark 
                    ? ESUNColors.darkSurfaceVariant 
                    : ESUNColors.surfaceVariant,
                contentPadding: EdgeInsets.symmetric(vertical: boxHeight * 0.25),
                border: OutlineInputBorder(
                  borderRadius: ESUNRadius.smRadius,
                  borderSide: BorderSide(
                    color: isDark ? Colors.white24 : Colors.black26,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: ESUNRadius.smRadius,
                  borderSide: BorderSide(
                    color: hasValue
                        ? primaryColor
                        : (isDark ? Colors.white24 : Colors.black26),
                    width: hasValue ? 2 : 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: ESUNRadius.smRadius,
                  borderSide: BorderSide(
                    color: primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// PIN Input Field
class FPPinField extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onCompleted;
  final bool obscure;
  
  const FPPinField({
    super.key,
    this.length = 4,
    this.onCompleted,
    this.obscure = true,
  });
  
  @override
  State<FPPinField> createState() => _FPPinFieldState();
}

class _FPPinFieldState extends State<FPPinField> {
  String _pin = '';
  
  void _addDigit(String digit) {
    if (_pin.length < widget.length) {
      setState(() {
        _pin += digit;
      });
      
      if (_pin.length == widget.length) {
        widget.onCompleted?.call(_pin);
      }
    }
  }
  
  void _removeDigit() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        // PIN Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (index) {
            final isFilled = index < _pin.length;
            return Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: ESUNSpacing.sm),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled 
                    ? colorScheme.primary 
                    : Colors.transparent,
                border: Border.all(
                  color: isFilled 
                      ? colorScheme.primary 
                      : (isDark ? ESUNColors.darkDivider : ESUNColors.border),
                  width: 2,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: ESUNSpacing.xxxl),
        // Number Pad
        _buildNumberPad(),
      ],
    );
  }
  
  Widget _buildNumberPad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPadButton('1'),
            _buildPadButton('2'),
            _buildPadButton('3'),
          ],
        ),
        const SizedBox(height: ESUNSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPadButton('4'),
            _buildPadButton('5'),
            _buildPadButton('6'),
          ],
        ),
        const SizedBox(height: ESUNSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPadButton('7'),
            _buildPadButton('8'),
            _buildPadButton('9'),
          ],
        ),
        const SizedBox(height: ESUNSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPadButton(
              '',
              icon: Icons.fingerprint,
              onTap: () {}, // Biometric trigger
            ),
            _buildPadButton('0'),
            _buildPadButton(
              '',
              icon: Icons.backspace_outlined,
              onTap: _removeDigit,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildPadButton(
    String digit, {
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (digit.isNotEmpty) {
            _addDigit(digit);
          } else {
            onTap?.call();
          }
        },
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, size: ESUNIconSize.lg)
              : Text(
                  digit,
                  style: ESUNTypography.headlineLarge,
                ),
        ),
      ),
    );
  }
}

/// Dropdown Field
class FPDropdownField<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final String? label;
  final String? hint;
  final String? errorText;
  final ValueChanged<T?>? onChanged;
  final IconData? prefixIcon;
  
  const FPDropdownField({
    super.key,
    this.value,
    required this.items,
    this.label,
    this.hint,
    this.errorText,
    this.onChanged,
    this.prefixIcon,
  });
  
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      style: ESUNTypography.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
    );
  }
}



