import 'package:flutter/material.dart';

void main() {
  runApp(const IsBulApp());
}

// =====================================================
// UYGULAMA
// =====================================================

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

// =====================================================
// İLAN MODELİ
// =====================================================

class IsIlani {
  String baslik;
  String firma;
  String sehir;
  String aciklama;

  IsIlani({
    required this.baslik,
    required this.firma,
    required this.sehir,
    required this.aciklama,
  });
}

// Geçici ilan deposu.
// Daha sonra Firebase veritabanına bağlayacağız.
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

// =====================================================
// ANA SAYFA
// =====================================================

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  final meslekController = TextEditingController();
  final sehirController = TextEditingController();

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
          meslek
