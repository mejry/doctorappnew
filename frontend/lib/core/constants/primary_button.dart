import 'package:flutter/material.dart';
import '../../../core/constants/button_styles.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool fullWidth;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        style: AppButtonStyles.primary(context),
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}