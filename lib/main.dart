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
  bool kontrol = true;

  @override
  void initState() {
    super.initState();
    adminKontrol();
  }

  Future<void> adminKontrol() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          admin = false;
          kontrol = false;
        });
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          admin = doc.exists && doc.data()?['role'] == 'admin';
          kontrol = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          admin = false;
          kontrol = false;
        });
      }
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
        kontrol = true;
      });
    }

    await adminKontrol();
  }

  Future<void> cikis() async {
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      setState(() {
        admin = false;
        kontrol = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İŞ BUL'),
        centerTitle: true,
      ),
      body: user == null
          ? Center(
              child: ElevatedButton.icon(
                onPressed: girisAc,
                icon: const Icon(Icons.login),
                label: const Text('GİRİŞ YAP / KAYIT OL'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 15),
                const Center(
                  child: Text(
                    'İş Bul',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        const Text(
                          'Giriş yapıldı',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(user.email ?? ''),
