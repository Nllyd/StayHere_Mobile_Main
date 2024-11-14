import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Modelo de datos para Alojamiento
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
      appBar: AppBar(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                    ),
                    onPressed: () {
                      // Acción para el botón de Filtros
                    },
                    child: const Text('Filtros'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                    ),
                    onPressed: () {
                      // Acción para el botón de Inicio
                    },
                    child: const Text('Inicio'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                    ),
                    onPressed: () {
                      // Acción para el botón de Mapa
                    },
                    child: const Text('Mapa'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            TextField(
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
            const SizedBox(height: 16.0),
            Expanded(
              child: FutureBuilder<List<Alojamiento>>(
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
              children: const [
                Icon(Icons.home, color: Colors.white, size: 30),
                Icon(Icons.person, color: Colors.white, size: 30),
                Icon(Icons.chat, color: Colors.white, size: 30),
              ],
            ),
          ),
        ),
      ),
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
                      backgroundColor: Colors.grey[800]!, // Negro menos intenso
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
