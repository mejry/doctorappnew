// lib/main.dart - VERSION CORRIGÉE AVEC ROLEPROVIDER
import 'package:flutter/material.dart';
import 'package:frontend/features/prescription/providers/medication_provider.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/auth/providers/role_provider.dart'; // ✅ IMPORT AJOUTÉ
import 'package:frontend/features/auth/widgets/auth_wrapper.dart';
import 'package:frontend/features/patient/providers/patient_provider.dart';
import 'package:frontend/features/consultation/providers/consultation_provider.dart';
import 'package:frontend/features/prescription/providers/prescription_provider.dart';
import 'package:frontend/features/auth/providers/user_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ AuthProvider DOIT être en premier car les autres en dépendent
        ChangeNotifierProvider(create: (context) => AuthProvider()),

        // ✅ AJOUT DE ROLEPROVIDER - CRITIQUE POUR LES ÉCRANS DE RÔLES
        ChangeNotifierProvider(create: (context) => RoleProvider()),

        // Autres providers
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => PatientProvider()),
        ChangeNotifierProvider(create: (context) => ConsultationProvider()),
        ChangeNotifierProvider(create: (context) => PrescriptionProvider()),
        ChangeNotifierProvider(create: (context) => MedicationProvider()),
      ],
      child: MaterialApp(
        title: 'Medical App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          fontFamily: 'Roboto',
        ),
        // ✅ AuthWrapper gère automatiquement la navigation
        home: const AuthWrapper(),
      ),
    );
  }
}
