import 'package:flutter/material.dart';

import '../pos/pos_screen.dart';

/// Pantalla de carga con barra de progreso y log de inicialización
/// (idéntica a la versión original).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  final List<String> _loadingLogs = [];
  final List<Map<String, dynamic>> _initSteps = [
    {'p': 0.1, 'm': 'Iniciando Bob Ventas...'},
    {'p': 0.2, 'm': 'Conectando a SQLite (pos_karen.db)...'},
    {'p': 0.4, 'm': 'Cargando catálogo de productos...'},
    {'p': 0.6, 'm': 'Cargando img/logo.png...'},
    {'p': 0.7, 'm': 'Configurando impresión térmica 58mm...'},
    {'p': 0.8, 'm': 'Verificando integridad de tablas...'},
    {'p': 0.9, 'm': 'Sincronizando ventas del día...'},
    {'p': 1.0, 'm': 'Sistema listo para operar.'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {
          for (var step in _initSteps) {
            if (_progressAnimation.value >= step['p'] &&
                !_loadingLogs.contains(step['m'])) {
              _loadingLogs.add(step['m']);
            }
          }
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PosScreen(title: 'Bob Ventas'),
            ),
          );
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'img/logo.png',
                height: 200,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.store,
                  color: Color(0xFFFF7043),
                  size: 160,
                ),
              ),
              const SizedBox(height: 40),
              LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: Colors.white10,
                color: const Color(0xFFFF7043),
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 10),
              Text(
                'Cargando: ${(_progressAnimation.value * 100).toInt()}%',
                style: const TextStyle(
                  color: Color(0xFFFF7043),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                height: 150,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListView.builder(
                  itemCount: _loadingLogs.length,
                  itemBuilder: (context, index) => Text(
                    '> ${_loadingLogs[index]}',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
