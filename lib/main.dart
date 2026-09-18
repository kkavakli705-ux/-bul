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
          seedColor: const Color(0xFF087CF0),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F9FF),
      ),
      home: const Baslangic(),
    );
  }
}

class Baslangic extends StatelessWidget {
  const Baslangic({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data != null) {
          return const AnaSayfa();
        }

        return const GirisSayfasi();
      },
    );
  }
}

// =====================================================
// GİRİŞ / KAYIT
// =====================================================

class GirisSayfasi extends StatefulWidget {
  const GirisSayfasi({super.key});

  @override
  State<GirisSayfasi> createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<GirisSayfasi> {
  final email = TextEditingController();
  final sifre = TextEditingController();
  final sifreTekrar = TextEditingController();

  bool kayit = false;
  bool yukleniyor = false;
  bool gizli = true;

  Future<void> islemiYap() async {
    final eposta = email.text.trim();
    final parola = sifre.text.trim();

    if (eposta.isEmpty || parola.length < 6) {
      mesaj('Geçerli e-posta ve en az 6 karakter şifre girin.');
      return;
    }

    if (kayit && parola != sifreTekrar.text.trim()) {
      mesaj('Şifreler aynı değil.');
      return;
    }

    setState(() => yukleniyor = true);

    try {
      if (kayit) {
        final sonuc =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: eposta,
          password: parola,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(sonuc.user!.uid)
            .set({
          'uid': sonuc.user!.uid,
          'email': eposta,
          'blocked': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        mesaj('Kayıt başarılı.');
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: eposta,
          password: parola,
        );
      }
    } on FirebaseAuthException catch (e) {
      mesaj(e.message ?? 'Giriş işlemi başarısız.');
    } catch (e) {
      mesaj('İşlem başarısız: $e');
    } finally {
      if (mounted) setState(() => yukleniyor = false);
    }
  }
Future<void> sifremiUnuttum() async {
  final eposta = email.text.trim();

  if (eposta.isEmpty) {
    mesaj('Önce e-posta adresinizi girin.');
    return;
  }

  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: eposta,
    );
    mesaj('Şifre sıfırlama bağlantısı e-postanıza gönderildi.');
  } catch (e) {
    mesaj('Şifre sıfırlama bağlantısı gönderilemedi.');
  }
}
  void mesaj(String yazi) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(yazi)),
    );
  }

  @override
  void dispose() {
    email.dispose();
    sifre.dispose();
    sifreTekrar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const mavi = Color(0xFF087CF0);
    const lacivert = Color(0xFF082D67);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 35),
            const Icon(
              Icons.work_rounded,
              size: 90,
              color: mavi,
            ),
            const SizedBox(height: 10),
            const Text(
              'İŞ BUL',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: lacivert,
              ),
            ),
            const Text(
              'Doğru İş, Daha İyi Yarın',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: Color(0xFF536A85),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 35),
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      kayit ? 'Hesap Oluştur' : 'Giriş Yap',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: lacivert,
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: sifre,
                      obscureText: gizli,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => gizli = !gizli);
                          },
                          icon: Icon(
                            gizli
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),
                    if (kayit) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: sifreTekrar,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Şifre Tekrar',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: yukleniyor ? null : islemiYap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mavi,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          yukleniyor
                              ? 'BEKLEYİN...'
                              : kayit
                                  ? 'KAYIT OL'
                                  : 'GİRİŞ YAP',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (!kayit)
  TextButton(
    onPressed: sifremiUnuttum,
    child: const Text('Şifremi Unuttum?'),
  ),
                    TextButton(
                      onPressed: () {
                        setState(() => kayit = !kayit);
                      },
                      child: Text(
                        kayit
                            ? 'Zaten hesabın var mı? Giriş Yap'
                            : 'Hesabın yok mu? Kayıt Ol',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'İşini bul, geleceğini kur.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF708399),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// ANA SAYFA
// =====================================================

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
      if (mounted) setState(() => kontrol = false);
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
      if (mounted) setState(() => kontrol = false);
    }
  }

  void ac(Widget sayfa) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => sayfa),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (kontrol) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              child: Icon(Icons.work),
            ),
            SizedBox(width: 10),
            Text(
              'İŞ BUL',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Bildirimler',
            onPressed: () => ac(const BildirimlerSayfasi()),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Merhaba 👋',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            user?.email ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF082D67),
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
  borderRadius: BorderRadius.circular(20),
  child: Image.asset(
    'file_0000000043a88210aa303ce3db3df68d.png',
    width: double.infinity,
    height: 220,
    fit: BoxFit.contain,
  ),
),
const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF073A80),
                  Color(0xFF168FF2),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.engineering,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 15),
                Text(
                  'Hayalindeki işe\nbir adım daha yakın!',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Yeni iş fırsatlarını keşfet.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: AnaKart(
                  renk: const Color(0xFF087CF0),
                  ikon: Icons.search,
                  baslik: 'İŞ ARA',
                  alt: 'Fırsatları keşfet',
                  onTap: () => ac(const IsAraSayfasi()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnaKart(
                  renk: const Color(0xFFFF8A00),
                  ikon: Icons.add_circle_outline,
                  baslik: 'İŞ İLANI VER',
                  alt: 'Ücretsiz ilan oluştur',
                  onTap: () => ac(const IlanVerSayfasi()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: AnaKart(
                  renk: const Color(0xFF09A85A),
                  ikon: Icons.description_outlined,
                  baslik: 'İLANLARIM',
                  alt: 'İlanlarını yönet',
                  onTap: () => ac(const IlanlarimSayfasi()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnaKart(
                  renk: const Color(0xFF7557E8),
                  ikon: Icons.notifications,
                  baslik: 'BİLDİRİMLER',
                  alt: 'Mesajları görüntüle',
                  onTap: () => ac(const BildirimlerSayfasi()),
                ),
              ),
            ],
          ),

          if (admin) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () => ac(const YonetimPaneli()),
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text(
                  'YÖNETİM PANELİ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
            label: const Text('ÇIKIŞ YAP'),
          ),

          const SizedBox(height: 30),
          const Center(
            child: Text(
              'İŞ BUL • Doğru İnsan, Doğru İş',
              style: TextStyle(
                color: Color(0xFF708399),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnaKart extends StatelessWidget {
  final Color renk;
  final IconData ikon;
  final String baslik;
  final String alt;
  final VoidCallback onTap;

  const AnaKart({
    super.key,
    required this.renk,
    required this.ikon,
    required this.baslik,
    required this.alt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: renk,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 150,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(ikon, color: Colors.white, size: 37),
              const Spacer(),
              Text(
                baslik,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              Text(
                alt,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// İLAN VER
// =====================================================

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

  String kategori = 'İnşaat';
  bool bekle = false;

  final kategoriler = const [
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

  Future<void> gonder() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    if (baslik.text.trim().isEmpty ||
        firma.text.trim().isEmpty ||
        konum.text.trim().isEmpty ||
        aciklama.text.trim().isEmpty) {
      mesaj('Zorunlu alanları doldurun.');
      return;
    }

    setState(() => bekle = true);

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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İlan yönetici onayına gönderildi.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      mesaj('İlan gönderilemedi: $e');
    } finally {
      if (mounted) setState(() => bekle = false);
    }
  }

  void mesaj(String yazi) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(yazi)),
    );
  }

  Widget alan(
    TextEditingController controller,
    String isim, {
    TextInputType? tip,
    int satir = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextField(
        controller: controller,
        keyboardType: tip,
        maxLines: satir,
        decoration: InputDecoration(
          labelText: isim,
          border: const OutlineInputBorder(),
        ),
      ),
    );
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
        padding: const EdgeInsets.all(16),
        children: [
          alan(baslik, 'İş Başlığı *'),
          alan(firma, 'Firma / İşveren *'),
          alan(konum, 'Şehir / İlçe *'),
          DropdownButtonFormField<String>(
            initialValue: kategori,
            decoration: const InputDecoration(
              labelText: 'Kategori',
              border: OutlineInputBorder(),
            ),
            items: kategoriler
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => kategori = v);
            },
          ),
          const SizedBox(height: 13),
          alan(
            telefon,
            'Telefon',
            tip: TextInputType.phone,
          ),
          alan(
            whatsapp,
            'WhatsApp',
            tip: TextInputType.phone,
          ),
          alan(ucret, 'Maaş / Ücret'),
          alan(
            aciklama,
            'İlan Açıklaması *',
            satir: 5,
          ),
          SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              onPressed: bekle ? null : gonder,
              icon: const Icon(Icons.send),
              label: Text(
                bekle
                    ? 'GÖNDERİLİYOR...'
                    : 'İLANI ONAYA GÖNDER',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// İŞ ARA
// =====================================================

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
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) {
                setState(() => arama = v.toLowerCase().trim());
              },
              decoration: const InputDecoration(
                hintText: 'Şehir, meslek veya firma ara...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;

                  final metin =
                      '${d['title'] ?? ''} ${d['company'] ?? ''} ${d['city'] ?? ''} ${d['category'] ?? ''}'
                          .toLowerCase();

                  return arama.isEmpty || metin.contains(arama);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Uygun ilan bulunamadı.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final d =
                        docs[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${d['title'] ?? 'İş İlanı'}',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text('${d['company'] ?? ''}'),
                            Text('📍 ${d['city'] ?? ''}'),
                            Text(
                              'Kategori: ${d['category'] ?? ''}',
                            ),
                            if ('${d['salary'] ?? ''}'.isNotEmpty)
                              Text(
                                'Ücret: ${d['salary']}',
                              ),
                            const Divider(),
                            Text('${d['description'] ?? ''}'),
                            if ('${d['phone'] ?? ''}'.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Telefon: ${d['phone']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            if ('${d['whatsapp'] ?? ''}'.isNotEmpty)
                              Text(
                                'WhatsApp: ${d['whatsapp']}',
                              ),
                          ],
                        ),
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

// =====================================================
// KENDİ İLANLARIM
// =====================================================

class IlanlarimSayfasi extends StatelessWidget {
  const IlanlarimSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Kendi İlanlarım')),
      body: user == null
          ? const Center(child: Text('Giriş yapılmamış.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .where('ownerUid', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Henüz ilan vermediniz.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final d =
                        doc.data() as Map<String, dynamic>;
                    final status =
                        '${d['status'] ?? 'pending'}';

                    String durum;

                    if (status == 'approved') {
                      durum = 'ONAYLANDI';
                    } else if (status == 'rejected') {
                      durum = 'REDDEDİLDİ';
                    } else {
                      durum = 'ONAY BEKLİYOR';
                    }

                    return Card(
                      child: ListTile(
                        title: Text(
                          '${d['title'] ?? 'İlan'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${d['company'] ?? ''}\nDurum: $durum',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('jobs')
                                .doc(doc.id)
                                .delete();
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

// =====================================================
// YÖNETİM PANELİ
// =====================================================


  class YonetimPaneli extends StatelessWidget {
  const YonetimPaneli({super.key});

  Future<void> durumDegistir(String id, String durum) async {
    await FirebaseFirestore.instance
        .collection('jobs')
        .doc(id)
        .update({'status': durum});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Yönetim Paneli',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Bildirim Gönder',
            icon: const Icon(Icons.send),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>  BildirimGonderSayfasi(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.people),
                    label: const Text('KULLANICILAR'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>  KullaniciYonetimiSayfasi(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.notifications),
                    label: const Text('BİLDİRİM GÖNDER'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BildirimGonderSayfasi(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Onay Bekleyen İlanlar',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'İlanlar yüklenemedi:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Onay bekleyen ilan yok.',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final d =
                        doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${d['title'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('Firma: ${d['company'] ?? ''}'),
                            Text('Konum: ${d['city'] ?? ''}'),
                            Text(
                              'Kategori: ${d['category'] ?? ''}',
                            ),
                            Text('Maaş: ${d['salary'] ?? ''}'),
                            Text('Telefon: ${d['phone'] ?? ''}'),
                            const SizedBox(height: 8),
                            Text('${d['description'] ?? ''}'),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon:
                                        const Icon(Icons.check),
                                    label:
                                        const Text('ONAYLA'),
                                    onPressed: () async {
                                      await durumDegistir(
                                        doc.id,
                                        'approved',
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon:
                                        const Icon(Icons.close),
                                    label:
                                        const Text('REDDET'),
                                    onPressed: () async {
                                      await durumDegistir(
                                        doc.id,
                                        'rejected',
                                      );
                                    },
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
          ),
        ],
      ),
    );
  }
}
    
// =====================================================
// BİLDİRİMLER
// =====================================================

class BildirimlerSayfasi extends StatelessWidget {
  const BildirimlerSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    final uid =
        FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bildirimler')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs.where((doc) {
            final d =
                doc.data() as Map<String, dynamic>;

            final hedef =
                '${d['hedefUid'] ?? 'all'}';

            return hedef == 'all' || hedef == uid;
          }).toList();

          docs.sort((a, b) {
            final da =
                a.data() as Map<String, dynamic>;
            final db =
                b.data() as Map<String, dynamic>;

            final ta = da['tarih'];
            final tb = db['tarih'];

            if (ta is Timestamp && tb is Timestamp) {
              return tb.compareTo(ta);
            }

            return 0;
          });

          if (docs.isEmpty) {
            return const Center(
              child: Text('Henüz bildiriminiz yok.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d =
                  docs[index].data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.notifications),
                  ),
                  title: Text(
                    '${d['baslik'] ?? 'Bildirim'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${d['mesaj'] ?? ''}',
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
