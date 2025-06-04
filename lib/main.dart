import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const String user_uuid = '3813ac1c7dea4993a2f44e8e408bfa9f';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebSocket Tester',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'WebSocket Testing Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  WebSocketChannel? _channel;
  String _lastMessage = 'No messages yet';
  bool _isConnected = false;
  final ScrollController _scrollController = ScrollController();
  
  // Loading states for different actions
  bool _isConnecting = false;
  bool _isUpdatingPosition = false;
  bool _isGettingBookings = false;
  bool _isConfirmTrip = false;
  
  // Message status tracking
  String _messageStatus = '';
  bool _showSuccessMessage = false;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() async {
    setState(() {
      _isConnecting = true;
      _messageStatus = 'Connecting...';
      _showSuccessMessage = false;
    });

    final wsUrl = Uri.parse('ws://44.247.168.30:8010/ride/681aa90e-949c-8006-991e-5bc1d41cf598/$user_uuid/');
    
    try {
      _channel = WebSocketChannel.connect(wsUrl);
      await _channel?.ready;
      
      setState(() {
        _isConnected = true;
        _isConnecting = false;
        _messageStatus = 'Connected successfully!';
        _lastMessage = 'WebSocket connection established';
        _messageStatus = 'connected';
        _showSuccessMessage = true;
      });

      _channel?.stream.listen(
        (message) {
          setState(() {
            _lastMessage = 'Received: $message';
            _messageStatus = 'Message received';
            _showSuccessMessage = true;
          });
          print('object: $message');
        },
        onError: (error) {
          setState(() {
            _isConnected = false;
            _isConnecting = false;
            _lastMessage = 'Error: $error';
            _messageStatus = 'Connection error';
            _showSuccessMessage = false;
          });
        },
        onDone: () {
          setState(() {
            _isConnected = false;
            _isConnecting = false;
            _lastMessage = 'WebSocket connection closed';
            _messageStatus = 'Disconnected';
            _showSuccessMessage = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isConnected = false;
        _isConnecting = false;
        _lastMessage = 'Connection error: $e';
        _messageStatus = 'Failed to connect';
        _showSuccessMessage = false;
      });
    }
  }

  void _sendMessage(Map<String, dynamic> message) async {
    if (_isConnected && _channel != null) {
      // Set loading state based on message type
      setState(() {
        switch (message['type']) {
          case 'update-position':
            _isUpdatingPosition = true;
            break;
          case 'drivers-trip-bookings':
            _isGettingBookings = true;
            break;
          case 'driver-confirm-trip-booking':
            _isConfirmTrip = true;
            break;
        }
        _messageStatus = 'Sending...';
        _showSuccessMessage = false;
      });

      try {
        _channel?.sink.add(json.encode(message));
        
        setState(() {
          _lastMessage = 'Sent: ${json.encode(message)}';
          _messageStatus = 'Success!';
          _showSuccessMessage = true;
        });
      } catch (e) {
        setState(() {
          _lastMessage = 'Error sending message: $e';
          _messageStatus = 'Failed to send';
        });
      } finally {
        setState(() {
          _isUpdatingPosition = false;
          _isGettingBookings = false;
          _isConfirmTrip = false;
        });
      }
    } else {
      setState(() {
        _lastMessage = 'Not connected to WebSocket';
        _messageStatus = 'Failed - Not connected';
      });
    }
  }

  Map<String, dynamic> buildUpdatePosition() {
    return {
      'type': 'update-position',
      'position': {
        'current_latitude': 5.3411,
        'current_longitude': -3.99083
      }
    };
  }

  Map<String, dynamic> buildDriverTripBooking() {
    return {
      'type': 'drivers-trip-bookings'
    };
  }

  Map<String, dynamic> buildDriverTripBookingConfirmation(String trip_uuid, String booking_uuid) {
    return {
      'type': 'driver-confirm-trip-booking',
      'trip_uuid': trip_uuid,
      'booking_uuid': booking_uuid
    };
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.circle : Icons.circle_outlined,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(_isConnected ? 'Connected' : 'Disconnected'),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: _isUpdatingPosition ? null : () => _sendMessage(buildUpdatePosition()),
                  icon: _isUpdatingPosition 
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2)
                      )
                    : const Icon(Icons.location_on),
                  label: Text(_isUpdatingPosition ? 'Updating...' : 'Update Position'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: _isGettingBookings ? null : () => _sendMessage(buildDriverTripBooking()),
              icon: _isGettingBookings
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : const Icon(Icons.list_alt),
              label: Text(_isGettingBookings ? 'Loading...' : 'Get Driver Trip Bookings'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _isConfirmTrip ? null : () => _sendMessage(buildDriverTripBooking()),
              icon: _isConfirmTrip
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : const Icon(Icons.confirmation_num),
              label: Text(_isConfirmTrip ? 'Loading...' : 'Confirm Trip Booking'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),
            
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Last Message:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (_messageStatus.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _showSuccessMessage ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _messageStatus,
                                style: TextStyle(
                                  color: _showSuccessMessage ? Colors.green : Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(_lastMessage),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isConnecting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (_isConnected || _isConnecting) ? null : _connectWebSocket,
        tooltip: _isConnecting ? 'Connecting...' : 'Reconnect WebSocket',
        child: _isConnecting 
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.refresh),
      ),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _scrollController.dispose();
    super.dispose();
  }
}
