# Bob Ventas — estructura del proyecto

```
bob_ventas_refactorizado/
├── pubspec.yaml                  # dependencias (sqflite, printing, esc_pos_utils_plus...)
├── lib/
│   ├── main.dart                 # punto de entrada (inicializa SQLite FFI en Windows)
│   ├── app.dart                  # MaterialApp + tema
│   ├── core/                     # CAPA COMPARTIDA
│   │   ├── constants/app_constants.dart   # salsas, áreas, tipos de servicio, claves
│   │   ├── theme/app_theme.dart           # tema oscuro naranja (igual al original)
│   │   ├── utils/formatters.dart          # dinero, moneda Bs/$, fechas, etiquetas
│   │   └── services/
│   │       ├── database_helper.dart       # pos_karen.db v10 (compatibilidad total)
│   │       ├── db_seed.dart               # catálogo semilla + 6 combos nuevos en $
│   │       ├── settings_service.dart      # ajustes guardados en la BD
│   │       └── print/
│   │           ├── print_service.dart     # FACHADA: elige Windows o Android
│   │           ├── esc_pos_templates.dart # 3 tickets en comandos térmicos 58mm
│   │           ├── pdf_templates.dart     # 3 tickets en PDF 58mm (Windows)
│   │           └── thermal_usb_printer.dart # puente con flutter_thermal_printer
│   └── features/                  # PANTALLAS POR MÓDULO
│       ├── splash/splash_screen.dart
│       ├── pos/
│       │   ├── pos_screen.dart            # pantalla principal (catálogo + carrito)
│       │   └── widgets/
│       │       ├── catalog_panel.dart     # cuadrícula categorías/productos
│       │       ├── cart_panel.dart        # carrito con totales Bs/$
│       │       ├── catalog_dialogs.dart   # CRUD categorías/productos/precios
│       │       ├── customization_dialogs.dart # personalizar, combos, extras
│       │       └── checkout_dialog.dart   # ticket previo + imprimir/finalizar
│       ├── pedidos/
│       │   ├── sales_history_dialog.dart  # ventas del día (Bs + $ por pedido)
│       │   ├── sale_detail_dialog.dart    # detalle con desglose de moneda
│       │   └── editable_sale_dialog.dart  # editar pedido guardado
│       ├── reportes/
│       │   └── daily_report_dialog.dart   # RESUMEN Bs. / $ SEPARADOS
│       └── ajustes/
│           └── settings_screen.dart       # impresora, prueba, nombre negocio
├── android/
│   ├── app/
│   │   ├── build.gradle / build.gradle.kts  # firma release con key.properties
│   │   ├── proguard-rules.pro
│   │   └── src/main/
│   │       ├── AndroidManifest.xml        # USB host + filtro de dispositivos
│   │       ├── res/xml/device_filter.xml  # clase impresora USB (7) y vendor
│   │       └── kotlin/com/bobburgers/ventas/MainActivity.kt
│   └── key.properties.example             # plantilla de credenciales de firma
├── scripts/
│   ├── generar_keystore_windows.bat       # crea tu .jks (firma Android)
│   ├── generar_keystore_linux_mac.sh
│   ├── firmar_windows.ps1 / .bat          # firma el .exe (Windows)
└── README.md                              # guía completa de uso
```

## Qué cambió respecto al original

| Antes | Ahora |
|---|---|
| `main.dart` de 3.160 líneas con TODO | 20 archivos organizados en `core/` + `features/` |
| Impresión solo PDF vía driver | **Android: ESC/POS USB OTG nativo** · Windows: PDF por driver |
| Reporte con total mezclado | **Reporte separa Bs. (productos) y $ (combos)** |
| 5 combos a $5.00 de relleno | 5 originales + **6 combos nuevos en divisas** con precios reales |
| Sin ajustes | **Pantalla Ajustes**: elegir impresora USB/sistema, probar impresión, nombre del negocio |
| Sin firma | Scripts de keystore + `build.gradle` firmado + firma de Windows |
