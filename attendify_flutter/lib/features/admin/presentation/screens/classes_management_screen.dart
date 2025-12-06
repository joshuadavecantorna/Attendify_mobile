import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/admin_bloc.dart';
import '../../bloc/admin_event.dart';
import '../../bloc/admin_state.dart';
import '../../data/models/admin_models.dart';

class ClassesManagementScreen extends StatefulWidget {
  const ClassesManagementScreen({super.key});

  @override
  State<ClassesManagementScreen> createState() => _ClassesManagementScreenState();
}

class _ClassesManagementScreenState extends State<ClassesManagementScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const LoadAllClasses());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Management'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateClassDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Class'),
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is ClassCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Class created successfully'),
                backgroundColor: Colors.green,
              ),
            );
            context.read<AdminBloc>().add(const LoadAllClasses());
          } else if (state is ClassUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Class updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            context.read<AdminBloc>().add(const LoadAllClasses());
          } else if (state is ClassDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            context.read<AdminBloc>().add(const LoadAllClasses());
          } else if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ClassesLoaded) {
            if (state.classes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No classes found',
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
                context.read<AdminBloc>().add(const LoadAllClasses());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.classes.length,
                itemBuilder: (context, index) {
                  final classData = state.classes[index];
                  return _buildClassCard(classData);
                },
              ),
            );
          }

          return const Center(
            child: Text('Unable to load classes'),
          );
        },
      ),
    );
  }

  Widget _buildClassCard(AdminClass classData) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.teal,
    ];
    final color = colors[classData.id % colors.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.school, color: color),
        ),
        title: Text(
          classData.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(classData.code),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'enrollments',
              child: Row(
                children: [
                  Icon(Icons.people, size: 20),
                  SizedBox(width: 8),
                  Text('Manage Enrollments'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditClassDialog(classData);
            } else if (value == 'enrollments') {
              _showEnrollmentsDialog(classData);
            } else if (value == 'delete') {
              _showDeleteConfirmation(classData);
            }
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (classData.description != null) ...[
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(classData.description!),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(classData.schedule ?? 'No schedule'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${classData.enrolledCount} students enrolled'),
                  ],
                ),
                if (classData.teacherName != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('Teacher: ${classData.teacherName}'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateClassDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final descriptionController = TextEditingController();
    final scheduleController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create New Class'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Class Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Class Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: scheduleController,
                decoration: const InputDecoration(
                  labelText: 'Schedule (Optional)',
                  hintText: 'e.g., Mon/Wed/Fri 10:00-11:30',
                  border: OutlineInputBorder(),
                ),
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
              if (nameController.text.isEmpty || codeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill required fields'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);
              context.read<AdminBloc>().add(
                    CreateClass(
                      name: nameController.text,
                      code: codeController.text,
                      description: descriptionController.text.isEmpty
                          ? null
                          : descriptionController.text,
                      schedule: scheduleController.text.isEmpty
                          ? null
                          : scheduleController.text,
                    ),
                  );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditClassDialog(AdminClass classData) {
    final nameController = TextEditingController(text: classData.name);
    final codeController = TextEditingController(text: classData.code);
    final descriptionController =
        TextEditingController(text: classData.description);
    final scheduleController = TextEditingController(text: classData.schedule);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Class'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Class Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Class Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: scheduleController,
                decoration: const InputDecoration(
                  labelText: 'Schedule',
                  border: OutlineInputBorder(),
                ),
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
              Navigator.pop(dialogContext);
              context.read<AdminBloc>().add(
                    UpdateClass(
                      classId: classData.id,
                      name: nameController.text,
                      code: codeController.text,
                      description: descriptionController.text.isEmpty
                          ? null
                          : descriptionController.text,
                      schedule: scheduleController.text.isEmpty
                          ? null
                          : scheduleController.text,
                    ),
                  );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showEnrollmentsDialog(AdminClass classData) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${classData.name} - Enrollments'),
        content: const Text('Enrollment management coming soon...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(AdminClass classData) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Are you sure you want to delete ${classData.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AdminBloc>().add(DeleteClass(classId: classData.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
