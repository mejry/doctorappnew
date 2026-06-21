// lib/features/prescription/screens/medication_list_screen.dart - VERSION CORRIGÉE
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/constants/add_button.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/features/prescription/providers/medication_provider.dart';
import 'package:frontend/features/prescription/widgets/update_medication_dialog.dart';
import '../widgets/medication_header.dart';
import '../widgets/medication_row.dart';

class MedicationListScreen extends StatefulWidget {
  final VoidCallback onAddMedicationPressed;

  const MedicationListScreen({super.key, required this.onAddMedicationPressed});

  @override
  State<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends State<MedicationListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Charger les médicaments au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationProvider>().loadMedications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });

    context.read<MedicationProvider>().searchMedications(query);
  }

  void _editMedication(Map<String, dynamic> medication) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Empêche la fermeture en cliquant à l'extérieur
      builder: (context) {
        return UpdateMedicationDialog(
          medication: medication,
          onUpdate: (updatedMed) async {
            final provider = context.read<MedicationProvider>();

            debugPrint('Updating medication with data: $updatedMed');

            final success = await provider.updateMedication(
                medication['id'], _convertToApiFormat(updatedMed));

            if (mounted) {
              if (success) {
                Navigator.of(context)
                    .pop(); // Fermer le dialog SEULEMENT en cas de succès
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Medication updated successfully'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                // NE PAS fermer le dialog en cas d'erreur
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Error: ${provider.error ?? 'Unknown error'}'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            }
          },
          onCancel: () {
            Navigator.of(context)
                .pop(); // Fermer seulement quand Cancel est pressé
          },
        );
      },
    );
  }

  void _deleteMedication(Map<String, dynamic> medication) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Medication'),
          content:
              Text('Are you sure you want to delete "${medication['name']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                final provider = context.read<MedicationProvider>();
                final success =
                    await provider.deleteMedication(medication['id']);

                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Medication deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Error: ${provider.error ?? 'Unknown error'}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic> _convertToApiFormat(Map<String, dynamic> formData) {
    // Liste des valeurs valides pour le formulaire
    const validForms = [
      'Tablet',
      'Capsule',
      'Solution',
      'Injection',
      'Cream',
      'Suppository',
      'Suspension',
      'Aerosol',
      'Powder',
      'Patch',
      'Drops',
      'Other'
    ];

    // Liste des valeurs valides pour la route
    const validRoutes = [
      'Oral',
      'Sublingual',
      'Topical',
      'IV',
      'IM',
      'SC',
      'Rectal',
      'Inhalation',
      'Other'
    ];

    debugPrint('Converting form data to API format: $formData');

    final apiData = {
      'identification': {
        'name': formData['name'] ?? '',
        'genericName': formData['genericName'] ?? '',
        'brandNames': formData['brandNames'] is String
            ? (formData['brandNames'] as String).isNotEmpty
                ? [(formData['brandNames'] as String)]
                : []
            : formData['brandNames'] ?? [],
        'manufacturer': formData['manufacturerName']?.toString().isNotEmpty ==
                true
            ? {
                'name': formData['manufacturerName'],
                'country':
                    formData['manufacturerCountry']?.toString().isNotEmpty ==
                            true
                        ? formData['manufacturerCountry']
                        : null
              }
            : null,
        'codes': {
          'internal': formData['code']?.toString() ?? '',
          'national': formData['code']?.toString() ?? '',
        }
      },
      'pharmaceuticalProperties': {
        'form': validForms.contains(formData['form'])
            ? formData['form']
            : 'Tablet', // Valeur par défaut valide
        'composition': formData['ingredient']?.toString().isNotEmpty == true
            ? [
                {
                  'ingredient': formData['ingredient']?.toString() ?? '',
                  'strength': formData['strength']?.toString() ?? '',
                }
              ]
            : [],
        'route': validRoutes.contains(formData['route'])
            ? formData['route']
            : 'Oral', // Valeur par défaut valide
        'storage': {
          'conditions': formData['storageConditions']?.toString() ?? '',
          'shelfLife': formData['shelfLife']?.toString() ?? '',
        }
      },
      'dosage': {
        'standard': {
          'adult': {
            'dose': formData['dosage']?.toString() ?? 'As directed',
            'frequency': 'As needed',
            'maxDailyDose': 'As directed'
          }
        }
      },
      'inventory': {
        'currentStock': _parseStock(formData['stock']),
        'unit': 'units',
        'threshold': 10,
        'status': 'In Stock'
      }
    };

    debugPrint('Converted API data: $apiData');
    return apiData;
  }

  int _parseStock(dynamic stockValue) {
    if (stockValue == null) return 0;
    if (stockValue is int) return stockValue;
    if (stockValue is String) {
      return int.tryParse(stockValue) ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textWhite,
      appBar: AppBar(
        backgroundColor: AppColors.textWhite,
        elevation: 0,
        title: const Text(
          'Medication List',
          style: TextStyle(color: AppColors.textBlack),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AddButton(
              text: 'Add Medication',
              icon: Icons.add,
              onPressed: widget.onAddMedicationPressed,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search medications...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _onSearch,
            ),
          ),

          // Liste des médicaments avec scroll
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.textWhite,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const MedicationTableHeader(),
                    const Divider(height: 1, thickness: 1),
                    Expanded(
                      child: Consumer<MedicationProvider>(
                        builder: (context, provider, child) {
                          // État de chargement
                          if (provider.isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          // Gestion des erreurs
                          if (provider.error != null) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading medications',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    provider.error!,
                                    style: TextStyle(color: Colors.grey[600]),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      provider.clearError();
                                      provider.loadMedications();
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Aucun médicament trouvé
                          if (!provider.hasMedications) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.medication_outlined,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _isSearching
                                        ? 'No medications found for your search'
                                        : 'No medications available',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isSearching
                                        ? 'Try adjusting your search terms'
                                        : 'Add medications to get started',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Liste des médicaments avec scroll
                          final medications = provider.medicationsAsMap;
                          return Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: medications.length,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemBuilder: (context, index) {
                                final medication = medications[index];
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  child: MedicationRow(
                                    medication: medication,
                                    onEditPressed: () =>
                                        _editMedication(medication),
                                    onDeletePressed: () =>
                                        _deleteMedication(medication),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
