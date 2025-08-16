import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CheckupPage extends StatefulWidget {
  const CheckupPage({super.key});

  @override
  State<CheckupPage> createState() => _CheckupPageState();
}

class _CheckupPageState extends State<CheckupPage> {
  List<CheckupRecord> _records = [];
  final _hospitalController = TextEditingController();
  final _doctorController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  // Load records from SharedPreferences
  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordsJson = prefs.getStringList('checkup_records') ?? [];
      
      setState(() {
        _records = recordsJson.map((json) {
          final Map<String, dynamic> data = jsonDecode(json);
          return CheckupRecord(
            hospital: data['hospital'],
            doctor: data['doctor'],
            date: DateTime.parse(data['date']),
            time: TimeOfDay(
              hour: data['time_hour'],
              minute: data['time_minute'],
            ),
            note: data['note'],
          );
        }).toList();
        
        // Sort records by date and time
        _records.sort((a, b) {
          int dateComparison = a.date.compareTo(b.date);
          if (dateComparison != 0) return dateComparison;
          
          return (a.time.hour * 60 + a.time.minute) - 
                 (b.time.hour * 60 + b.time.minute);
        });
        
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading checkup records: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save records to SharedPreferences
  Future<void> _saveRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordsJson = _records.map((record) {
        return jsonEncode({
          'hospital': record.hospital,
          'doctor': record.doctor,
          'date': record.date.toIso8601String(),
          'time_hour': record.time.hour,
          'time_minute': record.time.minute,
          'note': record.note,
        });
      }).toList();
      
      await prefs.setStringList('checkup_records', recordsJson);
    } catch (e) {
      print('Error saving checkup records: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A55A2),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4A55A2),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A55A2),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4A55A2),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _addRecord() {
    if (_hospitalController.text.isNotEmpty &&
        _doctorController.text.isNotEmpty &&
        _selectedDate != null &&
        _selectedTime != null) {
      setState(() {
        _records.insert(
          0,
          CheckupRecord(
            hospital: _hospitalController.text,
            doctor: _doctorController.text,
            date: _selectedDate!,
            time: _selectedTime!,
            note: _noteController.text,
          ),
        );
        
        // Sort records by date and time
        _records.sort((a, b) {
          int dateComparison = a.date.compareTo(b.date);
          if (dateComparison != 0) return dateComparison;
          
          return (a.time.hour * 60 + a.time.minute) - 
                 (b.time.hour * 60 + b.time.minute);
        });
      });
      
      // Save records
      _saveRecords();
      
      // Clear the fields
      _hospitalController.clear();
      _doctorController.clear();
      _noteController.clear();
      _selectedDate = null;
      _selectedTime = null;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checkup record added successfully'),
          backgroundColor: Color(0xFF4A55A2),
        ),
      );
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _deleteRecord(int index) {
    final deletedRecord = _records[index];
    setState(() {
      _records.removeAt(index);
    });
    _saveRecords();
    
    // Show snackbar with undo option
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Record deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _records.insert(index, deletedRecord);
              _records.sort((a, b) {
                int dateComparison = a.date.compareTo(b.date);
                if (dateComparison != 0) return dateComparison;
                
                return (a.time.hour * 60 + a.time.minute) - 
                       (b.time.hour * 60 + b.time.minute);
              });
            });
            _saveRecords();
          },
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
          'Checkup Records',
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
                    'Schedule New Checkup',
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
                          controller: _hospitalController,
                          label: 'Hospital Name',
                          icon: Icons.local_hospital,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          controller: _doctorController,
                          label: 'Doctor Name',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateTimeButton(
                                label: _selectedDate == null
                                    ? 'Select Date'
                                    : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                                icon: Icons.calendar_today,
                                onPressed: () => _selectDate(context),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDateTimeButton(
                                label: _selectedTime == null
                                    ? 'Select Time'
                                    : _selectedTime!.format(context),
                                icon: Icons.access_time,
                                onPressed: () => _selectTime(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          controller: _noteController,
                          label: 'Notes',
                          icon: Icons.note,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _addRecord,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A55A2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            child: const Text(
                              'Add Record',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upcoming Checkups',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A55A2),
                        ),
                      ),
                      _records.isNotEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A55A2).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_records.length} Records',
                                style: const TextStyle(
                                  color: Color(0xFF4A55A2),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : const SizedBox(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _records.isEmpty
                          ? Center(
                              child: Column(
                                children: [
                                  const SizedBox(height: 40),
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 80,
                                    color: Colors.grey.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No checkup records yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Add your first checkup above',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _records.length,
                              itemBuilder: (context, index) {
                                final record = _records[index];
                                final bool isPast = record.date.isBefore(
                                  DateTime.now().subtract(const Duration(days: 1)),
                                );
                                
                                // Calculate days remaining
                                final difference = record.date.difference(DateTime.now()).inDays;
                                final String timeStatus = isPast
                                    ? 'Past appointment'
                                    : difference == 0
                                        ? 'Today'
                                        : difference == 1
                                            ? 'Tomorrow'
                                            : '$difference days remaining';
                                
                                return Dismissible(
                                  key: Key('${record.hospital}_${record.date}_$index'),
                                  background: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade400,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (direction) {
                                    _deleteRecord(index);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        ListTile(
                                          contentPadding: const EdgeInsets.all(16),
                                          leading: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isPast
                                                  ? Colors.grey.withOpacity(0.1)
                                                  : const Color(0xFF4A55A2).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.calendar_month,
                                              color: isPast
                                                  ? Colors.grey
                                                  : const Color(0xFF4A55A2),
                                            ),
                                          ),
                                          title: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                record.hospital,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: isPast ? Colors.grey : Colors.black,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Dr. ${record.doctor}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 15,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time,
                                                    size: 14,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      '${DateFormat('MMM dd, yyyy').format(record.date)} at ${record.time.format(context)}',
                                                      style: TextStyle(
                                                        color: Colors.grey.shade500,
                                                        fontSize: 14,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (record.note.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.note,
                                                      size: 14,
                                                      color: Colors.grey.shade500,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        record.note,
                                                        style: TextStyle(
                                                          color: Colors.grey.shade500,
                                                          fontSize: 14,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isPast
                                                  ? Colors.grey.withOpacity(0.1)
                                                  : difference == 0
                                                      ? Colors.orange.withOpacity(0.1)
                                                      : const Color(0xFF4A55A2).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              timeStatus,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isPast
                                                    ? Colors.grey
                                                    : difference == 0
                                                        ? Colors.orange
                                                        : const Color(0xFF4A55A2),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
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

  Widget _buildDateTimeButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF4A55A2), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hospitalController.dispose();
    _doctorController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}

class CheckupRecord {
  final String hospital;
  final String doctor;
  final DateTime date;
  final TimeOfDay time;
  final String note;

  CheckupRecord({
    required this.hospital,
    required this.doctor,
    required this.date,
    required this.time,
    required this.note,
  });
} 