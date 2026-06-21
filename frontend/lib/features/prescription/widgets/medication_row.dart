import 'package:flutter/material.dart';
import 'package:frontend/core/constants/colors.dart';

class MedicationRow extends StatelessWidget {
  final Map<String, dynamic> medication;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;

  const MedicationRow({
    super.key,
    required this.medication,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  // Helper method to handle null values
  String _getFieldValue(String key) {
    final value = medication[key];
    if (value == null) return '-';
    if (value is String) return value;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(_getFieldValue('name'))),
          Expanded(flex: 2, child: Text(_getFieldValue('code'))),
          Expanded(flex: 2, child: Text(_getFieldValue('dosage'))),
          Expanded(flex: 2, child: Text(_getFieldValue('form'))),
          Expanded(flex: 1, child: Text(_getFieldValue('stock'))),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color:AppColors.primary),
                  onPressed: onEditPressed,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Color.fromARGB(255, 225, 42, 42),
                  ),
                  onPressed: onDeletePressed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
