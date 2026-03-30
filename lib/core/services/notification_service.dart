import 'package:flutter/material.dart';
import 'package:bg_med/core/theme/app_theme.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Notificar éxito de sincronización
  void showSyncSuccess(BuildContext context, int recordsSynced) {
    _showSnackBar(
      context,
      '✅ Sincronización exitosa',
      'Se sincronizaron $recordsSynced registros correctamente',
      AppTheme.primaryGreen,
    );
  }

  // Notificar duplicados encontrados
  void showDuplicatesFound(BuildContext context, int count) {
    _showSnackBar(
      context,
      '⚠️ Duplicados detectados',
      'Se encontraron $count registros duplicados',
      AppTheme.accentOrange,
    );
  }

  // Notificar errores de red
  void showNetworkError(BuildContext context, String message) {
    _showSnackBar(context, '❌ Error de conexión', message, AppTheme.accentRed);
  }

  // Notificar limpieza de duplicados
  void showCleanupResult(
    BuildContext context,
    int recordsRemoved,
    int spaceFreed,
  ) {
    final spaceMB = (spaceFreed / 1024 / 1024).toStringAsFixed(2);
    _showSnackBar(
      context,
      '🧹 Limpieza completada',
      'Se eliminaron $recordsRemoved duplicados ($spaceMB MB liberados)',
      AppTheme.primaryBlue,
    );
  }

  // Notificar error de limpieza
  void showCleanupError(BuildContext context, String error) {
    _showSnackBar(context, '❌ Error en limpieza', error, AppTheme.accentRed);
  }

  // Notificar modo offline
  void showOfflineMode(BuildContext context) {
    _showSnackBar(
      context,
      '📱 Modo offline',
      'Trabajando sin conexión. Los cambios se sincronizarán cuando se restablezca la conexión.',
      AppTheme.neutralGray,
      duration: const Duration(seconds: 4),
    );
  }

  // Notificar reconexión
  void showReconnected(BuildContext context) {
    _showSnackBar(
      context,
      '🌐 Conexión restablecida',
      'Sincronizando datos pendientes...',
      AppTheme.primaryGreen,
    );
  }

  // Notificar guardado local
  void showLocalSaveSuccess(BuildContext context) {
    _showSnackBar(
      context,
      '💾 Guardado local',
      'Registro guardado localmente. Se sincronizará cuando haya conexión.',
      AppTheme.primaryBlue,
    );
  }

  // Notificar validación de formulario
  void showValidationError(BuildContext context, String field, String message) {
    _showSnackBar(
      context,
      '⚠️ Error de validación',
      '$field: $message',
      AppTheme.accentOrange,
    );
  }

  // Notificar búsqueda sin resultados
  void showNoSearchResults(BuildContext context, String query) {
    _showSnackBar(
      context,
      '🔍 Sin resultados',
      'No se encontraron registros para "$query"',
      AppTheme.neutralGray,
    );
  }

  // Mostrar diálogo de confirmación
  Future<bool> showConfirmationDialog(
    BuildContext context,
    String title,
    String message, {
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelText),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: Text(confirmText),
              ),
            ],
          ),
    );

    return result ?? false;
  }

  // Mostrar diálogo de progreso
  void showProgressDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(child: Text(message)),
              ],
            ),
          ),
    );
  }

  // Ocultar diálogo de progreso
  void hideProgressDialog(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  // Mostrar snackbar personalizado
  void _showSnackBar(
    BuildContext context,
    String title,
    String message,
    Color backgroundColor, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(message, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Cerrar',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Mostrar toast personalizado
  void showToast(
    BuildContext context,
    String message, {
    Color? backgroundColor,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).padding.top + 50,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor ?? AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }
}
