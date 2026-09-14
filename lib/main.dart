import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

String bilgi(dynamic deger) {
  final yazi = deger?.toString().trim() ?? '';
  return yazi.isEmpty ? 'Belirtilmemiş' : yazi;
}

void mesaj(BuildContext context, String yazi) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(yazi)),
  );
}

bool aktifOneCikan(Map<String, dynamic> data) {
  if (data['featured'] != true) {
    return false;
  }

  final until = data['featuredUntil'];

  if (until == null) {
    return true;
  }

  if (until is Timestamp) {
    return until.toDate().isAfter(DateTime.now());
  }

  return true;
}

String kalanSure(Map<String, dynamic> data) {
  final until = data['featuredUntil'];

  if (until is! Timestamp) {
    return 'Süresiz';
  }

  final fark = until.toDate().difference(DateTime.now());

  if (fark.isNegative) {
    return 'Süresi doldu';
  }

  if (fark.inDays == 0) {
    return '1 günden az kaldı';
  }

  return '${fark.inDays} gün kaldı';
}

int paketFiyati(int gun) {
  if (gun == 3) return 49;
  if (gun == 7) return 89;
  if (gun == 15) return 149;
  if (gun == 30) return 249;
  return 0;
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
      final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
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

      yeniAdmin = adminDoc.exists && adminDoc.data()?['role'] == 'admin';
    } catch (_) {}

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      yeniEngelli = userDoc.data()?['blocked'] == true;
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
      MaterialPageRoute(builder: (_) => const GirisSayfasi()),
    );

    if (mounted) {
      setState(() {
        kontrol = true;
      });
    }

    await hesapKontrol();
  }

  Future<void> cikis() async {
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      setState(() {
        admin = false;
        engelli = false;
        kontrol = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (kontrol) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user != null && engelli) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('İŞ BUL'),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.block, size: 70),
                const SizedBox(height: 20),
                const Text(
                  'Hesabınız engellenmiştir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: cikis,
                  icon: const Icon(Icons.logout),
                  label: const Text('ÇIKIŞ YAP'),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
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
                      MaterialPageRoute(builder: (_) => const IsAraSayfasi()),
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
                      MaterialPageRoute(builder: (_) => const IlanVerSayfasi()),
                    );
                  },
                  icon: const Icon(Icons.add_business),
                  label: const Text('ÜCRETSİZ İŞ İLANI VER'),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const KendiIlanlarimSayfasi(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list_alt),
                  label: const Text('KENDİ İLANLARIM'),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AyarlarSayfasi(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('AYARLAR'),
                ),
                const SizedBox(height: 15),
                if (admin)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const YonetimPaneli()),
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
            ),
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

  Future<void> kullaniciKaydiOlustur(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'blocked': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> giris() async {
    if (email.text.trim().isEmpty || sifre.text.trim().isEmpty) {
      mesaj(context, 'E-posta ve şifreyi doldurun.');
      return;
    }

    setState(() {
      bekle = true;
    });

    try {
      UserCredential sonuc;

      if (kayit) {
        sonuc = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: sifre.text.trim(),
        );
      } else {
        sonuc = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: sifre.text.trim(),
        );
      }

      if (sonuc.user != null) {
        try {
          await kullaniciKaydiOlustur(sonuc.user!);
        } catch (_) {}
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      mesaj(context, e.message ?? 'İşlem yapılamadı.');
    } catch (_) {
      mesaj(context, 'Bir hata oluştu.');
    }

    if (mounted) {
      setState(() {
        bekle = false;
      });
    }
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
            keyboardType: TextInputType.emailAddress,
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
            onPressed: bekle ? null : giris,
            child: Text(kayit ? 'KAYIT OL' : 'GİRİŞ YAP'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                kayit = !kayit;
              });
            },
            child: Text(
              kayit ? 'Zaten hesabım var' : 'Hesabım yok, kayıt ol',
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
  final telefon = TextEditingController();
  final whatsapp = TextEditingController();
  final ucret = TextEditingController();
  final aciklama = TextEditingController();

  final kategoriler = [
    'İnşaat',
    'Boya / Alçı',
    'Elektrik',
    'Tesisat',
    'Şoför',
    'Garson / Restoran',
    'Temizlik',
    'Fabrika / Üretim',
    'Mağaza / Satış',
    'Ofis',
    'Güvenlik',
    'Nakliye',
    'Oto / Sanayi',
    'Tarım',
    'Diğer',
  ];

  String? kategori;
  bool bekle = false;

  Future<void> gonder() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      mesaj(context, 'Önce giriş yapmalısınız.');
      return;
    }

    if (baslik.text.trim().isEmpty ||
        firma.text.trim().isEmpty ||
        konum.text.trim().isEmpty ||
        telefon.text.trim().isEmpty ||
        whatsapp.text.trim().isEmpty ||
        ucret.text.trim().isEmpty ||
        aciklama.text.trim().isEmpty ||
        kategori == null) {
      mesaj(context, 'Bütün alanları doldurun.');
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
        'category': kategori,
        'phone': telefon.text.trim(),
        'whatsapp': whatsapp.text.trim(),
        'salary': ucret.text.trim(),
        'description': aciklama.text.trim(),
        'ownerUid': user.uid,
        'ownerEmail': user.email ?? '',
        'status': 'pending',
        'featured': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        mesaj(context, 'Ücretsiz ilan yönetici onayına gönderildi.');
        Navigator.pop(context);
      }
    } catch (_) {
      mesaj(context, 'İlan gönderilemedi.');
    }

    if (mounted) {
      setState(() {
        bekle = false;
      });
    }
  }

  @override
  void dispose() {
    baslik.dispose();
    firma.dispose();
    konum.dispose();
    telefon.dispose();
    whatsapp.dispose();
    ucret.dispose();
    aciklama.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ücretsiz İş İlanı Ver')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Normal iş ilanı vermek ücretsizdir. İlan yayınlandıktan sonra isterseniz ücretli olarak öne çıkarabilirsiniz.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: baslik,
            decoration: const InputDecoration(
              labelText: 'İş başlığı',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: kategori,
            decoration: const InputDecoration(
              labelText: 'Meslek / Kategori',
              border: OutlineInputBorder(),
            ),
            items: kategoriler
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                kategori = value;
              });
            },
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
            controller: telefon,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telefon numarası',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: whatsapp,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'WhatsApp numarası',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ucret,
            decoration: const InputDecoration(
              labelText: 'Ücret / Maaş',
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
              bekle ? 'GÖNDERİLİYOR...' : 'ÜCRETSİZ İLANI ONAYA GÖNDER',
            ),
          ),
        ],
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
  final arama = TextEditingController();

  String sadeceRakam(String numara) {
    return numara.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String whatsappNumarasi(String numara) {
    String rakam = sadeceRakam(numara);

    if (rakam.startsWith('0')) {
      rakam = '90${rakam.substring(1)}';
    } else if (!rakam.startsWith('90')) {
      rakam = '90$rakam';
    }

    return rakam;
  }

  Future<void> telefonAra(String numara) async {
    final uri = Uri(
      scheme: 'tel',
      path: sadeceRakam(numara),
    );

    await launchUrl(uri);
  }

  Future<void> whatsappAc(String numara) async {
    final uri = Uri.parse(
      'https://wa.me/${whatsappNumarasi(numara)}',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  bool eslesiyor(Map<String, dynamic> data) {
    final kelime = arama.text.trim().toLowerCase();

    if (kelime.isEmpty) return true;

    final metin = [
      data['title'],
      data['category'],
      data['company'],
      data['city'],
      data['description'],
    ].map((e) => (e ?? '').toString().toLowerCase()).join(' ');

    return metin.contains(kelime);
  }

  @override
  void dispose() {
    arama.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('jobs')
        .where('status', isEqualTo: 'approved')
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('İş Ara')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('İlanlar yüklenemedi.'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ilanlar = snapshot.data!.docs
              .where((doc) => eslesiyor(doc.data()))
              .toList();

          ilanlar.sort((a, b) {
            final af = aktifOneCikan(a.data());
            final bf = aktifOneCikan(b.data());

            if (af == bf) return 0;
            return af ? -1 : 1;
          });

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: arama,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: 'İş ara',
                    hintText: 'Örnek: boya, şoför, Edremit',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: arama.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              arama.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: ilanlar.isEmpty
                    ? const Center(child: Text('Uygun ilan bulunamadı.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: ilanlar.length,
                        itemBuilder: (context, index) {
                          final belge = ilanlar[index];
                          final data = belge.data();

                          final telefon = bilgi(data['phone']);
                          final whatsapp = bilgi(data['whatsapp']);
                          final featured = aktifOneCikan(data);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (featured)
                                    Row(
                                      children: [
                                        const Icon(Icons.star),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'ÖNE ÇIKAN İLAN',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(kalanSure(data)),
                                      ],
                                    ),
                                  if (featured) const SizedBox(height: 8),
                                  Text(
                                    bilgi(data['title']),
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Kategori: ${bilgi(data['category'])}'),
                                  Text('Firma: ${bilgi(data['company'])}'),
                                  Text('Konum: ${bilgi(data['city'])}'),
                                  Text(
                                    'Ücret / Maaş: ${bilgi(data['salary'])}',
                                  ),
                                  const Divider(height: 24),
                                  Text(bilgi(data['description'])),
                                  const Divider(height: 24),
                                  Text('Telefon: $telefon'),
                                  Text('WhatsApp: $whatsapp'),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: telefon == 'Belirtilmemiş'
                                              ? null
                                              : () {
                                                  telefonAra(telefon);
                                                },
                                          icon: const Icon(Icons.phone),
                                          label: const Text('ARA'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: whatsapp == 'Belirtilmemiş'
                                              ? null
                                              : () {
                                                  whatsappAc(whatsapp);
                                                },
                                          icon: const Icon(Icons.chat),
                                          label: const Text('WHATSAPP'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => SikayetEtSayfasi(
                                              jobId: belge.id,
                                              jobTitle: bilgi(data['title']),
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.flag),
                                      label: const Text('ŞİKAYET ET'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SikayetEtSayfasi extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const SikayetEtSayfasi({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<SikayetEtSayfasi> createState() => _SikayetEtSayfasiState();
}

class _SikayetEtSayfasiState extends State<SikayetEtSayfasi> {
  final aciklama = TextEditingController();

  final nedenler = [
    'Sahte ilan',
    'Yanlış bilgi',
    'Uygunsuz içerik',
    'Dolandırıcılık şüphesi',
    'Spam / Tekrarlanan ilan',
    'Diğer',
  ];

  String? neden;
  bool bekle = false;

  Future<void> sikayetGonder() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      mesaj(context, 'Önce giriş yapmalısınız.');
      return;
    }

    if (neden == null) {
      mesaj(context, 'Şikayet nedenini seçin.');
      return;
    }

    setState(() {
      bekle = true;
    });

    try {
      await FirebaseFirestore.instance.collection('complaints').add({
        'jobId': widget.jobId,
        'jobTitle': widget.jobTitle,
        'reason': neden,
        'details': aciklama.text.trim(),
        'reporterUid': user.uid,
        'reporterEmail': user.email ?? '',
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        mesaj(context, 'Şikayet yöneticiye gönderildi.');
        Navigator.pop(context);
      }
    } catch (_) {
      mesaj(context, 'Şikayet gönderilemedi.');
    }

    if (mounted) {
      setState(() {
        bekle = false;
      });
    }
  }

  @override
  void dispose() {
    aciklama.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Şikayet Et')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Text(
                widget.jobTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: neden,
            decoration: const InputDecoration(
              labelText: 'Şikayet nedeni',
              border: OutlineInputBorder(),
            ),
            items: nedenler
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                neden = value;
              });
            },
          ),
          const SizedBox(height: 15),
          TextField(
            controller: aciklama,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Açıklama',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: bekle ? null : sikayetGonder,
            icon: const Icon(Icons.send),
            label: const Text('ŞİKAYETİ GÖNDER'),
          ),
        ],
      ),
    );
  }
}

class KendiIlanlarimSayfasi extends StatelessWidget {
  const KendiIlanlarimSayfasi({super.key});

  String durumYazisi(String durum) {
    if (durum == 'approved') return 'YAYINDA';
    if (durum == 'rejected') return 'REDDEDİLDİ';
    return 'ONAY BEKLİYOR';
  }

  Future<int?> paketSec(BuildContext context) async {
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ücretli Öne Çıkarma'),
          content: const Text(
            'İlanınızın öne çıkacağı paketi seçin.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 3),
              child: const Text('3 GÜN - 49 TL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 7),
              child: const Text('7 GÜN - 89 TL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 15),
              child: const Text('15 GÜN - 149 TL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 30),
              child: const Text('30 GÜN - 249 TL'),
            ),
          ],
        );
      },
    );
  }

  Future<void> oneCikarmaTalebi(
    BuildContext context,
    String jobId,
    Map<String, dynamic> data,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final gun = await paketSec(context);
    if (gun == null) return;

    final fiyat = paketFiyati(gun);

    try {
      final mevcut = await FirebaseFirestore.instance
          .collection('featuredRequests')
          .where('ownerUid', isEqualTo: user.uid)
          .get();

      final zatenVar = mevcut.docs.any((doc) {
        final d = doc.data();
        return d['jobId'] == jobId && d['status'] == 'pending';
      });

      if (zatenVar) {
        if (context.mounted) {
          mesaj(context, 'Bu ilan için zaten bekleyen talep var.');
        }
        return;
      }

      await FirebaseFirestore.instance.collection('featuredRequests').add({
        'jobId': jobId,
        'jobTitle': bilgi(data['title']),
        'ownerUid': user.uid,
        'ownerEmail': user.email ?? '',
        'days': gun,
        'price': fiyat,
        'packageName': '$gun Gün - $fiyat TL',
        'paymentStatus': 'not_paid',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        mesaj(
          context,
          '$gun günlük, $fiyat TL öne çıkarma paketi seçildi.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        mesaj(context, 'Talep gönderilemedi.');
      }
    }
  }

  Future<void> ilanSil(BuildContext context, String id) async {
    final cevap = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('İlanı Sil'),
          content: const Text('Bu ilanı silmek istediğine emin misin?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('VAZGEÇ'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('SİL'),
            ),
          ],
        );
      },
    );

    if (cevap != true) return;

    try {
      await FirebaseFirestore.instance.collection('jobs').doc(id).delete();

      if (context.mounted) {
        mesaj(context, 'İlan silindi.');
      }
    } catch (_) {
      if (context.mounted) {
        mesaj(context, 'İlan silinemedi.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Önce giriş yapmalısınız.')),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('jobs')
        .where('ownerUid', isEqualTo: user.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Kendi İlanlarım')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ilanlar = snapshot.data!.docs;

          if (ilanlar.isEmpty) {
            return const Center(child: Text('Henüz ilanınız yok.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: ilanlar.length,
            itemBuilder: (context, index) {
              final belge = ilanlar[index];
              final data = belge.data();
              final durum = bilgi(data['status']);
              final featured = aktifOneCikan(data);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bilgi(data['title']),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(durumYazisi(durum)),
                      if (featured) ...[
                        const SizedBox(height: 8),
                        Text('★ ÖNE ÇIKAN İLAN - ${kalanSure(data)}'),
                      ],
                      const SizedBox(height: 12),
                      if (durum == 'approved' && !featured)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              oneCikarmaTalebi(context, belge.id, data);
                            },
                            icon: const Icon(Icons.star),
                            label: const Text('ÜCRETLİ ÖNE ÇIKAR'),
                          ),
                        ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ilanSil(context, belge.id);
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('İLANI SİL'),
                        ),
                      ),
                    ],
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
      appBar: AppBar(title: const Text('Yönetim Paneli')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.work),
              title: const Text('İş İlanlarını Yönet'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BekleyenIlanlarSayfasi(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Kullanıcıları Yönet'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const KullanicilariYonetSayfasi(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Şikayetler'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SikayetlerSayfasi(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.monetization_on),
              title: const Text('Öne Çıkarma Talepleri'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OneCikarmaTalepleriSayfasi(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Öne Çıkan İlanlar'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OneCikanIlanlarSayfasi(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ayarlar'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AyarlarSayfasi(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AyarlarSayfasi extends StatefulWidget {
  const AyarlarSayfasi({super.key});

  @override
  State<AyarlarSayfasi> createState() => _AyarlarSayfasiState();
}

class _AyarlarSayfasiState extends State<AyarlarSayfasi> {
  bool bildirimler = true;
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    ayarlariYukle();
  }

  Future<void> ayarlariYukle() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      bildirimler = prefs.getBool('bildirimler') ?? true;
      yukleniyor = false;
    });
  }

  Future<void> bildirimDegistir(bool deger) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('bildirimler', deger);

    if (!mounted) return;

    setState(() {
      bildirimler = deger;
    });

    mesaj(
      context,
      deger ? 'Bildirimler açıldı.' : 'Bildirimler kapatıldı.',
    );
  }

  Future<void> sifreSifirla() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;

    if (email == null || email.isEmpty) {
      mesaj(context, 'Hesabınıza ait e-posta bulunamadı.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (mounted) {
        mesaj(
          context,
          'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        mesaj(context, e.message ?? 'E-posta gönderilemedi.');
      }
    } catch (_) {
      if (mounted) {
        mesaj(context, 'E-posta gönderilemedi.');
      }
    }
  }

  void metinAc(String baslik, String metin) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MetinSayfasi(
          baslik: baslik,
          metin: metin,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (yukleniyor) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Hesabım'),
              subtitle: Text(user?.email ?? 'E-posta bulunamadı'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('Şifremi Değiştir'),
              subtitle: const Text(
                'E-posta adresine şifre sıfırlama bağlantısı gönder',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: sifreSifirla,
            ),
          ),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications),
              title: const Text('Bildirimler'),
              subtitle: Text(
                bildirimler ? 'Bildirimler açık' : 'Bildirimler kapalı',
              ),
              value: bildirimler,
              onChanged: bildirimDegistir,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Gizlilik Politikası'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                metinAc(
                  'Gizlilik Politikası',
                  '''
İş Bul uygulaması kullanıcı gizliliğine önem verir.

Uygulama; hesap oluşturma, ilan yayınlama, ilan yönetimi ve iletişim özelliklerini sağlamak amacıyla gerekli kullanıcı bilgilerini işler.

Kullanıcıların e-posta adresleri hesap işlemleri için kullanılabilir.

İlanlarda kullanıcı tarafından eklenen telefon ve WhatsApp bilgileri, ilanla ilgilenen kişiler tarafından görülebilir.

Kullanıcı bilgileri izinsiz olarak üçüncü kişilere satılmaz.

Uygunsuz kullanım, sahte ilan ve güvenlik ihlallerine karşı gerekli kayıtlar tutulabilir.

Bu metin uygulama Play Store'a gönderilmeden önce nihai hukuki metinle güncellenecektir.
''',
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Kullanım Koşulları'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                metinAc(
                  'Kullanım Koşulları',
                  '''
İş Bul uygulamasını kullanan kişiler doğru ve güncel bilgi vermekle yükümlüdür.

Sahte, yanıltıcı, hukuka aykırı veya uygunsuz iş ilanları yayınlanamaz.

Kullanıcılar diğer kullanıcıları yanıltamaz veya dolandırıcılık amacıyla uygulamayı kullanamaz.

Yönetici, uygulama kurallarına aykırı ilanları kaldırabilir ve kullanıcı hesaplarını engelleyebilir.

İlanlarda yapılan iş teklifleri ve kullanıcılar arasındaki anlaşmalar tarafların kendi sorumluluğundadır.

Bu koşullar uygulamanın geliştirilme sürecinde güncellenebilir.
''',
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Uygulama Hakkında'),
              subtitle: const Text('İş Bul - Sürüm 0.4.0'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                metinAc(
                  'Uygulama Hakkında',
                  '''
İş Bul

İş arayanlarla işverenleri bir araya getirmek amacıyla geliştirilen iş ilanı uygulamasıdır.

Normal iş ilanı vermek ücretsizdir.

Kullanıcılar ilan arayabilir, işverenle telefon veya WhatsApp üzerinden iletişime geçebilir ve uygunsuz ilanları şikayet edebilir.

Uygulama geliştirme aşamasındadır.

Sürüm: 0.4.0
''',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MetinSayfasi extends StatelessWidget {
  final String baslik;
  final String metin;

  const MetinSayfasi({
    super.key,
    required this.baslik,
    required this.metin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(baslik),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          metin,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class OneCikarmaTalepleriSayfasi extends StatelessWidget {
  const OneCikarmaTalepleriSayfasi({super.key});

  Future<void> onayla(
    BuildContext context,
    String requestId,
    String jobId,
    int gun,
  ) async {
    try {
      final jobRef =
          FirebaseFirestore.instance.collection('jobs').doc(jobId);

      final jobDoc = await jobRef.get();

      if (!jobDoc.exists) {
        mesaj(context, 'İlan artık mevcut değil.');
        return;
      }

      final bitis = DateTime.now().add(Duration(days: gun));

      await jobRef.update({
        'featured': true,
        'featuredUntil': Timestamp.fromDate(bitis),
        'featuredDays': gun,
      });

      await FirebaseFirestore.instance
          .collection('featuredRequests')
          .doc(requestId)
          .update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        mesaj(context, 'İlan $gun gün öne çıkarıldı.');
      }
    } catch (_) {
      if (context.mounted) {
        mesaj(context, 'İşlem yapılamadı.');
      }
    }
  }

  Future<void> reddet(
    BuildContext context,
    String requestId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('featuredRequests')
          .doc(requestId)
          .update({
        'status': 'rejected',
      });

      if (context.mounted) {
        mesaj(context, 'Talep reddedildi.');
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('featuredRequests')
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Öne Çıkarma Talepleri')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final talepler = snapshot.data!.docs
              .where((doc) => doc.data()['status'] == 'pending')
              .toList();

          if (talepler.isEmpty) {
            return const Center(child: Text('Bekleyen talep yok.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: talepler.length,
            itemBuilder: (context, index) {
              final belge = talepler[index];
              final data = belge.data();

              final gun = data['days'] is int
                  ? data['days'] as int
                  : int.tryParse(data['days']?.toString() ?? '') ?? 3;

              final fiyat = data['price'] is int
                  ? data['price'] as int
                  : paketFiyati(gun);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bilgi(data['jobTitle']),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Paket: $gun Gün'),
                      Text('Fiyat: $fiyat TL'),
                      Text('Sahibi: ${bilgi(data['ownerEmail'])}'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                onayla(
                                  context,
                                  belge.id,
                                  bilgi(data['jobId']),
                                  gun,
                                );
                              },
                              child: const Text('ONAYLA'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                reddet(context, belge.id);
                              },
                              child: const Text('REDDET'),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class OneCikanIlanlarSayfasi extends StatelessWidget {
  const OneCikanIlanlarSayfasi({super.key});

  Future<void> degistir(
    BuildContext context,
    String id,
    bool featured,
  ) async {
    final ref = FirebaseFirestore.instance.collection('jobs').doc(id);

    try {
      if (featured) {
        await ref.update({
          'featured': false,
          'featuredUntil': FieldValue.delete(),
          'featuredDays': FieldValue.delete(),
        });
      } else {
        await ref.update({
          'featured': true,
          'featuredUntil': FieldValue.delete(),
          'featuredDays': FieldValue.delete(),
        });
      }
    } catch (_) {}

    if (context.mounted) {
      mesaj(
        context,
        featured ? 'Öne çıkarma kaldırıldı.' : 'İlan öne çıkarıldı.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('jobs')
        .where('status', isEqualTo: 'approved')
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Öne Çıkan İlanlar')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ilanlar = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: ilanlar.length,
            itemBuilder: (context, index) {
              final belge = ilanlar[index];
              final data = belge.data();
              final featured = aktifOneCikan(data);

              return Card(
                child: ListTile(
                  title: Text(bilgi(data['title'])),
                  subtitle: Text(
                    featured
                        ? 'Öne çıkan - ${kalanSure(data)}'
                        : 'Normal ilan',
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      degistir(context, belge.id, featured);
                    },
                    child: Text(
                      featured ? 'KALDIR' : 'ÖNE ÇIKAR',
                    ),
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

class KullanicilariYonetSayfasi extends StatelessWidget {
  const KullanicilariYonetSayfasi({super.key});

  Future<void> engelDegistir(
    BuildContext context,
    String uid,
    bool blocked,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'blocked': !blocked,
      });
    } catch (_) {}

    if (context.mounted) {
      mesaj(
        context,
        blocked ? 'Engel kaldırıldı.' : 'Kullanıcı engellendi.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream =
        FirebaseFirestore.instance.collection('users').snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Kullanıcıları Yönet')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final kullanicilar = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: kullanicilar.length,
            itemBuilder: (context, index) {
              final belge = kullanicilar[index];
              final data = belge.data();

              final blocked = data['blocked'] == true;
              final kendi =
                  belge.id == FirebaseAuth.instance.currentUser?.uid;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bilgi(data['email'])),
                      const SizedBox(height: 6),
                      Text(
                        kendi
                            ? 'Durum: YÖNETİCİ'
                            : blocked
                                ? 'Durum: ENGELLİ'
                                : 'Durum: AKTİF',
                      ),
                      const SizedBox(height: 10),
                      if (kendi)
                        const Text(
                          'YÖNETİCİ HESABI',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )
                      else
                        ElevatedButton(
                          onPressed: () {
                            engelDegistir(
                              context,
                              belge.id,
                              blocked,
                            );
                          },
                          child: Text(
                            blocked ? 'ENGELİ KALDIR' : 'ENGELLE',
                          ),
                        ),
                    ],
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

class SikayetlerSayfasi extends StatelessWidget {
  const SikayetlerSayfasi({super.key});

  Future<void> cozuldu(
    BuildContext context,
    String id,
  ) async {
    await FirebaseFirestore.instance
        .collection('complaints')
        .doc(id)
        .update({
      'status': 'resolved',
    });
  }

  Future<void> sil(
    BuildContext context,
    String id,
  ) async {
    await FirebaseFirestore.instance
        .collection('complaints')
        .doc(id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final stream =
        FirebaseFirestore.instance.collection('complaints').snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Şikayetler')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final liste = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: liste.length,
            itemBuilder: (context, index) {
              final belge = liste[index];
              final data = belge.data();

              final resolved = data['status'] == 'resolved';

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bilgi(data['jobTitle'])),
                      Text('Neden: ${bilgi(data['reason'])}'),
                      Text('Açıklama: ${bilgi(data['details'])}'),
                      Text('Bildiren: ${bilgi(data['reporterEmail'])}'),
                      Text(
                        resolved ? 'Durum: ÇÖZÜLDÜ' : 'Durum: AÇIK',
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: resolved
                                  ? null
                                  : () {
                                      cozuldu(context, belge.id);
                                    },
                              child: const Text('ÇÖZÜLDÜ'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                sil(context, belge.id);
                              },
                              child: const Text('SİL'),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class BekleyenIlanlarSayfasi extends StatelessWidget {
  const BekleyenIlanlarSayfasi({super.key});

  Future<void> durumDegistir(
    BuildContext context,
    String id,
    String durum,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(id)
          .update({
        'status': durum,
      });

      if (context.mounted) {
        mesaj(
          context,
          durum == 'approved'
              ? 'İlan onaylandı.'
              : 'İlan reddedildi.',
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('jobs')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Bekleyen İlanlar')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ilanlar = snapshot.data!.docs;

          if (ilanlar.isEmpty) {
            return const Center(
              child: Text('Onay bekleyen ilan yok.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: ilanlar.length,
            itemBuilder: (context, index) {
              final belge = ilanlar[index];
              final data = belge.data();

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bilgi(data['title']),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Kategori: ${bilgi(data['category'])}'),
                      Text('Firma: ${bilgi(data['company'])}'),
                      Text('Konum: ${bilgi(data['city'])}'),
                      Text('Maaş: ${bilgi(data['salary'])}'),
                      const SizedBox(height: 8),
                      Text(bilgi(data['description'])),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                durumDegistir(
                                  context,
                                  belge.id,
                                  'approved',
                                );
                              },
                              child: const Text('ONAYLA'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                durumDegistir(
                                  context,
                                  belge.id,
                                  'rejected',
                                );
                              },
                              child: const Text('REDDET'),
                            ),
                          ),
                        ],
                      ),
                    ],
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
