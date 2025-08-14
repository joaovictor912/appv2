import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/tela_principal.dart';

late CameraDescription firstCamera;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  firstCamera = cameras.first;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color corPrincipal = Color(0xFF00295B); // Seu azul "Obsidian Navy"

    return MaterialApp(
      title: 'Corretor de Gabaritos',
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

       
        colorScheme: const ColorScheme.light(
          primary: corPrincipal,       // Cor de destaque principal (botões, ícones, etc.)
          onPrimary: Colors.white,     // Cor para texto/ícones EM CIMA da cor primária.
          background: Color(0xFFF5F5F5), // Fundo principal das telas (um branco suave)
          onBackground: Colors.black,    // Texto sobre o fundo principal.
          surface: Colors.white,       // Fundo de componentes como Cards.
          onSurface: Colors.black87,   // Texto sobre os componentes de superfície.
        ),
        // --- FIM DA MUDANÇA ---
        
        textTheme: GoogleFonts.montserratTextTheme(),

        appBarTheme: const AppBarTheme(
          backgroundColor: corPrincipal,
          foregroundColor: Colors.white,
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: corPrincipal,
          foregroundColor: Colors.white,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: corPrincipal,
            foregroundColor: Colors.white,
          ),
        ),
        
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        
        listTileTheme: const ListTileThemeData(
          iconColor: corPrincipal,
        ),
      ),
      
      home: TelaPrincipal(camera: firstCamera),
    );
  }
}