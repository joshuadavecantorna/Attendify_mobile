import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/teacher_bloc.dart';
import '../../bloc/teacher_event.dart';
import '../../bloc/teacher_state.dart';
import '../../data/models/teacher_models.dart';

class TeacherExcusesScreen extends StatefulWidget {
  const TeacherExcusesScreen({super.key});

  @override
  State<TeacherExcusesScreen> createState() => _TeacherExcusesScreenState();
}

class _TeacherExcusesScreenState extends State<TeacherExcusesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<TeacherBloc>().add(const LoadPendingExcuses());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Excuse Requests'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            if (index == 0) {
              context.read<TeacherBloc>().add(const LoadPendingExcuses());
            } else {
              context.read<TeacherBloc>().add(const LoadAllExcuses());
            }
          },
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'All Requests'),
          ],
        ),
      ),
      body: BlocConsumer<TeacherBloc, TeacherState>(
        listener: (context, state) {
          if (state is ExcuseRequestReviewed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Refresh the list
            if (_tabController.index == 0) {
              context.read<TeacherBloc>().add(const LoadPendingExcuses());
            } else {
              context.read<TeacherBloc>().add(const LoadAllExcuses());
            }
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

          if (state is PendingExcusesLoaded || state is AllExcusesLoaded) {
            final excuses = state is PendingExcusesLoaded
                ? state.excuses
                : (state as AllExcusesLoaded).excuses;

            if (excuses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _tabController.index == 0
                          ? 'No pending excuse requests'
                          : 'No excuse requests found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                if (_tabController.index == 0) {
                  context.read<TeacherBloc>().add(const LoadPendingExcuses());
                } else {
                  context.read<TeacherBloc>().add(const LoadAllExcuses());
                }
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: excuses.length,
                itemBuilder: (context, index) {
                  final excuse = excuses[index];
                  return _buildExcuseCard(excuse);
                },
              ),
            );
          }

          return const Center(
            child: Text('Unable to load excuse requests'),
          );
        },
      ),
    );
  }

  Widget _buildExcuseCard(TeacherExcuseRequest excuse) {
    final statusColor = _getStatusColor(excuse.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header with student info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor,
                  child: Text(
                    excuse.studentName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        excuse.studentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        excuse.className ?? 'Unknown Class',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(excuse.status, statusColor),
              ],
            ),
          ),

          // Excuse details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM d, y').format(excuse.date ?? excuse.createdAt),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (excuse.type ?? 'excuse').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Reason:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  excuse.reason,
                  style: const TextStyle(fontSize: 14),
                ),
                if (excuse.attachmentUrl != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Open attachment
                    },
                    icon: const Icon(Icons.attachment, size: 16),
                    label: const Text('View Attachment'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
                if (excuse.response != null) ...[
                  const SizedBox(height: 12),
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
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          excuse.response!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action buttons (only for pending)
          if (excuse.status == 'pending')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showReviewDialog(excuse, 'rejected'),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showReviewDialog(excuse, 'approved'),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    final icons = {
      'pending': Icons.schedule,
      'approved': Icons.check_circle,
      'rejected': Icons.cancel,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icons[status] ?? Icons.help,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  void _showReviewDialog(TeacherExcuseRequest excuse, String status) {
    final responseController = TextEditingController();
    final isApproval = status == 'approved';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isApproval ? 'Approve Excuse' : 'Reject Excuse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${excuse.studentName}'),
            Text('Date: ${DateFormat('MMM d, y').format(excuse.date ?? excuse.createdAt)}'),
            const SizedBox(height: 16),
            TextField(
              controller: responseController,
              decoration: const InputDecoration(
                labelText: 'Response (Optional)',
                hintText: 'Add a message for the student...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<TeacherBloc>().add(
                    ReviewExcuseRequest(
                      excuseId: excuse.id,
                      status: status,
                      response: responseController.text.isEmpty
                          ? null
                          : responseController.text,
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproval ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isApproval ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }
}
