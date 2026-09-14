import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AnaSayfa(),
    );
  }
}

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  bool admin = false;
  bool engelli = false;
  bool kontrol = true;

  @override
  void initState() {
    super.initState();
    hesapKontrol();
  }

  Future<void> kullaniciKaydiOlustur(User user) async {
    try {
      final ref =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      final doc = await ref.get();

      if (!doc.exists) {
        await ref.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'blocked': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  Future<void> hesapKontrol() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          admin = false;
          engelli = false;
          kontrol = false;
        });
      }
      return;
    }

    await kullaniciKaydiOlustur(user);

    bool yeniAdmin = false;
    bool yeniEngelli = false;

    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      yeniAdmin =
          adminDoc.exists && adminDoc.data()?['role'] == 'admin';
    } catch (_) {}

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        yeniEngelli = userDoc.data()?['blocked'] == true;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        admin = yeniAdmin;
        engelli = yeniAdmin ? false : yeniEngelli;
        kontrol = false;
      });
    }
  }

  Future<void> girisAc() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GirisSayfasi(),
      ),
    );

    if (mounted) {
      setState(() {
        kontrol = true
