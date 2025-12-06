import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/student_bloc.dart';
import '../../bloc/student_event.dart';
import '../../bloc/student_state.dart';

class ExcusesScreen extends StatefulWidget {
  const ExcusesScreen({super.key});

  @override
  State<ExcusesScreen> createState() => _ExcusesScreenState();
}

class _ExcusesScreenState extends State<ExcusesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<StudentBloc>().add(const LoadExcuseRequests());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Excuse Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<StudentBloc>().add(const LoadExcuseRequests());
            },
          ),
        ],
      ),
      body: BlocConsumer<StudentBloc, StudentState>(
        listener: (context, state) {
          if (state is ExcuseRequestSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Excuse request submitted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            context.read<StudentBloc>().add(const LoadExcuseRequests());
          }
        },
        builder: (context, state) {
          if (state is StudentLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ExcuseRequestsLoaded) {
            if (state.requests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No excuse requests',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showSubmitExcuseDialog(context);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Submit Request'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.requests.length,
              itemBuilder: (context, index) {
                final request = state.requests[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                request.className ?? 'Unknown Class',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            _buildStatusChip(request.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Session Date: ${request.sessionDate != null ? DateFormat('MMM dd, yyyy').format(request.sessionDate!) : 'N/A'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Reason: ${request.reason}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (request.teacherResponse != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Teacher Response:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  request.teacherResponse!,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Submitted: ${DateFormat('MMM dd, yyyy HH:mm').format(request.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          if (state is StudentError) {
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
                    state.message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<StudentBloc>()
                          .add(const LoadExcuseRequests());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showSubmitExcuseDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        label = 'Approved';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      case 'pending':
      default:
        color = Colors.orange;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showSubmitExcuseDialog(BuildContext context) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Submit Excuse Request'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Note: This is a placeholder. Implement attendance session selection.',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Enter reason for absence',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a reason';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                // TODO: Implement actual session selection
                context.read<StudentBloc>().add(
                      SubmitExcuseRequest(
                        attendanceSessionId: 1, // Placeholder
                        reason: reasonController.text,
                      ),
                    );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
