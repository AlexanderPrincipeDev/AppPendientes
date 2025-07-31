# Arquitectura del proyecto

La aplicación se organiza en componentes pequeños y enfocados:

- **ChoreModel**: modelo central observado por las vistas. Coordina la carga y el guardado de datos a través de `DataStorage`, gestiona el estado de las tareas y delega las notificaciones al `NotificationService` y la gamificación al `GamificationManager`.
- **DataStorage**: capa de persistencia que lee y escribe archivos JSON. Expone métodos específicos para tareas, registros, categorías, gamificación y datos de usuario.
- **NotificationService**: responsable de solicitar permisos y programar notificaciones locales.
- **GamificationManager**: encapsula la lógica de puntos y bonificaciones otorgados por completar tareas.
- **Vistas SwiftUI**: se dividen por secciones (Hoy, Tareas, Estadísticas, Historial) y observan el `ChoreModel` mediante `@EnvironmentObject`.

## Pruebas
Las pruebas unitarias se encuentran en el directorio `Tests` y validan la lógica de gamificación.
