import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bg_med/firebase_options.dart';
import 'package:bg_med/core/theme/app_theme.dart';
import 'package:bg_med/features/auth/presentation/screens/auth_wrapper.dart';
import 'package:bg_med/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:bg_med/core/models/patient.dart';
import 'package:bg_med/core/models/clinical_history.dart';
import 'package:bg_med/core/models/physical_exam.dart';
import 'package:bg_med/core/models/frap.dart';
import 'package:bg_med/core/models/medication.dart';
import 'package:bg_med/core/models/insumo.dart';
import 'package:bg_med/core/models/personal_medico.dart';
import 'package:bg_med/core/models/escalas_obstetricas.dart';
import 'package:bg_med/core/models/appointment.dart';
import 'package:bg_med/core/services/frap_local_service.dart';
import 'package:bg_med/core/services/frap_firestore_service.dart';
import 'package:bg_med/core/services/frap_unified_service.dart';
import 'core/navigation/route_observer.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientación
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Inicializar Hive
    await Hive.initFlutter();

    // Registrar adaptadores
    Hive.registerAdapter(PatientAdapter());
    Hive.registerAdapter(ClinicalHistoryAdapter());
    Hive.registerAdapter(PhysicalExamAdapter());
    Hive.registerAdapter(FrapAdapter());
    Hive.registerAdapter(MedicationAdapter());
    Hive.registerAdapter(InsumoAdapter());
    Hive.registerAdapter(PersonalMedicoAdapter());
    Hive.registerAdapter(EscalasObstetricasAdapter());
    Hive.registerAdapter(AppointmentAdapter());

    // Abrir cajas de Hive con mejor manejo de errores
    await _initializeHiveBoxes();
  } catch (e) {
    developer.log('error: $e', name: 'main_initialization');
    // Continuar sin la base de datos local si hay un error crítico
  }

  runApp(
    ProviderScope(
      overrides: [
        // Providers básicos que están en el archivo actual
        frapLocalServiceProvider,
        frapFirestoreServiceProvider,
        frapUnifiedServiceProvider,
      ],
      child: const MyApp(),
    ),
  );
}

// Función para inicializar las cajas de Hive
Future<void> _initializeHiveBoxes() async {
  try {
    // Verificar si la caja ya está abierta
    if (!Hive.isBoxOpen('fraps')) {
      await Hive.openBox<Frap>('fraps');
      developer.log(
        'Caja de FRAPs abierta correctamente',
        name: 'hive_initialization',
      );
    } else {
      developer.log(
        'Caja de FRAPs ya estaba abierta',
        name: 'hive_initialization',
      );
    }
  } catch (e) {
    developer.log(
      'Error abriendo caja de FRAPs: $e',
      name: 'hive_initialization',
    );
    try {
      // Si hay error, intentar limpiar y reabrir
      developer.log(
        'Intentando limpiar y reabrir la caja...',
        name: 'hive_initialization',
      );
      await Hive.deleteBoxFromDisk('fraps');
      await Future.delayed(const Duration(milliseconds: 500)); // Pequeña pausa
      await Hive.openBox<Frap>('fraps');
      developer.log(
        'Caja de FRAPs reabierta correctamente después de limpiar',
        name: 'hive_initialization',
      );
    } catch (e2) {
      developer.log(
        'Error crítico inicializando base de datos: $e2',
        name: 'hive_initialization',
      );
      // Continuar sin la base de datos local
    }
  }
}

// Providers principales
final frapLocalServiceProvider = Provider<FrapLocalService>((ref) {
  return FrapLocalService();
});

final frapFirestoreServiceProvider = Provider<FrapFirestoreService>((ref) {
  return FrapFirestoreService();
});

final frapUnifiedServiceProvider = Provider<FrapUnifiedService>((ref) {
  final localService = ref.watch(frapLocalServiceProvider);
  final cloudService = ref.watch(frapFirestoreServiceProvider);

  return FrapUnifiedService(
    localService: localService,
    cloudService: cloudService,
  );
});

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BG Med',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
      navigatorObservers: [routeObserver],
      routes: {'/dashboard': (context) => const DashboardScreen()},
    );
  }
}
