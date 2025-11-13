import 'package:flutter/material.dart';
import 'dart:async';
import '../services/websocket_service.dart';

/// Widget to display Raspberry Pi WebSocket connection status and alerts
class RaspberryPiAlertWidget extends StatefulWidget {
  const RaspberryPiAlertWidget({super.key});

  @override
  State<RaspberryPiAlertWidget> createState() => _RaspberryPiAlertWidgetState();
}

class _RaspberryPiAlertWidgetState extends State<RaspberryPiAlertWidget> {
  final WebSocketService _wsService = WebSocketService();
  StreamSubscription<ConnectionStatus>? _statusSubscription;
  StreamSubscription<RaspberryPiAlert>? _alertSubscription;
  
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  RaspberryPiAlert? _currentAlert;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
  }

  Future<void> _initializeWebSocket() async {
    // Listen to connection status changes
    _statusSubscription = _wsService.connectionStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _connectionStatus = status;
        });
      }
    });

    // Listen to alert messages
    _alertSubscription = _wsService.alertStream.listen((alert) {
      print('AlertWidget: Alert received in widget!');
      print('AlertWidget: Alert type: ${alert.alertType}');
      print('AlertWidget: Alert message: ${alert.message}');
      print('AlertWidget: Alert distance: ${alert.distance}');
      print('AlertWidget: Alert object: ${alert.object}');
      
      if (mounted) {
        setState(() {
          _currentAlert = alert;
        });
        print('AlertWidget: State updated with new alert');
        
        // Show snackbar for critical alerts
        if (alert.isCritical) {
          print('AlertWidget: Showing critical alert dialog');
          _showCriticalAlertDialog(alert);
        }
      }
    });

    // Auto-connect on widget initialization
    _connectionStatus = _wsService.connectionStatus;
    if (_connectionStatus == ConnectionStatus.disconnected) {
      await _wsService.autoConnect();
    }
  }

  void _showCriticalAlertDialog(RaspberryPiAlert alert) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            const Text(
              'CRITICAL ALERT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alert.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Object: ${alert.object}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Distance: ${alert.distance.toStringAsFixed(1)} meters',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    
    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  Color _getStatusColor() {
    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.error:
        return Colors.red;
      case ConnectionStatus.disconnected:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.error:
        return 'Error';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
    }
  }

  Color _getAlertColor() {
    if (_currentAlert == null) return Colors.grey.shade800;
    
    switch (_currentAlert!.alertType) {
      case 'critical':
        return Colors.red.shade900;
      case 'warning':
        return Colors.orange.shade800;
      case 'info':
        return Colors.blue.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _alertSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getAlertColor(),
      elevation: _currentAlert?.isCritical == true ? 8 : 2,
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Header with connection status
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.sensors,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Obstacle Detection',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getStatusColor(),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getStatusText(),
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_currentAlert != null && _currentAlert!.isCritical)
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded details
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connection info
                  _buildInfoRow(
                    Icons.router,
                    'Raspberry Pi IP',
                    _wsService.raspberryPiIP,
                  ),
                  const Divider(color: Colors.white24, height: 16),
                  
                  // Current alert info
                  if (_currentAlert != null) ...[
                    _buildInfoRow(
                      Icons.message,
                      'Last Alert',
                      _currentAlert!.message,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.category,
                      'Object',
                      _currentAlert!.object,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.straighten,
                      'Distance',
                      '${_currentAlert!.distance.toStringAsFixed(1)}m',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.access_time,
                      'Time',
                      _formatTime(_currentAlert!.timestamp),
                    ),
                  ] else ...[
                    const Center(
                      child: Text(
                        'No alerts yet',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                  
                  const Divider(color: Colors.white24, height: 16),
                  
                  // Test alert button (for debugging)
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        print('AlertWidget: Test alert button pressed');
                        // Simulate receiving an alert
                        final testAlert = RaspberryPiAlert(
                          type: 'alert',
                          alertType: 'critical',
                          message: 'TEST: Person ahead at 2.5 meters',
                          distance: 2.5,
                          object: 'person',
                          timestamp: DateTime.now().toIso8601String(),
                          vibrate: true,
                        );
                        setState(() {
                          _currentAlert = testAlert;
                        });
                        _showCriticalAlertDialog(testAlert);
                      },
                      icon: const Icon(Icons.bug_report),
                      label: const Text('Test Alert'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Reconnect button
                  if (_connectionStatus != ConnectionStatus.connected)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _wsService.connect();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reconnect'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatTime(String isoTime) {
    try {
      final dateTime = DateTime.parse(isoTime);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inSeconds < 60) {
        return '${difference.inSeconds}s ago';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else {
        return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return isoTime;
    }
  }
}
