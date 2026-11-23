
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mi Pokedex',
      home: const Inicio(),
    );
  }
}

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  final TextEditingController controlador = TextEditingController();

  Map<String, dynamic>? pokemon;
  String mensaje = 'Escribe el nombre de un Pokemon';
  bool cargando = false;

  Future<void> buscarPokemon() async {
    String nombre = controlador.text.trim().toLowerCase();

    if (nombre.isEmpty) {
      setState(() {
        pokemon = null;
        mensaje = 'Escribe un nombre para buscar';
      });
      return;
    }

    setState(() {
      cargando = true;
      pokemon = null;
      mensaje = '';
    });

    try {
      final url = Uri.parse(
        'https://pokeapi.co/api/v2/pokemon/${Uri.encodeComponent(nombre)}',
      );

      final respuesta = await http.get(url);

      if (!mounted) return;

      if (respuesta.statusCode == 200) {
        setState(() {
          pokemon = jsonDecode(respuesta.body);
        });
      } else {
        setState(() {
          mensaje = 'Pokemon no encontrado';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        mensaje = 'Error al conectar con Internet';
      });
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Pokedex'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Busca tu Pokemon favorito',
              style: TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: controlador,
              decoration: const InputDecoration(
                labelText: 'Nombre del Pokemon',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: cargando ? null : buscarPokemon,
              child: const Text('Buscar Pokemon'),
            ),

            const SizedBox(height: 25),

            if (cargando)
              const CircularProgressIndicator(),

            if (!cargando && pokemon == null)
              Text(mensaje),

            if (pokemon != null) ...[
              if (pokemon!['sprites']['front_default'] != null)
                Image.network(
                  pokemon!['sprites']['front_default'],
                  height: 160,
                ),

              Text(
                pokemon!['name'].toString().toUpperCase(),
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              Text('Numero: ${pokemon!['id']}'),
              Text('Altura: ${pokemon!['height'] / 10} metros'),
              Text('Peso: ${pokemon!['weight'] / 10} kg'),
              Text(
                'Tipo: ${(pokemon!['types'] as List).map((t) => t['type']['name']).join(', ')}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
