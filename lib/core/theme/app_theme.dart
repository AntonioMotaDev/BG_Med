import 'package:flutter/material.dart';

class AppTheme {
  // Colores principales médicos
//   static const Color primaryBlue = Color(0xFF2E86AB);      // Azul teal profesional
//   static const Color primaryGreen = Color(0xFF52C41A);     // Verde salud
  
  // colores de BG Med
  static const Color primaryBlue = Color(0xFF009EBD);      // Azul teal profesional
  static const Color primaryGreen = Color(0xFF7E84F2);     // lilac salud
  static const Color accentRed = Color(0xFFE53E3E);        // Rojo emergencia
  static const Color accentOrange = Color(0xFFFD7F28);     // Naranja alerta
  static const Color neutralGray = Color(0xFF718096);      // Gris profesional
  static const Color backgroundLight = Color(0xFFF7FAFC);  // Fondo claro
  static const Color cardWhite = Color(0xFFFFFFFF);        // Blanco puro
  static const Color textDark = Color(0xFF2D3748);         // Texto oscuro
  static const Color textLight = Color(0xFF718096);        // Texto claro

  // Colores para tema oscuro
  static const Color primaryBlueDark = Color(0xFF00A3A3);     // Azul teal más brillante para modo oscuro
  static const Color primaryGreenDark = Color(0xFF9090FF);   // Lilac más brillante para modo oscuro
  static const Color accentRedDark = Color(0xFFFF6B6B);      // Rojo más suave para modo oscuro
  static const Color accentOrangeDark = Color(0xFFFFB347);   // Naranja más suave para modo oscuro
  static const Color neutralGrayDark = Color(0xFF9CA3AF);    // Gris más claro para modo oscuro
  static const Color backgroundDark = Color(0xFF0F172A);     // Fondo oscuro principal
  static const Color cardDark = Color(0xFF1E293B);          // Cards oscuras
  static const Color surfaceDark = Color(0xFF334155);       // Superficie oscura
  static const Color textLightMode = Color(0xFFF1F5F9);     // Texto claro para modo oscuro
  static const Color textSecondaryDark = Color(0xFFCBD5E1); // Texto secundario modo oscuro

  // Gradientes médicos adaptativos
  static LinearGradient primaryGradient(bool isDark) => LinearGradient(
    colors: isDark 
        ? [primaryBlueDark, const Color(0xFF0EA5E9)]
        : [primaryBlue, const Color(0xFF4299E1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient emergencyGradient(bool isDark) => LinearGradient(
    colors: isDark 
        ? [accentRedDark, const Color(0xFFFF8A80)]
        : [accentRed, const Color(0xFFFC8181)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient successGradient(bool isDark) => LinearGradient(
    colors: isDark 
        ? [primaryGreenDark, const Color(0xFFA5B4FC)]
        : [primaryGreen, const Color(0xFF68D391)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Tema claro
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
        secondary: primaryGreen,
        error: accentRed,
        background: backgroundLight,
        surface: cardWhite,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onBackground: textDark,
        onSurface: textDark,
      ),
      
      // AppBar personalizado
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: cardWhite,
        foregroundColor: textDark,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: textDark),
      ),
      
      // Cards personalizadas
      cardTheme: CardThemeData(
        elevation: 3,
        shadowColor: primaryBlue.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: cardWhite,
      ),
      
      // Botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryBlue.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Campos de entrada
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neutralGray.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neutralGray.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentRed, width: 2),
        ),
        filled: true,
        fillColor: backgroundLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: neutralGray),
        hintStyle: TextStyle(color: neutralGray.withOpacity(0.7)),
      ),
      
      // FAB personalizado
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // BottomNavigationBar personalizado
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardWhite,
        selectedItemColor: primaryBlue,
        unselectedItemColor: neutralGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      
      // TabBar personalizado
      tabBarTheme: TabBarThemeData(
        labelColor: primaryBlue,
        unselectedLabelColor: neutralGray,
        indicator: UnderlineTabIndicator(
          borderSide: const BorderSide(color: primaryBlue, width: 3),
          insets: const EdgeInsets.symmetric(horizontal: 20),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      
      // Scaffold personalizado
      scaffoldBackgroundColor: backgroundLight,
      
      // Divider personalizado
      dividerTheme: DividerThemeData(
        color: neutralGray.withOpacity(0.2),
        thickness: 1,
      ),

      // ListTile personalizado
      listTileTheme: ListTileThemeData(
        tileColor: cardWhite,
        selectedTileColor: primaryBlue.withOpacity(0.1),
        iconColor: neutralGray,
        textColor: textDark,
      ),
    );
  }

  // Tema oscuro
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlueDark,
        brightness: Brightness.dark,
        primary: primaryBlueDark,
        secondary: primaryGreenDark,
        error: accentRedDark,
        background: backgroundDark,
        surface: cardDark,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onError: Colors.black,
        onBackground: textLightMode,
        onSurface: textLightMode,
      ),
      
      // AppBar personalizado oscuro
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: cardDark,
        foregroundColor: textLightMode,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: textLightMode,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: textLightMode),
      ),
      
      // Cards personalizadas oscuras
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: cardDark,
      ),
      
      // Botones elevados oscuros
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlueDark,
          foregroundColor: Colors.black,
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Botones de texto oscuros
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlueDark,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Campos de entrada oscuros
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neutralGrayDark.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neutralGrayDark.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlueDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentRedDark, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentRedDark, width: 2),
        ),
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: neutralGrayDark),
        hintStyle: TextStyle(color: neutralGrayDark.withOpacity(0.7)),
      ),
      
      // FAB personalizado oscuro
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryBlueDark,
        foregroundColor: Colors.black,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // BottomNavigationBar personalizado oscuro
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardDark,
        selectedItemColor: primaryBlueDark,
        unselectedItemColor: neutralGrayDark,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      
      // TabBar personalizado oscuro
      tabBarTheme: TabBarThemeData(
        labelColor: primaryBlueDark,
        unselectedLabelColor: neutralGrayDark,
        indicator: UnderlineTabIndicator(
          borderSide: const BorderSide(color: primaryBlueDark, width: 3),
          insets: const EdgeInsets.symmetric(horizontal: 20),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      
      // Scaffold personalizado oscuro
      scaffoldBackgroundColor: backgroundDark,
      
      // Divider personalizado oscuro
      dividerTheme: DividerThemeData(
        color: neutralGrayDark.withOpacity(0.3),
        thickness: 1,
      ),

      // ListTile personalizado oscuro
      listTileTheme: ListTileThemeData(
        tileColor: cardDark,
        selectedTileColor: primaryBlueDark.withOpacity(0.2),
        iconColor: neutralGrayDark,
        textColor: textLightMode,
      ),
    );
  }

  // Colores específicos para tipos de datos médicos (adaptativos)
  static Map<String, Color> medicalColors(bool isDark) => {
    'emergency': isDark ? accentRedDark : accentRed,
    'warning': isDark ? accentOrangeDark : accentOrange,
    'success': isDark ? primaryGreenDark : primaryGreen,
    'info': isDark ? primaryBlueDark : primaryBlue,
    'neutral': isDark ? neutralGrayDark : neutralGray,
  };

  // Método para obtener color por estado médico (adaptativo)
  static Color getColorByStatus(String status, {bool isDark = false}) {
    return medicalColors(isDark)[status.toLowerCase()] ?? 
           (isDark ? neutralGrayDark : neutralGray);
  }

  // Método auxiliar para obtener el gradiente de header adaptativo
  static LinearGradient getHeaderGradient(bool isDark) => isDark 
      ? LinearGradient(
          colors: [primaryBlueDark, primaryGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : LinearGradient(
          colors: [primaryBlue, primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
} 