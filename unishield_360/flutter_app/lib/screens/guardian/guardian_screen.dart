import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unishield_360/providers/auth_provider.dart';
import 'package:unishield_360/providers/alert_provider.dart';
import 'package:unishield_360/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Guardian Mode Screen - Women's Safety Features (Module B)
class GuardianScreen extends StatefulWidget {
  const GuardianScreen({super.key});

  @override
  State<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends State<GuardianScreen> {
  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Mode'),
        backgroundColor: AppTheme.guardianColor.withOpacity(0.1),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showSettingsSheet();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            _buildStatusCard(alertProvider),
            const SizedBox(height: 20),
            // Alert Buttons
            _buildAlertButtons(alertProvider, authProvider),
            const SizedBox(height: 20),
            // Emergency Contacts
            _buildEmergencyContacts(authProvider),
            const SizedBox(height: 20),
            // Safety Resources
            _buildSafetyResources(),
            const SizedBox(height: 20),
            // Recent Alerts
            _buildRecentAlerts(alertProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(AlertProvider alertProvider) {
    final isAlertActive = alertProvider.hasActiveAlert;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAlertActive
              ? [AppTheme.emergencyRed, AppTheme.emergencyRed.withOpacity(0.7)]
              : [AppTheme.guardianColor, AppTheme.guardianColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            isAlertActive ? Icons.warning_amber_rounded : Icons.shield,
            size: 50,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            isAlertActive ? 'ALERT ACTIVE' : 'Guardian Active',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAlertActive
                ? 'Your location is being shared with your contacts'
                : 'Tap below to send alerts',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (isAlertActive) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await alertProvider.cancelAlert();
              },
              icon: const Icon(Icons.close),
              label: const Text('Cancel Alert'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.emergencyRed,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertButtons(AlertProvider alertProvider, AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Send Alert',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Yellow Alert
            Expanded(
              child: _AlertButton(
                title: 'Yellow Alert',
                subtitle: 'I\'m uncomfortable',
                icon: Icons.warning_amber,
                color: AppTheme.warningYellow,
                onPressed: alertProvider.isLoading
                    ? null
                    : () async {
                        final success = await alertProvider.sendYellowAlert(
                          userId: authProvider.user?.uid ?? '',
                          message: 'I\'m feeling uncomfortable, please track me.',
                        );
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Yellow alert sent to your contacts'),
                              backgroundColor: AppTheme.warningYellow,
                            ),
                          );
                        }
                      },
              ),
            ),
            const SizedBox(width: 12),
            // Red Alert
            Expanded(
              child: _AlertButton(
                title: 'Red Alert',
                subtitle: 'EMERGENCY',
                icon: Icons.emergency,
                color: AppTheme.emergencyRed,
                onPressed: alertProvider.isLoading
                    ? null
                    : () async {
                        // Confirm before sending
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Send Emergency Alert?'),
                            content: const Text(
                              'This will immediately notify campus security and your emergency contacts with your live location.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.emergencyRed,
                                ),
                                child: const Text('Send Alert'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          final success = await alertProvider.sendRedAlert(
                            userId: authProvider.user?.uid ?? '',
                            message: 'EMERGENCY! I need help immediately!',
                          );
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Emergency alert sent!'),
                                backgroundColor: AppTheme.emergencyRed,
                              ),
                            );
                          }
                        }
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmergencyContacts(AuthProvider authProvider) {
    final contacts = authProvider.user?.emergencyContacts ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Emergency Contacts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                _showAddContactDialog(authProvider);
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (contacts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.contacts, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                const Text(
                  'No emergency contacts added',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    _showAddContactDialog(authProvider);
                  },
                  child: const Text('Add Contact'),
                ),
              ],
            ),
          )
        else
          ...contacts.map((contact) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(contact),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.phone, color: AppTheme.safeGreen),
                        onPressed: () {
                          launchUrl(Uri.parse('tel:$contact'));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await authProvider.removeEmergencyContact(contact);
                        },
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildSafetyResources() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Safety Resources',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _ResourceCard(
          title: 'Campus Security',
          subtitle: '24/7 Emergency Line',
          icon: Icons.security,
          phone: '100', // Replace with actual number
        ),
        _ResourceCard(
          title: 'Women Helpline',
          subtitle: 'National Commission for Women',
          icon: Icons.support_agent,
          phone: '181',
        ),
        _ResourceCard(
          title: 'Police Emergency',
          subtitle: 'Dial for police assistance',
          icon: Icons.local_police,
          phone: '100',
        ),
      ],
    );
  }

  Widget _buildRecentAlerts(AlertProvider alertProvider) {
    final alerts = alertProvider.activeAlerts;

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Alerts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...alerts.take(5).map((alert) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: alert.isEmergency
                      ? AppTheme.emergencyRed
                      : AppTheme.warningYellow,
                  child: Icon(
                    alert.isEmergency ? Icons.emergency : Icons.warning,
                    color: Colors.white,
                  ),
                ),
                title: Text(alert.isEmergency ? 'Emergency Alert' : 'Yellow Alert'),
                subtitle: Text(
                  '${alert.status} • ${_formatDate(alert.createdAt)}',
                ),
                trailing: alert.isActive
                    ? const Chip(
                        label: Text('Active'),
                        backgroundColor: AppTheme.warningYellow,
                      )
                    : null,
              ),
            )),
      ],
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Guardian Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Shake to Alert'),
              subtitle: const Text('Shake phone 3 times for emergency'),
              value: true,
              onChanged: (value) {
                // TODO: Implement shake detection toggle
              },
            ),
            SwitchListTile(
              title: const Text('Auto-record Audio'),
              subtitle: const Text('Record audio during emergency'),
              value: false,
              onChanged: (value) {
                // TODO: Implement audio recording toggle
              },
            ),
            SwitchListTile(
              title: const Text('Share Location History'),
              subtitle: const Text('Include last 30 min location'),
              value: true,
              onChanged: (value) {
                // TODO: Implement location history toggle
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContactDialog(AuthProvider authProvider) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: 'Enter phone number',
            prefixIcon: Icon(Icons.phone),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await authProvider.addEmergencyContact(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _AlertButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _AlertButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String phone;

  const _ResourceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.guardianColor.withOpacity(0.1),
          child: Icon(icon, color: AppTheme.guardianColor),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: IconButton(
          icon: const Icon(Icons.phone, color: AppTheme.safeGreen),
          onPressed: () {
            launchUrl(Uri.parse('tel:$phone'));
          },
        ),
      ),
    );
  }
}
