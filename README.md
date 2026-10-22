# Bob Ventas v2.0 — POS refactorizado (Windows + Android)

POS para Bob Burguer refactorizado con arquitectura por features, impresión
térmica **USB OTG en Android (58 mm, ESC/POS nativo)**, impresión **PDF por
driver en Windows**, **firma de la app** (keystore Android + firma de código
Windows), **reportes separados Bs. / $** y **6 combos nuevos en divisas**.

---

## 1. Qué incluye esta versión

| Función | Estado |
|---|---|
| Arquitectura `lib/core` + `lib/features` | ✔ 20 archivos organizados |
| Impresión Android USB OTG (58 mm ESC/POS) | ✔ `flutter_thermal_printer` + `esc_pos_utils_plus` |
| Impresión Windows (PDF 58 mm por driver) | ✔ igual que la versión anterior |
| 3 tickets en ambas plataformas | ✔ venta · área (COCINA/SALCHIPAPAS) · número de pedido |
| Reporte diario Bs. / $ separados | ✔ total Bs. (productos) y total $ (combos) |
| Historial por pedido con Bs + $ | ✔ |
| Combos nuevos en divisas | ✔ migración v10 automática |
| Pantalla de Ajustes | ✔ elegir impresora, probar impresión, nombre del negocio |
| Firma Android | ✔ scripts keystore + `build.gradle` con `key.properties` |
| Firma Windows | ✔ script `signtool` con certificado |
| Compatibilidad con `pos_karen.db` | ✔ versiones 1 → 10 sin perder datos |

---

## 2. Instalación en tu proyecto actual

### 2.1 Copia el código

1. Copia el contenido de `lib/` de este paquete sobre el `lib/` de tu
   proyecto Flutter (reemplaza `main.dart` y `database_helper.dart`).
2. Copia la carpeta `scripts/` a la raíz de tu proyecto.
3. **Conserva tu `img/logo.png`** en la raíz del proyecto (la app sigue
   cargándolo como asset `img/`).

### 2.2 Actualiza `pubspec.yaml`

Reemplaza el bloque `dependencies:` con el del `pubspec.yaml` de este
paquete (agrega `esc_pos_utils_plus`, `flutter_thermal_printer`, `image`,
y conserva `pdf`, `printing`, `sqflite`, `sqflite_common_ffi`, `path`).
Luego:

```bash
flutter pub get
```

### 2.3 Windows — no requiere nada más

```bash
flutter run -d windows
```
La impresión sigue funcionando por el driver de tu XP-58:
**Ajustes → Impresora → Impresoras del sistema → elegir → Probar impresora**.

---

## 3. Impresión en Android por USB OTG

### 3.1 Requisitos

- Cable **OTG** (USB-C o micro-USB → USB hembra).
- Impresora térmica 58 mm (XP-58, POS-58, 5890T…) encendida con papel.
- `minSdk` 23 (ya configurado en el `build.gradle` incluido).

### 3.2 Configurar (una sola vez)

1. Conecta la impresora al teléfono con el cable OTG.
2. Abre la app → **⚙ Ajustes → Impresora**.
3. Toca **"Buscar de nuevo"**: aparecerá la impresora USB detectada.
   *Si Android muestra el aviso "¿Permitir que la app acceda al
   dispositivo USB?", acéptalo.*
4. Selecciónala y toca **"Probar impresora"**: debe salir un ticket de
   prueba con acentos y el formato de 58 mm.
5. Listo. Cada venta imprimirá los 3 tickets (venta → área → número)
   exactamente como en Windows.

> **Si la impresora no aparece:** prueba otro cable OTG, revisa que la
> impresora tenga papel/encendida, y desenchufa-enchufa el cable. Algunos
> teléfonos requieren aceptar el permiso USB cada vez que se reconecta.

### 3.3 Formato térmico (ESC/POS)

- Ancho 32 columnas (58 mm), corte automático (`cut`).
- Ticket de venta: negocio, cliente/nota, nº pedido, secciones
  COMER AQUÍ / PARA LLEVAR, notas "SIN/CON", totales separados:
  `TOTAL: x.xx Bs.` y `TOTAL COMBOS: y.yy $`.
- Ticket de área: título grande COCINA/SALCHIPAPAS, tag `[AQUI]`/`[LLEVAR]`,
  unidades.
- Ticket de número: logo rasterizado + nº gigante + CON/SIN BEBIDA invertido.

---

## 4. Firma de la app

### 4.1 Android (keystore + release APK)

```bat
:: 1. Generar el keystore (Windows) — pide contraseñas y tus datos
scripts\generar_keystore_windows.bat
```
```bash
# o en Linux/Mac:
./scripts/generar_keystore_linux_mac.sh
```

2. Copia `android/key.properties.example` → `android/key.properties` y
   escribe tus contraseñas:
   ```properties
   storePassword=tu_contraseña
   keyPassword=tu_contraseña
   keyAlias=bob-ventas-key
   storeFile=../app/bob-ventas-key.jks
   ```
3. Copia `android/app/build.gradle` (Groovy) **o** `build.gradle.kts`
   (Kotlin) según el que use tu proyecto, reemplazando el contenido.
4. **Guarda el `.jks` y las contraseñas**: sin ellos no podrás publicar
   actualizaciones de la misma app.
5. Compila firmado:
   ```bash
   flutter build apk --release
   # APK firmado en: build/app/outputs/flutter-apk/app-release.apk
   ```

> ⚠️ **Package ID y datos:** el ID configurado es `com.bobburgers.ventas`.
> Si tu app ya estaba instalada en el teléfono con **otro** package ID y
> quieres **actualizarla conservando sus ventas**, cambia
> `applicationId` (y el `namespace` + la ruta de `MainActivity.kt`) por el
> ID que ya tenías. Un ID nuevo se instala como app aparte y no ve la BD
> anterior. También copia `MainActivity.kt` a
> `android/app/src/main/kotlin/com/bobburgers/ventas/` o ajústalo a tu
> paquete actual.

> 🔒 Agrega a `.gitignore`:
> ```
> android/key.properties
> android/app/*.jks
> *.pfx
> ```

### 4.2 Windows (firma de código del .exe)

```powershell
# Certificado auto-firmado (para tu propio uso / instalaciones controladas)
powershell -ExecutionPolicy Bypass -File .\scripts\firmar_windows.ps1 `
    -ExePath "build\windows\x64\runner\Release\bob_ventas.exe" `
    -PfxPassword "una-contraseña"
```
El script crea un certificado `.pfx`, firma el `.exe` con SHA-256 y lo
verifica. Para distribución seria conviene un certificado comprado
(Sectigo/Certum/DigiCert): pasa `-PfxPath` y `-PfxPassword` de tu
certificado real.

---

## 5. Reportes Bs. / $ (lo nuevo)

- **Resumen de ventas** (📊 en la barra superior): muestra dos tarjetas,
  `VENTAS EN Bs. (productos)` y `VENTAS EN $ (combos)`, y el desglose por
  producto con su moneda.
- **Ventas del día** (🧾): cada pedido muestra `12.50 + $14.00`
  (Bs. + combos) y el detalle completo desglosado.
- Regla de negocio: **todo lo marcado como combo se cobra y reporta en
  divisas ($); el resto en Bs.** La moneda se detecta por el flag de combo
  (`combo_quantity > 1`), igual que en la versión anterior, así que tus
  ventas viejas siguen cuadrando.

### Novedades del menú real (migración v10, automática)

Tomado de **bobventas.netlify.app**. La migración solo inserta lo que
no exista (dedup por nombre), así que no duplica nada de tu base de datos.

Combos nuevos (en $):

| Combo | Precio | Desglose |
|---|---|---|
| Promo Hamburguesa Completo | $10.00 | 2 hamburguesas + 1 combo perro + 1 ración de papa + 1 refresco 1L |
| Combo 4 Hamburguesas | $10.00 | 4 hamburguesas + 1 ración de papa + 1 refresco 1L |
| Combo 4 Enrollados | $10.00 | 4 enrollados + 1 ración de papa + 1 refresco 1L |

Productos nuevos (en Bs.):

| Producto | Precio | Categoría |
|---|---|---|
| Choriperro | 3.500 Bs. | Perros Calientes |
| Pepito | 7.000 Bs. | Otros |

Los precios son editables en la app (✏️ sobre cada producto). El catálogo
semilla para instalaciones nuevas también quedó actualizado con todos los
precios del menú web (Perro Sencillo 1.000 Bs., Bob Burguer 8.000 Bs., etc.).

---

## 6. Atajos de teclado (Windows)

Igual que antes:
- **1–9**: entrar a categoría / agregar producto / EXTRAS
- **Enter**: generar ticket · **Backspace**: volver a categorías
- Dentro de personalización: **Enter** agrega, **Esc/Backspace** cierra

---

## 7. Solución de problemas

| Problema | Solución |
|---|---|
| "No hay impresora USB configurada" (Android) | Ajustes → Impresora → buscar y seleccionar |
| La impresora USB no aparece | Cable OTG, permiso USB, reconectar; toca "Buscar de nuevo" |
| Sale papel sin texto en Android | Impresora sin soporte ESC/POS (raro en 58 mm); prueba el ticket de prueba |
| Acentos raros en el ticket | Ya usa tabla CP437; si tu modelo usa otra, cambia `CapabilityProfile.load()` por `CapabilityProfile.load('XP-58')` en `esc_pos_templates.dart` |
| Windows abre diálogo en vez de imprimir directo | Selecciona la impresora en Ajustes (guarda el nombre exacto del driver) |
| Cambié el package ID y no veo mis ventas | Es una app nueva para Android; usa el ID original para actualizar la existente |
| `minSdk` error al compilar | Usa el `build.gradle` incluido (minSdk 23) |
