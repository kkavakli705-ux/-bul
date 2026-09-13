import 'package:flutter/material.dart';

void main() {
  runApp(const IsBulApp());
}

class IsBulApp extends StatelessWidget {
  const IsBulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'İş Bul',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const AnaSayfa(),
    );
  }
}

class AnaSayfa extends StatelessWidget {
  const AnaSayfa({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İŞ BUL'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.work,
                size: 90,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              const Text(
                'İş Bul\'a Hoş Geldiniz',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {},
                child: const Text('İŞ ARA'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {},
                child: const Text('İŞ İLANI VER'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {},
                child: const Text('GİRİŞ YAP / KAYIT OL'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
