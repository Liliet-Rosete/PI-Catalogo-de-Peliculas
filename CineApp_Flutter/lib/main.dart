import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// La URL 127.0.0.1 funciona en el simulador de iPhone cuando Laravel
// se ejecuta en esta misma Mac con: php artisan serve --port=8000.
class Api {
  static const String base = 'http://127.0.0.1:8000/api';

  static Map<String, String> headers([String? token]) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static dynamic parse(http.Response response) {
    dynamic content;
    try {
      content = jsonDecode(response.body);
    } catch (_) {
      throw Exception('El servidor no devolvió una respuesta válida.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Error del servidor (${response.statusCode}).';
      if (content is Map) {
        if (content['message'] is String) message = content['message'];
        final errors = content['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) message = '${first.first}';
        }
      }
      throw Exception(message);
    }
    return content;
  }

  static Future<Map<String, dynamic>> authenticate({
    required bool register,
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$base/${register ? 'register' : 'login'}'),
          headers: headers(),
          body: jsonEncode({
            if (register) 'name': name.trim(),
            'email': email.trim(),
            'password': password,
            if (register) 'password_confirmation': password,
          }),
        )
        .timeout(const Duration(seconds: 12));
    final data = parse(response);
    if (data is! Map || data['token'] == null) {
      throw Exception('No se recibió el acceso del servidor.');
    }
    return Map<String, dynamic>.from(data);
  }

  static Future<List<Movie>> getMovies(String token) async {
    final response = await http
        .get(Uri.parse('$base/movies'), headers: headers(token))
        .timeout(const Duration(seconds: 12));
    final data = parse(response);
    if (data is! List) throw Exception('El catálogo tiene un formato incorrecto.');
    return data.map((item) => Movie.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  static Future<void> addMovie(String token, Map<String, dynamic> movie) async {
    final response = await http
        .post(Uri.parse('$base/movies'), headers: headers(token), body: jsonEncode(movie))
        .timeout(const Duration(seconds: 12));
    parse(response);
  }

  static Future<void> deleteMovie(String token, int id) async {
    final response = await http
        .delete(Uri.parse('$base/movies/$id'), headers: headers(token))
        .timeout(const Duration(seconds: 12));
    parse(response);
  }

  static Future<void> logout(String token) async {
    try {
      await http.post(Uri.parse('$base/logout'), headers: headers(token)).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Se cierra la sesión visible incluso si el servidor no responde.
    }
  }
}

class Movie {
  final int id;
  final String title;
  final String year;
  final String director;
  final String genre;
  final String synopsis;
  final String cover;

  const Movie({required this.id, required this.title, required this.year,
    required this.director, required this.genre, required this.synopsis, required this.cover});

  factory Movie.fromJson(Map<String, dynamic> j) => Movie(
    id: int.tryParse('${j['id']}') ?? 0,
    title: '${j['title'] ?? ''}',
    year: '${j['year'] ?? ''}',
    director: '${j['director'] ?? ''}',
    genre: '${j['genre'] ?? ''}',
    synopsis: '${j['synopsis'] ?? ''}',
    cover: '${j['cover'] ?? ''}',
  );
}

void main() => runApp(const CineApp());

class CineApp extends StatelessWidget {
  const CineApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'CineApp',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5A3CC8)),
      scaffoldBackgroundColor: const Color(0xFFF6F5FA),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    ),
    home: const WelcomePage(),
  );
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.local_movies_rounded, size: 95, color: Color(0xFF5A3CC8)),
              const SizedBox(height: 22),
              Text('Bienvenido a CineApp', style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text('Descubre películas, consulta sus detalles y administra tu catálogo.',
                textAlign: TextAlign.center),
              const SizedBox(height: 34),
              SizedBox(width: double.infinity, child: FilledButton(
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AuthPage(register: true))),
                child: const Text('Registrarme'),
              )),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: OutlinedButton(
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AuthPage(register: false))),
                child: const Text('Ya tengo una cuenta'),
              )),
            ]),
          ),
        ),
      ),
    ),
  );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.register});
  final bool register;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  bool hidden = true;

  @override
  void dispose() {
    name.dispose(); email.dispose(); password.dispose(); super.dispose();
  }

  Future<void> submit() async {
    if (!(form.currentState?.validate() ?? false)) return;
    setState(() => busy = true);
    try {
      final result = await Api.authenticate(register: widget.register,
        name: name.text, email: email.text, password: password.text);
      if (!mounted) return;
      final user = result['user'];
      final username = user is Map ? '${user['name'] ?? email.text}' : email.text;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => CatalogPage(token: '${result['token']}', username: username)),
        (_) => false,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${e.toString().replaceFirst('Exception: ', '')}\nComprueba que Laravel está encendido.')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.register ? 'Crear cuenta' : 'Iniciar sesión')),
    body: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Form(
        key: form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.movie_filter, size: 65, color: Color(0xFF5A3CC8)),
          const SizedBox(height: 25),
          if (widget.register) ...[
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Escribe tu nombre' : null),
            const SizedBox(height: 15),
          ],
          TextFormField(controller: email, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Correo electrónico'),
            validator: (v) => v == null || !v.contains('@') ? 'Escribe un correo válido' : null),
          const SizedBox(height: 15),
          TextFormField(controller: password, obscureText: hidden,
            decoration: InputDecoration(labelText: 'Contraseña', suffixIcon: IconButton(
              icon: Icon(hidden ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => hidden = !hidden))),
            validator: (v) => v == null || v.length < 8 ? 'Mínimo 8 caracteres' : null),
          const SizedBox(height: 25),
          FilledButton(onPressed: busy ? null : submit,
            child: Text(busy ? 'Conectando...' : widget.register ? 'Crear mi cuenta' : 'Ingresar')),
        ]),
      )),
    )),
  );
}

class Poster extends StatelessWidget {
  const Poster(this.url, {super.key, this.height = 160, this.width = 110});
  final String url;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: SizedBox(width: width, height: height,
      child: url.trim().isEmpty
        ? const ColoredBox(color: Color(0xFFE1DEF0), child: Icon(Icons.movie, size: 40))
        : Image.network(url, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: Color(0xFFE1DEF0), child: Icon(Icons.broken_image, size: 35))),
    ),
  );
}

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key, required this.token, required this.username});
  final String token;
  final String username;
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  bool loading = true;
  String? error;
  int view = 0;
  List<Movie> movies = [];

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final result = await Api.getMovies(widget.token);
      if (mounted) setState(() => movies = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> remove(Movie movie) async {
    final confirmation = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Eliminar película'),
      content: Text('¿Eliminar "${movie.title}" del catálogo?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
      ],
    ));
    if (confirmation != true) return;
    try {
      await Api.deleteMovie(widget.token, movie.id);
      await load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Película eliminada correctamente.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: $e')));
    }
  }

  Future<void> add() async {
    final saved = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) => AddMoviePage(token: widget.token)));
    if (saved == true) load();
  }

  Future<void> signOut() async {
    await Api.logout(widget.token);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomePage()), (_) => false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('CineApp'),
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Menú',
          onSelected: (value) {
            if (value == 'logout') { signOut(); return; }
            setState(() => view = value == 'admin' ? 1 : 0);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'catalog', child: Text('Catálogo de películas')),
            PopupMenuItem(value: 'admin', child: Text('Administración')),
            PopupMenuItem(value: 'logout', child: Text('Cerrar sesión')),
          ],
          icon: const Icon(Icons.menu),
        ),
      ],
    ),
    body: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        child: Row(children: [
          Expanded(child: Text('Hola, ${widget.username}', style: const TextStyle(fontWeight: FontWeight.w500))),
          Text(view == 0 ? 'Catálogo' : 'Administración',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        ])),
      Expanded(child: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('No se pudo cargar el catálogo:\n$error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: load, child: const Text('Reintentar')),
            ])))
          : RefreshIndicator(onRefresh: load, child: movies.isEmpty
              ? ListView(children: const [SizedBox(height: 120),
                  Center(child: Text('Todavía no hay películas registradas.'))])
              : ListView.builder(padding: const EdgeInsets.all(12),
                  itemCount: movies.length,
                  itemBuilder: (context, i) {
                    final movie = movies[i];
                    return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(children: [
                        Poster(movie.cover),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(movie.title, style: Theme.of(context).textTheme.titleMedium),
                          Text(movie.year),
                          if (movie.genre.isNotEmpty) Text(movie.genre),
                          const SizedBox(height: 8),
                          TextButton(onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => MovieDetails(movie: movie))),
                            child: const Text('Ver detalles')),
                        ])),
                        if (view == 1) IconButton(icon: const Icon(Icons.delete_outline),
                          tooltip: 'Eliminar', onPressed: () => remove(movie)),
                      ]),
                    ));
                  }))),
    ]),
    floatingActionButton: view == 1 ? FloatingActionButton.extended(
      onPressed: add, icon: const Icon(Icons.add), label: const Text('Agregar película')) : null,
  );
}

class MovieDetails extends StatelessWidget {
  const MovieDetails({super.key, required this.movie});
  final Movie movie;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Descripción de la película')),
    body: ListView(padding: const EdgeInsets.all(22), children: [
      Center(child: Poster(movie.cover, width: 220, height: 310)),
      const SizedBox(height: 20),
      Text(movie.title, textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 18),
      Text('Año de estreno: ${movie.year}'),
      const SizedBox(height: 8),
      Text('Director: ${movie.director.isEmpty ? 'No registrado' : movie.director}'),
      const SizedBox(height: 8),
      Text('Género: ${movie.genre.isEmpty ? 'No registrado' : movie.genre}'),
      const SizedBox(height: 22),
      Text('Sinopsis', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Text(movie.synopsis),
    ]),
  );
}

class AddMoviePage extends StatefulWidget {
  const AddMoviePage({super.key, required this.token});
  final String token;
  @override
  State<AddMoviePage> createState() => _AddMoviePageState();
}

class _AddMoviePageState extends State<AddMoviePage> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final year = TextEditingController();
  final director = TextEditingController();
  final genre = TextEditingController();
  final synopsis = TextEditingController();
  final cover = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    for (final c in [title, year, director, genre, synopsis, cover]) { c.dispose(); }
    super.dispose();
  }

  Widget field(TextEditingController controller, String label, {int lines = 1,
    TextInputType? keyboard}) => Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller, maxLines: lines, keyboardType: keyboard,
        decoration: InputDecoration(labelText: label, alignLabelWithHint: lines > 1),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Completa $label';
          if (controller == year) {
            final n = int.tryParse(v);
            if (n == null || n < 1888 || n > 2100) return 'Escribe un año válido';
          }
          if (controller == cover) {
            final url = Uri.tryParse(v.trim());
            if (url == null || !['http', 'https'].contains(url.scheme) || url.host.isEmpty) {
              return 'Escribe una URL de imagen válida';
            }
          }
          return null;
        },
      ),
    );

  Future<void> save() async {
    if (!(form.currentState?.validate() ?? false)) return;
    setState(() => busy = true);
    try {
      await Api.addMovie(widget.token, {
        'title': title.text.trim(), 'year': int.parse(year.text.trim()),
        'director': director.text.trim(), 'genre': genre.text.trim(),
        'synopsis': synopsis.text.trim(), 'cover': cover.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Agregar película')),
    body: Form(key: form, child: ListView(padding: const EdgeInsets.all(20), children: [
      field(title, 'Título'),
      field(year, 'Año de estreno', keyboard: TextInputType.number),
      field(director, 'Director'),
      field(genre, 'Género cinematográfico'),
      field(synopsis, 'Sinopsis', lines: 4),
      field(cover, 'URL de la imagen', keyboard: TextInputType.url),
      const SizedBox(height: 8),
      FilledButton(onPressed: busy ? null : save,
        child: Text(busy ? 'Guardando...' : 'Guardar película')),
    ])),
  );
}
