import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart'; // Importar la página de HomePage

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final PageController _pageController = PageController();
  bool isCaptchaVerified = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  DateTime? selectedDate;
  int? age;
  String errorMessage = ''; // Mensaje de error
  String? jwtToken; // Token JWT que obtendremos del backend
  final TextEditingController captchaController = TextEditingController();
  late String captchaCode;
  bool _obscurePassword = true; // Para mostrar/ocultar contraseña
  final Color buttonColor = Color(0xFF212F38); // Nuevo color de botón

  @override
  void initState() {
    super.initState();
    captchaCode = _generateCaptchaCode();
  }

  // Funciones comunes
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Funciones para la página de login
  Future<void> _login() async {
    if (!isCaptchaVerified) {
      _showErrorSnackBar('Debes verificar el CAPTCHA antes de iniciar sesión.');
      return;
    }

    _showLoadingDialog();
    final url = Uri.parse('https://stayhere-web.onrender.com/api/token/');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': emailController.text,
        'password': passwordController.text,
      }),
    );
    _hideLoadingDialog();

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      jwtToken = data['access'];

      // Guardar el correo electrónico ingresado
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwtToken', jwtToken!);
      await prefs.setString('userEmail', emailController.text);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(username: emailController.text),
        ),
      );
    } else {
      _showErrorSnackBar('Datos incorrectos o error en el servidor');
    }
  }

  // Funciones para la página de registro
  Future<void> _register() async {
    final url = Uri.parse('https://stayhere-web.onrender.com/api/usuarios/');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': emailController.text,
        'password': passwordController.text,
        'nombre': nameController.text,
        'telefono': phoneController.text,
        'fecha_nacimiento': selectedDate != null
            ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
            : null,
      }),
    );

    if (response.statusCode == 201) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(username: nameController.text),
        ),
      );
    } else {
      final data = jsonDecode(response.body);
      _showErrorSnackBar(data['error'] ?? 'Error en el registro. Inténtalo de nuevo.');
    }
  }

  // Función para mostrar el modal de CAPTCHA
  void _showCaptchaModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _buildCaptchaModal(),
      ),
    );
  }

  Widget _buildCaptchaModal() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Por favor, ingresa el código CAPTCHA',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          _buildCaptchaDisplay(),
          const SizedBox(height: 20),
          TextField(
            controller: captchaController,
            decoration: const InputDecoration(
              labelText: 'Ingrese el código CAPTCHA',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _verifyCaptcha,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: buttonColor, // Texto blanco
            ),
            child: const Text('Verificar CAPTCHA'),
          ),
        ],
      ),
    );
  }

  // CAPTCHA
  String _generateCaptchaCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789*.:@#';
    return List.generate(4, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  Widget _buildCaptchaDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: captchaCode.split('').map((char) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            char,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _verifyCaptcha() {
    if (captchaController.text == captchaCode) {
      setState(() {
        isCaptchaVerified = true;
      });
      Navigator.pop(context);
    } else {
      _showErrorSnackBar('Código incorrecto. Intenta de nuevo.');
    }
  }

  // Diálogo de carga
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _hideLoadingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autenticación'),
      ),
      body: PageView(
        controller: _pageController,
        children: [
          _buildLoginPage(),
          _buildRegisterPage(),
        ],
      ),
    );
  }

  Widget _buildLoginPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Iniciar Sesión',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Correo Electrónico'),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _showCaptchaModal,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: buttonColor, // Texto blanco
            ),
            child: const Text('Verificar CAPTCHA'),
          ),
          const SizedBox(height: 10),
          if (isCaptchaVerified)
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: buttonColor, // Texto blanco
              ),
              child: const Text('Iniciar Sesión'),
            ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => _pageController.jumpToPage(1),
            child: const Text('¿Aún no estás registrado? Regístrate aquí'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Registro',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Nombre y Apellidos'),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Correo Electrónico'),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: phoneController,
            decoration: const InputDecoration(labelText: 'Número de Teléfono'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _showCaptchaModal,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: buttonColor, // Texto blanco
            ),
            child: const Text('Verificar CAPTCHA'),
          ),
          const SizedBox(height: 10),
          if (isCaptchaVerified)
            ElevatedButton(
              onPressed: _register,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: buttonColor, // Texto blanco
              ),
              child: const Text('Registrar'),
            ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => _pageController.jumpToPage(0),
            child: const Text('¿Ya tienes una cuenta? Inicia Sesión'),
          ),
        ],
      ),
    );
  }
}
