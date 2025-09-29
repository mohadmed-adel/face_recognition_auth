import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import 'anti_spoofing_demo_screen.dart';
import 'database_operations_screen.dart';
import 'enhanced_face_auth_demo_screen.dart';
import 'enhanced_registration_screen.dart';
import 'login_screen.dart';
import 'registration_screen.dart';
import 'user_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Recognition Auth Demo'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, _) {
          if (appState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.face_retouching_natural,
                          size: 64,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Face Recognition Authentication',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Secure, reliable face-based authentication using TensorFlow Lite and Google ML Kit',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Main Actions
                _buildActionCard(
                  context,
                  'Enhanced Registration',
                  'Register with auto ID, multi-angle capture & anti-spoofing',
                  Icons.auto_awesome,
                  Colors.green,
                  () => _navigateToEnhancedRegistration(),
                ),

                const SizedBox(height: 16),

                _buildActionCard(
                  context,
                  'Standard Registration',
                  'Basic registration with manual user ID',
                  Icons.person_add,
                  Colors.teal,
                  () => _navigateToRegistration(),
                ),

                const SizedBox(height: 16),

                _buildActionCard(
                  context,
                  'Login with Face',
                  'Authenticate using face recognition',
                  Icons.login,
                  Colors.blue,
                  () => _navigateToLogin(),
                ),

                const SizedBox(height: 16),

                _buildActionCard(
                  context,
                  'User Management',
                  'View and manage registered users',
                  Icons.people,
                  Colors.orange,
                  () => _navigateToUserManagement(),
                ),

                const SizedBox(height: 16),

                _buildActionCard(
                  context,
                  'Anti-Spoofing Demo',
                  'Test and configure anti-spoofing features',
                  Icons.security,
                  Colors.purple,
                  () => _navigateToAntiSpoofingDemo(),
                ),

                const SizedBox(height: 16),

                _buildActionCard(
                  context,
                  'Enhanced Face Auth Demo',
                  'Interactive face authentication with live anti-spoofing UI',
                  Icons.face_retouching_natural,
                  Colors.cyan,
                  () => _navigateToEnhancedDemo(),
                ),

                const SizedBox(height: 16),

                _buildActionCard(
                  context,
                  'Database Operations',
                  'Advanced database operations and testing',
                  Icons.storage,
                  Colors.indigo,
                  () => _navigateToDatabaseOperations(),
                ),

                const SizedBox(height: 24),

                // Stats Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Registered Users',
                          '${appState.registeredUsers.length}',
                          Icons.people,
                          Colors.blue,
                        ),
                        _buildStatItem(
                          'Face Samples',
                          '${appState.registeredUsers.fold(0, (sum, user) => sum + user.modelData.length)}',
                          Icons.face,
                          Colors.green,
                        ),
                      ],
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

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  void _navigateToEnhancedRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EnhancedRegistrationScreen(),
      ),
    );
  }

  void _navigateToRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
    );
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToUserManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserManagementScreen()),
    );
  }

  void _navigateToAntiSpoofingDemo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AntiSpoofingDemoScreen()),
    );
  }

  void _navigateToEnhancedDemo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EnhancedFaceAuthDemoScreen(),
      ),
    );
  }

  void _navigateToDatabaseOperations() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DatabaseOperationsScreen()),
    );
  }
}
