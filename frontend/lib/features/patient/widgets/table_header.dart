import 'package:flutter/material.dart';

class TableHeader extends StatelessWidget {
  final String title;
  final Color color;

  const TableHeader(this.title, {super.key, this.color = Colors.black});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
