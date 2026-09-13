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

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  bool admin = false;
  bool kontrolEdiliyor = false;

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
          kontrolEdiliyor = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        kontrolEdiliyor = true;
      });
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      setState(() {
        admin = doc.exists &&
            doc.data()?['role'] == 'admin';

        kontrolEdiliyor = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        admin = false;
        kontrolEdiliyor = false;
      });
    }
  }

  Future<void> girisAc() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GirisKayitSayfasi(),
      ),
    );

    await adminKontrol();

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
        title: const Text(
          'İŞ BUL',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
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
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 35),

          if (user == null) ...[
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: girisAc,
                icon: const Icon(Icons.person),
                label: const Text(
                  'GİRİŞ YAP / KAYIT OL',
                ),
              ),
            ),
          ],

          if (user != null) ...[
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.account_circle,
                  size: 40,
                ),
                title: const Text(
                  'Giriş yapıldı',
                ),
                subtitle: Text(
                  user.email ?? '',
                ),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.search),
                label: const Text('İŞ ARA'),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_business),
                label: const Text(
                  'İŞ İLANI VER',
                ),
              ),
            ),

            if (kontrolEdiliyor) ...[
              const SizedBox(height: 20),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],

            if (admin) ...[
              const SizedBox(height: 25),

              const Divider(),

              const SizedBox(height: 10),

              SizedBox(
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const YonetimPaneli(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.admin_panel_settings,
                  ),
                  label: const Text(
                    'YÖNETİM PANELİ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: cikisYap,
              icon: const Icon(Icons.logout),
              label: const Text('ÇIKIŞ YAP'),
            ),
          ],
        ],
      ),
    );
  }
}

class GirisKayitSayfasi extends StatefulWidget {
  const GirisKayitSayfasi({super.key});

  @override
  State<GirisKayitSayfasi> createState() =>
      _GirisKayitSayfasiState();
}

class _GirisKayitSayfasiState
    extends State<GirisKayitSayfasi> {
  final emailController =
      TextEditingController();

  final sifreController =
      TextEditingController();

  bool kayitModu = false;
  bool yukleniyor = false;

  Future<void> islemYap() async {
    final email =
        emailController.text.trim();

    final sifre =
        sifreController.text.trim();

    if (email.isEmpty || sifre.length < 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'E-posta ve en az 6 karakter şifre girin.',
          ),
        ),
      );
      return;
    }

    setState(() {
      yukleniyor = true;
    });

    try {
      if (kayitModu) {
        await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email,
          password: sifre,
        );
      } else {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: email,
          password: sifre,
        );
      }

      if (!mounted) return;

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String mesaj = 'İşlem başarısız.';

      if (e.code == 'invalid-credential') {
        mesaj = 'E-posta veya şifre yanlış.';
      } else if (e.code ==
          'email-already-in-use') {
        mesaj =
            'Bu e-posta zaten kayıtlı.';
      } else if (e.code ==
          'invalid-email') {
        mesaj =
            'Geçerli bir e-posta girin.';
      } else if (e.code ==
          'weak-password') {
        mesaj = 'Şifre çok zayıf.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(mesaj),
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
  void dispose() {
    emailController.dispose();
    sifreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          kayitModu
              ? 'Kayıt Ol'
              : 'Giriş Yap',
        ),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            TextField(
              controller:
                  emailController,
              keyboardType:
                  TextInputType
                      .emailAddress,
              decoration:
                  const InputDecoration(
                labelText: 'E-posta',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller:
                  sifreController,
              obscureText: true,
              decoration:
                  const InputDecoration(
                labelText: 'Şifre',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    yukleniyor
                        ? null
                        : islemYap,
                child: Text(
                  kayitModu
                      ? 'KAYIT OL'
                      : 'GİRİŞ YAP',
                ),
              ),
            ),

            TextButton(
              onPressed: () {
                setState(() {
                  kayitModu =
                      !kayitModu;
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

class YonetimPaneli
    extends StatelessWidget {
  const YonetimPaneli({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Yönetim Paneli'),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(18),
        children: [
          const Card(
            child: ListTile(
              leading: Icon(
                Icons.verified_user,
                color: Colors.green,
              ),
              title: Text(
                'Yönetici hesabı',
              ),
              subtitle: Text(
                'Bu bölüm sadece yönetici hesabına açıktır.',
              ),
            ),
          ),

          const SizedBox(height: 15),

          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.work),
              title: const Text(
                'İş İlanlarını Yönet',
              ),
              subtitle: const Text(
                'Bekleyen ilanları onayla veya reddet',
              ),
              trailing:
                  const Icon(
                Icons.chevron_right,
              ),
              onTap: () {},
            ),
          ),

          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.people),
              title: const Text(
                'Kullanıcıları Yönet',
              ),
              subtitle: const Text(
                'Üyeleri görüntüle ve yönet',
              ),
              trailing:
                  const Icon(
                Icons.chevron_right,
              ),
              onTap: () {},
            ),
          ),

          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.report),
              title: const Text(
                'Şikayetler',
              ),
              subtitle: const Text(
                'Kullanıcı şikayetlerini incele',
              ),
              trailing:
                  const Icon(
                Icons.chevron_right,
              ),
              onTap: () {},
            ),
          ),

          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.star),
              title: const Text(
                'Öne Çıkan İlanlar',
              ),
              subtitle: const Text(
                'Öne çıkarılan ilanları yönet',
              ),
              trailing:
                  const Icon(
                Icons.chevron_right,
              ),
              onTap: () {},
            ),
          ),

          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.settings),
              title:
                  const Text('Ayarlar'),
              subtitle: const Text(
                'Uygulama yönetim ayarları',
              ),
              trailing:
                  const Icon(
                Icons.chevron_right,
              ),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
