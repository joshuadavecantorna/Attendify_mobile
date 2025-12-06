import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../bloc/teacher_bloc.dart';
import '../../bloc/teacher_event.dart';
import '../../bloc/teacher_state.dart';

class CreateSessionScreen extends StatefulWidget {
  final int? classId;

  const CreateSessionScreen({super.key, this.classId});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  int? _selectedClassId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
  bool _generateQR = true;

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.classId;
    if (_selectedClassId == null) {
      context.read<TeacherBloc>().add(const LoadTeacherClasses());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Attendance Session'),
      ),
      body: BlocConsumer<TeacherBloc, TeacherState>(
        listener: (context, state) {
          if (state is AttendanceSessionCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Session created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            // Navigate to session details or QR display
            context.push('/teacher/session-qr/${state.session.id}');
          } else if (state is TeacherError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class Selection
                if (_selectedClassId == null)
                  _buildClassDropdown(state)
                else
                  _buildSelectedClass(),
                const SizedBox(height: 24),

                // Date Selection
                _buildDateSelector(),
                const SizedBox(height: 24),

                // Time Selection
                _buildTimeSelector(),
                const SizedBox(height: 24),

                // QR Generation Option
                _buildQROption(),
                const SizedBox(height: 32),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedClassId == null || state is TeacherLoading
                        ? null
                        : _createSession,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: state is TeacherLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Create Session',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassDropdown(TeacherState state) {
    if (state is TeacherClassesLoaded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Class',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            hint: const Text('Choose a class'),
            initialValue: _selectedClassId,
            items: state.classes.map((classItem) {
              return DropdownMenuItem<int>(
                value: classItem.id,
                child: Text('${classItem.name} (${classItem.code ?? classItem.classCode})'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedClassId = value;
              });
            },
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSelectedClass() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.school,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Class',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Class Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Session Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 7)),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (date != null) {
              setState(() {
                _selectedDate = date;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Session Time',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTimePicker(
                'Start Time',
                _startTime,
                (time) => setState(() => _startTime = time),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimePicker(
                'End Time',
                _endTime,
                (time) => setState(() => _endTime = time),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimePicker(
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (pickedTime != null) {
          onChanged(pickedTime);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQROption() {
    return Card(
      child: SwitchListTile(
        title: const Text('Generate QR Code'),
        subtitle: const Text('Enable QR-based check-in for this session'),
        value: _generateQR,
        onChanged: (value) {
          setState(() {
            _generateQR = value;
          });
        },
        secondary: Icon(
          Icons.qr_code_2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _createSession() {
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a class'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.read<TeacherBloc>().add(
          CreateAttendanceSession(
            classId: _selectedClassId!,
            startTime: startDateTime,
            endTime: endDateTime,
            generateQR: _generateQR,
          ),
        );
  }
}
