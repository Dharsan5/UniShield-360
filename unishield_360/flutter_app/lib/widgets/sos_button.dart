import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:unishield_360/providers/auth_provider.dart';
import 'package:unishield_360/providers/alert_provider.dart';
import 'package:unishield_360/theme/app_theme.dart';

/// SOS Floating Action Button - Always visible for emergencies
class SOSButton extends StatefulWidget {
  const SOSButton({super.key});

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isLongPressing = false;
  double _longPressProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onTap() {
    // Single tap - show options
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SOSOptionsSheet(
        onYellowAlert: () => _sendAlert('yellow'),
        onRedAlert: () => _sendAlert('red'),
      ),
    );
  }

  Future<void> _onLongPressStart(LongPressStartDetails details) async {
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isLongPressing = true;
    });

    // Animate progress over 3 seconds
    const duration = Duration(milliseconds: 3000);
    const steps = 60;
    final stepDuration = duration.inMilliseconds ~/ steps;

    for (int i = 0; i <= steps; i++) {
      if (!_isLongPressing) break;

      await Future.delayed(Duration(milliseconds: stepDuration));
      
      if (mounted && _isLongPressing) {
        setState(() {
          _longPressProgress = i / steps;
        });

        // Vibrate at milestones
        if (i == steps ~/ 2 || i == (steps * 3) ~/ 4) {
          HapticFeedback.lightImpact();
        }
      }
    }

    // If completed, send emergency alert
    if (_isLongPressing && _longPressProgress >= 0.99) {
      HapticFeedback.heavyImpact();
      await _sendAlert('red');
    }
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    setState(() {
      _isLongPressing = false;
      _longPressProgress = 0.0;
    });
  }

  Future<void> _sendAlert(String type) async {
    final authProvider = context.read<AuthProvider>();
    final alertProvider = context.read<AlertProvider>();

    Navigator.of(context).pop(); // Close bottom sheet if open

    bool success;
    if (type == 'red') {
      success = await alertProvider.sendRedAlert(
        userId: authProvider.user?.uid ?? '',
        message: 'EMERGENCY! Long press SOS activated!',
      );
    } else {
      success = await alertProvider.sendYellowAlert(
        userId: authProvider.user?.uid ?? '',
        message: 'I\'m feeling unsafe, please track me.',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (type == 'red'
                    ? 'Emergency alert sent!'
                    : 'Yellow alert sent!')
                : 'Failed to send alert',
          ),
          backgroundColor: success
              ? (type == 'red' ? AppTheme.emergencyRed : AppTheme.warningYellow)
              : Colors.grey,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();

    return GestureDetector(
      onTap: _onTap,
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: alertProvider.hasActiveAlert ? _pulseAnimation.value : 1.0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress indicator for long press
                if (_isLongPressing)
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: _longPressProgress,
                      strokeWidth: 4,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                // SOS button
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: alertProvider.hasActiveAlert
                        ? AppTheme.warningYellow
                        : AppTheme.emergencyRed,
                    boxShadow: [
                      BoxShadow(
                        color: (alertProvider.hasActiveAlert
                                ? AppTheme.warningYellow
                                : AppTheme.emergencyRed)
                            .withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        alertProvider.hasActiveAlert
                            ? Icons.location_on
                            : Icons.emergency,
                        color: Colors.white,
                        size: 24,
                      ),
                      const Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SOSOptionsSheet extends StatelessWidget {
  final VoidCallback onYellowAlert;
  final VoidCallback onRedAlert;

  const _SOSOptionsSheet({
    required this.onYellowAlert,
    required this.onRedAlert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Send Safety Alert',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose alert type based on your situation',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          // Yellow Alert
          _AlertOption(
            title: 'Yellow Alert',
            description: 'I\'m uncomfortable, please track me',
            icon: Icons.warning_amber,
            color: AppTheme.warningYellow,
            onTap: onYellowAlert,
          ),
          const SizedBox(height: 12),
          // Red Alert
          _AlertOption(
            title: 'Red Alert - EMERGENCY',
            description: 'Notify security & emergency contacts NOW',
            icon: Icons.emergency,
            color: AppTheme.emergencyRed,
            onTap: onRedAlert,
          ),
          const SizedBox(height: 20),
          // Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Long press SOS button for 3 seconds to send emergency alert instantly',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _AlertOption extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AlertOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
