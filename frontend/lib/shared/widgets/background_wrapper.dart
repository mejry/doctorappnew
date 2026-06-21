import 'package:flutter/material.dart';

class BackgroundWrapper extends StatelessWidget {
  final Widget child;

  const BackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Image en haut à droite
        Positioned(
          top: 0,
          right: 0,
          child: Image.asset(
            'assets/images/global/haut.png',
            width: 150,
            fit: BoxFit.contain,
          ),
        ),
        // Image en bas à gauche
        Positioned(
          bottom: 0,
          left: 0,
          child: Image.asset(
            'assets/images/global/bas.png',
            width: 150,
            fit: BoxFit.contain,
          ),
        ),
        // Contenu principal
        Positioned.fill(child: child),
      ],
    );
  }
}
