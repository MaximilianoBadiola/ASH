@echo off
echo Iniciando proceso de compilacion y renombrado...
call flutter build apk --release
echo APK generado. Procediendo a renombrar...
cd build\app\outputs\flutter-apk
if exist "app-release.apk" (
    if exist "ash.apk" del "ash.apk"
    ren "app-release.apk" "ash.apk"
    echo APK renombrado a ash.apk
) else (
    echo No se encontro el archivo app-release.apk
)
cd ..\..\..\..\
echo Proceso completado.