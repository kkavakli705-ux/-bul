import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
await FirebaseMessaging.instance.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);

await FirebaseMessaging.instance.subscribeToTopic('yeni_ilanlar');
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
    actions: [
      IconButton(
        icon: const Icon(Icons.notifications),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BildirimlerSayfasi(),
            ),
          );
        },
      ),
    ],
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
                Center(
  child: ClipRRect(
    borderRadius: BorderRadius.circular(15),
    child: Image.asset(
      'file_0000000043a88210aa303ce3db3df68d.png',
      width: 150,
      height: 110,
      fit: BoxFit.contain,
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
  final sifreTekrar = TextEditingController();
  final telefon = TextEditingController();
  final smsKodu = TextEditingController();

  bool kayit = false;
  bool bekle = false;
  bool telefonModu = false;
  bool smsGonderildi = false;

  String verificationId = '';

  Future<void> kullaniciKaydiOlustur(User user) async {
    try {
      final ref =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      final doc = await ref.get();

      if (!doc.exists) {
        await ref.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'phone': user.phoneNumber ?? '',
          'blocked': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  Future<void> emailIslemi() async {
    final eposta = email.text.trim();
    final parola = sifre.text.trim();

    if (eposta.isEmpty || parola.isEmpty) {
      mesaj(context, 'E-posta ve şifreyi doldurun.');
      return;
    }

    if (parola.length < 6) {
      mesaj(context, 'Şifre en az 6 karakter olmalıdır.');
      return;
    }

    if (kayit && parola != sifreTekrar.text.trim()) {
      mesaj(context, 'Şifreler aynı değil.');
      return;
    }

    setState(() {
      bekle = true;
    });

    try {
      if (kayit) {
        final sonuc =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: eposta,
          password: parola,
        );

        final user = sonuc.user;

        if (user != null) {
          await kullaniciKaydiOlustur(user);

          await user.sendEmailVerification();

          await FirebaseAuth.instance.signOut();

          if (mounted) {
            mesaj(
              context,
              'Doğrulama bağlantısı e-posta adresine gönderildi. '
              'E-postanı doğruladıktan sonra giriş yap.',
            );

            setState(() {
              kayit = false;
              sifre.clear();
              sifreTekrar.clear();
            });
          }
        }
      } else {
        final sonuc =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: eposta,
          password: parola,
        );

        final user = sonuc.user;

        if (user == null) {
          throw Exception();
        }

        await user.reload();

        final guncelUser = FirebaseAuth.instance.currentUser;

        if (guncelUser == null) {
          throw Exception();
        }

        if (!guncelUser.emailVerified) {
          try {
            await guncelUser.sendEmailVerification();
          } catch (_) {}

          await FirebaseAuth.instance.signOut();

          if (mounted) {
            mesaj(
              context,
              'E-posta adresin henüz doğrulanmamış. '
              'Doğrulama e-postanı kontrol et.',
            );
          }

          return;
        }

        await kullaniciKaydiOlustur(guncelUser);

        if (mounted) {
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      String hata = 'İşlem yapılamadı.';

      switch (e.code) {
        case 'email-already-in-use':
          hata = 'Bu e-posta adresi zaten kayıtlı.';
          break;

        case 'invalid-email':
          hata = 'Geçerli bir e-posta adresi girin.';
          break;

        case 'weak-password':
          hata = 'Şifre çok zayıf.';
          break;

        case 'user-not-found':
        case 'invalid-credential':
        case 'wrong-password':
          hata = 'E-posta veya şifre hatalı.';
          break;

        case 'too-many-requests':
          hata = 'Çok fazla deneme yapıldı. Biraz sonra tekrar deneyin.';
          break;

        default:
          hata = e.message ?? hata;
      }

      if (mounted) {
        mesaj(context, hata);
      }
    } catch (_) {
      if (mounted) {
        mesaj(context, 'Bir hata oluştu.');
      }
    } finally {
      if (mounted) {
        setState(() {
          bekle = false;
        });
      }
    }
  }

  String telefonDuzenle(String girilen) {
    String numara = girilen.trim().replaceAll(' ', '');

    if (numara.startsWith('05')) {
      numara = '+90${numara.substring(1)}';
    } else if (numara.startsWith('5') && numara.length == 10) {
      numara = '+90$numara';
    } else if (numara.startsWith('90')) {
      numara = '+$numara';
    }

    return numara;
  }

  Future<void> smsGonder() async {
    final numara = telefonDuzenle(telefon.text);

    if (numara.isEmpty) {
      mesaj(context, 'Telefon numaranı gir.');
      return;
    }

    if (!numara.startsWith('+')) {
      mesaj(
        context,
        'Telefon numarasını 05XXXXXXXXX şeklinde gir.',
      );
      return;
    }

    setState(() {
      bekle = true;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: numara,

      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final sonuc =
              await FirebaseAuth.instance.signInWithCredential(credential);

          if (sonuc.user != null) {
            await kullaniciKaydiOlustur(sonuc.user!);
          }

          if (mounted) {
            Navigator.pop(context);
          }
        } catch (_) {
          if (mounted) {
            mesaj(context, 'Telefon doğrulanamadı.');
          }
        }
      },

      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;

        setState(() {
          bekle = false;
        });

        String hata = 'SMS gönderilemedi.';

        if (e.code == 'invalid-phone-number') {
          hata = 'Telefon numarası geçersiz.';
        } else if (e.code == 'too-many-requests') {
          hata = 'Çok fazla SMS isteği yapıldı. Daha sonra tekrar deneyin.';
        } else if (e.message != null) {
          hata = e.message!;
        }

        mesaj(context, hata);
      },

      codeSent: (String id, int? resendToken) {
        if (!mounted) return;

        setState(() {
          verificationId = id;
          smsGonderildi = true;
          bekle = false;
        });

        mesaj(context, 'SMS doğrulama kodu gönderildi.');
      },

      codeAutoRetrievalTimeout: (String id) {
        verificationId = id;

        if (mounted) {
          setState(() {
            bekle = false;
          });
        }
      },

      timeout: const Duration(seconds: 60),
    );
  }

  Future<void> smsDogrula() async {
    if (smsKodu.text.trim().length < 6) {
      mesaj(context, 'SMS ile gelen 6 haneli kodu gir.');
      return;
    }

    if (verificationId.isEmpty) {
      mesaj(context, 'Önce SMS kodu gönder.');
      return;
    }

    setState(() {
      bekle = true;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsKodu.text.trim(),
      );

      final sonuc =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (sonuc.user != null) {
        await kullaniciKaydiOlustur(sonuc.user!);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String hata = 'Kod doğrulanamadı.';

      if (e.code == 'invalid-verification-code') {
        hata = 'SMS kodu yanlış.';
      } else if (e.code == 'session-expired') {
        hata = 'SMS kodunun süresi doldu. Tekrar kod gönder.';
      } else if (e.message != null) {
        hata = e.message!;
      }

      if (mounted) {
        mesaj(context, hata);
      }
    } catch (_) {
      if (mounted) {
        mesaj(context, 'Telefon doğrulanamadı.');
      }
    } finally {
      if (mounted) {
        setState(() {
          bekle = false;
        });
      }
    }
  }

  void moduDegistir(bool telefonSecildi) {
    setState(() {
      telefonModu = telefonSecildi;
      smsGonderildi = false;
      verificationId = '';
      smsKodu.clear();
    });
  }

  @override
  void dispose() {
    email.dispose();
    sifre.dispose();
    sifreTekrar.dispose();
    telefon.dispose();
    smsKodu.dispose();
    super.dispose();
  }

  @override
    @override
  Widget build(BuildContext context) {
    const mavi = Color(0xFF087CF0);
    const lacivert = Color(0xFF092A5E);

    InputDecoration alanTasarimi({
      required String label,
      required IconData icon,
      String? hint,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: mavi),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD9E5F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD9E5F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: mavi, width: 2),
        ),
      );
    }

    ButtonStyle anaButon = ElevatedButton.styleFrom(
      backgroundColor: mavi,
      foregroundColor: Colors.white,
      elevation: 3,
      minimumSize: const Size(double.infinity, 58),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F9FF),
        elevation: 0,
        foregroundColor: lacivert,
        centerTitle: true,
        title: Text(
          telefonModu
              ? 'Telefon ile Giriş'
              : kayit
                  ? 'Kayıt Ol'
                  : 'Giriş Yap',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: lacivert,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            const Text(
              'İŞ BUL',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: mavi,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Doğru İş, Daha İyi Yarın',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: lacivert,
              ),
            ),
            const SizedBox(height: 14),

            Center(
              child: Image.asset(
                'file_0000000043a88210aa303ce3db3df68d.png',
                height: 125,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1FB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: bekle
                          ? null
                          : () {
                              moduDegistir(false);
                            },
                      icon: const Icon(Icons.email_outlined),
                      label: const Text('E-POSTA'),
                      style: ElevatedButton.styleFrom(
                        elevation: telefonModu ? 0 : 2,
                        backgroundColor:
                            telefonModu ? Colors.transparent : Colors.white,
                        foregroundColor:
                            telefonModu ? Colors.blueGrey : mavi,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        minimumSize: const Size(0, 50),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: bekle
                          ? null
                          : () {
                              moduDegistir(true);
                            },
                      icon: const Icon(Icons.phone_android),
                      label: const Text('TELEFON'),
                      style: ElevatedButton.styleFrom(
                        elevation: telefonModu ? 2 : 0,
                        backgroundColor:
                            telefonModu ? Colors.white : Colors.transparent,
                        foregroundColor:
                            telefonModu ? mavi : Colors.blueGrey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        minimumSize: const Size(0, 50),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            if (!telefonModu) ...[
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: alanTasarimi(
                  label: 'E-posta',
                  icon: Icons.email_outlined,
                  hint: 'E-posta adresini yaz',
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: sifre,
                obscureText: true,
                decoration: alanTasarimi(
                  label: 'Şifre',
                  icon: Icons.lock_outline,
                  hint: 'Şifreni yaz',
                ),
              ),

              if (kayit) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: sifreTekrar,
                  obscureText: true,
                  decoration: alanTasarimi(
                    label: 'Şifre Tekrar',
                    icon: Icons.lock_reset,
                    hint: 'Şifreni tekrar yaz',
                  ),
                ),
              ],

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: bekle ? null : emailIslemi,
                style: anaButon,
                icon: Icon(
                  kayit ? Icons.person_add_alt_1 : Icons.login,
                ),
                label: Text(
                  bekle
                      ? 'BEKLEYİN...'
                      : kayit
                          ? 'KAYIT OL'
                          : 'GİRİŞ YAP',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: bekle
                    ? null
                    : () {
                        setState(() {
                          kayit = !kayit;
                          sifre.clear();
                          sifreTekrar.clear();
                        });
                      },
                child: Text(
                  kayit
                      ? 'Zaten hesabım var - Giriş yap'
                      : 'Hesabım yok - Kayıt ol',
                  style: const TextStyle(
                    color: mavi,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              if (kayit)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Kayıt olduktan sonra e-posta adresine doğrulama bağlantısı gönderilir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],

            if (telefonModu) ...[
              const Text(
                'Telefon numaran ile giriş yap veya hesap oluştur.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: lacivert,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: telefon,
                enabled: !smsGonderildi,
                keyboardType: TextInputType.phone,
                decoration: alanTasarimi(
                  label: 'Telefon Numarası',
                  icon: Icons.phone_outlined,
                  hint: '05XXXXXXXXX',
                ),
              ),

              const SizedBox(height: 16),

              if (!smsGonderildi)
                ElevatedButton.icon(
                  onPressed: bekle ? null : smsGonder,
                  style: anaButon,
                  icon: const Icon(Icons.sms_outlined),
                  label: Text(
                    bekle ? 'GÖNDERİLİYOR...' : 'SMS KODU GÖNDER',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

              if (smsGonderildi) ...[
                TextField(
                  controller: smsKodu,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: alanTasarimi(
                    label: 'SMS Doğrulama Kodu',
                    icon: Icons.sms_outlined,
                    hint: '6 haneli kod',
                  ),
                ),

                const SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: bekle ? null : smsDogrula,
                  style: anaButon,
                  icon: const Icon(Icons.verified_outlined),
                  label: Text(
                    bekle ? 'DOĞRULANIYOR...' : 'KODU DOĞRULA',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                TextButton(
                  onPressed: bekle
                      ? null
                      : () {
                          setState(() {
                            smsGonderildi = false;
                            verificationId = '';
                            smsKodu.clear();
                          });
                        },
                  child: const Text(
                    'Telefon numarasını değiştir',
                    style: TextStyle(
                      color: mavi,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 25),

            const Text(
              'İşini bul, geleceğini kur.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF708399),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
      appBar: AppBar(
        title: const Text('Yönetim Paneli'),
      ),
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
              leading: const Icon(Icons.star_border),
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

          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Bildirim Gönder'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BildirimGonderSayfasi(),
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
Future<void> hesabiSil() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    mesaj(context, 'Oturum bulunamadı.');
    return;
  }

  final sifreKontrol = TextEditingController();

  final sifreIleGiris = user.providerData.any(
    (provider) => provider.providerId == 'password',
  );

  final onay = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Hesabı Sil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Hesabınızı kalıcı olarak silmek istediğinize emin misiniz? '
              'Bu işlem geri alınamaz.',
            ),
            if (sifreIleGiris) ...[
              const SizedBox(height: 15),
              TextField(
                controller: sifreKontrol,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Şifrenizi girin',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('VAZGEÇ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('HESABI SİL'),
          ),
        ],
      );
    },
  );

  if (onay != true) {
    sifreKontrol.dispose();
    return;
  }

  try {
    // E-posta + şifre ile açılmış hesaplarda
    // silmeden önce kullanıcıyı tekrar doğrula.
    if (sifreIleGiris) {
      final email = user.email;

      if (email == null || email.isEmpty) {
        sifreKontrol.dispose();
        mesaj(context, 'Hesabın e-posta adresi bulunamadı.');
        return;
      }

      if (sifreKontrol.text.trim().isEmpty) {
        sifreKontrol.dispose();
        mesaj(context, 'Hesabı silmek için şifrenizi girin.');
        return;
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: sifreKontrol.text,
      );

      await user.reauthenticateWithCredential(credential);
    }

    final uid = user.uid;

    // Önce Firebase Authentication hesabını sil.
    await user.delete();

    // Sonra Firestore kullanıcı kaydını silmeyi dene.
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .delete();
    } catch (_) {
      // Auth hesabı silindiyse Firestore hatası işlemi durdurmasın.
    }

    sifreKontrol.dispose();

    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);

    mesaj(context, 'Hesabınız kalıcı olarak silindi.');
  } on FirebaseAuthException catch (e) {
    sifreKontrol.dispose();

    if (!mounted) return;

    if (e.code == 'wrong-password' ||
        e.code == 'invalid-credential') {
      mesaj(context, 'Şifre yanlış. Hesap silinmedi.');
    } else if (e.code == 'requires-recent-login') {
      mesaj(
        context,
        'Güvenlik nedeniyle yeniden giriş yapıp tekrar deneyin.',
      );
    } else {
      mesaj(context, e.message ?? 'Hesap silinemedi.');
    }
  } catch (_) {
    sifreKontrol.dispose();

    if (mounted) {
      mesaj(context, 'Hesap silinemedi.');
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
  child: ListTile(
    leading: const Icon(Icons.delete_forever),
    title: const Text('HESABIMI SİL'),
    subtitle: const Text('Hesabımı kalıcı olarak sil'),
    trailing: const Icon(Icons.arrow_forward_ios),
    onTap: hesabiSil,
  ),
),
          Card (        child: SwitchListTile(
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
class BildirimlerSayfasi extends StatelessWidget {
  const BildirimlerSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BİLDİRİMLER'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bildirimler')
            .orderBy('tarih', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Bildirimler yüklenemedi.'),
            );
          }

          final bildirimler = snapshot.data?.docs ?? [];

          if (bildirimler.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 70,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Henüz bildiriminiz yok.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bildirimler.length,
            itemBuilder: (context, index) {
              final veri =
                  bildirimler[index].data() as Map<String, dynamic>;

              final baslik =
                  veri['baslik']?.toString() ?? 'Bildirim';

              final mesaj =
                  veri['mesaj']?.toString() ?? '';

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.notifications),
                  ),
                  title: Text(
                    baslik,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(mesaj),
                ),
              );
            },
          );
        },
           ), 
    );
  }
}

class BildirimGonderSayfasi extends StatefulWidget {
  const BildirimGonderSayfasi({super.key});

  @override
  State<BildirimGonderSayfasi> createState() =>
      _BildirimGonderSayfasiState();
}

class _BildirimGonderSayfasiState
    extends State<BildirimGonderSayfasi> {
  final TextEditingController baslikController =
      TextEditingController();
  final TextEditingController mesajController =
      TextEditingController();

  bool tumKullanicilar = true;
  bool yukleniyor = false;

  String? secilenUid;
  String? secilenEmail;

  List<Map<String, String>> kullanicilar = [];

  @override
  void initState() {
    super.initState();
    kullanicilariYukle();
  }

  Future<void> kullanicilariYukle() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('users').get();

    final liste = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'uid': doc.id,
        'email': (data['email'] ?? 'E-posta yok').toString(),
      };
    }).toList();

    if (!mounted) return;

    setState(() {
      kullanicilar = liste;
    });
  }

  Future<void> bildirimGonder() async {
    final baslik = baslikController.text.trim();
    final mesaj = mesajController.text.trim();

    if (baslik.isEmpty || mesaj.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Başlık ve mesaj boş bırakılamaz.'),
        ),
      );
      return;
    }

    if (!tumKullanicilar && secilenUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bir kullanıcı seçin.'),
        ),
      );
      return;
    }

    setState(() {
      yukleniyor = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('bildirimler')
          .add({
        'baslik': baslik,
        'mesaj': mesaj,
        'tarih': FieldValue.serverTimestamp(),
        'hedefUid':
            tumKullanicilar ? 'all' : secilenUid,
        'hedefEmail':
            tumKullanicilar ? 'Tüm Kullanıcılar' : secilenEmail,
      });

      baslikController.clear();
      mesajController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bildirim başarıyla gönderildi.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
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
    baslikController.dispose();
    mesajController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Gönder'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Tüm Kullanıcılara Gönder'),
            value: tumKullanicilar,
            onChanged: (value) {
              setState(() {
                tumKullanicilar = value;
                secilenUid = null;
                secilenEmail = null;
              });
            },
          ),

          if (!tumKullanicilar)
            DropdownButtonFormField<String>(
              value: secilenUid,
              decoration: const InputDecoration(
                labelText: 'Kullanıcı Seç',
                border: OutlineInputBorder(),
              ),
              items: kullanicilar.map((kullanici) {
                return DropdownMenuItem<String>(
                  value: kullanici['uid'],
                  child: Text(
                    kullanici['email'] ?? '',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                final kullanici = kullanicilar.firstWhere(
                  (k) => k['uid'] == value,
                );

                setState(() {
                  secilenUid = value;
                  secilenEmail = kullanici['email'];
                });
              },
            ),

          const SizedBox(height: 16),

          TextField(
            controller: baslikController,
            decoration: const InputDecoration(
              labelText: 'Bildirim Başlığı',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: mesajController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Bildirim Mesajı',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: yukleniyor ? null : bildirimGonder,
            icon: const Icon(Icons.send),
            label: Text(
              yukleniyor ? 'Gönderiliyor...' : 'BİLDİRİM GÖNDER',
            ),
          ),
        ],
      ),
    );
  }
}
