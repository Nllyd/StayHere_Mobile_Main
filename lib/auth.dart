import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool isLogin = true;
  String captcha = '';
  String userCaptchaInput = '';
  bool isCaptchaVerified = false;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  // Generar CAPTCHA aleatorio
  void _generateCaptcha() {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()';
    final random = Random();
    captcha = List.generate(4, (index) => characters[random.nextInt(characters.length)]).join();
  }

  // Función para hacer la solicitud de login
  Future<void> _login() async {
    final url = Uri.parse('https://stayhere-web.onrender.com/api/login/'); // URL de la API de login

    // Preparar los datos para la solicitud
    final body = json.encode({
      'email': email,
      'password': password,
    });

    // Hacer la solicitud POST
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success']) {
        // Guardar el correo electrónico en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('email', email);

        // Si la respuesta es exitosa, navegar a la página de habitaciones
        Navigator.pushReplacementNamed(context, '/habitaciones');
      } else {
        // Mostrar el mensaje de error como un SnackBar
        _showErrorSnackbar('Credenciales incorrectas');
      }
    } else {
      // Mostrar el mensaje de error si la respuesta no es 200
      _showErrorSnackbar('Error al iniciar sesión. Intenta de nuevo.');
    }
  }

  // Función para mostrar el mensaje de error como un SnackBar
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Verificar si el CAPTCHA ingresado por el usuario es correcto
  void _verifyCaptcha() {
    if (userCaptchaInput == captcha) {
      setState(() {
        isCaptchaVerified = true;
      });
    } else {
      setState(() {
        isCaptchaVerified = false;
      });
      _showErrorSnackbar('CAPTCHA incorrecto. Intenta de nuevo.');
    }
  }

  // Función para generar colores aleatorios (excepto rojo)
  Color _getRandomColor() {
    List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
      Colors.indigo,
      Colors.yellow
    ];
    return colors[Random().nextInt(colors.length)];
  }

  // Mostrar el modal para CAPTCHA
  void _showCaptchaDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verificar CAPTCHA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 235, 110, 101),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: Text(
                  captcha,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getRandomColor(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Ingresa el CAPTCHA',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  userCaptchaInput = value;
                });
              },
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              _verifyCaptcha();
              Navigator.of(ctx).pop(); // Cerrar el modal
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF212F38), // Color del header
            ),
            child: const Text('Verificar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autenticación'),
        backgroundColor: const Color(0xFF212F38),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                isLogin ? 'Iniciar sesión' : 'Registrarse',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212F38),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu correo electrónico';
                  }
                  if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) {
                    return 'Por favor ingresa un correo válido';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    email = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu contraseña';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    password = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _showCaptchaDialog, // Abre el modal para CAPTCHA
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  backgroundColor: const Color(0xFF212F38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Text(
                  'Verificar CAPTCHA',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              // Mostrar el mensaje si el CAPTCHA no se ha verificado
              if (!isCaptchaVerified)
                const Text(
                  'Por favor verifica el CAPTCHA antes de iniciar sesión.',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 20),
              // Botón de login solo si el CAPTCHA es verificado
              ElevatedButton(
                onPressed: isCaptchaVerified
                    ? () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _login();
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  backgroundColor: const Color(0xFF212F38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: Text(
                  isLogin ? 'Iniciar sesión' : 'Registrarse',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin; // Cambiar entre login y registro
                  });
                },
                child: Text(
                  isLogin
                      ? '¿No tienes cuenta? Regístrate aquí'
                      : '¿Ya tienes cuenta? Inicia sesión',
                  style: const TextStyle(fontSize: 16, color: Color(0xFF212F38)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
