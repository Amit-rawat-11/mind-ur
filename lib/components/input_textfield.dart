// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class InputTextfield extends StatefulWidget {
  final String labelText;
  final TextEditingController controller;
  final bool isPassword;
  final Iterable<String>? autofillHints;
  // NEW (optional)
  final String? helperText;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool autocorrect;

  const InputTextfield({
    super.key,
    required this.labelText,
    required this.controller,
    required this.isPassword,
    this.helperText,
    this.errorText,
    this.autofillHints,
    this.keyboardType,
    this.autocorrect = true,
  });

  @override
  State<InputTextfield> createState() => _InputTextfieldState();
}

class _InputTextfieldState extends State<InputTextfield> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: colorScheme.surface,
      ),
      child: TextFormField(
        keyboardType: widget.keyboardType,
        autocorrect: widget.autocorrect,

        controller: widget.controller,
        obscureText: widget.isPassword ? _obscureText : false,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),

          // ✅ Helper & error
          helperText: widget.helperText,
          helperStyle: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.error,
          ),
          errorText: widget.errorText,

          // ✅ Password eye icon
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: _obscureText
                        ? colorScheme.onSurface.withOpacity(0.6)
                        : colorScheme.primary,
                  ),
                  tooltip: _obscureText ? 'Show password' : 'Hide password',
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: colorScheme.onSurface.withOpacity(0.4),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
          ),

          // ✅ Error borders
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.error, width: 1.2),
          ),
        ),
      ),
    );
  }
}
