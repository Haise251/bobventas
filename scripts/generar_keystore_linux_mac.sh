#!/usr/bin/env bash
# ============================================================
#  Genera el keystore de firma para la app Bob Ventas (Android)
#  Requisito: tener JDK instalado (incluye keytool)
#  Resultado: android/app/bob-ventas-key.jks
# ============================================================
set -e

KEYSTORE="android/app/bob-ventas-key.jks"
ALIAS="bob-ventas-key"

if [ -f "$KEYSTORE" ]; then
  echo "[AVISO] El keystore $KEYSTORE ya existe."
  read -p "Escribe SI para reemplazarlo: " OVERWRITE
  if [ "$OVERWRITE" != "SI" ]; then
    echo "Cancelado."
    exit 0
  fi
  rm "$KEYSTORE"
fi

echo "Se te pedirán: contraseñas (usa la misma en ambas), nombre, organización,"
echo "ciudad, estado y país (VE para Venezuela)."
echo

keytool -genkeypair -v \
  -keystore "$KEYSTORE" \
  -alias "$ALIAS" \
  -keyalg RSA -keysize 2048 -validity 10000

echo
echo "============================================================"
echo " Keystore creado: $KEYSTORE"
echo
echo " Siguiente paso: copia android/key.properties.example como"
echo " android/key.properties y escribe tus contraseñas:"
echo "   storePassword=..."
echo "   keyPassword=..."
echo "   keyAlias=$ALIAS"
echo "   storeFile=../app/bob-ventas-key.jks"
echo
echo " Luego compila con:  flutter build apk --release"
echo "============================================================"
