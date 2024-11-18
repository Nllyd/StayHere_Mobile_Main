import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Alojamiento {
  final String usuarioNombre;
  final String descripcion;
  final double precio;
  final double latitud;
  final double longitud;
  final List<String> caracteristicas;
  final String? primeraImagen;

  Alojamiento({
    required this.usuarioNombre,
    required this.descripcion,
    required this.precio,
    required this.latitud,
    required this.longitud,
    required this.caracteristicas,
    this.primeraImagen,
  });

  factory Alojamiento.fromJson(Map<String, dynamic> json) {
    const String baseUrl = 'https://stayhere-web.onrender.com'; // Asegúrate de tener el dominio base

    return Alojamiento(
      usuarioNombre: json['usuario']['nombre'],
      descripcion: json['descripcion'],
      precio: json['precio'] is double ? json['precio'] : double.parse(json['precio']),
      latitud: json['latitud'],
      longitud: json['longitud'],
      caracteristicas: List<String>.from(json['caracteristicas']),
      primeraImagen: json['primera_imagen'] != null
          ? baseUrl + json['primera_imagen']
          : null, // Combina el dominio base con la ruta de la imagen
    );
  }
}

class Usuario {
  final String email;
  final String nombre;
  final String telefono;
  final String fechaNacimiento;
  final int edad;

  Usuario({
    required this.email,
    required this.nombre,
    required this.telefono,
    required this.fechaNacimiento,
    required this.edad,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      email: json['email'],
      nombre: json['nombre'],
      telefono: json['telefono'],
      fechaNacimiento: json['fecha_nacimiento'],
      edad: json['edad'],
    );
  }
}

Future<Usuario> fetchUsuario() async {
  // Obtener el ID del usuario desde SharedPreferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('userId');  // Obtienes el userId almacenado

  if (userId == null) {
    throw Exception('No hay usuario logueado'); // Puedes manejarlo de otra manera si prefieres.
  }

  final response = await http.get(
    Uri.parse('https://stayhere-web.onrender.com/api/usuarios/$userId/'),
  );

  if (response.statusCode == 200) {
    return Usuario.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to load user data');
  }
}

Future<List<Alojamiento>> fetchAlojamientos() async {
  final response = await http.get(Uri.parse('https://stayhere-web.onrender.com/api/alojamientos/'));

  if (response.statusCode == 200) {
    List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
    return jsonResponse.map((data) => Alojamiento.fromJson(data)).toList();
  } else {
    throw Exception('Failed to load alojamientos');
  }
}

class HomePage extends StatefulWidget {
  final String? username;

  const HomePage({Key? key, this.username}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Alojamiento>> futureAlojamientos;
  List<Alojamiento> alojamientos = []; // Lista completa de alojamientos
  List<Alojamiento> filteredAlojamientos = []; // Lista filtrada
  final TextEditingController searchController = TextEditingController();
  bool isMapView = false; // Variable para controlar si estamos en el mapa o en la lista de alojamientos
  bool isProfileView = false; // Variable para controlar si estamos viendo el perfil del usuario
  bool isChatView = false; // Variable para controlar si estamos en la vista de chat

  @override
  void initState() {
    super.initState();
    futureAlojamientos = fetchAlojamientos();
    futureAlojamientos.then((data) {
      setState(() {
        alojamientos = data;
        filteredAlojamientos = data; // Inicialmente, mostrar todos
      });
    });

    // Agregar listener al campo de búsqueda para actualizar la lista filtrada
    searchController.addListener(() {
      filterAlojamientos();
    });
  }

  void filterAlojamientos() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredAlojamientos = alojamientos.where((alojamiento) {
        return alojamiento.descripcion.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose(); // Liberar el controlador al eliminar el widget
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isProfileView || isChatView
          ? null // No mostrar AppBar en las vistas de Perfil y Chat
          : AppBar(
              backgroundColor: const Color(0xFF212F38),
              title: Image.asset(
                'assets/images/StayPandaHere.png',
                height: 30,
                fit: BoxFit.contain,
              ),
              centerTitle: true,
              automaticallyImplyLeading: false,
            ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!isProfileView && !isChatView) // Mostrar solo barra de búsqueda en vista de alojamientos
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController, // Controlador para la barra de búsqueda
                      decoration: InputDecoration(
                        hintText: 'Buscar...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16.0),
            Expanded(
              child: isProfileView
                  ? buildProfileView()
                  : isChatView
                      ? buildChatView()
                      : isMapView
                          ? Container(
                              color: Colors.grey, // Rectángulo gris en lugar del mapa
                            )
                          : FutureBuilder<List<Alojamiento>>(
                              future: futureAlojamientos,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(child: Text('Error: ${snapshot.error}'));
                                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const Center(child: Text('No hay alojamientos disponibles'));
                                } else {
                                  return ListView(
                                    children: filteredAlojamientos
                                        .map((alojamiento) => buildAlojamientoCard(alojamiento))
                                        .toList(),
                                  );
                                }
                              },
                            ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF212F38),
        child: SizedBox(
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.home, color: Colors.white, size: 30),
                  onPressed: () {
                    setState(() {
                      isMapView = false;
                      isProfileView = false;
                      isChatView = false; // Regresar a la vista de inicio
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chat, color: Colors.white, size: 30), // Icono de chat
                  onPressed: () {
                    setState(() {
                      isChatView = true;
                      isProfileView = false;
                      isMapView = false; // Cambiar a la vista de chat
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person, color: Colors.white, size: 30), // Icono de usuario
                  onPressed: () {
                    setState(() {
                      isProfileView = true; // Cambiar a la vista del perfil
                      isMapView = false; // Asegurarse de que el mapa no esté activo
                      isChatView = false; // Asegurarse de que la vista de chat no esté activa
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildProfileView() {
    return FutureBuilder<Usuario>(
      future: fetchUsuario(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('No se pudo cargar el perfil'));
        } else {
          final usuario = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perfil de Usuario',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Nombre de usuario: ${usuario.nombre}'),
                const SizedBox(height: 8),
                Text('Correo: ${usuario.email}'),
                Text('Teléfono: ${usuario.telefono}'),
                Text('Fecha de nacimiento: ${usuario.fechaNacimiento}'),
                Text('Edad: ${usuario.edad}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // Acción para editar el perfil, si es necesario
                  },
                  child: const Text('Editar perfil'),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget buildChatView() {
    return Center(
      child: Text("Vista de Chat"),
    );
  }

  Widget buildAlojamientoCard(Alojamiento alojamiento) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => buildAlojamientoModal(alojamiento),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(16.0),
                  image: alojamiento.primeraImagen != null
                      ? DecorationImage(
                          image: NetworkImage(alojamiento.primeraImagen!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                alojamiento.usuarioNombre,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                alojamiento.descripcion.length > 50
                    ? '${alojamiento.descripcion.substring(0, 50)}...'
                    : alojamiento.descripcion,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: alojamiento.caracteristicas.take(3).map((caracteristica) => Chip(
                      label: Text(
                        caracteristica,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Colors.grey[800]!,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        side: BorderSide(color: Colors.grey[800]!),
                      ),
                    )).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Precio:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF789668),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      '\$${alojamiento.precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAlojamientoModal(Alojamiento alojamiento) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            alojamiento.usuarioNombre,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            alojamiento.descripcion,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (alojamiento.primeraImagen != null)
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: 1,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Image.network(
                      alojamiento.primeraImagen!,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: alojamiento.caracteristicas.map((caracteristica) => Chip(
                  label: Text(
                    caracteristica,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.grey[800]!,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    side: BorderSide(color: Colors.grey[800]!),
                  ),
                )).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // Acción para el botón "Ver perfil"
                },
                child: const Text('Ver perfil'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF25D366),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // Acción para el botón "Contactar"
                },
                child: const Text('Contactar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
