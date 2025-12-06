import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/teacher_bloc.dart';
import '../../bloc/teacher_event.dart';
import '../../bloc/teacher_state.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  @override
  void initState() {
    super.initState();
    context.read<TeacherBloc>().add(const LoadTeacherDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              // TODO: Navigate to profile
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/chatbot'),
        child: const Icon(Icons.chat_bubble_outline),
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

          if (state is TeacherDashboardLoaded) {
            final data = state.dashboardData;
            return RefreshIndicator(
              onRefresh: () async {
                context.read<TeacherBloc>().add(const LoadTeacherDashboard());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    _buildWelcomeCard(data),
                    const SizedBox(height: 20),

                    // Quick Stats
                    _buildQuickStats(data),
                    const SizedBox(height: 20),

                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: 20),

                    // Pending Excuses
                    _buildPendingExcuses(data),
                    const SizedBox(height: 20),

                    // Recent Sessions
                    _buildRecentSessions(data),
                  ],
                ),
              ),
            );
          }

          return const Center(
            child: Text('Something went wrong. Pull to refresh.'),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data['teacher_name'] ?? 'Teacher',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You have ${data['total_classes'] ?? 0} classes',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Map<String, dynamic> data) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Classes',
            '${data['total_classes'] ?? 0}',
            Icons.class_outlined,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Active Sessions',
            '${data['active_sessions'] ?? 0}',
            Icons.qr_code_scanner,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Pending Excuses',
            '${data['pending_excuses'] ?? 0}',
            Icons.pending_actions,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
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
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'My Classes',
                Icons.school_outlined,
                Colors.blue,
                () => context.push('/teacher/classes'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Create Session',
                Icons.add_circle_outline,
                Colors.green,
                () => context.push('/teacher/create-session'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Excuses',
                Icons.description_outlined,
                Colors.orange,
                () => context.push('/teacher/excuses'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Sessions',
                Icons.history,
                Colors.purple,
                () => context.push('/teacher/sessions'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingExcuses(Map<String, dynamic> data) {
    final pendingCount = data['pending_excuses'] ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pending Excuse Requests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (pendingCount > 0)
              TextButton(
                onPressed: () => context.push('/teacher/excuses'),
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: pendingCount > 0 ? Colors.orange[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: pendingCount > 0 ? Colors.orange : Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                pendingCount > 0 ? Icons.pending_actions : Icons.check_circle,
                color: pendingCount > 0 ? Colors.orange : Colors.green,
                size: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pendingCount > 0
                          ? '$pendingCount excuse${pendingCount > 1 ? 's' : ''} pending'
                          : 'No pending excuses',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      pendingCount > 0
                          ? 'Review and respond to student requests'
                          : 'All excuse requests have been reviewed',
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
        ),
      ],
    );
  }

  Widget _buildRecentSessions(Map<String, dynamic> data) {
    final recentSessions = (data['recent_sessions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Sessions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/teacher/sessions'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentSessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No recent sessions',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...recentSessions.take(3).map((session) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.qr_code, color: Colors.white),
              ),
              title: Text(session['class_name'] ?? 'Unknown Class'),
              subtitle: Text(session['date'] ?? ''),
              trailing: Chip(
                label: Text(
                  session['status'] ?? 'active',
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: session['status'] == 'active'
                    ? Colors.green[100]
                    : Colors.grey[200],
              ),
            ),
          )),
      ],
    );
  }
}
