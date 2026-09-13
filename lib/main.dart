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
                    content: Text('İş arama bölümü yakında aktif olacak.'),
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
                    content: Text('İş ilanı verme bölümü yakında aktif olacak.'),
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
  final TextEditingController sifreController = TextEditingController();

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
                    builder: (context) => const IlanlarSayfasi(),
                  ),
                );
              },
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.people),
              title: Text('Kullanıcılar'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.report),
              title: Text('Şikayetler'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.settings),
              title: Text('Ayarlar'),
            ),
          ),
        ],
      ),
    );
  }
}

class IlanlarSayfasi extends StatefulWidget {
  const IlanlarSayfasi({super.key});

  @override
  State<IlanlarSayfasi> createState() => _IlanlarSayfasiState();
}

class _IlanlarSayfasiState extends State<IlanlarSayfasi> {
  final List<String> ilanlar = [
    'İnşaat Ustası - Balıkesir',
    'Şoför - Bursa',
  ];

  Future<void> ilanEkle() async {
    final sonuc = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const IlanEkleSayfasi(),
      ),
    );

    if (sonuc != null && sonuc.isNotEmpty) {
      setState(() {
        ilanlar.add(sonuc);
      });
    }
  }

  void ilanSil(int index) {
    setState(() {
      ilanlar.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlanları Yönet'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ilanEkle,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ilanlar.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.work),
              title: Text(ilanlar[index]),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  ilanSil(index);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class IlanEkleSayfasi extends StatefulWidget {
  const IlanEkleSayfasi({super.key});

  @override
  State<IlanEkleSayfasi> createState() => _IlanEkleSayfasiState();
}

class _IlanEkleSayfasiState extends State<IlanEkleSayfasi> {
  final TextEditingController meslekController = TextEditingController();
  final TextEditingController sehirController = TextEditingController();

  void kaydet() {
    final meslek = meslekController.text.trim();
    final sehir = sehirController.text.trim();

    if (meslek.isEmpty || sehir.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meslek ve şehir alanlarını doldur.'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      '$meslek - $sehir',
    );
  }

  @override
  void dispose() {
    meslekController.dispose();
    sehirController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni İlan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: meslekController,
              decoration: const InputDecoration(
                labelText: 'İş / Meslek',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: sehirController,
              decoration: const InputDecoration(
                labelText: 'Şehir',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: kaydet,
              child: const Text('İLANI KAYDET'),
            ),
          ],
        ),
      ),
    );
  }
}
