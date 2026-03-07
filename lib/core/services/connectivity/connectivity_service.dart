import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((item) => item != ConnectivityResult.none);
    } catch (_) {
      // If the plugin fails, assume online and let network requests decide.
      return true;
    }
  }
}
