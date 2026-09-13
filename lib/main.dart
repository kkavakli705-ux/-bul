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

class AdminServisi {
  static Future<bool> adminMi() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return false;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      return doc.exists &&
          doc.data()?['role'] == 'admin';
    } catch (_) {
      return false;
    }
  }
}

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() =>
      _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  bool admin = false;

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
    });
  }

  Future<void> girisAc() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const GirisKayitSayfasi(),
      ),
    );

    await adminKontrol();
  }

  Future<void> ilanVerAc() async {
    if (FirebaseAuth.instance.currentUser ==
        null) {
      await girisAc();

      if (FirebaseAuth.instance.currentUser ==
          null) {
        return;
      }
    }

    if (!mounted
