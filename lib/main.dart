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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
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

  final gun = fark.inDays;

  if (gun == 0) {
    return '1 günden az kaldı';
  }

  return '$gun gün kaldı';
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
      final ref =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

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

      yeniAdmin =
          adminDoc.exists && adminDoc.data()?['role'] == 'admin';
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
      MaterialPageRoute(
        builder: (_) => const GirisSayfasi(),
      ),
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
        body: Center(
          child: CircularProgressIndicator(),
        ),
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
                const Icon(
                  Icons.block,
                  size: 70,
                ),
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
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
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const KendiIlanlarimSayfasi(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list_alt),
                  label: const Text('KENDİ İLANLARIM'),
                ),
                const SizedBox(height: 15),
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
                    icon: const Icon(
                      Icons.admin_panel_settings,
                    ),
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
  State<GirisSayfasi> createState() =>
      _GirisSayfasiState();
}

class _GirisSayfasiState
    extends State<GirisSayfasi> {
  final email = TextEditingController();
  final sifre = TextEditingController();

  bool kayit = false;
  bool bekle = false;

  Future<void> kullaniciKaydiOlustur(
    User user,
  ) async {
    final ref =
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);

    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'blocked': false,
        'createdAt':
            FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> giris() async {
    if (email.text.trim().isEmpty ||
        sifre.text.trim().isEmpty) {
      mesaj(
        context,
        'E-posta ve şifreyi doldurun.',
      );
      return;
    }

    setState(() {
      bekle = true;
    });

    try {
      UserCredential sonuc;

      if (kayit) {
        sonuc = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: sifre.text.trim(),
        );
      } else {
        sonuc = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: email.text.trim(),
          password: sifre.text.trim(),
        );
      }

      if (sonuc.user != null) {
        try {
          await kullaniciKaydiOlustur(
            sonuc.user!,
          );
        } catch (_) {}
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      mesaj(
        context,
        e.message ?? 'İşlem yapılamadı.',
      );
    } catch (_) {
      mesaj(
        context,
        'Bir hata oluştu.',
      );
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
        title:
            Text(kayit ? 'Kayıt Ol' : 'Giriş Yap'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: email,
            keyboardType:
                TextInputType.emailAddress,
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
            child: Text(
              kayit
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
  State<IlanVerSayfasi> createState() =>
      _IlanVerSayfasiState();
}

class _IlanVerSayfasiState
    extends State<IlanVerSayfasi> {
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
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      mesaj(
        context,
        'Önce giriş yapmalısınız.',
      );
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
      mesaj(
        context,
        'Bütün alanları doldurun.',
      );
      return;
    }

    setState(() {
      bekle = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .add({
        'title': baslik.text.trim(),
        'company': firma.text.trim(),
        'city': konum.text.trim(),
        'category': kategori,
        'phone': telefon.text.trim(),
        'whatsapp': whatsapp.text.trim(),
        'salary': ucret.text.trim(),
        'description':
            aciklama.text.trim(),
        'ownerUid': user.uid,
        'ownerEmail': user.email ?? '',
        'status': 'pending',
        'featured': false,
        'createdAt':
            FieldValue.serverTimestamp(),
      });

      if (mounted) {
        mesaj(
          context,
          'İlan yönetici onayına gönderildi.',
        );
        Navigator.pop(context);
      }
    } catch (_) {
      mesaj(
        context,
        'İlan gönderilemedi.',
      );
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
      appBar: AppBar(
        title: const Text(
          'İş İlanı Ver',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: baslik,
            decoration:
                const InputDecoration(
              labelText: 'İş başlığı',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: kategori,
            decoration:
                const InputDecoration(
              labelText:
                  'Meslek / Kategori',
              border: OutlineInputBorder(),
            ),
            items: kategoriler
                .map(
                  (item) =>
                      DropdownMenuItem<
                          String>(
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
            decoration:
                const InputDecoration(
              labelText:
                  'Firma / İşveren',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: konum,
            decoration:
                const InputDecoration(
              labelText: 'Şehir / İlçe',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: telefon,
            keyboardType:
                TextInputType.phone,
            decoration:
                const InputDecoration(
              labelText:
                  'Telefon numarası',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: whatsapp,
            keyboardType:
                TextInputType.phone,
            decoration:
                const InputDecoration(
              labelText:
                  'WhatsApp numarası',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ucret,
            decoration:
                const InputDecoration(
              labelText:
                  'Ücret / Maaş',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: aciklama,
            maxLines: 5,
            decoration:
                const InputDecoration(
              labelText:
                  'İlan açıklaması',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed:
                bekle ? null : gonder,
            icon: const Icon(Icons.send),
            label: Text(
              bekle
                  ? 'GÖNDERİLİYOR...'
                  : 'İLANI ONAYA GÖNDER',
            ),
          ),
        ],
      ),
    );
  }
}

class IsAraSayfasi
    extends StatefulWidget {
  const IsAraSayfasi({super.key});

  @override
  State<IsAraSayfasi> createState() =>
      _IsAraSayfasiState();
}

class _IsAraSayfasiState
    extends State<IsAraSayfasi> {
  final arama = TextEditingController();

  String sadeceRakam(String numara) {
    return numara.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
  }

  String whatsappNumarasi(
    String numara,
  ) {
    String rakam =
        sadeceRakam(numara);

    if (rakam.startsWith('0')) {
      rakam =
          '90${rakam.substring(1)}';
    } else if (!rakam.startsWith('90')) {
      rakam = '90$rakam';
    }

    return rakam;
  }

  Future<void> telefonAra(
    String numara,
  ) async {
    final uri = Uri(
      scheme: 'tel',
      path: sadeceRakam(numara),
    );

    await launchUrl(uri);
  }

  Future<void> whatsappAc(
    String numara,
  ) async {
    final uri = Uri.parse(
      'https://wa.me/${whatsappNumarasi(numara)}',
    );

    await launchUrl(
      uri,
      mode:
          LaunchMode.externalApplication,
    );
  }

  bool eslesiyor(
    Map<String, dynamic> data,
  ) {
    final kelime =
        arama.text.trim().toLowerCase();

    if (kelime.isEmpty) {
      return true;
    }

    final metin = [
      data['title'],
      data['category'],
      data['company'],
      data['city'],
      data['description'],
    ].map(
      (e) =>
          (e ?? '')
              .toString()
              .toLowerCase(),
    ).join(' ');

    return metin.contains(kelime);
  }

  @override
  void dispose() {
    arama.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stream =
        FirebaseFirestore.instance
            .collection('jobs')
            .where(
              'status',
              isEqualTo: 'approved',
            )
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('İş Ara'),
      ),
      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'İlanlar yüklenemedi.',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final ilanlar =
              snapshot.data!.docs
                  .where(
                    (doc) =>
                        eslesiyor(
                      doc.data(),
                    ),
                  )
                  .toList();

          ilanlar.sort((a, b) {
            final af =
                aktifOneCikan(a.data());
            final bf =
                aktifOneCikan(b.data());

            if (af == bf) {
              return 0;
            }

            return af ? -1 : 1;
          });

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                child: TextField(
                  controller: arama,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration:
                      InputDecoration(
                    labelText: 'İş ara',
                    hintText:
                        'Örnek: boya, şoför, Edremit',
                    prefixIcon:
                        const Icon(
                      Icons.search,
                    ),
                    suffixIcon:
                        arama.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed:
                                    () {
                                  arama
                                      .clear();
                                  setState(
                                      () {});
                                },
                                icon:
                                    const Icon(
                                  Icons.clear,
                                ),
                              ),
                    border:
                        const OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: ilanlar.isEmpty
                    ? const Center(
                        child: Text(
                          'Uygun ilan bulunamadı.',
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets
                                .all(12),
                        itemCount:
                            ilanlar.length,
                        itemBuilder:
                            (context,
                                index) {
                          final belge =
                              ilanlar[
                                  index];

                          final data =
                              belge.data();

                          final telefon =
                              bilgi(
                            data['phone'],
                          );

                          final whatsapp =
                              bilgi(
                            data[
                                'whatsapp'],
                          );

                          final featured =
                              aktifOneCikan(
                            data,
                          );

                          return Card(
                            margin:
                                const EdgeInsets
                                    .only(
                              bottom: 12,
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets
                                      .all(
                                15,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  if (featured)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons
                                              .star,
                                        ),
                                        const SizedBox(
                                          width:
                                              6,
                                        ),
                                        const Text(
                                          'ÖNE ÇIKAN İLAN',
                                          style:
                                              TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          kalanSure(
                                            data,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (featured)
                                    const SizedBox(
                                      height: 8,
                                    ),
                                  Text(
                                    bilgi(
                                      data[
                                          'title'],
                                    ),
                                    style:
                                        const TextStyle(
                                      fontSize:
                                          19,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Text(
                                    'Kategori: ${bilgi(data['category'])}',
                                  ),
                                  Text(
                                    'Firma: ${bilgi(data['company'])}',
                                  ),
                                  Text(
                                    'Konum: ${bilgi(data['city'])}',
                                  ),
                                  Text(
                                    'Ücret / Maaş: ${bilgi(data['salary'])}',
                                  ),
                                  const Divider(
                                    height: 24,
                                  ),
                                  Text(
                                    bilgi(
                                      data[
                                          'description'],
                                    ),
                                  ),
                                  const Divider(
                                    height: 24,
                                  ),
                                  Text(
                                    'Telefon: $telefon',
                                  ),
                                  Text(
                                    'WhatsApp: $whatsapp',
                                  ),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child:
                                            ElevatedButton
                                                .icon(
                                          onPressed:
                                              telefon ==
                                                      'Belirtilmemiş'
                                                  ? null
                                                  : () {
                                                      telefonAra(
                                                        telefon,
                                                      );
                                                    },
                                          icon:
                                              const Icon(
                                            Icons
                                                .phone,
                                          ),
                                          label:
                                              const Text(
                                            'ARA',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      Expanded(
                                        child:
                                            ElevatedButton
                                                .icon(
                                          onPressed:
                                              whatsapp ==
                                                      'Belirtilmemiş'
                                                  ? null
                                                  : () {
                                                      whatsappAc(
                                                        whatsapp,
                                                      );
                                                    },
                                          icon:
                                              const Icon(
                                            Icons
                                                .chat,
                                          ),
                                          label:
                                              const Text(
                                            'WHATSAPP',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  SizedBox(
                                    width: double
                                        .infinity,
                                    child:
                                        OutlinedButton
                                            .icon(
                                      onPressed:
                                          () {
                                        Navigator
                                            .push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    SikayetEtSayfasi(
                                              jobId:
                                                  belge.id,
                                              jobTitle:
                                                  bilgi(
                                                data['title'],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      icon:
                                          const Icon(
                                        Icons.flag,
                                      ),
                                      label:
                                          const Text(
                                        'ŞİKAYET ET',
                                      ),
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

class SikayetEtSayfasi
    extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const SikayetEtSayfasi({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<SikayetEtSayfasi>
      createState() =>
          _SikayetEtSayfasiState();
}

class _SikayetEtSayfasiState
    extends State<SikayetEtSayfasi> {
  final aciklama =
      TextEditingController();

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
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      mesaj(
        context,
        'Önce giriş yapmalısınız.',
      );
      return;
    }

    if (neden == null) {
      mesaj(
        context,
        'Şikayet nedenini seçin.',
      );
      return;
    }

    setState(() {
      bekle = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .add({
        'jobId': widget.jobId,
        'jobTitle': widget.jobTitle,
        'reason': neden,
        'details':
            aciklama.text.trim(),
        'reporterUid': user.uid,
        'reporterEmail':
            user.email ?? '',
        'status': 'open',
        'createdAt':
            FieldValue.serverTimestamp(),
      });

      if (mounted) {
        mesaj(
          context,
          'Şikayet yöneticiye gönderildi.',
        );
        Navigator.pop(context);
      }
    } catch (_) {
      mesaj(
        context,
        'Şikayet gönderilemedi.',
      );
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
      appBar: AppBar(
        title:
            const Text('Şikayet Et'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                15,
              ),
              child: Text(
                widget.jobTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: neden,
            decoration:
                const InputDecoration(
              labelText:
                  'Şikayet nedeni',
              border: OutlineInputBorder(),
            ),
            items: nedenler
                .map(
                  (item) =>
                      DropdownMenuItem<
                          String>(
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
            decoration:
                const InputDecoration(
              labelText:
                  'Açıklama (isteğe bağlı)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed:
                bekle
                    ? null
                    : sikayetGonder,
            icon: const Icon(Icons.send),
            label: Text(
              bekle
                  ? 'GÖNDERİLİYOR...'
                  : 'ŞİKAYETİ GÖNDER',
            ),
          ),
        ],
      ),
    );
  }
}

class KendiIlanlarimSayfasi
    extends StatelessWidget {
  const KendiIlanlarimSayfasi({
    super.key,
  });

  String durumYazisi(
    String durum,
  ) {
    if (durum == 'approved') {
      return 'YAYINDA';
    }

    if (durum == 'rejected') {
      return 'REDDEDİLDİ';
    }

    return 'ONAY BEKLİYOR';
  }

  Future<int?> paketSec(
    BuildContext context,
  ) async {
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Öne Çıkarma Paketi',
          ),
          content: const Text(
            'İlanın kaç gün öne çıksın?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  3,
                );
              },
              child:
                  const Text('3 GÜN'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  7,
                );
              },
              child:
                  const Text('7 GÜN'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  15,
                );
              },
              child:
                  const Text('15 GÜN'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  30,
                );
              },
              child:
                  const Text('30 GÜN'),
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
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      mesaj(
        context,
        'Önce giriş yapmalısınız.',
      );
      return;
    }

    final gun =
        await paketSec(context);

    if (gun == null) {
      return;
    }

    try {
      final mevcut =
          await FirebaseFirestore.instance
              .collection(
                'featuredRequests',
              )
              .where(
                'ownerUid',
                isEqualTo: user.uid,
              )
              .get();

      final zatenVar =
          mevcut.docs.any((doc) {
        final d = doc.data();

        return d['jobId'] == jobId &&
            d['status'] == 'pending';
      });

      if (zatenVar) {
        if (context.mounted) {
          mesaj(
            context,
            'Bu ilan için zaten bekleyen bir talep var.',
          );
        }
        return;
      }

      await FirebaseFirestore.instance
          .collection(
            'featuredRequests',
          )
          .add({
        'jobId': jobId,
        'jobTitle':
            bilgi(data['title']),
        'ownerUid': user.uid,
        'ownerEmail':
            user.email ?? '',
        'days': gun,
        'packageName': '$gun Gün',
        'status': 'pending',
        'createdAt':
            FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        mesaj(
          context,
          '$gun günlük öne çıkarma talebi gönderildi.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        mesaj(
          context,
          'Öne çıkarma talebi gönderilemedi.',
        );
      }
    }
  }

  Future<void> ilanSil(
    BuildContext context,
    String id,
  ) async {
    final cevap =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text('İlanı Sil'),
          content: const Text(
            'Bu ilanı silmek istediğine emin misin?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text('VAZGEÇ'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text('SİL'),
            ),
          ],
        );
      },
    );

    if (cevap != true) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(id)
          .delete();

      if (context.mounted) {
        mesaj(
          context,
          'İlan silindi.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        mesaj(
          context,
          'İlan silinemedi.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Önce giriş yapmalısınız.',
          ),
        ),
      );
    }

    final stream =
        FirebaseFirestore.instance
            .collection('jobs')
            .where(
              'ownerUid',
              isEqualTo: user.uid,
            )
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Kendi İlanlarım'),
      ),
      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'İlanlar yüklenemedi.',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final ilanlar =
              snapshot.data!.docs;

          if (ilanlar.isEmpty) {
            return const Center(
              child: Text(
                'Henüz verdiğiniz ilan yok.',
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(12),
            itemCount: ilanlar.length,
            itemBuilder:
                (context, index) {
              final belge =
                  ilanlar[index];

              final data =
                  belge.data();

              final durum =
                  bilgi(data['status']);

              final featured =
                  aktifOneCikan(data);

              return Card(
                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    15,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        bilgi(
                          data['title'],
                        ),
                        style:
                            const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        durumYazisi(
                          durum,
                        ),
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      if (featured) ...[
                        const SizedBox(
                          height: 8,
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                            ),
                            const SizedBox(
                              width: 6,
                            ),
                            const Text(
                              'ÖNE ÇIKAN İLAN',
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              kalanSure(
                                data,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(
                        height: 24,
                      ),
                      Text(
                        'Kategori: ${bilgi(data['category'])}',
                      ),
                      Text(
                        'Firma: ${bilgi(data['company'])}',
                      ),
                      Text(
                        'Konum: ${bilgi(data['city'])}',
                      ),
                      Text(
                        'Ücret / Maaş: ${bilgi(data['salary'])}',
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        bilgi(
                          data['description'],
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      if (durum ==
                              'approved' &&
                          !featured)
                        SizedBox(
                          width:
                              double.infinity,
                          child:
                              ElevatedButton
                                  .icon(
                            onPressed: () {
                              oneCikarmaTalebi(
                                context,
                                belge.id,
                                data,
                              );
                            },
                            icon: const Icon(
                              Icons.star,
                            ),
                            label:
                                const Text(
                              'ÖNE ÇIKARMA TALEBİ GÖNDER',
                            ),
                          ),
                        ),
                      if (durum ==
                              'approved' &&
                          !featured)
                        const SizedBox(
                          height: 8,
                        ),
                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            OutlinedButton
                                .icon(
                          onPressed: () {
                            ilanSil(
                              context,
                              belge.id,
                            );
                          },
                          icon: const Icon(
                            Icons.delete,
                          ),
                          label:
                              const Text(
                            'İLANI SİL',
                          ),
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

class YonetimPaneli
    extends StatelessWidget {
  const YonetimPaneli({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Yönetim Paneli'),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons
                        .admin_panel_settings,
                    size: 45,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Yönetici hesabı',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
              trailing: const Icon(
                Icons.arrow_forward_ios,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const BekleyenIlanlarSayfasi(),
                  ),
                );
              },
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
                'Kullanıcıları görüntüle ve engelle',
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const KullanicilariYonetSayfasi(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.report),
              title:
                  const Text('Şikayetler'),
              subtitle: const Text(
                'Kullanıcı şikayetlerini görüntüle',
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const SikayetlerSayfasi(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.monetization_on,
              ),
              title: const Text(
                'Öne Çıkarma Talepleri',
              ),
              subtitle: const Text(
                '3 / 7 / 15 / 30 günlük talepleri yönet',
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const OneCikarmaTalepleriSayfasi(),
                  ),
                );
              },
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
                'İlanları manuel olarak yönet',
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const OneCikanIlanlarSayfasi(),
                  ),
                );
              },
            ),
          ),
          const Card(
            child: ListTile(
              leading:
                  Icon(Icons.settings),
              title:
                  Text('Ayarlar'),
            ),
          ),
        ],
      ),
    );
  }
}

class OneCikarmaTalepleriSayfasi
    extends StatelessWidget {
  const OneCikarmaTalepleriSayfasi({
    super.key,
  });

  Future<void> onayla(
    BuildContext context,
    String requestId,
    String jobId,
    int gun,
  ) async {
    try {
      final jobRef =
          FirebaseFirestore.instance
              .collection('jobs')
              .doc(jobId);

      final jobDoc =
          await jobRef.get();

      if (!jobDoc.exists) {
        mesaj(
          context,
          'İlan artık mevcut değil.',
        );

        await FirebaseFirestore.instance
            .collection(
              'featuredRequests',
            )
            .doc(requestId)
            .update({
          'status': 'rejected',
        });

        return;
      }

      final bitis =
          DateTime.now().add(
        Duration(days: gun),
      );

      await jobRef.update({
        'featured': true,
        'featuredUntil':
            Timestamp.fromDate(bitis),
        'featuredDays': gun,
      });

      await FirebaseFirestore.instance
          .collection(
            'featuredRequests',
          )
          .doc(requestId)
          .update({
        'status': 'approved',
        'approvedAt':
            FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        mesaj(
          context,
          'Talep onaylandı. İlan $gun gün öne çıkarıldı.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        mesaj(
          context,
          'İşlem yapılamadı.',
        );
      }
    }
  }

  Future<void> reddet(
    BuildContext context,
    String requestId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection(
            'featuredRequests',
          )
          .doc(requestId)
          .update({
        'status': 'rejected',
      });

      if (context.mounted) {
        mesaj(
          context,
          'Öne çıkarma talebi reddedildi.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        mesaj(
          context,
          'İşlem yapılamadı.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream =
        FirebaseFirestore.instance
            .collection(
              'featuredRequests',
            )
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Öne Çıkarma Talepleri',
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Talepler yüklenemedi.',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final talepler =
              snapshot.data!.docs
                  .where(
                    (doc) =>
                        doc.data()[
                            'status'] ==
                        'pending',
                  )
                  .toList();

          if (talepler.isEmpty) {
            return const Center(
              child: Text(
                'Bekleyen öne çıkarma talebi yok.',
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(
              12,
            ),
            itemCount: talepler.length,
            itemBuilder:
                (context, index) {
              final belge =
                  talepler[index];

              final data =
                  belge.data();

              final gun =
                  data['days'] is int
                      ? data['days']
                          as int
                      : int.tryParse(
                            data['days']
                                    ?.toString() ??
                                '',
                          ) ??
                          3;

              return Card(
                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    15,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        bilgi(
                          data['jobTitle'],
                        ),
                        style:
                            const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        'Talep sahibi: ${bilgi(data['ownerEmail'])}',
                      ),
                      const SizedBox(
                        height: 6,
                      ),
                      Text(
                        'Paket: $gun GÜN',
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 6,
                      ),
                      const Text(
                        'Durum: ONAY BEKLİYOR',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child:
                                ElevatedButton
                                    .icon(
                              onPressed: () {
                                onayla(
                                  context,
                                  belge.id,
                                  bilgi(
                                    data[
                                        'jobId'],
                                  ),
                                  gun,
                                );
                              },
                              icon:
                                  const Icon(
                                Icons.check,
                              ),
                              label:
                                  const Text(
                                'ONAYLA',
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child:
                                OutlinedButton
                                    .icon(
                              onPressed: () {
                                reddet(
                                  context,
                                  belge.id,
                                );
                              },
                              icon:
                                  const Icon(
                                Icons.close,
                              ),
                              label:
                                  const Text(
                                'REDDET',
                              ),
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

class OneCikanIlanlarSayfasi
    extends StatelessWidget {
  const OneCikanIlanlarSayfasi({
    super.key,
  });

  Future<void> oneCikarDegistir(
    BuildContext context,
    String id,
    bool featured,
  ) async {
    try {
      final ref =
          FirebaseFirestore.instance
              .collection('jobs')
              .doc(id);

      if (featured) {
        await ref.update({
          'featured': false,
          'featuredUntil':
              FieldValue.delete(),
          'featuredDays':
              FieldValue.delete(),
        });
      } else {
        await ref.update({
          'featured': true,
          'featuredUntil':
              FieldValue.delete(),
          'featuredDays':
              FieldValue.delete(),
        });
      }

      if (context.mounted) {
        mesaj(
          context,
          featured
              ? 'Öne çıkarma kaldırıldı.'
              : 'İlan manuel olarak öne çıkarıldı.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        mesaj(
          context,
          'İşlem yapılamadı.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream =
        FirebaseFirestore.instance
            .collection('jobs')
            .where(
              'status',
              isEqualTo: 'approved',
            )
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Öne Çıkan İlanlar',
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'İlanlar yüklenemedi.',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final ilanlar =
              snapshot.data!.docs;

          if (ilanlar.isEmpty) {
            return const Center(
              child: Text(
                'Yayında ilan yok.',
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(
              12,
            ),
            itemCount: ilanlar.length,
            itemBuilder:
                (context, index) {
              final belge =
                  ilanlar[index];

              final data =
                  belge.data();

              final featured =
                  aktifOneCikan(data);

              return Card(
                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    15,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            featured
                                ? Icons.star
                                : Icons
                                    .star_border,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child: Text(
                              bilgi(
                                data['title'],
                              ),
                              style:
                                  const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        'Firma: ${bilgi(data['company'])}',
                      ),
                      Text(
                        'Konum: ${bilgi(data['city'])}',
                      ),
                      Text(
                        'Kategori: ${bilgi(data['category'])}',
                      ),
                      if (featured) ...[
                        const SizedBox(
                          height: 6,
                        ),
                        Text(
                          'Kalan süre: ${kalanSure(data)}',
                        ),
                      ],
                      const SizedBox(
                        height: 12,
                      ),
                      SizedBox(
                        width:
                            double.infinity,
                        child: featured
                            ? OutlinedButton
                                .icon(
                                onPressed:
                                    () {
                                  oneCikarDegistir(
                                    context,
                                    belge.id,
                                    true,
                                  );
                                },
                                icon:
                                    const Icon(
                                  Icons
                                      .star_border,
                                ),
                                label:
                                    const Text(
                                  'ÖNE ÇIKARMAYI KALDIR',
                                ),
                              )
                            : ElevatedButton
                                .icon(
                                onPressed:
                                    () {
                                  oneCikarDegistir(
                                    context,
                                    belge.id,
                                    false,
                                  );
                                },
                                icon:
                                    const Icon(
                                  Icons.star,
                                ),
                                label:
                                    const Text(
                                  'ÖNE ÇIKAR',
                                ),
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

class KullanicilariYonetSayfasi
    extends StatelessWidget {
  const KullanicilariYonetSayfasi({
    super.key,
  });

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

      if (context.mounted) {
        mesaj(
          context,
          blocked
              ? 'Kullanıcının engeli kaldırıldı.'
              : 'Kullanıcı engellendi.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        mesaj(
          context,
          'İşlem yapılamadı.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream =
        FirebaseFirestore.instance
            .collection('users')
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kullanıcıları Yönet',
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Kullanıcılar yüklenemedi.',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final kullanicilar =
              snapshot.data!.docs;

          if (kullanicilar.isEmpty) {
            return const Center(
              child: Text(
                'Henüz kullanıcı kaydı yok.',
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(
              12,
            ),
            itemCount:
                kullanicilar.length,
            itemBuilder:
                (context, index) {
              final belge =
                  kullanicilar[index];

              final data =
                  belge.data();

              final email =
                  bilgi(data['email']);

              final blocked =
                  data['blocked'] == true;

              final kendiHesabin =
                  belge.id ==
                      FirebaseAuth
                          .instance
                          .currentUser
                          ?.uid;

              return Card(
                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    15,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        email,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        kendiHesabin
                            ? 'Durum: YÖNETİCİ'
                            : blocked
                                ? 'Durum: ENGELLİ'
                                : 'Durum: AKTİF',
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      SizedBox(
                        width:
                            double.infinity,
                        child: kendiHesabin
                            ? const Center(
                                child: Text(
                                  'YÖNETİCİ HESABI',
                                  style:
                                      TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              )
                            : blocked
                                ? ElevatedButton
                                    .icon(
                                    onPressed:
                                        () {
                                      engelDegistir(
                                        context,
                                        belge.id,
                                        true,
                                      );
                                    },
                                    icon:
                                        const Icon(
                                      Icons
                                          .lock_open,
                                    ),
                                    label:
                                        const Text(
                                      'ENGELİ KALDIR',
                                    ),
                                  )
                                : OutlinedButton
                                    .icon(
                                    onPressed:
                                        () {
                                      engelDegistir(
                                        context,
                                        belge.id,
                                        false,
                                      );
                                    },
                                    icon:
                                        const Icon(
                                      Icons.block,
                                    ),
                                    label:
                                        const Text(
                                      'ENGELLE',
                                    ),
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

class SikayetlerSayfasi
    extends StatelessWidget {
  const SikayetlerSayfasi({
    super.key,
  });

  Future<void> cozulduYap(
    BuildContext context,
    String id,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(id)
          .update({
        'status': 'resolved',
      });

      if (context.mounted) {
        mesaj(
          context,
          'Şikayet çözüldü.',
        );
      }
    } catch (_) {}
  }

  Future<void> sikayetSil(
    BuildContext context,
    String id,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(id)
          .delete();

      if (context.mounted) {
        mesaj(
          context,
          'Şikayet silindi.',
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final stream =
        FirebaseFirestore.instance
            .collection('complaints')
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Şikayetler'),
      ),
      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Şikayetler yüklenemedi.',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final sikayetler =
              snapshot.data!.docs;

          if (sikayetler.isEmpty) {
            return const Center(
              child: Text(
                'Henüz şikayet yok.',
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(
              12,
            ),
            itemCount:
                sikayetler.length,
            itemBuilder:
                (context, index) {
              final belge =
                  sikayetler[index];

              final data =
                  belge.data();

              final durum =
                  bilgi(data['status']);

              return Card(
                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    15,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        bilgi(
                          data[
                              'jobTitle'],
                        ),
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        'Neden: ${bilgi(data['reason'])}',
                      ),
                      Text(
                        'Açıklama: ${bilgi(data['details'])}',
                      ),
                      Text(
                        'Bildiren: ${bilgi(data['reporterEmail'])}',
                      ),
                      Text(
                        durum ==
                                'resolved'
                            ? 'Durum: ÇÖZÜLDÜ'
                            : 'Durum: AÇIK',
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child:
                                ElevatedButton
                                    .icon(
                              onPressed:
                                  durum ==
                                          'resolved'
                                      ? null
                                      : () {
                                          cozulduYap(
                                            context,
                                            belge.id,
                                          );
                                        },
                              icon:
                                  const Icon(
                                Icons.check,
                              ),
                              label:
                                  const Text(
                                'ÇÖZÜLDÜ',
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child:
                                OutlinedButton
                                    .icon(
                              onPressed: () {
                                sikayetSil(
                                  context,
                                  belge.id,
                                );
                              },
                              icon:
                                  const Icon(
                                Icons.delete,
                              ),
                              label:
                                  const Text(
                                'SİL',
                              ),
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

class BekleyenIlanlarSayfasi
    extends StatelessWidget {
  const BekleyenIlanlarSayfasi({
    super.key,
  });

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
    final stream =
        FirebaseFirestore.instance
            .collection('jobs')
            .where(
              'status',
              isEqualTo: 'pending',
            )
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bekleyen İlanlar',
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'İlanlar yüklenemedi.',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final ilanlar =
              snapshot.data!.docs;

          if (ilanlar.isEmpty) {
            return const Center(
              child: Text(
                'Onay bekleyen ilan yok.',
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(
              12,
            ),
            itemCount: ilanlar.length,
            itemBuilder:
                (context, index) {
              final belge =
                  ilanlar[index];

              final data =
                  belge.data();

              return Card(
                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    15,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        bilgi(
                          data['title'],
                        ),
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        'Kategori: ${bilgi(data['category'])}',
                      ),
                      Text(
                        'Firma: ${bilgi(data['company'])}',
                      ),
                      Text(
                        'Konum: ${bilgi(data['city'])}',
                      ),
                      Text(
                        'Ücret / Maaş: ${bilgi(data['salary'])}',
                      ),
                      Text(
                        'Telefon: ${bilgi(data['phone'])}',
                      ),
                      Text(
                        'WhatsApp: ${bilgi(data['whatsapp'])}',
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        bilgi(
                          data[
                              'description'],
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child:
                                ElevatedButton
                                    .icon(
                              onPressed: () {
                                durumDegistir(
                                  context,
                                  belge.id,
                                  'approved',
                                );
                              },
                              icon:
                                  const Icon(
                                Icons.check,
                              ),
                              label:
                                  const Text(
                                'ONAYLA',
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child:
                                OutlinedButton
                                    .icon(
                              onPressed: () {
                                durumDegistir(
                                  context,
                                  belge.id,
                                  'rejected',
                                );
                              },
                              icon:
                                  const Icon(
                                Icons.close,
                              ),
                              label:
                                  const Text(
                                'REDDET',
                              ),
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
