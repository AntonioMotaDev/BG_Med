# BG Med - Sistema de Atención Prehospitalaria

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.7.2-02569B?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.7.2-0175C2?style=for-the-badge&logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/License-Private-red?style=for-the-badge)

**Aplicación móvil multiplataforma para la gestión profesional de registros médicos prehospitalarios (FRAP)**

[Características](#-características-principales) • [Instalación](#-instalación) • [Uso](#-uso) • [Arquitectura](#-arquitectura) • [Contribuir](#-contribuir)

</div>


##  Descripción

**BG Med** es una aplicación Flutter diseñada específicamente para administradores que trabajan en servicios de atención prehospitalaria. Permite la creación, gestión y sincronización de Formatos de Registro de Atención Prehospitalaria (FRAP) con funcionalidades offline-first y sincronización automática en la nube.

###  Soluciones a problemas previos

- Digitalización de formularios médicos de emergencia
- Persistencia local con sincronización automática cuando hay conectividad
- Generación de PDFs profesionales para reportes
- Gestión de pacientes, citas y equipamiento médico
- Trazabilidad completa del personal médico y materiales utilizados


##  Características principales

### Funcionalidades Core

- Registro completo FRAP: Información del servicio, paciente, signos vitales, exploración física
- Gestión de pacientes: Historial clínico completo y patológico
- Escalas médicas: Implementación de Glasgow, Silverman-Anderson y escalas obstétricas
- Gestión de medicamentos e insumos: Control de material utilizado con registro detallado
- Personal médico: Registro del equipo interviniente con firma digital
- Calendario de citas: Programación y seguimiento de consultas

### Sincronización y Almacenamiento

- Almacenamiento local: Base de datos Hive para funcionamiento offline
- Firebase Firestore: Sincronización automática en la nube
- Modo híbrido: Funciona sin internet, sincroniza cuando está disponible
- Backup y restauración: Sistema de respaldo de datos

### Generación de Documentos

- PDFs profesionales: Exportación completa de registros FRAP
- Firmas digitales: Captura de firma del paciente y personal médico
- Compartir: Exportación y compartición de documentos


## Instalación

### Prerrequisitos

```bash
# Verificar versiones
flutter --version  # >= 3.7.2
dart --version     # >= 3.7.2
```

### Configuración del Proyecto

1. Clonar el repositorio
```bash
git clone https://github.com/AntonioMotaDev/BG_Med_Flutter.git
cd BG_Med_Flutter
```

2. Instalar dependencias
```bash
flutter pub get
```

3. Configurar Firebase
    - Crear proyecto en [Firebase Console](https://console.firebase.google.com/)
    - Descargar `google-services.json` y colocarlo en `android/app/`
    - Configurar Firebase CLI:
    ```bash
    firebase login
    flutterfire configure
    ```

4. Generar código (Hive adapters)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Ejecutar la aplicación

```bash
# Modo desarrollo
flutter run

# Modo release
flutter run --release
```



## Tecnologías y Dependencias

### Core
- Flutter 3.7.2 
- Dart 3.7.2 
- flutter_riverpod 2.6.1 

### Backend y Persistencia
- Firebase Auth 5.3.3 
- Firebase Storage 12.3.7 
- Hive 2.2.3  

### Utilidades
- intl 0.20.2 
- uuid 4.5.1 
- equatable 2.0.7 


## Arquitectura del Proyecto

```
lib/
├── core/                          # Núcleo de la aplicación
│   ├── models/                    # Modelos de datos (Hive & Firestore)
│   │   ├── patient.dart
│   │   ├── frap.dart
│   │   ├── clinical_history.dart
│   │   └── ...
│   ├── servicios/                 # Servicios y lógica de negocio
│   │   ├── frap_local_service.dart
│   │   ├── frap_firestore_service.dart
│   │   ├── frap_unified_service.dart
│   │   └── pdf_generator_service.dart
│   ├── theme/                     # Temas y estilos
│   │   └── app_theme.dart
│   └── widgets/                   # Widgets reutilizables
│
├── features/                      # Características por módulos
│   ├── auth/                      # Autenticación
│   │   └── presentation/
│   │       └── screens/
│   ├── dashboard/                 # Panel principal
│   │   └── presentation/
│   │       └── screens/
│   ├── frap/                      # Módulo principal FRAP
│   │   └── presentation/
│   │       ├── screens/
│   │       ├── dialogs/
│   │       └── providers/
│   └── patients/                  # Gestión de pacientes
│       └── presentation/
│
├── firebase_options.dart          # Configuración Firebase
└── main.dart                      # Punto de entrada
```

## Uso

### Flujo Principal

1. Login: Autenticación con Firebase Auth
2. Dashboard: Vista general con acceso a todas las funcionalidades
3. Crear FRAP: 
    - Información del servicio y registro
    - Datos del paciente
    - Exploración física y signos vitales
    - Manejo y medicamentos
    - Firmas digitales
4. Guardar: Almacenamiento local + sincronización cloud (si hay internet)
5. Ver registros: Lista completa con búsqueda y filtros
6. Generar PDF: Documento profesional listo para compartir

### Pantallas Principales

- Dashboard: Vista general y navegación
- FRAP Screen: Creación de registros
- Records List: Historial de atenciones
- Record Details: Vista detallada con opción de editar/eliminar
- Calendar: Gestión de citas
- Settings: Configuración y preferencias



## Seguridad y Privacidad

- Autenticación obligatoria con Firebase Auth
- Reglas de seguridad en Firestore
- Datos sensibles encriptados localmente
- Sin acceso a datos sin autenticación
- Cumplimiento con normativas médicas de privacidad


## Autores

- Antonio Mota - *Desarrollo inicial* - [@AntonioMotaDev](https://github.com/AntonioMotaDev)
- Diego Chacon - *Desarrolo auxiliar* - [@diego-dcr](https://github.com/diego-dcr)


## Licencia

Este proyecto es **software propietario privado**. 

Para consultas sobre licencias comerciales o permisos especiales, consulte el archivo [LICENSE](LICENSE).


## Soporte

Para soporte técnico o consultas:
- Email: contacto@bgmed.com
- Issues: [GitHub Issues](https://github.com/AntonioMotaDev/BG_Med_Flutter/issues)

