import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Donaciones Animales Sin Hogar',
      theme: ThemeData(
        primaryColor: Color(0xFFFF8200),
        primarySwatch: Colors.orange,
        fontFamily: 'Roboto',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFF8200),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFFFF8200)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFFFF8200), width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey[600]),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _cantidadController = TextEditingController();
  final String _numeroASH = "24200"; // Número de destino
  bool _enviando = false;
  int _donacionesCompletadas = 0;
  int _donacionesTotal = 0;
  String _estado = "";
  bool _mostrarEstado = false;
  bool _esError = false;
  bool _exitoso = false;

  // Controlador de animación para el ícono
  late AnimationController _iconAnimationController;
  late Animation<double> _iconAnimation;

  @override
  void initState() {
    super.initState();
    // Configuración del controlador de animación
    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _iconAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.elasticInOut,
      ),
    );

    // Registrar el observer
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _iconAnimationController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  // Método para verificar y solicitar permisos de SMS
  Future<bool> _requestSmsPermission() async {
    try {
      // Verificamos si tenemos permiso para enviar SMS
      final status = await Permission.sms.status;

      if (status.isGranted) {
        return true;
      }

      // Mostrar diálogo explicando por qué necesitamos el permiso
      if (context.mounted) {
        final bool shouldRequest =
            await showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Text('Permiso necesario'),
                    content: Text(
                      'Para realizar donaciones, necesitamos permiso para enviar SMS automáticamente a Animales Sin Hogar.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Continuar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
            ) ??
            false;

        if (!shouldRequest) {
          return false;
        }
      }

      // Solicitamos permiso
      final result = await Permission.sms.request();
      return result.isGranted;
    } catch (e) {
      debugPrint("Error verificando permisos: $e");
      return false;
    }
  }

  // Método para enviar SMS usando flutter_sms
  Future<bool> _sendSMS(String phoneNumber, String message) async {
    try {
      // Usar sendSMS con sendDirect:true
      final String result = await sendSMS(
        message: message,
        recipients: [phoneNumber],
        sendDirect: true,
      );

      debugPrint("Resultado del envío de SMS: $result");

      // Envío exitoso
      return result.contains("sent") || result.contains("success");
    } catch (e) {
      debugPrint("Error al enviar SMS: $e");
      return false;
    }
  }

  // Animar el ícono cuando se realiza una donación exitosa
  void _animateIcon() {
    _iconAnimationController.reset();
    _iconAnimationController.forward();
  }

  Future<void> _enviarDonaciones() async {
    String cantidadText = _cantidadController.text.trim();
    if (cantidadText.isEmpty) {
      setState(() {
        _estado = "Por favor ingresa una cantidad";
        _mostrarEstado = true;
        _esError = true;
      });
      return;
    }

    int cantidad = int.tryParse(cantidadText) ?? 0;
    if (cantidad <= 0) {
      setState(() {
        _estado = "Por favor ingresa un número válido";
        _mostrarEstado = true;
        _esError = true;
      });
      return;
    }

    // Solicitar permiso de SMS antes de proceder
    final hasPermission = await _requestSmsPermission();
    if (!hasPermission) {
      setState(() {
        _estado = "Se requiere permiso para enviar SMS";
        _mostrarEstado = true;
        _esError = true;
      });
      return;
    }

    setState(() {
      _enviando = true;
      _donacionesCompletadas = 0;
      _donacionesTotal = cantidad;
      _estado = "Iniciando donación 1 de $cantidad";
      _mostrarEstado = true;
      _esError = false;
      _exitoso = false;
    });

    await _iniciarDonacion();
  }

  Future<void> _iniciarDonacion() async {
    try {
      setState(() {
        _estado =
            "Enviando donación ${_donacionesCompletadas + 1} de $_donacionesTotal...";
        _mostrarEstado = true;
        _esError = false;
      });

      // Usar sendSMS para enviar el mensaje
      final result = await _sendSMS(_numeroASH, "DONAR");

      if (result) {
        setState(() {
          _donacionesCompletadas++;

          // Animar el icono con cada donación exitosa
          _animateIcon();

          if (_donacionesCompletadas < _donacionesTotal) {
            _estado = "Donación enviada correctamente. Preparando siguiente...";
            _mostrarEstado = true;
            _esError = false;
            // Añadir un pequeño retraso entre mensajes
            Future.delayed(Duration(milliseconds: 800), () {
              if (_enviando) {
                _iniciarDonacion();
              }
            });
          } else {
            _estado = "¡Gracias por colaborar!";
            _mostrarEstado = true;
            _esError = false;
            _exitoso = true;
            _enviando = false;
          }
        });
      } else {
        setState(() {
          _estado = "Error al enviar el mensaje. Verifica los permisos de SMS.";
          _mostrarEstado = true;
          _esError = true;
          _enviando = false;
        });
      }
    } catch (e) {
      debugPrint("Error en donación: ${e.toString()}");
      setState(() {
        _estado = "Error: ${e.toString()}";
        _mostrarEstado = true;
        _esError = true;
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Donaciones Animales Sin Hogar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFFFF8200),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Animación del ícono
              ScaleTransition(
                scale: _iconAnimation,
                child: Icon(Icons.pets, size: 80, color: Color(0xFFFF8200)),
              ),
              const SizedBox(height: 24),
              Text(
                'Animales Sin Hogar',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF8200),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Dona tu saldo de Antel a Animales Sin Hogar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFFFF6E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Cada donación equivale a 10 pesos de tu saldo',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFF0F9E8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'La app enviará mensajes automáticamente',
                  style: TextStyle(fontSize: 14, color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              // Campo de texto con decoración estándar
              TextField(
                controller: _cantidadController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cantidad de donaciones',
                  hintText: 'Ingresa el número de donaciones',
                  prefixIcon: Icon(
                    Icons.monetization_on,
                    color: Color(0xFFFF8200),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Mostrar el estado de la donación con animación
              if (_mostrarEstado)
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color:
                        _esError
                            ? Colors.red[100]
                            : _exitoso
                            ? Colors.green[100]
                            : Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _esError
                                ? Icons.error_outline
                                : _exitoso
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            color:
                                _esError
                                    ? Colors.red[700]
                                    : _exitoso
                                    ? Colors.green[700]
                                    : Colors.blue[700],
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _estado,
                              style: TextStyle(
                                color:
                                    _esError
                                        ? Colors.red[700]
                                        : _exitoso
                                        ? Colors.green[700]
                                        : Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Barra de progreso si está enviando
                      if (_enviando && _donacionesTotal > 0) ...[
                        SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            tween: Tween<double>(
                              begin: 0,
                              end: _donacionesCompletadas / _donacionesTotal,
                            ),
                            builder:
                                (context, value, _) => LinearProgressIndicator(
                                  value: value,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.3,
                                  ),
                                  color: Color(0xFFFF8200),
                                  minHeight: 10,
                                ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${_donacionesCompletadas} de $_donacionesTotal donaciones completadas',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),

              // Botón para iniciar donaciones
              ElevatedButton(
                onPressed: _enviando ? null : _enviarDonaciones,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  // Añadir animación de sombra
                  elevation: 5,
                  shadowColor: Color(0xFFFF8200).withOpacity(0.5),
                ),
                child:
                    _enviando
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Enviando...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                        : Text(
                          'Iniciar donaciones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
              ),

              // Espacio extra para evitar problemas de layout
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
