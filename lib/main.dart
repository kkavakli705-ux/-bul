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
      MaterialPageRoute(builder: (_) => const GirisSayfasi()),
    );

    if (mounted) {
      setState(() {
        kontrol = true;
      });
    }

    await adminKontrol();
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
                  label: const Text('İŞ İLANI VER'),
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

                const SizedBox(height: 15),

                if (kontrol)
                  const Center(child: CircularProgressIndicator()),

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

  void mesaj(String yazi) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(yazi)),
    );
  }

  Future<void> giris() async {
    if (email.text.trim().isEmpty || sifre.text.trim().isEmpty) {
      mesaj('E-posta ve şifreyi doldurun.');
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

      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      mesaj(e.message ?? 'İşlem yapılamadı.');
    } catch (_) {
      mesaj('Bir hata oluştu.');
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

  void mesaj(String yazi) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(yazi)),
    );
  }

  Future<void> gonder() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      mesaj('Önce giriş yapmalısınız.');
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
      appBar: AppBar(title: const Text('İş İlanı Ver')),
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

          DropdownButtonFormField<String>(
            value: kategori,
            decoration: const InputDecoration(
              labelText: 'Meslek / Kategori',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: kategoriler
                .map(
                  (item) => DropdownMenuItem(
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
              prefixIcon: Icon(Icons.phone),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: whatsapp,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'WhatsApp numarası',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.chat),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: ucret,
            decoration: const InputDecoration(
              labelText: 'Ücret / Maaş',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.payments),
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

class IsAraSayfasi extends StatefulWidget {
  const IsAraSayfasi({super.key});

  @override
  State<IsAraSayfasi> createState() => _IsAraSayfasiState();
}

class _IsAraSayfasiState extends State<IsAraSayfasi> {
  final arama = TextEditingController();

  String bilgi(dynamic deger) {
    final yazi = deger?.toString().trim() ?? '';
    return yazi.isEmpty ? 'Belirtilmemiş' : yazi;
  }

  String sadeceRakam(String numara) {
    return numara.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String whatsappNumarasi(String numara) {
    var rakam = sadeceRakam(numara);

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
            return const Center(
              child: Text('İlanlar yüklenemedi.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final ilanlar = snapshot.data!.docs
              .where((doc) => eslesiyor(doc.data()))
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: arama,
                  onChanged: (_) => setState(() {}),
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
                    ? const Center(
                        child: Text('Uygun ilan bulunamadı.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: ilanlar.length,
                        itemBuilder: (context, index) {
                          final data = ilanlar[index].data();

                          final telefon = bilgi(data['phone']);
                          final whatsapp = bilgi(data['whatsapp']);

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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Divider(height: 24),
                                  Text(
                                    bilgi(data['description']),
                                  ),
                                  const Divider(height: 24),
                                  Text('Telefon: $telefon'),
                                  Text('WhatsApp: $whatsapp'),
                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              telefon == 'Belirtilmemiş'
                                                  ? null
                                                  : () => telefonAra(telefon),
                                          icon: const Icon(Icons.phone),
                                          label: const Text('ARA'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              whatsapp == 'Belirtilmemiş'
                                                  ? null
                                                  : () =>
                                                      whatsappAc(whatsapp),
                                          icon: const Icon(Icons.chat),
                                          label: const Text('WHATSAPP'),
                                        ),
                                      ),
                                    ],
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

class KendiIlanlarimSayfasi extends StatelessWidget {
  const KendiIlanlarimSayfasi({super.key});

  String bilgi(dynamic deger) {
    final yazi = deger?.toString().trim() ?? '';
    return yazi.isEmpty ? 'Belirtilmemiş' : yazi;
  }

  String durumYazisi(String durum) {
    if (durum == 'approved') {
      return 'YAYINDA';
    }

    if (durum == 'rejected') {
      return 'REDDEDİLDİ';
    }

    return 'ONAY BEKLİYOR';
  }

  IconData durumIkonu(String durum) {
    if (durum == 'approved') {
      return Icons.check_circle;
    }

    if (durum == 'rejected') {
      return Icons.cancel;
    }

    return Icons.hourglass_top;
  }

  Future<void> ilanSil(
    BuildContext context,
    String id,
  ) async {
    final cevap = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('İlanı Sil'),
          content: const Text(
            'Bu ilanı silmek istediğine emin misin?',
          ),
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
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(id)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İlan silindi.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'İlan şu anda silinemedi.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Önce giriş yapmalısınız.'),
        ),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('jobs')
        .where('ownerUid', isEqualTo: user.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kendi İlanlarım'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
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
              child: Text(
                'Henüz verdiğiniz ilan yok.',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: ilanlar.length,
            itemBuilder: (context, index) {
              final belge = ilanlar[index];
              final data = belge.data();

              final durum = bilgi(data['status']);

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

                      Row(
                        children: [
                          Icon(
                            durumIkonu(durum),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            durumYazisi(durum),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 24),

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

                      const SizedBox(height: 8),

                      Text(
                        bilgi(data['description']),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => ilanSil(
                            context,
                            belge.id,
                          ),
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
      appBar: AppBar(
        title: const Text('Yönetim Paneli'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 45,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Yönetici hesabı',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(Icons.work),
              title: const Text('İş İlanlarını Yönet'),
              subtitle: const Text(
                'Bekleyen ilanları onayla veya reddet',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
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

          const Card(
            child: ListTile(
              leading: Icon(Icons.people),
              title: Text('Kullanıcıları Yönet'),
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
              leading: Icon(Icons.star),
              title: Text('Öne Çıkan İlanlar'),
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

class BekleyenIlanlarSayfasi extends StatelessWidget {
  const BekleyenIlanlarSayfasi({super.key});

  String bilgi(dynamic deger) {
    final yazi = deger?.toString().trim() ?? '';
    return yazi.isEmpty ? 'Belirtilmemiş' : yazi;
  }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              durum == 'approved'
                  ? 'İlan onaylandı.'
                  : 'İlan reddedildi.',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İşlem yapılamadı.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('jobs')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bekleyen İlanlar'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
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
                margin: const EdgeInsets.only(bottom: 12),
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

                      const SizedBox(height: 8),

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

                      const SizedBox(height: 8),

                      Text(
                        bilgi(data['description']),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                durumDegistir(
                                  context,
                                  belge.id,
                                  'approved',
                                );
                              },
                              icon: const Icon(Icons.check),
                              label: const Text('ONAYLA'),
                            ),
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                durumDegistir(
                                  context,
                                  belge.id,
                                  'rejected',
                                );
                              },
                              icon: const Icon(Icons.close),
                              label: const Text('REDDET'),
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
