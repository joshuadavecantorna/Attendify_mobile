import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/teacher_bloc.dart';
import '../../bloc/teacher_event.dart';
import '../../bloc/teacher_state.dart';
import '../../data/models/teacher_models.dart';

class TeacherClassesScreen extends StatefulWidget {
  const TeacherClassesScreen({super.key});

  @override
  State<TeacherClassesScreen> createState() => _TeacherClassesScreenState();
}

class _TeacherClassesScreenState extends State<TeacherClassesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TeacherBloc>().add(const LoadTeacherClasses());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
      ),
      body: BlocConsumer<TeacherBloc, TeacherState>(
        listener: (context, state) {
          if (state is TeacherError) {
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

          if (state is TeacherClassesLoaded) {
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
                      'No classes assigned',
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
                context.read<TeacherBloc>().add(const LoadTeacherClasses());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.classes.length,
                itemBuilder: (context, index) {
                  final classItem = state.classes[index];
                  return _buildClassCard(classItem);
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

  Widget _buildClassCard(TeacherClass classItem) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.indigo,
      Colors.teal,
      Colors.orange,
    ];
    final color = colors[classItem.id % colors.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.push('/teacher/class-details/${classItem.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.school,
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classItem.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          classItem.code ?? classItem.classCode,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.people_outline,
                    '${classItem.enrolledCount} students',
                    color,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.schedule,
                    classItem.schedule ?? 'No schedule',
                    color,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push('/teacher/create-session?classId=${classItem.id}');
                      },
                      icon: const Icon(Icons.qr_code_2, size: 18),
                      label: const Text('Start Session'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push('/teacher/class-report/${classItem.id}');
                      },
                      icon: const Icon(Icons.bar_chart, size: 18),
                      label: const Text('View Report'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
