import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/app_constants.dart';

/// Service to communicate with Raspberry Pi via WebSocket
class HardwareService {
  static final HardwareService _instance = HardwareService._internal();
  factory HardwareService() => _instance;
  HardwareService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Connect to the Raspberry Pi WebSocket server
  Future<bool> connect() async {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(AppConstants.piWebSocketUrl),
      );

      _subscription = _channel!.stream.listen(
        (message) {
          _onMessageReceived(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          print('WebSocket connection closed');
          _handleDisconnection();
        },
      );

      _isConnected = true;
      _connectionController.add(true);
      return true;
    } catch (e) {
      print('Failed to connect to Pi: $e');
      _isConnected = false;
      _connectionController.add(false);
      return false;
    }
  }

  /// Send a message to the Raspberry Pi
  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(message));
      } catch (e) {
        print('Error sending message: $e');
      }
    }
  }

  /// Handle received messages
  void _onMessageReceived(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      _messageController.add(data);
    } catch (e) {
      print('Error parsing message: $e');
    }
  }

  /// Handle disconnection
  void _handleDisconnection() {
    if (_isConnected) {
      _isConnected = false;
      _connectionController.add(false);

      // Attempt to reconnect after 5 seconds
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 5), () {
        connect();
      });
    }
  }

  /// Disconnect from the Pi
  void disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _connectionController.add(false);
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}
