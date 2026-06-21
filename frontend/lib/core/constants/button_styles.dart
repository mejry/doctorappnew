import 'package:flutter/material.dart';
import 'colors.dart';

class AppButtonStyles {
  // Style pour le bouton principal (vert avec texte blanc)
  static ButtonStyle primary(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.buttonPrimary,
      foregroundColor: AppColors.buttonPrimaryText,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  // Style pour le bouton secondaire (contour vert, texte noir)
  static ButtonStyle secondary(BuildContext context) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.buttonBorder,
      side: const BorderSide(color: AppColors.buttonBorder),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  // Style pour le bouton "Add" avec icône
  static ButtonStyle addButton(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryVariant,
      foregroundColor: AppColors.textWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
