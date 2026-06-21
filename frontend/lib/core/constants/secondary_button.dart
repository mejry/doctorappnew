import 'package:flutter/material.dart';
import '../../../core/constants/button_styles.dart';

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool fullWidth;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: OutlinedButton(
        style: AppButtonStyles.secondary(context),
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}
