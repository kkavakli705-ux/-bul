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

/* =========================================================
   ADMIN KONTROLÜ
   ========================================================= */

class AdminServisi {
  static Future<bool> adminMi() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return false;
    }

    try {
      final belge = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      if (!belge.exists) {
        return false;
      }

      final data = belge.data();

      return data != null && data['role'] == 'admin';
    } catch (_) {
      return false;
    }
  }
}

/* =========================================================
   ANA SAYFA
   ========================================================= */

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  bool admin = false;
  bool adminKontrolEdiliyor = false;

  @override
  void initState() {
    super.initState();
    adminKontrol();
  }

  Future<void> adminKontrol() async {
    setState(() {
      adminKontrolEdiliyor = true;
    });

    final sonuc = await AdminServisi.adminMi();

    if (!mounted) return;

    setState(() {
      admin = sonuc;
      adminKontrolEdiliyor = false;
    });
  }

  Future<void> girisSayfasiniAc() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GirisKayitSayfasi(),
      ),
    );

    await adminKontrol();
  }

  Future<void> ilanVerSayfasiniAc() async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'İlan vermek için önce giriş yapmalısınız.',
          ),
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
      body: RefreshIndicator(
        onRefresh: adminKontrol,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),

            const Icon(
              Icons.work_rounded,
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

            const SizedBox(height: 8),

            const Text(
              'İş arayanlarla işverenleri buluşturan platform',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 35),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text(
                  'İŞ ARA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const IsAraSayfasi(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_business),
                label: const Text(
                  'İŞ İLANI VER',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: ilanVerSayfasiniAc,
              ),
            ),

            const SizedBox(height: 15),

            if (user == null)
              SizedBox(
                height: 55,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.person),
                  label: const Text(
                    'GİRİŞ YAP / KAYIT OL',
                  ),
                  onPressed: girisSayfasiniAc,
                ),
              ),

            if (user != null) ...[
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.account_circle,
                  ),
                  title: const Text(
                    'Giriş yapıldı',
                  ),
                  subtitle: Text(
                    user.email ?? 'Kullanıcı',
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('ÇIKIŞ YAP'),
                  onPressed: cikisYap,
                ),
              ),
            ],

            if (adminKontrolEdiliyor && user != null) ...[
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
                  icon: const Icon(
                    Icons.admin_panel_settings,
                  ),
                  label: const Text(
                    'YÖNETİM PANELİ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const YonetimPaneli(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/* =========================================================
   GİRİŞ / KAYIT
   ========================================================= */

class GirisKayitSayfasi extends StatefulWidget {
  const GirisKayitSayfasi({super.key});

  @override
  State<GirisKayitSayfasi> createState() =>
      _GirisKayitSayfasiState();
}

class _GirisKayitSayfasiState
    extends State<GirisKayitSayfasi> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController sifreController =
      TextEditingController();

  bool kayitModu = false;
  bool yukleniyor = false;
  bool sifreGizli = true;

  void mesaj(String yazi) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(yazi),
      ),
    );
  }

  Future<void> girisVeyaKayit() async {
    final email = emailController.text.trim();
    final sifre = sifreController.text.trim();

    if (email.isEmpty || sifre.isEmpty) {
      mesaj('E-posta ve şifreyi doldurun.');
      return;
    }

    if (sifre.length < 6) {
      mesaj('Şifre en az 6 karakter olmalıdır.');
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
      String hata = 'İşlem başarısız.';

      if (e.code == 'invalid-credential') {
        hata = 'E-posta veya şifre yanlış.';
      } else if (e.code == 'email-already-in-use') {
        hata = 'Bu e-posta zaten kayıtlı.';
      } else if (e.code == 'invalid-email') {
        hata = 'Geçerli bir e-posta girin.';
      } else if (e.code == 'weak-password') {
        hata = 'Şifre çok zayıf.';
      } else if (e.code == 'user-disabled') {
        hata = 'Bu kullanıcı hesabı devre dışı.';
      }

      if (mounted) {
        mesaj(hata);
      }
    } catch (_) {
      if (mounted) {
        mesaj('Bağlantı hatası oluştu.');
      }
    }

    if (mounted) {
      setState(() {
        yukleniyor = false;
      });
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
          kayitModu ? 'Kayıt Ol' : 'Giriş Yap',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            Icon(
              kayitModu
                  ? Icons.person_add
                  : Icons.account_circle,
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
                  icon: Icon(
                    sifreGizli
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      sifreGizli = !sifreGizli;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    yukleniyor ? null : girisVeyaKayit,
                child: yukleniyor
                    ? const CircularProgressIndicator()
                    : Text(
                        kayitModu
                            ? 'KAYIT OL'
                            : 'GİRİŞ YAP',
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

/* =========================================================
   İŞ İLANI VER
   ========================================================= */

class IlanVerSayfasi extends StatefulWidget {
  const IlanVerSayfasi({super.key});

  @override
  State<IlanVerSayfasi> createState() =>
      _IlanVerSayfasiState();
}

class _IlanVerSayfasiState
    extends State<IlanVerSayfasi> {
  final TextEditingController baslikController =
      TextEditingController();

  final TextEditingController firmaController =
      TextEditingController();

  final TextEditingController sehirController =
      TextEditingController();

  final TextEditingController ilceController =
      TextEditingController();

  final TextEditingController maasController =
      TextEditingController();

  final TextEditingController deneyimController =
      TextEditingController();

  final TextEditingController aciklamaController =
      TextEditingController();

  final TextEditingController iletisimController =
      TextEditingController();

  String kategori = 'İnşaat';
  String calismaSekli = 'Tam zamanlı';

  bool yukleniyor = false;

  final List<String> kategoriler = [
    'İnşaat',
    'Şoför',
    'Sanayi',
    'Restoran',
    'Mağaza',
    'Temizlik',
    'Ofis',
    'Güvenlik',
    'Tarım',
    'Nakliye',
    'Otomotiv',
    'Diğer',
  ];

  final List<String> calismaSekilleri = [
    'Tam zamanlı',
    'Part-time',
    'Günlük',
    'Sezonluk',
    'Gece vardiyası',
  ];

  void mesaj(String yazi) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(yazi),
      ),
    );
  }

  Future<void> ilaniGonder() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      mesaj('Önce giriş yapmalısınız.');
      return;
    }

    if (baslikController.text.trim().isEmpty ||
        firmaController.text.trim().isEmpty ||
        sehirController.text.trim().isEmpty ||
        ilceController.text.trim().isEmpty ||
        aciklamaController.text.trim().isEmpty ||
        iletisimController.text.trim().isEmpty) {
      mesaj('Yıldızlı alanları doldurun.');
      return;
    }

    setState(() {
      yukleniyor = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .add({
        'title': baslikController.text.trim(),
        'category': kategori,
        'company': firmaController.text.trim(),
        'city': sehirController.text.trim(),
        'district': ilceController.text.trim(),
        'workType': calismaSekli,
        'salary': maasController.text.trim(),
        'experience': deneyimController.text.trim(),
        'description': aciklamaController.text.trim(),
        'contact': iletisimController.text.trim(),
        'ownerUid': user.uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('İlan Gönderildi'),
            content: const Text(
              'İlanınız yönetici onayına gönderildi. '
              'Onaylandıktan sonra yayınlanacaktır.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('TAMAM'),
              ),
            ],
          );
        },
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        mesaj(
          'İlan gönderilemedi: ${e.code}',
        );
      }
    } catch (_) {
      if (mounted) {
        mesaj('İlan gönderilemedi.');
      }
    }

    if (mounted) {
      setState(() {
        yukleniyor = false;
      });
    }
  }

  @override
  void dispose() {
    baslikController.dispose();
    firmaController.dispose();
    sehirController.dispose();
    ilceController.dispose();
    maasController.dispose();
    deneyimController.dispose();
    aciklamaController.dispose();
    iletisimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İş İlanı Ver'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            TextField(
              controller: baslikController,
              decoration: const InputDecoration(
                labelText: 'İş başlığı *',
                hintText: 'Örn: Boya ustası aranıyor',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: kategori,
              decoration: const InputDecoration(
                labelText: 'İş kategorisi',
                border: OutlineInputBorder(),
              ),
              items: kategoriler.map((kategoriAdi) {
                return DropdownMenuItem<String>(
                  value: kategoriAdi,
                  child: Text(kategoriAdi),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  kategori = value;
                });
              },
            ),

            const SizedBox(height: 15),

            TextField(
              controller: firmaController,
              decoration: const InputDecoration(
                labelText: 'Firma / İşveren adı *',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: sehirController,
              decoration: const InputDecoration(
                labelText: 'Şehir *',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: ilceController,
              decoration: const InputDecoration(
                labelText: 'İlçe *',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: calismaSekli,
              decoration: const InputDecoration(
                labelText: 'Çalışma şekli',
                border: OutlineInputBorder(),
              ),
              items: calismaSekilleri.map((calisma) {
                return DropdownMenuItem<String>(
                  value: calisma,
                  child: Text(calisma),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  calismaSekli = value;
                });
              },
            ),

            const SizedBox(height: 15),

            TextField(
              controller: maasController,
              decoration: const InputDecoration(
                labelText: 'Maaş / Ücret',
                hintText: 'Örn: 40.000 TL / Görüşülür',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: deneyimController,
              decoration: const InputDecoration(
                labelText: 'Deneyim şartı',
                hintText: 'Örn: Tecrübe aranmıyor',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: aciklamaController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'İş açıklaması *',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: iletisimController,
              decoration: const InputDecoration(
                labelText: 'İletişim bilgisi *',
                hintText: 'Telefon veya e-posta',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: yukleniyor
                    ? const SizedBox(
                        width: 25,
                        height: 25,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'İLANI ONAYA GÖNDER',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                onPressed:
                    yukleniyor ? null : ilaniGonder,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'İlan yönetici tarafından onaylandıktan sonra yayınlanır.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================================================
   İŞ ARA
   ========================================================= */

class IsAraSayfasi extends StatefulWidget {
  const IsAraSayfasi({super.key});

  @override
  State<IsAraSayfasi> createState() =>
      _IsAraSayfasiState();
}

class _IsAraSayfasiState extends State<IsAraSayfasi> {
  String arama = '';

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
              decoration: const InputDecoration(
                hintText: 'İş, firma, şehir veya ilçe ara...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  arama = value.toLowerCase().trim();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .where(
                    'status',
                    isEqualTo: 'approved',
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'İlanlar şu anda yüklenemedi.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final tumBelgeler =
                    snapshot.data?.docs ?? [];

                final belgeler =
                    tumBelgeler.where((doc) {
                  final data =
                      doc.data() as Map<String, dynamic>;

                  final metin = [
                    data['title'] ?? '',
                    data['company'] ?? '',
                    data['city'] ?? '',
                    data['district'] ?? '',
                    data['category'] ?? '',
                  ].join(' ').toLowerCase();

                  return metin.contains(arama);
                }).toList();

                if (belgeler.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Text(
                        'Henüz yayınlanmış iş ilanı yok.\n\n'
                        'Yeni ilanlar yayınlandığında burada görünecek.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: belgeler.length,
                  itemBuilder: (context, index) {
                    final doc = belgeler[index];

                    final data =
                        doc.data()
                            as Map<String, dynamic>;

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.work),
                        ),
                        title: Text(
                          data['title']?.toString() ??
                              'İş ilanı',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${data['company'] ?? ''}\n'
                          '${data['city'] ?? ''} / '
                          '${data['district'] ?? ''}',
                        ),
                        isThreeLine: true,
                        trailing:
                            const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  IlanDetaySayfasi(
                                data: data,
                              ),
                            ),
                          );
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

/* =========================================================
   İLAN DETAYI
   ========================================================= */

class IlanDetaySayfasi extends StatelessWidget {
  final Map<String, dynamic> data;

  const IlanDetaySayfasi({
    super.key,
    required this.data,
  });

  Widget bilgiSatiri(
    String baslik,
    dynamic deger,
  ) {
    final yazi = deger?.toString().trim() ?? '';

    if (yazi.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        '$baslik: $yazi',
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlan Detayı'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            data['title']?.toString() ??
                'İş İlanı',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 25),

          bilgiSatiri(
            'Kategori',
            data['category'],
          ),

          bilgiSatiri(
            'Firma',
            data['company'],
          ),

          bilgiSatiri(
            'Şehir',
            data['city'],
          ),

          bilgiSatiri(
            'İlçe',
            data['district'],
          ),

          bilgiSatiri(
            'Çalışma şekli',
            data['workType'],
          ),

          bilgiSatiri(
            'Maaş / Ücret',
            data['salary'],
          ),

          bilgiSatiri
