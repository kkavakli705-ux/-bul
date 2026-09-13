import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyD0H50wL0r2MB41mfj1MqBsRiB8lMkxKXs',
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
      await adminKontrol();
    }
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
          ? girisYapilmamis()
          : girisYapilmis(user),
    );
  }

  Widget girisYapilmamis() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton.icon(
          onPressed: girisAc,
          icon: const Icon(Icons.login),
          label: const Text('GİRİŞ YAP / KAYIT OL'),
        ),
      ),
    );
  }

  Widget girisYapilmis(User user) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(
          Icons.business_center,
          size: 70,
          color: Colors.blue,
        ),
        const SizedBox(height: 15),
        const Center(
          child: Text(
            'İş Bul\'a Hoş Geldiniz',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Text(
              'Giriş yapıldı\n${user.email ?? ''}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 15),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const IsAraSayfasi(),
              ),
            );
          },
          icon: const Icon(Icons.search),
          label: const Text('İŞ ARA'),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const IlanVerSayfasi(),
              ),
            );
          },
          icon: const Icon(Icons.add_business),
          label: const Text('İŞ İLANI VER'),
        ),
        const SizedBox(height: 15),
        if (kontrol)
          const Center(
            child: CircularProgressIndicator(),
          ),
        if (admin)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const YonetimPaneli(),
                ),
              );
            },
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text('YÖNETİM PANELİ'),
          ),
        const SizedBox(height: 15),
        OutlinedButton.icon(
          onPressed: cikis,
          icon: const Icon(Icons.logout),
          label: const Text('ÇIKIŞ YAP'),
        ),
      ],
    );
  }
}

class GirisSayfasi extends StatefulWidget {
  const GirisSayfasi({super.key});

  @override
  State<GirisSayfasi> createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<GirisSayfasi> {
  final email = TextEditingController();
  final sifre = TextEditingController();

  bool kayit = false;
  bool bekle = false;

  Future<void> devam() async {
    if (email.text.trim().isEmpty || sifre.text.trim().isEmpty) {
      mesaj('E-posta ve şifreyi girin.');
      return;
    }

    setState(() {
      bekle = true;
    });

    try {
      if (kayit) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: sifre.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: sifre.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      mesaj(e.message ?? 'Giriş yapılamadı.');
    } catch (_) {
      mesaj('Bir hata oluştu.');
    }

    if (mounted) {
      setState(() {
        bekle = false;
      });
    }
  }

  void mesaj(String yazi) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(yazi)),
    );
  }

  @override
  void dispose() {
    email.dispose();
    sifre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kayit ? 'Kayıt Ol' : 'Giriş Yap'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: email,
            decoration: const InputDecoration(
              labelText: 'E-posta',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: sifre,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Şifre',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: bekle ? null : devam,
            child: Text(
              bekle
                  ? 'BEKLEYİN...'
                  : kayit
                      ? 'KAYIT OL'
                      : 'GİRİŞ YAP',
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                kayit = !kayit;
              });
            },
            child: Text(
              kayit
                  ? 'Zaten hesabım var'
                  : 'Hesabım yok, kayıt ol',
            ),
          ),
        ],
      ),
    );
  }
}

class IlanVerSayfasi extends StatefulWidget {
  const IlanVerSayfasi({super.key});

  @override
  State<IlanVerSayfasi> createState() => _IlanVerSayfasiState();
}

class _IlanVerSayfasiState extends State<IlanVerSayfasi> {
  final baslik = TextEditingController();
  final firma = TextEditingController();
  final konum = TextEditingController();
  final aciklama = TextEditingController();

  bool bekle = false;

  Future<void> gonder() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    if (baslik.text.trim().isEmpty ||
        firma.text.trim().isEmpty ||
        konum.text.trim().isEmpty ||
        aciklama.text.trim().isEmpty) {
      mesaj('Bütün alanları doldurun.');
      return;
    }

    setState(() {
      bekle = true;
    });

    try {
      await FirebaseFirestore.instance.collection('jobs').add({
        'title': baslik.text.trim(),
        'company': firma.text.trim(),
        'city': konum.text.trim(),
        'description': aciklama.text.trim(),
        'ownerUid': user.uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İlan yönetici onayına gönderildi.'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      mesaj('İlan gönderilemedi.');
    }

    if (mounted) {
      setState(() {
        bekle = false;
      });
    }
  }

  void mesaj(String yazi) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(yazi)),
    );
  }

  @override
  void dispose() {
    baslik.dispose();
    firma.dispose();
    konum.dispose();
    aciklama.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İş İlanı Ver'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: baslik,
            decoration: const InputDecoration(
              labelText: 'İş başlığı',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: firma,
            decoration: const InputDecoration(
              labelText: 'Firma / İşveren',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: konum,
            decoration: const InputDecoration(
              labelText: 'Şehir / İlçe',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: aciklama,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'İlan açıklaması',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: bekle ? null : gonder,
            icon: const Icon(Icons.send),
            label: Text(
              bekle ? 'GÖNDERİLİYOR...' : 'İLANI ONAYA GÖNDER',
            ),
          ),
        ],
      ),
    );
  }
}

class IsAraSayfasi extends StatelessWidget {
  const IsAraSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İş Ara'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('İlanlar yüklenemedi.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final ilanlar = snapshot.data!.docs;

          if (ilanlar.isEmpty) {
            return const Center(
              child: Text('Henüz onaylanmış ilan yok.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: ilanlar.length,
            itemBuilder: (context, index) {
              final data =
                  ilanlar[index].data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  title: Text(data['title'] ?? ''),
                  subtitle: Text(
                    '${data['company'] ?? ''}\n'
                    '${data['city'] ?? ''}\n\n'
                    '${data['description'] ?? ''}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class YonetimPaneli extends StatelessWidget {
  const YonetimPaneli({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetim Paneli'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Yönetici hesabı - Bu bölüm sadece yöneticiye açıktır.',
textAlign: TextAlign.center,
),
