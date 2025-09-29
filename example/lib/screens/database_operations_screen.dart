import 'package:face_recognition_auth/face_recognition_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';

class DatabaseOperationsScreen extends StatefulWidget {
  const DatabaseOperationsScreen({super.key});

  @override
  State<DatabaseOperationsScreen> createState() =>
      _DatabaseOperationsScreenState();
}

class _DatabaseOperationsScreenState extends State<DatabaseOperationsScreen> {
  final FaceAuthController _controller = FaceAuthController();
  final TextEditingController _userIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String _operationResult = '';
  User? _foundUser;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      await _controller.initializeDatabaseOnly();
      setState(() {});
    } catch (e) {
      _showErrorDialog('Failed to initialize database: $e');
    }
  }

  Future<void> _checkUserExists() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      _showErrorDialog('Please enter a user ID');
      return;
    }

    setState(() => _isLoading = true);
    _operationResult = '';

    try {
      final exists = await _controller.userExists(userId);
      setState(() {
        _operationResult = exists
            ? 'User "$userId" exists in the database'
            : 'User "$userId" does not exist in the database';
      });
    } catch (e) {
      _showErrorDialog('Failed to check user existence: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getUserById() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      _showErrorDialog('Please enter a user ID');
      return;
    }

    setState(() {
      _isLoading = true;
      _operationResult = '';
      _foundUser = null;
    });

    try {
      final user = await _controller.getUserById(userId);
      setState(() {
        if (user != null) {
          _foundUser = user;
          _operationResult =
              'User found: ${user.id} with ${user.modelData.length} face samples';
        } else {
          _operationResult = 'User "$userId" not found in the database';
        }
      });
    } catch (e) {
      _showErrorDialog('Failed to get user: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      _showErrorDialog('Please enter a user ID');
      return;
    }

    final confirmed = await _showConfirmDialog(
      'Delete User',
      'Are you sure you want to delete user "$userId"?',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _operationResult = '';
    });

    try {
      final deletedCount = await _controller.deleteUser(userId);
      setState(() {
        _operationResult = deletedCount > 0
            ? 'User "$userId" deleted successfully'
            : 'User "$userId" not found or already deleted';
      });

      // Update app state
      if (mounted) {
        final appState = Provider.of<AppStateProvider>(context, listen: false);
        appState.removeUser(userId);
      }
    } catch (e) {
      _showErrorDialog('Failed to delete user: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getAllUsers() async {
    setState(() {
      _isLoading = true;
      _operationResult = '';
    });

    try {
      final users = await _controller.getAllUsers();
      setState(() {
        _operationResult = 'Found ${users.length} users in the database';
      });

      // Update app state
      if (mounted) {
        final appState = Provider.of<AppStateProvider>(context, listen: false);
        appState.updateUsers(users);
      }
    } catch (e) {
      _showErrorDialog('Failed to get all users: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAllUsers() async {
    final confirmed = await _showConfirmDialog(
      'Delete All Users',
      'Are you sure you want to delete ALL users? This action cannot be undone.',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _operationResult = '';
    });

    try {
      await _controller.deleteAllUsers();
      setState(() {
        _operationResult = 'All users deleted successfully';
      });

      // Update app state
      if (mounted) {
        final appState = Provider.of<AppStateProvider>(context, listen: false);
        appState.clearAllUsers();
      }
    } catch (e) {
      _showErrorDialog('Failed to delete all users: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _clearResult() {
    setState(() {
      _operationResult = '';
      _foundUser = null;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Database Operations'),
      backgroundColor: Colors.purple.shade600,
      foregroundColor: Colors.white,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.storage, size: 48, color: Colors.purple.shade600),
                  const SizedBox(height: 16),
                  Text(
                    'Database Operations',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Test and manage the face recognition database',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // User ID Input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'User ID Operations',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _userIdController,
                      decoration: const InputDecoration(
                        labelText: 'User ID',
                        hintText: 'Enter user ID for operations',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a user ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _checkUserExists,
                          icon: const Icon(Icons.search),
                          label: const Text('Check Exists'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _getUserById,
                          icon: const Icon(Icons.person_search),
                          label: const Text('Get User'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _deleteUser,
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete User'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Global Operations
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Global Operations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _getAllUsers,
                        icon: const Icon(Icons.list),
                        label: const Text('Get All Users'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _deleteAllUsers,
                        icon: const Icon(Icons.delete_sweep),
                        label: const Text('Delete All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Loading Indicator
          if (_isLoading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing...'),
                    ],
                  ),
                ),
              ),
            ),

          // Operation Result
          if (_operationResult.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Operation Result',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _clearResult,
                          icon: const Icon(Icons.clear),
                          iconSize: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        _operationResult,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // User Details
          if (_foundUser != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'User Details',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('User ID', _foundUser!.id),
                          _buildDetailRow(
                            'Face Samples',
                            '${_foundUser!.modelData.length}',
                          ),
                          _buildDetailRow(
                            'Data Size',
                            '${_foundUser!.modelData.toString().length} characters',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Database Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Database Information',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• Database Type: SQLite (Local)',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '• Storage: Device Local Storage',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '• Security: Encrypted Local Storage',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '• Privacy: No Cloud Dependencies',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildDetailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    _userIdController.dispose();
    super.dispose();
  }
}
