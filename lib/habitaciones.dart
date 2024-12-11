import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// Modelo de usuario
class Usuario {
  final String email;
  final String nombre;
  final String telefono;
  final String fechaNacimiento;
  final String tipoUsuario;
  final String fotoperfil;
  final int edad;

  Usuario({
    required this.email,
    required this.nombre,
    required this.telefono,
    required this.fechaNacimiento,
    required this.tipoUsuario,
    required this.fotoperfil,
    required this.edad,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      email: json['email'] ?? '',
      nombre: json['nombre'] ?? '',
      telefono: json['telefono'] ?? '',
      fechaNacimiento: json['fecha_nacimiento'] ?? '',
      tipoUsuario: json['tipo_usuario'] ?? '',
      fotoperfil: json['foto_perfil'] ?? '',
      edad: json['edad'] ?? 0,
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;

  const _FeatureChip(this.label, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      onSelected: null, // No funcional
      selected: false,
    );
  }
}

Future<void> actualizarPerfil(BuildContext context, String email, String nombre, String? fotoPerfilPath) async {
  final url = Uri.parse('https://stayhere-web.onrender.com/api/usuarios/actualizar/');

  final request = http.MultipartRequest('PUT', url)
    ..fields['email'] = email // Agrega el email del usuario a los datos enviados
    ..fields['nombre'] = nombre;

  // Si se seleccionó una nueva imagen de perfil, añádela al request
  if (fotoPerfilPath != null) {
    request.files.add(await http.MultipartFile.fromPath('foto_perfil', fotoPerfilPath));
  }

  final response = await request.send();

  if (response.statusCode == 200) {
    final responseBody = await http.Response.fromStream(response);
    final responseData = json.decode(responseBody.body);

    if (responseData['success']) {
      print('Perfil actualizado correctamente.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );
    } else {
      print('Error al actualizar perfil: ${responseData['message']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${responseData['message']}')),
      );
    }
  } else {
    print('Error al conectar con la API: ${response.statusCode}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error al conectar con el servidor')),
    );
  }
}


void _mostrarModalEditarPerfil(BuildContext parentContext, Usuario usuario) {
  final TextEditingController _nombreController = TextEditingController(text: usuario.nombre);
  String? _fotoPerfilPath;

  showDialog(
    context: parentContext, // Usa el contexto del widget padre
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Editar Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                // Permitir al usuario seleccionar una imagen
                final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  _fotoPerfilPath = pickedFile.path;
                }
              },
              child: const Text('Seleccionar Foto de Perfil'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (_nombreController.text.trim().isEmpty) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(content: Text('El nombre no puede estar vacío')),
                );
                return;
              }

              // Llamar a la función para actualizar el perfil
              await actualizarPerfil(parentContext, usuario.email, _nombreController.text, _fotoPerfilPath);
              Navigator.pop(dialogContext); // Cierra el modal
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );
}



class Alojamiento {
  final String usuarioNombre;
  final String usuarioTelefono; // Nueva propiedad
  final String descripcion;
  final double precio;
  final double latitud;
  final double longitud;
  final List<String> caracteristicas;
  final String? primeraImagen;

  Alojamiento({
    required this.usuarioNombre,
    required this.usuarioTelefono, // Inicializar aquí
    required this.descripcion,
    required this.precio,
    required this.latitud,
    required this.longitud,
    required this.caracteristicas,
    this.primeraImagen,
  });

  factory Alojamiento.fromJson(Map<String, dynamic> json) {
    const String baseUrl = 'https://stayhere-web.onrender.com'; // Base URL para las imágenes

    return Alojamiento(
      usuarioNombre: json['usuario']['nombre'], // Obtenemos el nombre del usuario
      usuarioTelefono: json['usuario']['telefono'], // Asignar el teléfono del usuario
      descripcion: json['descripcion'],
      precio: json['precio'] is double ? json['precio'] : double.parse(json['precio']),
      latitud: json['latitud'],
      longitud: json['longitud'],
      caracteristicas: List<String>.from(json['caracteristicas']),
      primeraImagen: json['primera_imagen'] != null
          ? baseUrl + json['primera_imagen']
          : null,
    );
  }
}


// Función para reemplazar caracteres especiales
String reemplazarCaracteresEspeciales(String texto) {
  return texto
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('Á', 'A')
      .replaceAll('É', 'E')
      .replaceAll('Í', 'I')
      .replaceAll('Ó', 'O')
      .replaceAll('Ú', 'U')
      .replaceAll('ñ', 'n')
      .replaceAll('Ñ', 'N');
}

class HabitacionesPage extends StatefulWidget {
  const HabitacionesPage({Key? key}) : super(key: key);

  @override
  _HabitacionesPageState createState() => _HabitacionesPageState();
}

class _HabitacionesPageState extends State<HabitacionesPage> {
  int _selectedIndex = 1; // Para que la vista de alojamientos sea la primera en aparecer

  // Función para obtener el correo electrónico desde SharedPreferences
  Future<String?> _getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  // Función para obtener los datos del usuario desde la API
  Future<Usuario?> _getUsuario(String email) async {
    final url = Uri.parse('https://stayhere-web.onrender.com/api/usuarios/email/$email/'); // URL de la API

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return Usuario.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al obtener los datos del usuario');
    }
  }

  
  // Función para obtener los alojamientos desde la API
  Future<List<Alojamiento>> _getAlojamientos() async {
    final response = await http.get(Uri.parse('https://stayhere-web.onrender.com/api/alojamientos/'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      return jsonResponse.map((data) => Alojamiento.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load alojamientos');
    }
  }

  // Función para obtener los alojamientos en base al nombre de usuario
  Future<List<Alojamiento>> _getAlojamientosPorNombre(String nombre) async {
    final response = await http.get(Uri.parse('https://stayhere-web.onrender.com/api/alojamientos/'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(utf8.decode(response.bodyBytes));

      // Filtramos los alojamientos que coincidan con el nombre del usuario
      List<Alojamiento> alojamientos = jsonResponse
          .map((data) => Alojamiento.fromJson(data))
          .where((alojamiento) => alojamiento.usuarioNombre == nombre) // Filtramos por el nombre del usuario
          .toList();

      return alojamientos;
    } else {
      throw Exception('Failed to load alojamientos');
    }
  }

  // Cambiar la vista seleccionada
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  
  // Vista de datos del usuario
  Widget _userInfoView() {
    return FutureBuilder<String?>(
      future: _getEmail(), // Aquí obtienes el email del usuario logueado
      builder: (context, emailSnapshot) {
        if (emailSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (emailSnapshot.hasData) {
          final email = emailSnapshot.data;

          if (email == null) {
            return Center(child: const Text('Email no encontrado.'));
          }

          return FutureBuilder<Usuario?>(
            future: _getUsuario(email), // Obtenemos los datos del usuario logueado
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (userSnapshot.hasError) {
                return Center(child: Text('Error: ${userSnapshot.error}'));
              }

              if (userSnapshot.hasData) {
                final usuario = userSnapshot.data;

                if (usuario == null) {
                  return const Center(child: Text('No se encontraron datos del usuario.'));
                }

                // Siempre mostramos los datos del usuario
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Text(
                          'Bienvenido, ${reemplazarCaracteresEspeciales(usuario.nombre)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212F38),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: usuario.fotoperfil.isNotEmpty
                            ? NetworkImage(usuario.fotoperfil)
                            : null,
                        child: usuario.fotoperfil.isEmpty
                            ? const Icon(Icons.camera_alt, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Tipo de usuario: ${usuario.tipoUsuario}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF212F38),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _mostrarModalEditarPerfil(context, usuario); // Pasa el contexto correcto y el usuario
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF212F38),
                            ),
                            child: const Text('Editar perfil'),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: () {
                              // Acción de cerrar sesión
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF37272),
                            ),
                            child: const Text(
                              'Cerrar sesión',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        color: Colors.grey,
                        thickness: 1,
                        indent: 30,
                        endIndent: 30,
                      ),
                      const SizedBox(height: 20),

                      // Cargar alojamientos adicionalmente
                      FutureBuilder<List<Alojamiento>>(
                        future: _getAlojamientosPorNombre(usuario.nombre),
                        builder: (context, alojamientosSnapshot) {
                          if (alojamientosSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (alojamientosSnapshot.hasError) {
                            return Center(child: Text('Error al cargar alojamientos: ${alojamientosSnapshot.error}'));
                          }

                          if (alojamientosSnapshot.hasData && alojamientosSnapshot.data!.isNotEmpty) {
                            return Column(
                              children: alojamientosSnapshot.data!.map((alojamiento) {
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: alojamiento.primeraImagen != null
                                              ? Image.network(
                                                  alojamiento.primeraImagen!,
                                                  width: 150,
                                                  height: 150,
                                                  fit: BoxFit.cover,
                                                )
                                              : const Icon(Icons.image, size: 100),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                alojamiento.descripcion,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF212F38),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 4,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Precio: \$${alojamiento.precio}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF212F38),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          } else {
                            return const Center(child: Text('No tienes alojamientos.'));
                          }
                        },
                      ),
                    ],
                  ),
                );
              } else {
                return const Center(child: Text('No se encontraron datos del usuario.'));
              }
            },
          );
        } else {
          return Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
              },
              child: const Text('Iniciar sesión'),
            ),
          );
        }
      },
    );
  }

  Widget _nuevoView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ubica tu alojamiento",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              "https://www.netlima.com/avisos/fotos/62.png",
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Descripción",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Describe tu alojamiento",
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          const Text(
            "Agrega las imágenes de tu alojamiento",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                "Subir imágenes",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Establece tu precio",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: "S/.",
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          const Text(
            "Distrito",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            items: const [
              DropdownMenuItem(value: "Ancón", child: Text("Ancón")),
              DropdownMenuItem(value: "Carabayllo", child: Text("Carabayllo")),
              DropdownMenuItem(value: "Comas", child: Text("Comas")),
              DropdownMenuItem(value: "Independencia", child: Text("Independencia")),
              DropdownMenuItem(value: "Los Olivos", child: Text("Los Olivos")),
              DropdownMenuItem(value: "Puente Piedra", child: Text("Puente Piedra")),
              DropdownMenuItem(value: "San Martín de Porres", child: Text("San Martín de Porres")),
              DropdownMenuItem(value: "Santa Rosa", child: Text("Santa Rosa")),
              DropdownMenuItem(value: "Santa Anita", child: Text("Santa Anita")),
            ],
            onChanged: (_) {},
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Seleccione un distrito",
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Selecciona las características del alojamiento",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _FeatureChip("Habitación Personal"),
              _FeatureChip("Habitación Doble"),
              _FeatureChip("Petfriendly"),
              _FeatureChip("Baño Propio"),
              _FeatureChip("Wi-Fi"),
              _FeatureChip("Estacionamiento"),
              _FeatureChip("Espacio de Cocina"),
              _FeatureChip("Agua caliente"),
              _FeatureChip("Amueblado"),
              _FeatureChip("Zonas Comunes"),
              _FeatureChip("Tendedero"),
              _FeatureChip("Restaurante"),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: null, // Botón no funcional
              child: const Text("Publicar"),
            ),
          ),
        ],
      ),
    );
  }


  // Vista de los alojamientos
  Widget _alojamientosView() {
    return FutureBuilder<List<Alojamiento>>(
      future: _getAlojamientos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.hasData) {
          final alojamientos = snapshot.data!;
          return ListView.builder(
            itemCount: alojamientos.length,
            itemBuilder: (context, index) {
              final alojamiento = alojamientos[index];
              return Card(
                elevation: 5,
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      alojamiento.primeraImagen != null
                          ? Image.network(alojamiento.primeraImagen!)
                          : const Placeholder(fallbackHeight: 200),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Publicado por: ${reemplazarCaracteresEspeciales(alojamiento.usuarioNombre)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        'Descripción: ${reemplazarCaracteresEspeciales(alojamiento.descripcion.length > 100 ? alojamiento.descripcion.substring(0, 100) + "..." : alojamiento.descripcion)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Características:',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: alojamiento.caracteristicas.map<Widget>((caracteristica) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF212F38),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              reemplazarCaracteresEspeciales(caracteristica),
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Precio: S/. ${alojamiento.precio.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final whatsappUrl =
                                  'https://wa.me/${alojamiento.usuarioTelefono}?text=Hola%20estoy%20interesado%20en%20tu%20alojamiento.';
                              launchUrl(Uri.parse(whatsappUrl));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Contactar'),
                            
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          return const Center(child: Text('No hay alojamientos disponibles.'));
        }
      },
    );
  }


  // Vista general
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Usuario?>(
      future: _getEmail().then((email) => email != null ? _getUsuario(email) : null),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: const Center(
              child: Text('Error al cargar usuario o usuario no disponible.'),
            ),
          );
        }

        final usuario = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF212F38),
            automaticallyImplyLeading: false,
          ),
          body: _selectedIndex == 0
              ? _userInfoView()
              : _selectedIndex == 1
                  ? _alojamientosView()
                  : _nuevoView(), // Muestra el formulario en la pestaña "Nuevo"
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.account_circle),
                label: 'Perfil',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Alojamientos',
              ),
              if (usuario.tipoUsuario == "arrendador")
                const BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle),
                  label: 'Nuevo',
                ),
            ],
          ),
        );
      },
    );
  }
}