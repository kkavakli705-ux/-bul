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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AnaSayfa(),
    );
  }
}

class IsIlani {
  final String baslik;
  final String sehir;

  IsIlani({
    required this.baslik,
    required this.sehir,
  });
}

class IlanDeposu {
  static final List<IsIlani> ilanlar = [
    IsIlani(
      baslik: 'İnşaat Ustası',
      sehir: 'Balıkesir',
    ),
    IsIlani(
      baslik: 'Şoför',
      sehir: 'Bursa',
    ),
  ];
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
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
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('İş arama bölümü sonra eklenecek.'),
                  ),
                );
              },
              icon: const Icon(Icons.search),
              label: const Text('İŞ ARA'),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('İş ilanı verme bölümü sonra eklenecek.'),
                  ),
                );
              },
              icon: const Icon(Icons.add_business),
              label: const Text('İŞ İLANI VER'),
            ),
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Giriş ve kayıt bölümü hazırlanıyor.'),
                  ),
                );
              },
              onLongPress: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminGirisSayfasi(),
                  ),
                );
              },
              icon: const Icon(Icons.person),
              label: const Text('GİRİŞ YAP / KAYIT OL'),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminGirisSayfasi extends StatefulWidget {
  const AdminGirisSayfasi({super.key});

  @override
  State<AdminGirisSayfasi> createState() => _AdminGirisSayfasiState();
}

class _AdminGirisSayfasiState extends State<AdminGirisSayfasi> {
  final sifreController = TextEditingController();

  void girisYap() {
    if (sifreController.text == '1234') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AdminPaneli(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifre yanlış'),
        ),
      );
    }
  }

  @override
  void dispose() {
    sifreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetici Girişi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            TextField(
              controller: sifreController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Yönetici Şifresi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: girisYap,
              child: const Text('GİRİŞ YAP'),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminPaneli extends StatelessWidget {
  const AdminPaneli({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetim Paneli'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.work),
              title: const Text('İlanlar'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminIlanlarSayf
