// lib/features/patient/widgets/health_assessment_step.dart - VERSION COMPATIBLE MODÈLE IA
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/add_button.dart';
import 'package:frontend/core/constants/primary_button.dart';
import 'package:frontend/core/constants/secondary_button.dart';
import 'package:frontend/shared/widgets/forms/form_field.dart';
import 'package:frontend/features/patient/models/medical_history.dart';
import '../../../core/constants/button_styles.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/form_styles.dart';

class HealthAssessmentStep extends StatefulWidget {
  final MedicalHistory? initialData;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const HealthAssessmentStep({
    super.key,
    this.initialData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<HealthAssessmentStep> createState() => _HealthAssessmentStepState();
}

class _HealthAssessmentStepState extends State<HealthAssessmentStep> {
  String? _smokingStatus;
  String? _alcoholConsumption;

  final List<String> _chronicDiseases = [];
  final List<String> _allergies = [];

  final _chronicController = TextEditingController();
  final _allergyController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.initialData != null) {
      final data = widget.initialData!;
      _smokingStatus = data.smokingStatus;
      _alcoholConsumption = data.alcoholConsumption;

      if (data.chronicDiseases != null) {
        _chronicDiseases.addAll(data.chronicDiseases!);
      }
      if (data.allergies != null) {
        _allergies.addAll(data.allergies!);
      }
    }
  }

  void _saveAndProceed() {
    final healthData = <String, dynamic>{
      'chronicDiseases': _chronicDiseases,
      'allergies': _allergies,
      'smokingStatus': _smokingStatus,
      'alcoholConsumption': _alcoholConsumption,
      'currentMedications': <CurrentMedication>[],
    };

    widget.onNext(healthData);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDynamicList("Allergy", _allergyController, _allergies),
            const SizedBox(height: 10),
            _buildDynamicList(
                "Chronic Disease", _chronicController, _chronicDiseases),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildRadioGroup<String>(
                      "Smoking Status",
                      [
                        'Non-smoker',
                        'Ex-smoker',
                        'Smoker',
                        'Former smoker'
                      ], // ✅ AJOUT: Former smoker
                      _smokingStatus,
                      (val) => setState(() => _smokingStatus = val),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildRadioGroup<String>(
                      "Alcohol Consumption",
                      [
                        'Never',
                        'Occasionally',
                        'Regularly',
                        'No'
                      ], // ✅ AJOUT: No
                      _alcoholConsumption,
                      (val) => setState(() => _alcoholConsumption = val),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SecondaryButton(
                  text: "Back",
                  onPressed: widget.onBack,
                ),
                const SizedBox(width: 16),
                PrimaryButton(
                  text: "Next",
                  onPressed: _saveAndProceed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioGroup<T>(String title, List<T> options, T? groupValue,
      void Function(T?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
        ),
        Wrap(
          spacing: 20,
          children: options
              .map((option) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<T>(
                        value: option,
                        groupValue: groupValue,
                        onChanged: onChanged,
                        activeColor: AppColors.primary,
                      ),
                      Text(option.toString()),
                    ],
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDynamicList(
      String label, TextEditingController controller, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AppFormField(
                label: "Enter $label",
                controller: controller,
              ),
            ),
            const SizedBox(width: 10),
            AddButton(
              text: '',
              icon: Icons.add,
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    items.add(controller.text.trim());
                    controller.clear();
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .asMap()
              .entries
              .map(
                (entry) => Chip(
                  label: Text(entry.value),
                  onDeleted: () {
                    setState(() {
                      items.removeAt(entry.key);
                    });
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
