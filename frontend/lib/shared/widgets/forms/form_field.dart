import 'package:flutter/material.dart';
import '../../../core/constants/form_styles.dart';

class AppFormField extends StatelessWidget {
  final String label;
  final bool required;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String?)? onChanged;
  final void Function(String)? onFieldSubmitted; // ✅ added
  final Widget? suffixIcon;
  final bool readOnly;
  final void Function()? onTap;
  final bool obscureText;

  const AppFormField({
    super.key,
    required this.label,
    this.required = false,
    this.controller,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted, // ✅ added
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppFormStyles.wrapWithShadow(
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        obscureText: obscureText,
        decoration:
            AppFormStyles.inputDecoration(label, suffixIcon: suffixIcon),
        validator: validator ??
            (required
                ? (v) => v?.isEmpty ?? true ? 'This field is required' : null
                : null),
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted, // ✅ added
      ),
    );
  }
}

class AppDropdownField<T> extends StatelessWidget {
  final String label;
  final bool required;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;

  const AppDropdownField({
    super.key,
    required this.label,
    this.required = false,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return AppFormStyles.wrapWithShadow(
      DropdownButtonFormField<T>(
        value: value,
        decoration: AppFormStyles.inputDecoration(label),
        items: items,
        onChanged: onChanged,
        validator: validator ??
            (required
                ? (v) => v == null ? 'Please select a value' : null
                : null),
      ),
    );
  }
}
