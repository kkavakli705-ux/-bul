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
        title: const Text(
          'İŞ BUL',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),

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

            const SizedBox(height: 10),

            const Text(
              'İş arayanlarla işverenleri buluşturuyoruz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 35),

            TextField(
              decoration: InputDecoration(
                hintText: 'Meslek veya iş ara',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              decoration: InputDecoration(
                hintText: 'Şehir',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('İş arama bölümü hazır olacak.'),
                  ),
                );
              },
              icon: const Icon(Icons.search),
              label: const Text('İŞ ARA'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(18),
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('İş ilanı verme bölümü hazır olacak.'),
                  ),
                );
              },
              icon: const Icon(Icons.add_business),
              label: const Text('İŞ İLANI VER'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(18),
              ),
            ),

    
             const SizedBox(height: 15),

OutlinedButton.icon(
  onPressed: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Giriş ve kayıt bölümü hazırlanıyor'),
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
  style: OutlinedButton.styleFrom(
    padding: const EdgeInsets.all(18),
  ),
), 
              
                
                
                
  
              ),
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
      Navigator.push(
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetici Girişi'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(
              Icons.admin_panel_settings,
              size: 90,
              color: Colors.blue,
            ),
            const SizedBox(height: 30),

            TextField(
              controller: sifreController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Yönetici Şifresi',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: girisYap,
                icon: const Icon(Icons.login),
                label: const Text('YÖNETİCİ GİRİŞİ'),
              ),
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
        title: const Text('İş Bul Yönetim Paneli'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          adminButon(
            context,
            Icons.work,
            'İlanlar',
          ),
          adminButon(
            context,
            Icons.people,
            'Kullanıcılar',
          ),
          adminButon(
            context,
            Icons.pending_actions,
            'Bekleyen İlanlar',
          ),
          adminButon(
            context,
            Icons.report,
            'Şikayetler',
          ),
          adminButon(
            context,
            Icons.star,
            'Öne Çıkan İlanlar',
          ),
          adminButon(
            context,
            Icons.settings,
            'Ayarlar',
          ),
        ],
      ),
    );
  }

  Widget adminButon(
    BuildContext context,
    IconData icon,
    String baslik,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.blue,
          size: 32,
        ),
        title: Text(
          baslik,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$baslik bölümü hazırlanıyor'),
            ),
          );
        },
      ),
    );
  }
}
