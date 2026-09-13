import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyD0H50wL0r2MB41mfjiMqBsRiB8lMkxKXs',
      appId: '1:308098362070:android:964692ab6543a09d42b777',
      messagingSenderId: '308098362070',
      projectId: 'is-bul-1652d',
      storageBucket: 'is-bul-1652d.firebasestorage.app',
    ),
  );

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

  const IsIlani({
    required this.baslik,
    required this.firma,
    required this.sehir,
    required this.aciklama,
  });
}

class IlanDeposu {
  static final ValueNotifier<List<IsIlani>> ilanlar =
      ValueNotifier<List<IsIlani>>([
    const IsIlani(
      baslik: 'İnşaat Ustası',
      firma: 'Örnek İnşaat',
      sehir: 'Balıkesir',
      aciklama: 'Deneyimli inşaat ustası aranmaktadır.',
    ),
    const IsIlani(
      baslik: 'Şoför',
      firma: 'Örnek Lojistik',
      sehir: 'Bursa',
      aciklama: 'B sınıfı ehliyeti olan şoför aranmaktadır.',
    ),
  ]);

  static void ekle(IsIlani ilan) {
    ilanlar.value = [
      ...ilanlar.value,
      ilan,
    ];
  }

  static void sil(int index) {
    final yeniListe = [...ilanlar.value];

    if (index >= 0 && index < yeniListe.length) {
      yeniListe.removeAt(index);
      ilanlar.value = yeniListe;
    }
  }
}

class AdminServisi {
  static Future<bool> adminMi() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return false;
    }

    try {
      final belge = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      if (!belge.exists) {
        return false;
      }

      final data = belge.data();

      return data != null && data['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }
}

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  bool admin = false;
  bool adminKontrolEdiliyor = true;

  @override
  void initState() {
    super.initState();
    adminKontrol();
  }

  Future<void> adminKontrol() async {
    final sonuc = await AdminServisi.adminMi();

    if (!mounted) return;

    setState(() {
      admin = sonuc;
      adminKontrolEdiliyor = false;
    });
  }

  Future<void> girisSayfasiniAc() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GirisKayitSayfasi(),
      ),
    );

    await adminKontrol();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> ilanVerSayfasiniAc() async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'İlan vermek için önce giriş yapmalısınız.',
          ),
        ),
      );

      await girisSayfasiniAc();

      if (FirebaseAuth.instance.currentUser == null) {
        return;
      }
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const IlanVerSayfasi(),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> cikisYap() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    setState(() {
      admin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
       
