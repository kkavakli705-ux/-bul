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

class IsIlani {
  final String baslik;
  final String firma;
  final String sehir;
  final String aciklama;

  IsIlani({
    required this.baslik,
    required this.firma,
    required this.sehir,
    required this.aciklama,
  });
}

class IlanDeposu {
  static final List<IsIlani> ilanlar = [
    IsIlani(
      baslik: 'İnşaat Ustası',
      firma: 'Örnek İnşaat',
      sehir: 'Balıkesir',
      aciklama: 'Deneyimli inşaat ustası aranmaktadır.',
    ),
    IsIlani(
      baslik: 'Şoför',
      firma: 'Örnek Lojistik',
      sehir: 'Bursa',
      aciklama: 'B sınıfı ehliyetli şoför aranmaktadır.',
    ),
  ];
}

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  final TextEditingController meslekController =
      TextEditingController();

  final TextEditingController sehirController =
      TextEditingController();

  @override
  void dispose() {
    meslekController.dispose();
    sehirController.dispose();
    super.dispose();
  }

  void isAra() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IsAraSayfasi(
          meslek: meslekController.text,
          sehir: sehirController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'İŞ BUL',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 25),
            const Icon(
              Icons.work,
              size: 90,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              'İş Bul\'
