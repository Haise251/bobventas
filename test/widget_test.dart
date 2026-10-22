// Test de humo: verifica que el paquete compila y el widget raíz existe.
import 'package:flutter_test/flutter_test.dart';

import 'package:bob_ventas/app.dart';

void main() {
  test('BobVentasApp se instancia correctamente', () {
    const app = BobVentasApp();
    expect(app, isA<BobVentasApp>());
  });
}
