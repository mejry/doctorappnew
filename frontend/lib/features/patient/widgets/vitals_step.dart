// lib/features/patient/widgets/vitals_step.dart - MODIFIÉ
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/primary_button.dart';
import 'package:frontend/core/constants/secondary_button.dart';
import 'package:frontend/shared/widgets/forms/form_field.dart';
import 'package:frontend/features/patient/models/medical_history.dart';

class VitalsStep extends StatefulWidget {
  final MedicalHistory? initialData;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const VitalsStep({
    super.key,
    this.initialData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<VitalsStep> createState() => _VitalsStepState();
}

class _VitalsStepState extends State<VitalsStep> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _bloodGlucoseController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _oxygenSaturationController = TextEditingController();
  final _bloodPressureController = TextEditingController();
  final _respiratoryRateController = TextEditingController();
  final _bodyTemperatureController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize with existing data if available
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _bloodGlucoseController.text = data.bloodGlucoseLevel?.toString() ?? '';
      _heartRateController.text = data.heartRate?.toString() ?? '';
      _oxygenSaturationController.text =
          data.oxygenSaturation?.toString() ?? '';
      _bloodPressureController.text = data.bloodPressure ?? '';
      _respiratoryRateController.text = data.respiratoryRate?.toString() ?? '';
      _bodyTemperatureController.text = data.bodyTemperature?.toString() ?? '';
      _weightController.text = data.weight?.toString() ?? '';
      _heightController.text = data.height?.toString() ?? '';
    }
  }

  void _saveAndProceed() {
    if (!_formKey.currentState!.validate()) return;

    final vitalsData = <String, dynamic>{
      'bloodGlucoseLevel': _bloodGlucoseController.text.isNotEmpty
          ? double.tryParse(_bloodGlucoseController.text)
          : null,
      'heartRate': _heartRateController.text.isNotEmpty
          ? int.tryParse(_heartRateController.text)
          : null,
      'oxygenSaturation': _oxygenSaturationController.text.isNotEmpty
          ? int.tryParse(_oxygenSaturationController.text)
          : null,
      'bloodPressure': _bloodPressureController.text.isNotEmpty
          ? _bloodPressureController.text
          : null,
      'respiratoryRate': _respiratoryRateController.text.isNotEmpty
          ? int.tryParse(_respiratoryRateController.text)
          : null,
      'bodyTemperature': _bodyTemperatureController.text.isNotEmpty
          ? double.tryParse(_bodyTemperatureController.text)
          : null,
      'weight': _weightController.text.isNotEmpty
          ? double.tryParse(_weightController.text)
          : null,
      'height': _heightController.text.isNotEmpty
          ? double.tryParse(_heightController.text)
          : null,
    };

    widget.onNext(vitalsData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      SizedBox(
                        width: 350,
                        child: AppFormField(
                          label: "Blood Glucose Level (mg/dL)",
                          keyboardType: TextInputType.number,
                          controller: _bloodGlucoseController,
                        ),
                      ),
                      SizedBox(
                        width: 350,
                        child: AppFormField(
                          label: "Heart Rate (bpm)",
                          keyboardType: TextInputType.number,
                          controller: _heartRateController,
                        ),
                      ),
                      SizedBox(
                        width: 350,
                        child: AppFormField(
                          label: "Oxygen Saturation (%)",
                          keyboardType: TextInputType.number,
                          controller: _oxygenSaturationController,
                        ),
                      ),
                      SizedBox(
                        width: 350,
                        child: AppFormField(
                          label: "Blood Pressure (e.g., 120/80)",
                          keyboardType: TextInputType.text,
                          controller: _bloodPressureController,
                        ),
                      ),
                      SizedBox(
                        width: 350,
                        child: AppFormField(
                          label: "Respiratory Rate (breaths/min)",
                          keyboardType: TextInputType.number,
                          controller: _respiratoryRateController,
                        ),
                      ),
                      SizedBox(
                        width: 350,
                        child: AppFormField(
                          label: "Body Temperature (°C)",
                          keyboardType: TextInputType.number,
                          controller: _bodyTemperatureController,
                        ),
                      ),
                      SizedBox(
                        width: 350,
                        child: AppFormField(
                          label: "Weight (kg)",
                          keyboardType: TextInputType.number,
                          controller: _weightController,
                        ),
                      ),
                      SizedBox(
                        width: 350,
                        child: AppFormField(
                          label: "Height (cm)",
                          keyboardType: TextInputType.number,
                          controller: _heightController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
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
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bloodGlucoseController.dispose();
    _heartRateController.dispose();
    _oxygenSaturationController.dispose();
    _bloodPressureController.dispose();
    _respiratoryRateController.dispose();
    _bodyTemperatureController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }
}
