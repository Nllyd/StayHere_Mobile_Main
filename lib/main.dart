import 'package:flutter/material.dart';
import 'auth.dart'; // Importa auth.dart

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(), // Página principal
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double halfHeight = screenHeight / 2 + 70;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              height: halfHeight,
              color: const Color(0xFF212F38),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60.0),
                  Container(
                    height: 30,
                    alignment: Alignment.topCenter,
                    child: Image.asset(
                      'assets/images/StayPandaHere.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  const Text(
                    'UN NUEVO ESPACIO',
                    style: TextStyle(
                      fontFamily: 'Inria Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    'PARA TI',
                    style: TextStyle(
                      fontFamily: 'Inria Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: Image.asset(
                          'assets/images/ImagenMain/Habitacion 1.jpg',
                          height: 130, // Reducido de 150 a 130
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: Image.asset(
                          'assets/images/ImagenMain/Habitacion 2.jpg',
                          height: 130, // Reducido de 150 a 130
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),
                  ElevatedButton(
                    onPressed: () {
                      // Redirigir a AuthPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AuthPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDE5D5D),
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: const Text(
                      'Buscar habitaciones',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¿Buscas una nueva habitación?',
              style: TextStyle(
                fontFamily: 'Inria Sans',
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Color(0xFFDE5D5D),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              child: const Text(
                'Encuentra tu espacio perfecto para estudiar, relajarte y crecer con nuestra plataforma especializada en buscar habitaciones para estudiantes.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF262626),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(
              thickness: 2,
              color: Color(0xFF262626),
              indent: 20,
              endIndent: 20,
            ),
            const SizedBox(height: 10),
            // Sección de imágenes, una debajo de la otra
            Column(
              children: [
                Card(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: Image.asset(
                          'assets/images/ImagenMain/Cuartos.png',
                          fit: BoxFit.cover,
                          height: 300, // Reducido de 200 a 300
                          width: double.infinity,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Regístrate',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Crea tu cuenta o inicia sesión y encuentra tu alojamiento adecuado, basándote en tus gustos y necesidades u ofrece tus habitaciones.',
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                Card(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: Image.asset(
                          'assets/images/ImagenMain/Buscando.png',
                          fit: BoxFit.cover,
                          height: 300, // Reducido de 200 a 300
                          width: double.infinity,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Contacta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Ponte en contacto de una forma sencilla y rápida para poder reunirse y así saber si es la habitación que estás buscando para poder vivir de forma cómoda.',
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                Card(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: Image.asset(
                          'assets/images/ImagenMain/Disfruta.png',
                          fit: BoxFit.cover,
                          height: 300, // Reducido de 200 a 300
                          width: double.infinity,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Relájate',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Disfruta de tu nuevo alojamiento a tu medida, comparte tu experiencia con los demás y recomienda el aplicativo a tus conocidos.',
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
