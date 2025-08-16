import 'package:flutter/material.dart';
import 'package:appointment_reminder/models/reminder_service.dart';
import 'package:appointment_reminder/widgets/time_input.dart';
import 'package:appointment_reminder/services/notification_service.dart';

// Add Medication model in same file for reference
class Medication {
  final String name;
  final String dosage;
  final List<String> times;
  final int days;
  bool isDone;

  Medication({
    required this.name,
    required this.dosage,
    required this.times,
    required this.days,
    this.isDone = false,
  });
}

class MedicationReminderPage extends StatefulWidget {
  const MedicationReminderPage({super.key});

  @override
  State<MedicationReminderPage> createState() => _MedicationReminderPageState();
}

class _MedicationReminderPageState extends State<MedicationReminderPage> {
  final TextEditingController _medicationNameController =
      TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();

  TimeOfDay? _time1;
  TimeOfDay? _time2;
  TimeOfDay? _time3;

  @override
  void dispose() {
    _medicationNameController.dispose();
    _dosageController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _scheduleReminders() async {
    if (_medicationNameController.text.isEmpty ||
        _dosageController.text.isEmpty ||
        _daysController.text.isEmpty ||
        _time1 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in required fields.')),
      );
      return;
    }

    final String medicationName = _medicationNameController.text;
    final String dosage = _dosageController.text;
    final int days = int.tryParse(_daysController.text) ?? 0;

    if (days <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number of days.')),
      );
      return;
    }

    final List<String> times = [
      if (_time1 != null) _formatTime(_time1!),
      if (_time2 != null) _formatTime(_time2!),
      if (_time3 != null) _formatTime(_time3!),
    ];

    try {
      // Schedule notifications for each time
      for (int day = 0; day < days; day++) {
        for (int i = 0; i < times.length; i++) {
          final List<String> timeParts = times[i].split(':');
          final int hour = int.parse(timeParts[0]);
          final int minute = int.parse(timeParts[1]);

          final DateTime scheduledTime = DateTime.now()
              .add(Duration(days: day))
              .copyWith(hour: hour, minute: minute, second: 0);

          // Only schedule if the time hasn't passed today
          if (scheduledTime.isAfter(DateTime.now())) {
            await NotificationService.scheduleNotification(
              id: day * times.length + i,
              title: 'Medication Reminder',
              body: 'Time to take $medicationName - $dosage',
              scheduledTime: scheduledTime,
            );
          }
        }
      }

      // Save to ReminderService
      await ReminderService.addReminder(
        medicationName: medicationName,
        dosage: dosage,
        times: times,
        days: days,
      );

      // Create medication object
      final newMedication = Medication(
        name: medicationName,
        dosage: dosage,
        times: times,
        days: days,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder saved successfully!')),
        );
      }

      // Return the medication data
      Navigator.pop(context, newMedication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save reminder: $e')),
        );
      }
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF4A55A2)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          labelStyle: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4A55A2),
        title: const Text(
          'Add New Medication',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF4A55A2),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Medication Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInputField(
                          controller: _medicationNameController,
                          label: 'Medication Name',
                          icon: Icons.medication,
                          capitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          controller: _dosageController,
                          label: 'Dosage (e.g., 25 mcg, 2 pills)',
                          icon: Icons.medical_information,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reminder Times',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A55A2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TimeInput(
                          label: 'First Dose (Required)',
                          onTimeChanged: (time) => setState(() => _time1 = time),
                        ),
                        const SizedBox(height: 12),
                        TimeInput(
                          label: 'Second Dose (Optional)',
                          onTimeChanged: (time) => setState(() => _time2 = time),
                        ),
                        const SizedBox(height: 12),
                        TimeInput(
                          label: 'Third Dose (Optional)',
                          onTimeChanged: (time) => setState(() => _time3 = time),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Duration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A55A2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          controller: _daysController,
                          label: 'Number of Days',
                          icon: Icons.calendar_today,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _scheduleReminders,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A55A2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'Save Medication',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
