import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../bloc/teacher_bloc.dart';
import '../../bloc/teacher_event.dart';
import '../../bloc/teacher_state.dart';
import '../../data/models/teacher_models.dart';

class SessionQRScreen extends StatefulWidget {
  final int sessionId;

  const SessionQRScreen({super.key, required this.sessionId});

  @override
  State<SessionQRScreen> createState() => _SessionQRScreenState();
}

class _SessionQRScreenState extends State<SessionQRScreen> {
  @override
  void initState() {
    super.initState();
    // Load session details
    context.read<TeacherBloc>().add(const LoadAttendanceSessions());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_fullscreen),
            onPressed: () => _showEndSessionDialog(),
          ),
        ],
      ),
      body: BlocConsumer<TeacherBloc, TeacherState>(
        listener: (context, state) {
          if (state is AttendanceSessionEnded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
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
          if (state is TeacherLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AttendanceSessionsLoaded) {
            final session = state.sessions.firstWhere(
              (s) => s.id == widget.sessionId,
              orElse: () => state.sessions.isNotEmpty
                  ? state.sessions.first
                  : AttendanceSession(
                      id: 0,
                      classId: 0,
                      startTime: DateTime.now(),
                      endTime: DateTime.now(),
                      status: 'unknown',
                      presentCount: 0,
                      absentCount: 0,
                      lateCount: 0,
                    ),
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Session Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Session Active',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Class: ${session.className}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatChip(
                                'Present',
                                session.presentCount.toString(),
                                Colors.green,
                              ),
                              _buildStatChip(
                                'Absent',
                                session.absentCount.toString(),
                                Colors.red,
                              ),
                              _buildStatChip(
                                'Late',
                                session.lateCount.toString(),
                                Colors.orange,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // QR Code Display
                  if (session.qrCode != null) ...[
                    const Text(
                      'Students can scan this QR code to check in',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: session.qrCode!,
                        version: QrVersions.auto,
                        size: 280.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Session ID: ${session.id}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'QR Code not generated for this session',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to manual attendance marking
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Mark Attendance Manually'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showEndSessionDialog,
                      icon: const Icon(Icons.stop),
                      label: const Text('End Session'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return const Center(
            child: Text('Unable to load session details'),
          );
        },
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showEndSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session'),
        content: const Text(
          'Are you sure you want to end this attendance session? '
          'Students will no longer be able to check in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<TeacherBloc>().add(
                    EndAttendanceSession(sessionId: widget.sessionId),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }
}
