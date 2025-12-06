import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/admin_bloc.dart';
import '../../bloc/admin_event.dart';
import '../../bloc/admin_state.dart';
import '../../data/models/admin_models.dart';
import '../../../../core/constants/app_constants.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<AdminBloc>().add(const LoadAllUsers());
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
        title: const Text('User Management'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          onTap: (index) {
            String? role;
            switch (index) {
              case 1:
                role = AppConstants.roleStudent;
                break;
              case 2:
                role = AppConstants.roleTeacher;
                break;
              case 3:
                role = AppConstants.roleAdmin;
                break;
            }
            context.read<AdminBloc>().add(LoadAllUsers(role: role));
          },
          tabs: const [
            Tab(text: 'All Users'),
            Tab(text: 'Students'),
            Tab(text: 'Teachers'),
            Tab(text: 'Admins'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add User'),
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is UserCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User created successfully'),
                backgroundColor: Colors.green,
              ),
            );
            context.read<AdminBloc>().add(const LoadAllUsers());
          } else if (state is UserDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            context.read<AdminBloc>().add(const LoadAllUsers());
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

          if (state is UsersLoaded) {
            if (state.users.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No users found',
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
                context.read<AdminBloc>().add(const LoadAllUsers());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.users.length,
                itemBuilder: (context, index) {
                  final user = state.users[index];
                  return _buildUserCard(user);
                },
              ),
            );
          }

          return const Center(
            child: Text('Unable to load users'),
          );
        },
      ),
    );
  }

  Widget _buildUserCard(AdminUser user) {
    final roleColor = _getRoleColor(user.role);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withOpacity(0.2),
          child: Icon(
            _getRoleIcon(user.role),
            color: roleColor,
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user.role.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: roleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
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
              _showEditUserDialog(user);
            } else if (value == 'delete') {
              _showDeleteConfirmation(user);
            }
          },
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case AppConstants.roleStudent:
        return Colors.blue;
      case AppConstants.roleTeacher:
        return Colors.green;
      case AppConstants.roleAdmin:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case AppConstants.roleStudent:
        return Icons.school;
      case AppConstants.roleTeacher:
        return Icons.person;
      case AppConstants.roleAdmin:
        return Icons.admin_panel_settings;
      default:
        return Icons.person_outline;
    }
  }

  void _showCreateUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = AppConstants.roleStudent;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create New User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: AppConstants.roleStudent,
                    child: Text('Student'),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.roleTeacher,
                    child: Text('Teacher'),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.roleAdmin,
                    child: Text('Admin'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) selectedRole = value;
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
              if (nameController.text.isEmpty ||
                  emailController.text.isEmpty ||
                  passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);
              context.read<AdminBloc>().add(
                    CreateUser(
                      name: nameController.text,
                      email: emailController.text,
                      password: passwordController.text,
                      role: selectedRole,
                    ),
                  );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(AdminUser user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
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
              context.read<AdminBloc>().add(
                    UpdateUser(
                      userId: user.id,
                      name: nameController.text,
                      email: emailController.text,
                    ),
                  );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(AdminUser user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AdminBloc>().add(DeleteUser(userId: user.id));
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
