import 'package:flutter/material.dart';
import 'package:appointment_reminder/pages/medication_reminders.dart';
import 'package:appointment_reminder/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MedicationTrackerPage extends StatefulWidget {
  const MedicationTrackerPage({super.key});

  @override
  State<MedicationTrackerPage> createState() => _MedicationTrackerPageState();
}

class _MedicationTrackerPageState extends State<MedicationTrackerPage> {
  final List<DateTime> _weekDays = List.generate(
    7,
    (index) => DateTime.now().add(Duration(days: index - 2)),
  );

  List<Medication> medications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  // Load medications from SharedPreferences
  Future<void> _loadMedications() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final medicationsJson = prefs.getStringList('medications') ?? [];
      
      setState(() {
        medications = medicationsJson.map((json) {
          final Map<String, dynamic> data = jsonDecode(json);
          return Medication(
            name: data['name'],
            dosage: data['dosage'],
            times: List<String>.from(data['times']),
            days: data['days'],
            isDone: data['isDone'] ?? false,
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading medications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save medications to SharedPreferences
  Future<void> _saveMedications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final medicationsJson = medications.map((medication) {
        return jsonEncode({
          'name': medication.name,
          'dosage': medication.dosage,
          'times': medication.times,
          'days': medication.days,
          'isDone': medication.isDone,
        });
      }).toList();
      
      await prefs.setStringList('medications', medicationsJson);
    } catch (e) {
      print('Error saving medications: $e');
    }
  }

  void _addNewMedication() async {
    final result = await Navigator.push<Medication>(
      context,
      MaterialPageRoute(
        builder: (context) => const MedicationReminderPage(),
      ),
    );

    if (result != null) {
      setState(() {
        medications.add(result);
      });
      _saveMedications(); // Save after adding
    }
  }

  void _toggleMedicationStatus(int index, bool? isDone) {
    setState(() {
      medications[index].isDone = isDone ?? false;
    });
    _saveMedications(); // Save after toggling status
  }

  void _deleteMedication(int index) {
    setState(() {
      medications.removeAt(index);
    });
    _saveMedications(); // Save after deleting
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const HomePage()),
                          );
                        },
                      ),
                      const Text(
                        'Your drug cabinet',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _addNewMedication,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Days of the week
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _weekDays.length,
                  itemBuilder: (context, index) {
                    final day = _weekDays[index];
                    final isToday = day.day == DateTime.now().day;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        width: 60,
                        decoration: BoxDecoration(
                          color: isToday
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              day.day.toString(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isToday ? Colors.green : Colors.black87,
                              ),
                            ),
                            Text(
                              [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun'
                              ][day.weekday - 1],
                              style: TextStyle(
                                fontSize: 14,
                                color: isToday ? Colors.green : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Today's medication plan",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : medications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.medication_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No medications added yet',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _addNewMedication,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Medication'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4A55A2),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: medications.length,
                            itemBuilder: (context, index) {
                              final medication = medications[index];
                              return Dismissible(
                                key: Key('medication_${index}_${medication.name}'),
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                direction: DismissDirection.endToStart,
                                onDismissed: (direction) {
                                  _deleteMedication(index);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${medication.name} removed'),
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        onPressed: () {
                                          setState(() {
                                            medications.insert(index, medication);
                                          });
                                          _saveMedications();
                                        },
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  medication.name.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    decoration: medication.isDone
                                                        ? TextDecoration.lineThrough
                                                        : null,
                                                    color: medication.isDone
                                                        ? Colors.grey
                                                        : Colors.black,
                                                  ),
                                                ),
                                                Text(
                                                  medication.dosage,
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Times: ${medication.times.join(", ")}',
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              TextButton.icon(
                                                onPressed: () =>
                                                    _toggleMedicationStatus(
                                                        index, false),
                                                icon: const Icon(Icons.close),
                                                label: const Text('Skip'),
                                              ),
                                              const SizedBox(width: 8),
                                              TextButton.icon(
                                                onPressed: () =>
                                                    _toggleMedicationStatus(
                                                        index, true),
                                                icon: const Icon(Icons.check),
                                                label: const Text('Done'),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
