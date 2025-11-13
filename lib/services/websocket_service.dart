import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Model for alert messages from Raspberry Pi
class RaspberryPiAlert {
  final String type;
  final String alertType; // critical, warning, info
  final String message;
  final double distance;
  final String object;
  final String timestamp;
  final bool vibrate;

  RaspberryPiAlert({
    required this.type,
    required this.alertType,
    required this.message,
    required this.distance,
    required this.object,
    required this.timestamp,
    required this.vibrate,
  });

  factory RaspberryPiAlert.fromJson(Map<String, dynamic> json) {
    return RaspberryPiAlert(
      type: json['type'] ?? 'alert',
      alertType: json['alert_type'] ?? 'info',
      message: json['message'] ?? '',
      distance: (json['distance'] ?? 0.0).toDouble(),
      object: json['object'] ?? 'unknown',
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      vibrate: json['vibrate'] ?? false,
    );
  }

  bool get isCritical => alertType == 'critical';
  bool get isWarning => alertType == 'warning';
  bool get isInfo => alertType == 'info';
}

enum ConnectionStatus { disconnected, connecting, connected, error }

/// Service to handle WebSocket connection to Raspberry Pi
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // Raspberry Pi WebSocket configuration
  static const String defaultRaspberryPiIP = '10.249.63.60';
  // static const String defaultRaspberryPiIP = '10.61.25.139';

  static const int websocketPort = 8765;

  String _raspberryPiIP = defaultRaspberryPiIP;
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  // State streams
  final _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();
  final _alertController = StreamController<RaspberryPiAlert>.broadcast();

  Stream<ConnectionStatus> get connectionStatusStream =>
      _connectionStatusController.stream;
  Stream<RaspberryPiAlert> get alertStream => _alertController.stream;

  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  ConnectionStatus get connectionStatus => _connectionStatus;

  RaspberryPiAlert? _lastAlert;
  RaspberryPiAlert? get lastAlert => _lastAlert;

  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 999; // Keep trying indefinitely
  static const Duration reconnectInterval = Duration(seconds: 5);
  static const Duration pingInterval = Duration(seconds: 10);

  /// Get current Raspberry Pi IP
  String get raspberryPiIP => _raspberryPiIP;

  /// Set Raspberry Pi IP address
  void setRaspberryPiIP(String ip) {
    if (ip.isNotEmpty && ip != _raspberryPiIP) {
      _raspberryPiIP = ip;
      // Reconnect with new IP
      if (_connectionStatus != ConnectionStatus.disconnected) {
        disconnect();
        connect();
      }
    }
  }

  /// Connect to Raspberry Pi WebSocket server
  Future<void> connect() async {
    if (_connectionStatus == ConnectionStatus.connecting ||
        _connectionStatus == ConnectionStatus.connected) {
      print('WebSocket: Already connecting or connected');
      return;
    }

    _updateConnectionStatus(ConnectionStatus.connecting);
    print(
      'WebSocket: Attempting to connect to ws://$_raspberryPiIP:$websocketPort',
    );

    try {
      final uri = Uri.parse('ws://$_raspberryPiIP:$websocketPort');
      _channel = WebSocketChannel.connect(uri);

      // Wait for connection to establish
      await _channel!.ready;

      _updateConnectionStatus(ConnectionStatus.connected);
      _reconnectAttempts = 0;
      print('WebSocket: Connected successfully');

      // Enable wakelock to keep screen awake
      await WakelockPlus.enable();
      print('WebSocket: Wakelock enabled');

      // Start ping timer to keep connection alive
      _startPingTimer();

      // Listen to incoming messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
        cancelOnError: false,
      );
    } catch (e) {
      print('WebSocket: Connection error: $e');
      _updateConnectionStatus(ConnectionStatus.error);
      _scheduleReconnect();
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      print('WebSocket: RAW MESSAGE RECEIVED: $message');
      print('WebSocket: Message type: ${message.runtimeType}');

      if (message == 'pong') {
        // Ping response received
        print('WebSocket: Pong received');
        return;
      }

      final data = jsonDecode(message);
      print('WebSocket: Decoded JSON: $data');
      print('WebSocket: JSON type field: ${data['type']}');

      if (data['type'] == 'alert') {
        print('WebSocket: Processing alert...');
        final alert = RaspberryPiAlert.fromJson(data);
        _lastAlert = alert;
        _alertController.add(alert);
        print('WebSocket: Alert added to stream!');

        // Handle critical alerts
        if (alert.isCritical && alert.vibrate) {
          print('WebSocket: Triggering vibration for critical alert');
          _triggerVibration();
        }

        print(
          'WebSocket: Alert received - ${alert.alertType}: ${alert.message}',
        );
      } else {
        print('WebSocket: Message type is not "alert", it is: ${data['type']}');
      }
    } catch (e, stackTrace) {
      print('WebSocket: Error parsing message: $e');
      print('WebSocket: Stack trace: $stackTrace');
    }
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    print('WebSocket: Error occurred: $error');
    _updateConnectionStatus(ConnectionStatus.error);
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnection
  void _handleDisconnection() {
    print('WebSocket: Connection closed');
    if (_connectionStatus != ConnectionStatus.disconnected) {
      _updateConnectionStatus(ConnectionStatus.disconnected);
      _scheduleReconnect();
    }
  }

  /// Start ping timer to keep connection alive
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (timer) {
      if (_connectionStatus == ConnectionStatus.connected) {
        try {
          _channel?.sink.add('ping');
        } catch (e) {
          print('WebSocket: Ping failed: $e');
        }
      } else {
        timer.cancel();
      }
    });
  }

  /// Schedule automatic reconnection
  void _scheduleReconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();

    if (_reconnectAttempts >= maxReconnectAttempts) {
      print('WebSocket: Max reconnect attempts reached');
      return;
    }

    _reconnectAttempts++;
    final delay = reconnectInterval * _reconnectAttempts.clamp(1, 5);

    print(
      'WebSocket: Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s',
    );

    _reconnectTimer = Timer(delay, () {
      if (_connectionStatus != ConnectionStatus.connected) {
        print('WebSocket: Reconnecting...');
        connect();
      }
    });
  }

  /// Trigger phone vibration for critical alerts
  Future<void> _triggerVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        // Strong vibration pattern: [wait, vibrate, wait, vibrate]
        // 500ms vibration with pattern for emphasis
        await Vibration.vibrate(
          pattern: [0, 500, 200, 500],
          intensities: [0, 255, 0, 255],
        );
        print('WebSocket: Vibration triggered for critical alert');
      }
    } catch (e) {
      print('WebSocket: Vibration error: $e');
    }
  }

  /// Update connection status and notify listeners
  void _updateConnectionStatus(ConnectionStatus status) {
    _connectionStatus = status;
    _connectionStatusController.add(status);
  }

  /// Disconnect from WebSocket server
  void disconnect() {
    print('WebSocket: Disconnecting');
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _updateConnectionStatus(ConnectionStatus.disconnected);

    // Disable wakelock when disconnected
    WakelockPlus.disable();
    print('WebSocket: Wakelock disabled');
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _connectionStatusController.close();
    _alertController.close();
  }

  /// Auto-connect on app launch
  Future<void> autoConnect() async {
    print('WebSocket: Auto-connecting on app launch');
    await connect();
  }
}
