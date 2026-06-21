import 'package:flutter/material.dart';
import '../../../core/constants/button_styles.dart';

class AddButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData icon;

  const AddButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: AppButtonStyles.addButton(context),
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(text),
    );
  }
}
