import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  List<HealthRecord> _records = [];
  final _heartRateController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
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
      final recordsJson = prefs.getStringList('health_records') ?? [];
      
      setState(() {
        _records = recordsJson.map((json) {
          final Map<String, dynamic> data = jsonDecode(json);
          return HealthRecord(
            heartRate: data['heartRate'],
            systolic: data['systolic'],
            diastolic: data['diastolic'],
            timestamp: DateTime.parse(data['timestamp']),
          );
        }).toList();
        
        // Sort records by timestamp (newest first)
        _records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading health records: $e');
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
          'heartRate': record.heartRate,
          'systolic': record.systolic,
          'diastolic': record.diastolic,
          'timestamp': record.timestamp.toIso8601String(),
        });
      }).toList();
      
      await prefs.setStringList('health_records', recordsJson);
    } catch (e) {
      print('Error saving health records: $e');
    }
  }

  void _addRecord() {
    if (_heartRateController.text.isNotEmpty &&
        _systolicController.text.isNotEmpty &&
        _diastolicController.text.isNotEmpty) {
      
      // Validate input values
      int? heartRate = int.tryParse(_heartRateController.text);
      int? systolic = int.tryParse(_systolicController.text);
      int? diastolic = int.tryParse(_diastolicController.text);
      
      if (heartRate == null || systolic == null || diastolic == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter valid numbers'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() {
        _records.insert(
          0,
          HealthRecord(
            heartRate: heartRate,
            systolic: systolic,
            diastolic: diastolic,
            timestamp: DateTime.now(),
          ),
        );
      });
      
      // Save records
      _saveRecords();
      
      // Clear the text fields
      _heartRateController.clear();
      _systolicController.clear();
      _diastolicController.clear();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Health record added successfully'),
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
              _records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
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
          'Health Tracker',
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
                    'Add New Record',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Input fields with modern styling
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
                          controller: _heartRateController,
                          label: 'Heart Rate',
                          suffix: 'bpm',
                          icon: Icons.favorite,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                controller: _systolicController,
                                label: 'Systolic',
                                suffix: 'mmHg',
                                icon: Icons.arrow_upward,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInputField(
                                controller: _diastolicController,
                                label: 'Diastolic',
                                suffix: 'mmHg',
                                icon: Icons.arrow_downward,
                              ),
                            ),
                          ],
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
                        'History',
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
                                    Icons.favorite_border,
                                    size: 80,
                                    color: Colors.grey.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No health records yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Add your first health record above',
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
                                
                                // Determine blood pressure status
                                String bpStatus = 'Normal';
                                Color bpColor = Colors.green;
                                
                                if (record.systolic >= 140 || record.diastolic >= 90) {
                                  bpStatus = 'High';
                                  bpColor = Colors.red;
                                } else if (record.systolic >= 120 || record.diastolic >= 80) {
                                  bpStatus = 'Elevated';
                                  bpColor = Colors.orange;
                                }
                                
                                return Dismissible(
                                  key: Key(record.timestamp.toString()),
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
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      leading: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4A55A2).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.favorite,
                                          color: Color(0xFF4A55A2),
                                        ),
                                      ),
                                      title: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Heart Rate: ${record.heartRate} bpm',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: bpColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  bpStatus,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: bpColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'BP: ${record.systolic}/${record.diastolic} mmHg',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 14,
                                              color: Colors.grey.shade500,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormat('MMM dd, yyyy HH:mm').format(record.timestamp),
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
    required String suffix,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          prefixIcon: Icon(icon, color: const Color(0xFF4A55A2)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          labelStyle: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _heartRateController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    super.dispose();
  }
}

class HealthRecord {
  final int heartRate;
  final int systolic;
  final int diastolic;
  final DateTime timestamp;

  HealthRecord({
    required this.heartRate,
    required this.systolic,
    required this.diastolic,
    required this.timestamp,
  });
} 