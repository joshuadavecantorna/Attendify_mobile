import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();

  Stream<bool> get connectivityStream => _connectivityController.stream;
  bool _isOnline = true;

  ConnectivityService() {
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen((dynamic result) {
      if (result is List<ConnectivityResult>) {
        _updateConnectionStatus(result);
      } else if (result is ConnectivityResult) {
        _updateConnectionStatus([result]);
      }
    });
  }

  bool get isOnline => _isOnline;

  Future<void> _initConnectivity() async {
    try {
      final dynamic result = await _connectivity.checkConnectivity();
      if (result is List<ConnectivityResult>) {
        _updateConnectionStatus(result);
      } else if (result is ConnectivityResult) {
        _updateConnectionStatus([result]);
      } else {
        _isOnline = false;
        _connectivityController.add(false);
      }
    } catch (e) {
      _isOnline = false;
      _connectivityController.add(false);
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    _isOnline = result != ConnectivityResult.none;
    _connectivityController.add(_isOnline);
  }

  Future<bool> checkConnection() async {
    try {
      final dynamic result = await _connectivity.checkConnectivity();
      if (result is List<ConnectivityResult>) {
        return result.isNotEmpty && result.first != ConnectivityResult.none;
      } else if (result is ConnectivityResult) {
        return result != ConnectivityResult.none;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _connectivityController.close();
  }
}
