import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDOH5OwL0r2MB41mfjiMqBsRiB81MkxKXs',
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
      aciklama: 'B sınıfı ehliyetli şoför aranmaktadır.',
    ),
  ]);

  static void ilanEkle(IsIlani ilan) {
    ilanlar.value = [...ilanlar.value, ilan];
  }

  static void ilanSil(int index) {
    final yeniListe = [...ilanlar.value];
    yeniListe.removeAt(index);
    ilanlar.value = yeniListe;
  }
}

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  User? get kullanici => FirebaseAuth.instance.currentUser;

  Future<void> girisSayfasiniAc() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GirisKayitSayfasi(),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> ilanVerSayfasiniAc() async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İlan vermek için önce giriş yapmalısınız.'),
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
  }

  Future<void> cikisYap() async {
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = kullanici;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'İŞ BUL',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IsAraSayfasi(),
                  ),
                );
              },
              icon: const Icon(Icons.search),
              label: const Text('İŞ ARA'),
            ),

            const SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed: ilanVerSayfasiniAc,
              icon: const Icon(Icons.add_business),
              label: const Text('İŞ İLANI VER'),
            ),

            const SizedBox(height: 15),

            if (user == null)
              OutlinedButton.icon(
                onPressed: girisSayfasiniAc,
                icon: const Icon(Icons.person),
                label: const Text('GİRİŞ YAP / KAYIT OL'),
              )
            else
              OutlinedButton.icon(
                onPressed: cikisYap,
                icon: const Icon(Icons.logout),
                label: const Text('ÇIKIŞ YAP'),
              ),

            const SizedBox(height: 15),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminGirisSayfasi(),
                  ),
                );
              },
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('YÖNETİCİ GİRİŞİ'),
            ),
          ],
        ),
      ),
    );
  }
}

class GirisKayitSayfasi extends StatefulWidget {
  const GirisKayitSayfasi({super.key});

  @override
  State<GirisKayitSayfasi> createState() => _GirisKayitSayfasiState();
}

class _GirisKayitSayfasiState extends State<GirisKayitSayfasi> {
  final emailController = TextEditingController();
  final sifreController = TextEditingController();

  bool kayitModu = false;
  bool yukleniyor = false;

  Future<void> girisVeyaKayit() async {
    final email = emailController.text.trim();
    final sifre = sifreController.text.trim();

    if (email.isEmpty || sifre.isEmpty) return;

    setState(() {
      yukleniyor = true;
    });

    try {
      if (kayitModu) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: sifre,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: sifre,
        );
      }

      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Giriş hatası'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          yukleniyor = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kayitModu ? 'Kayıt Ol' : 'Giriş Yap'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: sifreController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Şifre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: yukleniyor ? null : girisVeyaKayit,
              child: Text(kayitModu ? 'KAYIT OL' : 'GİRİŞ YAP'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  kayitModu = !kayitModu;
                });
              },
              child: Text(
                kayitModu
                    ? 'Zaten hesabın var mı? Giriş yap'
                    : 'Hesabın yok mu? Kayıt ol',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IsAraSayfasi extends StatefulWidget {
  const IsAraSayfasi({super.key});

  @override
  State<IsAraSayfasi> createState() => _IsAraSayfasiState();
}

class _IsAraSayfasiState extends State<IsAraSayfasi> {
  String arama = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İş Ara')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  arama = value.toLowerCase();
                });
              },
              decoration: const InputDecoration(
                labelText: 'İş veya şehir ara',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<IsIlani>>(
              valueListenable: IlanDeposu.ilanlar,
              builder: (context, ilanlar, child) {
                final sonuc = ilanlar.where((ilan) {
                  return ilan.baslik.toLowerCase().contains(arama) ||
                      ilan.sehir.toLowerCase().contains(arama) ||
                      ilan.firma.toLowerCase().contains(arama);
                }).toList();

                return ListView.builder(
                  itemCount: sonuc.length,
                  itemBuilder: (context, index) {
                    final ilan = sonuc[index];

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.work),
                        title: Text(ilan.baslik),
                        subtitle: Text('${ilan.firma} - ${ilan.sehir}'),
                      ),
                    );
                  },
                );
              },
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
  final sehir = TextEditingController();
  final aciklama = TextEditingController();

  void kaydet() {
    if (baslik.text.isEmpty ||
        firma.text.isEmpty ||
        sehir.text.isEmpty ||
        aciklama.text.isEmpty) {
      return;
    }

    IlanDeposu.ilanEkle(
      IsIlani(
        baslik: baslik.text,
        firma: firma.text,
        sehir: sehir.text,
        aciklama: aciklama.text,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İş İlanı Ver')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: baslik,
              decoration: const InputDecoration(
                labelText: 'İş başlığı',
              ),
            ),
            TextField(
              controller: firma,
              decoration: const InputDecoration(
                labelText: 'Firma',
              ),
            ),
            TextField(
              controller: sehir,
              decoration: const InputDecoration(
                labelText: 'Şehir',
              ),
            ),
            TextField(
              controller: aciklama,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: kaydet,
              child: const Text('İLANI YAYINLA'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetici Girişi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Icon(
              Icons.admin_panel_settings,
              size: 90,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: sifreController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Yönetici şifresi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: girisYap,
              child: const Text('YÖNETİCİ GİRİŞ'),
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
        title: const Text('İlanları Yönet'),
      ),
      body: ValueListenableBuilder<List<IsIlani>>(
        valueListenable: IlanDeposu.ilanlar,
        builder: (context, ilanlar, child) {
          if (ilanlar.isEmpty) {
            return const Center(
              child: Text('Henüz ilan yok'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: ilanlar.length,
            itemBuilder: (context, index) {
              final ilan = ilanlar[index];

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.work),
                  title: Text('${ilan.baslik} - ${ilan.sehir}'),
                  subtitle: Text(ilan.firma),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      IlanDeposu.ilanSil(index);
                    },
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
