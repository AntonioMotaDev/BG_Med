import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ConnectivityIndicator extends StatelessWidget {
  const ConnectivityIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ConnectivityResult>>(
      future: Connectivity().checkConnectivity(),
      builder: (context, initialSnapshot) {
        return StreamBuilder<List<ConnectivityResult>>(
          stream: Connectivity().onConnectivityChanged,
          initialData: initialSnapshot.data ?? [ConnectivityResult.none],
          builder: (context, snapshot) {
            final connectivityResults = snapshot.data ?? [ConnectivityResult.none];
            final isConnected = connectivityResults.any((result) => 
                result != ConnectivityResult.none);
            
            // Para debug - ver qué detecta en web
            if (kDebugMode) {
              print('🌐 Connectivity results: $connectivityResults');
              print('📱 Platform: ${Theme.of(context).platform}');
            }
            
            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isConnected ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isConnected ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isConnected ? Icons.wifi : Icons.wifi_off,
                    size: 14,
                    color: isConnected ? Colors.green[700] : Colors.red[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isConnected ? 'En línea' : 'Sin conexión',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isConnected ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
} 