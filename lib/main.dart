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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Çıkış yapıldı.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = kullanici;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 25),

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
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 30),

            if (user != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.verified_user,
                        color: Colors.green,
                        size: 35,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Giriş yapıldı',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(user.email ?? ''),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 15),

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
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(18),
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed: ilanVerSayfasiniAc,
              icon: const Icon(Icons.add_business),
              label: const Text('İŞ İLANI VER'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(18),
              ),
            ),

            const SizedBox(height: 15),

            if (user == null)
              OutlinedButton.icon(
                onPressed: girisSayfasiniAc,
                icon: const Icon(Icons.person),
                label: const Text('GİRİŞ YAP / KAYIT OL'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(18),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: cikisYap,
                icon: const Icon(Icons.logout),
                label: const Text('ÇIKIŞ YAP'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(18),
                ),
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
  final TextEditingController emailController = TextEditingController();
  final TextEditingController sifreController = TextEditingController();

  bool kayitModu = false;
  bool yukleniyor = false;
  bool sifreGizli = true;

  @override
  void dispose() {
    emailController.dispose();
    sifreController.dispose();
    super.dispose();
  }

  Future<void> girisVeyaKayit() async {
    final email = emailController.text.trim();
    final sifre = sifreController.text.trim();

    if (email.isEmpty || sifre.isEmpty) {
      mesajGoster('E-posta ve şifreyi doldurun.');
      return;
    }

    if (sifre.length < 6) {
      mesajGoster('Şifre en az 6 karakter olmalı.');
      return;
    }

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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kayitModu
                ? 'Kayıt başarılı. Hoş geldiniz!'
                : 'Giriş başarılı.',
          ),
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String mesaj = 'Bir hata oluştu.';

      if (e.code == 'email-already-in-use') {
        mesaj = 'Bu e-posta adresi zaten kayıtlı.';
      } else if (e.code == 'invalid-email') {
        mesaj = 'Geçerli bir e-posta adresi girin.';
      } else if (e.code == 'weak-password') {
        mesaj = 'Şifre çok zayıf.';
      } else if (e.code == 'user-not-found') {
        mesaj = 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
      } else if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        mesaj = 'E-posta veya şifre yanlış.';
      } else if (e.message != null) {
        mesaj = e.message!;
      }

      mesajGoster(mesaj);
    } catch (e) {
      mesajGoster('Bağlantı hatası oluştu.');
    } finally {
      if (mounted) {
        setState(() {
          yukleniyor = false;
        });
      }
    }
  }

  void mesajGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          kayitModu ? 'Kayıt Ol' : 'Giriş Yap',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            Icon(
              kayitModu ? Icons.person_add : Icons.lock,
              size: 90,
              color: Colors.blue,
            ),

            const SizedBox(height: 30),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: sifreController,
              obscureText: sifreGizli,
              decoration: InputDecoration(
                labelText: 'Şifre',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      sifreGizli = !sifreGizli;
                    });
                  },
                  icon: Icon(
                    sifreGizli
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: yukleniyor ? null : girisVeyaKayit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(17),
                ),
                child: yukleniyor
                    ? const CircularProgressIndicator()
                    : Text(
                        kayitModu ? 'KAYIT OL' : 'GİRİŞ YAP',
                      ),
              ),
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: yukleniyor
                  ? null
                  : () {
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
  final TextEditingController aramaController = TextEditingController();

  String arama = '';

  @override
  void dispose() {
    aramaController.dispose();
    super.dispose();
  }

  bool eslesiyor(IsIlani ilan) {
    final kelime = arama.toLowerCase();

    return ilan.baslik.toLowerCase().contains(kelime) ||
        ilan.firma.toLowerCase().contains(kelime) ||
        ilan.sehir.toLowerCase().contains(kelime) ||
        ilan.aciklama.toLowerCase().contains(kelime);
  }

  void detayGoster(IsIlani ilan) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(ilan.baslik),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Firma: ${ilan.firma}'),
              const SizedBox(height: 8),
              Text('Şehir: ${ilan.sehir}'),
              const SizedBox(height: 12),
              Text(ilan.aciklama),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('KAPAT'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İş Ara'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: aramaController,
              onChanged: (deger) {
                setState(() {
                  arama = deger;
                });
              },
              decoration: const InputDecoration(
                labelText: 'İş, firma veya şehir ara',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          Expanded(
            child: ValueListenableBuilder<List<IsIlani>>(
              valueListenable: IlanDeposu.ilanlar,
              builder: (context, ilanlar, child) {
                final sonuc =
                    ilanlar.where(eslesiyor).toList();

                if (sonuc.isEmpty) {
                  return const Center(
                    child: Text('İlan bulunamadı.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: sonuc.length,
                  itemBuilder: (context, index) {
                    final ilan = sonuc[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(
                          Icons.work,
                          size: 35,
                        ),
                        title: Text(
                          ilan.baslik,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${ilan.firma} • ${ilan.sehir}',
                        ),
                        trailing:
                            const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          detayGoster(ilan);
                        },
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
  final TextEditingController baslikController =
      TextEditingController();
  final TextEditingController firmaController =
      TextEditingController();
  final TextEditingController sehirController =
      TextEditingController();
  final TextEditingController aciklamaController =
      TextEditingController();

  @override
  void dispose() {
    baslikController.dispose();
    firmaController.dispose();
    sehirController.dispose();
    aciklamaController.dispose();
    super.dispose();
  }

  void ilanKaydet() {
    final baslik = baslikController.text.trim();
    final firma = firmaController.text.trim();
    final sehir = sehirController.text.trim();
    final aciklama = aciklamaController.text.trim();

    if (baslik.isEmpty ||
        firma.isEmpty ||
        sehir.isEmpty ||
        aciklama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bütün alanları doldurun.'),
        ),
      );
      return;
    }

    IlanDeposu.ilanEkle(
      IsIlani(
        baslik: baslik,
        firma: firma,
        sehir: sehir,
        aciklama: aciklama,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('İş ilanı başarıyla eklendi.'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İş İlanı Ver'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: baslikController,
              decoration: const InputDecoration(
                labelText: 'İş başlığı',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: firmaController,
              decoration: const InputDecoration(
                labelText: 'Firma adı',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: sehirController,
              decoration: const InputDecoration(
                labelText: 'Şehir',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: aciklamaController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'İlan açıklaması',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: ilanKaydet,
                icon: const Icon(Icons.save),
                label: const Text('İLANI YAYINLA'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(17),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
