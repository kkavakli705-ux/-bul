import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

try {
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  await FirebaseMessaging.instance.subscribeToTopic('yeni_ilanlar');
} catch (_) {}
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
late VideoPlayerController _videoController;
bool _videoHazir = false;
  @override
  void initState() {
    super.initState();
    hesapKontrol();
   _videoController = VideoPlayerController.asset('1789613362944.mp4')
  ..initialize().then((_) async {
    await _videoController.setLooping(true);

    if (FirebaseAuth.instance.currentUser == null) {
      await _videoController.setVolume(1.0);
      await _videoController.play();
    } else {
      await _videoController.setVolume(0.0);
      await _videoController.pause();
    }

    if (mounted) {
      setState(() {
        _videoHazir = true;
      });
    }
  }); 
  }
@override
void dispose() {
  _videoController.dispose();
  super.dispose();
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
  if (!mounted) return;
   await _videoController.pause();
await _videoController.setVolume(0.0);

  final girisYapildi = await Navigator.push<bool>(
  context,
  PageRouteBuilder(
    pageBuilder: (_, __, ___) => const GirisSayfasi(),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  ),
);

  if (!mounted) return;

  if (girisYapildi == true ||
      FirebaseAuth.instance.currentUser != null) {
    await _videoController.pause();
    await _videoController.setVolume(0.0);
    await hesapKontrol();
  } else {
    await _videoController.setVolume(1.0);

    if (!_videoController.value.isPlaying) {
      await _videoController.play();
    }
  }
} 
  
Future<void> cikis() async {
  await FirebaseAuth.instance.signOut();

  if (!mounted) return;

  setState(() {
    admin = false;
    engelli = false;
    kontrol = false;
  });

  await _videoController.seekTo(Duration.zero);
  await _videoController.setVolume(1.0);
  await _videoController.play();
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
     onPressed: () async {
  await _videoController.pause();
  await _videoController.setVolume(0.0);

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const BildirimlerSayfasi(),
    ),
  );

  if (!mounted) return;

  if (FirebaseAuth.instance.currentUser == null) {
    await _videoController.setVolume(1.0);
    await _videoController.play();
  }
}, 
        
      ),
    ],
  ),
      
     body: user == null
    ? Column(
        children: [
          Expanded(
            child: Center(
              child: _videoHazir
                  ? AspectRatio(
                      aspectRatio: _videoController.value.aspectRatio,
                      child: VideoPlayer(_videoController),
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: ElevatedButton.icon(
              onPressed: () async {
  await girisAc();
  
  
},
              icon: const Icon(Icons.login),
              label: const Text('GİRİŞ YAP / KAYIT OL'),
            ),
          ),
        ],
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

  Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.asset(
        'file_0000000043a88210aa303ce3db3df68d.png',
        width: 150,
        height: 110,
        fit: BoxFit.contain,
      ),
    ),
    
  ],
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

                  // ===============================
// İŞ İLANLARI
// ===============================
InkWell(
  borderRadius: BorderRadius.circular(22),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const IsAraSayfasi(),
      ),
    );
  },
  child: Container(
    height: 110,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color(0xFF1194FF),
          Color(0xFF087CF0),
        ],
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -25,
          top: -20,
          bottom: -20,
          child: Transform(
            transform: Matrix4.skewX(-0.20),
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(width: 18),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İŞ İLANLARI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sana uygun iş fırsatlarını keşfet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 40,
              ),
            ],
          ),
        ),
      ],
    ),
  ),
),

const SizedBox(height: 12),

// ===============================
// İŞ İLANI VER
// ===============================
InkWell(
  borderRadius: BorderRadius.circular(22),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const IlanVerSayfasi(),
      ),
    );
  },
  child: Container(
    height: 110,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color(0xFF38A9FF),
          Color(0xFF1688F5),
        ],
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -25,
          top: -20,
          bottom: -20,
          child: Transform(
            transform: Matrix4.skewX(-0.20),
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_note,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(width: 18),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İŞ İLANI VER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'İş fırsatını herkese duyur',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 40,
              ),
            ],
          ),
        ),
      ],
    ),
  ),
),

const SizedBox(height: 12),

// ===============================
// İKİNCİ EL
// ===============================
InkWell(
  borderRadius: BorderRadius.circular(22),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const IkinciElSayfasi(),
      ),
    );
  },
  child: Container(
    height: 110,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color(0xFF2DD56F),
          Color(0xFF12AD50),
        ],
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -25,
          top: -20,
          bottom: -20,
          child: Transform(
            transform: Matrix4.skewX(-0.20),
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(width: 18),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İKİNCİ EL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Aradığın ikinci el ürünü bul',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 40,
              ),
            ],
          ),
        ),
      ],
    ),
  ),
),

const SizedBox(height: 12),

// ===============================
// İKİNCİ EL İLANI VER
// ===============================
InkWell(
  borderRadius: BorderRadius.circular(22),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const IkinciElIlanVerSayfasi(),
      ),
    );
  },
  child: Container(
    height: 110,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color(0xFF43DB76),
          Color(0xFF20BA58),
        ],
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -25,
          top: -20,
          bottom: -20,
          child: Transform(
            transform: Matrix4.skewX(-0.20),
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sell_outlined,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(width: 18),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İKİNCİ EL İLANI VER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ürününü kolayca ilanla',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 40,
              ),
            ],
          ),
        ),
      ],
    ),
  ),
),

const SizedBox(height: 14),

// KENDİ İLANLARIM
InkWell(
  borderRadius: BorderRadius.circular(18),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const KendiIlanlarimSayfasi(),
      ),
    );
  },
  child: Container(
    height: 82,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: const Row(
      children: [
        Icon(
          Icons.list_alt,
          size: 38,
          color: Color(0xFF405A7A),
        ),
        SizedBox(width: 18),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KENDİ İLANLARIM',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF142A4A),
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Tüm ilanlarını görüntüle ve yönet',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF63738A),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right,
          size: 32,
          color: Color(0xFF63738A),
        ),
      ],
    ),
  ),
),

const SizedBox(height: 12),

// AYARLAR
InkWell(
  borderRadius: BorderRadius.circular(18),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AyarlarSayfasi(),
      ),
    );
  },
  child: Container(
    height: 82,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: const Row(
      children: [
        Icon(
          Icons.settings,
          size: 38,
          color: Color(0xFF405A7A),
        ),
        SizedBox(width: 18),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AYARLAR',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF142A4A),
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Uygulama tercihlerini düzenle',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF63738A),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right,
          size: 32,
          color: Color(0xFF63738A),
        ),
      ],
    ),
  ),
),

const SizedBox(height: 12),

// YÖNETİM PANELİ
if (admin)
  InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const YonetimPaneli(),
        ),
      );
    },
    child: Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.admin_panel_settings,
            size: 38,
            color: Color(0xFF405A7A),
          ),
          SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YÖNETİM PANELİ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF142A4A),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Sistem yönetimi ve istatistikler',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF63738A),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 32,
            color: Color(0xFF63738A),
          ),
        ],
      ),
    ),
  ),

if (admin) const SizedBox(height: 12),

// ÇIKIŞ YAP
InkWell(
  borderRadius: BorderRadius.circular(18),
  onTap: cikis,
  child: Container(
    height: 82,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: const Row(
      children: [
        Icon(
          Icons.logout,
          size: 38,
          color: Colors.red,
        ),
        SizedBox(width: 18),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ÇIKIŞ YAP',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF142A4A),
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Güvenli şekilde oturumu kapat',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF63738A),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right,
          size: 32,
          color: Color(0xFF63738A),
        ),
      ],
    ),
  ),
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
Future<void> sifremiUnuttum() async {
  final eposta = email.text.trim();

  if (eposta.isEmpty) {
    mesaj(context, 'Önce e-posta adresinizi girin.');
    return;
  }

  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: eposta,
    );
    mesaj(context, 'Şifre sıfırlama bağlantısı e-postanıza gönderildi.');
  } on FirebaseAuthException catch (e) {
    mesaj(
      context,
      e.message ?? 'Şifre sıfırlama bağlantısı gönderilemedi.',
    );
  }
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
  
  Navigator.pop(context, true);
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
            const Center(
  child: Column(
    children: [
      Text(
        '👋',
        style: TextStyle(fontSize: 42),
      ),
      SizedBox(height: 5),
      Text(
        'Hoş Geldiniz!',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: 5),
      Text(
        'İş fırsatları burada seni bekliyor.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15),
      ),
      SizedBox(height: 14),
    ],
  ),
),

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
              if (!kayit)
  TextButton(
    onPressed: bekle ? null : sifremiUnuttum,
    child: const Text('Şifremi Unuttum?'),
  ),

const SizedBox(height: 8),

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
  final adres = TextEditingController();
final mapsLink = TextEditingController();
  final telefon = TextEditingController();
  final whatsapp = TextEditingController();
  final ucret = TextEditingController();
  final aciklama = TextEditingController();
final ImagePicker _imagePicker = ImagePicker();
final List<XFile> _secilenFotograflar = [];

Future<void> galeridenFotografSec() async {
  final List<XFile> fotograflar = await _imagePicker.pickMultiImage(
    imageQuality: 75,
  );

  if (fotograflar.isNotEmpty) {
    setState(() {
      final kalan = 4 - _secilenFotograflar.length;
      _secilenFotograflar.addAll(fotograflar.take(kalan));
    });
  }
}

Future<void> kameradanFotografCek() async {
  if (_secilenFotograflar.length >= 4) {
    mesaj(context, 'En fazla 4 fotoğraf ekleyebilirsiniz.');
    return;
  }

  final XFile? fotograf = await _imagePicker.pickImage(
    source: ImageSource.camera,
    imageQuality: 75,
  );

  if (fotograf != null) {
    setState(() {
      _secilenFotograflar.add(fotograf);
    });
  }
}
  void fotografSil(int index) {
  setState(() {
    _secilenFotograflar.removeAt(index);
  });
}
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
        adres.text.trim().isEmpty ||
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
      final List<String> fotografUrlListesi = [];

for (int i = 0; i < _secilenFotograflar.length; i++) {
  final fotograf = _secilenFotograflar[i];

  final bytes = await fotograf.readAsBytes();
final contentType = fotograf.mimeType ?? 'image/jpeg';

final extension = contentType == 'image/png'
    ? 'png'
    : contentType == 'image/webp'
        ? 'webp'
        : 'jpg';

const supabaseUrl = 'https://jwdqmfbbbwzjcgmenzdd.supabase.co';
const supabaseKey =
    'sb_publishable_aX-ufKnmFxI57G8t7Tznnw_4SWJ0EOs';

final dosyaYolu =
    '${user.uid}/${DateTime.now().microsecondsSinceEpoch}_$i.$extension';

final response = await http
    .post(
      Uri.parse(
        '$supabaseUrl/storage/v1/object/ilan-fotograflari/$dosyaYolu',
      ),
      headers: {
        'apikey': supabaseKey,
        'Content-Type': contentType,
      },
      body: bytes,
    )
    .timeout(const Duration(seconds: 30));

if (response.statusCode < 200 || response.statusCode >= 300) {
  String hata = 'Fotoğraf yüklenemedi.';

  try {
    final responseText = utf8.decode(response.bodyBytes);
    final data = jsonDecode(responseText);

    if (data is Map) {
      final hataMesaji = data['message'] ?? data['error'];

      if (hataMesaji != null &&
          hataMesaji.toString().trim().isNotEmpty) {
        hata = hataMesaji.toString();
      }
    }
  } catch (_) {}

  throw Exception(hata);
}

final publicPath =
    dosyaYolu.split('/').map(Uri.encodeComponent).join('/');

final url =
    '$supabaseUrl/storage/v1/object/public/ilan-fotograflari/$publicPath';

fotografUrlListesi.add(url);
}
  final firestore = FirebaseFirestore.instance;

await firestore.collection('jobs').add({
  'title': baslik.text.trim(),
  'company': firma.text.trim(),
  'city': konum.text.trim(),
  'address': adres.text.trim(),
'mapsUrl': mapsLink.text.trim(),
  'category': kategori,
  'phone': telefon.text.trim(),
  'whatsapp': whatsapp.text.trim(),
  'salary': ucret.text.trim(),
  'description': aciklama.text.trim(),
  'ownerUid': user.uid,
  'ownerEmail': user.email ?? '',
  'status': 'approved',
  'featured': false,
  'imageUrls': fotografUrlListesi,
  'createdAt': FieldValue.serverTimestamp(),
});

  if (mounted) {
    mesaj(context, 'İlanınız yayınlandı.');
    Navigator.pop(context);
  }
} catch (e) {
  if (mounted) {
    mesaj(context, 'İlan gönderilemedi: $e');
  }
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
    adres.dispose();
mapsLink.dispose();
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
  controller: adres,
  decoration: const InputDecoration(
    labelText: 'Açık Adres',
    border: OutlineInputBorder(),
  ),
),
const SizedBox(height: 12),
TextField(
  controller: mapsLink,
  decoration: const InputDecoration(
    labelText: 'Google Maps Konum Linki (isteğe bağlı)',
    border: OutlineInputBorder(),
  ),
),  
          const SizedBox(height: 12),
          TextField(
            controller: telefon,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
            labelText: 'Telefon isteğe bağlı',  
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: whatsapp,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'WhatsApp isteğe bağlı',
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
          Row(
  children: [
    Expanded(
      child: ElevatedButton.icon(
        onPressed: galeridenFotografSec,
        icon: const Icon(Icons.photo_library),
        label: const Text('GALERİDEN'),
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: ElevatedButton.icon(
        onPressed: kameradanFotografCek,
        icon: const Icon(Icons.camera_alt),
        label: const Text('KAMERA'),
      ),
    ),
  ],
),

const SizedBox(height: 8),

Text(
  'Seçilen fotoğraf: ${_secilenFotograflar.length}/4',
  style: const TextStyle(
    fontWeight: FontWeight.bold,
  ),
),
if (_secilenFotograflar.isNotEmpty) ...[
  const SizedBox(height: 10),
  SizedBox(
    height: 90,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _secilenFotograflar.length,
      separatorBuilder: (context, index) =>
          const SizedBox(width: 8),
      itemBuilder: (context, index) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(_secilenFotograflar[index].path),
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              right: -4,
              top: -4,
              child: GestureDetector(
                onTap: () => fotografSil(index),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  ),
],
const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: bekle ? null : gonder,
            icon: const Icon(Icons.send),
            label: Text(
              bekle ? 'GÖNDERİLİYOR...' : 'ÜCRETSİZ İLANI YAYINLA',
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
Set<String> favoriler = <String>{};
  String seciliKategori = 'Tümü';

@override
void initState() {
  super.initState();
  _favorileriYukle();
}

Future<void> _favorileriYukle() async {
  final prefs = await SharedPreferences.getInstance();
  final liste = prefs.getStringList('favori_ilanlar') ?? [];

  if (mounted) {
    setState(() {
      favoriler = liste.toSet();
    });
  }
}

Future<void> _favoriDegistir(String id) async {
  setState(() {
    if (favoriler.contains(id)) {
      favoriler.remove(id);
    } else {
      favoriler.add(id);
    }
  });

  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    'favori_ilanlar',
    favoriler.toList(),
  );
}
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

  final kategori =
      (data['category'] ?? '').toString().trim().toLowerCase();

 final kategoriUyuyor =
    seciliKategori == 'Tümü' ||
    (seciliKategori == 'İnşaat'
        ? ['inşaat', 'boya / alçı', 'elektrik', 'tesisat']
            .contains(kategori)
        : seciliKategori == 'Garson'
            ? ['garson', 'garson / restoran'].contains(kategori)
            : seciliKategori == 'Temizlik'
                ? kategori == 'temizlik'
                : seciliKategori == 'Şoför'
                    ? kategori == 'şoför'
                    : seciliKategori == 'Diğer'
                        ? ![
                            'inşaat',
                            'boya / alçı',
                            'elektrik',
                            'tesisat',
                            'temizlik',
                            'şoför',
                            'garson',
                            'garson / restoran',
                          ].contains(kategori)
                        : kategori == seciliKategori.toLowerCase());
  if (!kategoriUyuyor) return false;

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
      backgroundColor: const Color(0xFFF6F9FE),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        toolbarHeight: 88,
        titleSpacing: 18,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İş Bul',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Color(0xFF087CF0),
              ),
            ),
            Text(
              'Doğru işi, doğru insanla buluşturur',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF52617D),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 20),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7FC),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Color(0xFF087CF0),
                ),
                SizedBox(width: 4),
                Text(
                  'Balıkesir',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF08163B),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF087CF0),
                ),
              ],
            ),
          ),
         
         IconButton(
          onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const BildirimlerSayfasi(),
    ),
  );
},
           
  icon: StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('bildirimler')
      .where('hedefUid', isEqualTo: 'all')
      .snapshots(),
  builder: (context, snapshot) {
    final sayi = snapshot.data?.docs.length ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(
          Icons.notifications,
          color: Color(0xFF08163B),
          size: 28,
        ),
        if (sayi > 0)
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                sayi > 9 ? '9+' : '$sayi',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  },
),
),
],
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
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: arama,
                            onChanged: (_) {
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              hintText: 'Ne iş arıyorsunuz?',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color(0xFF17294E),
                              ),
                              suffixIcon: arama.text.isEmpty
                                  ? const Icon(
                                      Icons.tune,
                                      color: Color(0xFF17294E),
                                    )
                                  : IconButton(
                                      onPressed: () {
                                        arama.clear();
                                        setState(() {});
                                      },
                                      icon: const Icon(Icons.clear),
                                    ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: Color(0xFFDDE5F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: Color(0xFFDDE5F0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: Color(0xFF087CF0),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF087CF0),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'Ara',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _kategoriButonu(
                            Icons.grid_view_rounded,
                            'Tümü',
                            seciliKategori == 'Tümü',
                          ),
                          _kategoriButonu(
                            Icons.construction,
                            'İnşaat',
                            seciliKategori == 'İnşaat',
                          ),
                          _kategoriButonu(
                            Icons.cleaning_services,
                            'Temizlik',
                            seciliKategori == 'Temizlik',
                          ),
                          _kategoriButonu(
                            Icons.directions_car,
                            'Şoför',
                            seciliKategori == 'Şoför',
                          ),
                          _kategoriButonu(
                            Icons.restaurant,
                            'Garson',
                            seciliKategori == 'Garson',
                          ),
                          _kategoriButonu(
                            Icons.more_horiz,
                            'Diğer',
                            seciliKategori == 'Diğer',
                          ),
                        ],
                      ),
                    ),
                  ],
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
                          final belge = ilanlar[index];
                          final data = belge.data();

                          final List<String> fotograflar =
                              (data['imageUrls']
                                          as List<dynamic>?)
                                      ?.map((e) => e.toString())
                                      .toList() ??
                                  [];

                          final createdAt =
                              data['createdAt'] as Timestamp?;

                          final tarih = createdAt == null
                              ? ''
                              : '${createdAt.toDate().day.toString().padLeft(2, '0')}.'
                                  '${createdAt.toDate().month.toString().padLeft(2, '0')}.'
                                  '${createdAt.toDate().year}';

                          final title = bilgi(data['title']);
                          final company = bilgi(data['company']);
                          final city = bilgi(data['city']);
                          final category =
                              bilgi(data['category']);
                          final salary = bilgi(data['salary']);
                          final description =
                              bilgi(data['description']);

                          
                            
                            return Container(
  margin: const EdgeInsets.only(bottom: 8),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: const [
      BoxShadow(
        color: Color(0x12000000),
        blurRadius: 10,
        offset: Offset(0, 3),
      ),
    ],
  ),
  child: Padding(
    padding: const EdgeInsets.all(8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          height: 125,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),          child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          if (fotograflar.isNotEmpty)
                                            Image.network(
                                              fotograflar.first,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error,
                                                      stackTrace) {
                                                return Container(
                                                  color: const Color(
                                                      0xFFE8EEF5),
                                                  child: const Icon(
                                                    Icons.image,
                                                    size: 42,
                                                  ),
                                                );
                                              },
                                            )
                                          else
                                            Container(
                                              color: const Color(
                                                  0xFFE8EEF5),
                                              child: const Icon(
                                                Icons.work_outline,
                                                size: 42,
                                                color: Color(
                                                    0xFF7E8CA3),
                                              ),
                                            ),
                                          Positioned(
                                            left: 7,
                                            top: 7,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                horizontal: 9,
                                                vertical: 5,
                                              ),
                                              decoration:
                                                  BoxDecoration(
                                                color: const Color(
                                                    0xFF087CF0),
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(8),
                                              ),
                                              child: const Text(
                                                'Yeni',
                                                style: TextStyle(
                                                  color:
                                                      Colors.white,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (fotograflar.isNotEmpty)
                                            Positioned(
                                              left: 7,
                                              bottom: 7,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                  horizontal: 7,
                                                  vertical: 4,
                                                ),
                                                decoration:
                                                    BoxDecoration(
                                                  color: const Color(
                                                      0xB8000000),
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(7),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .photo_camera,
                                                      color:
                                                          Colors.white,
                                                      size: 14,
                                                    ),
                                                    const SizedBox(
                                                        width: 4),
                                                    Text(
                                                      '${fotograflar.length} Fotoğraf',
                                                      style:
                                                          const TextStyle(
                                                        color: Colors
                                                            .white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight
                                                                .bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow
                                                        .ellipsis,
                                                style:
                                                    const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight:
                                                      FontWeight.w900,
                                                  color: Color(
                                                      0xFF08163B),
                                                ),
                                              ),
                                            ),
                                            if (tarih.isNotEmpty)
                                              Text(
                                                tarih,
                                                style:
                                                    const TextStyle(
                                                  fontSize: 10,
                                                  color: Color(
                                                      0xFF52617D),
                                                ),
                                              ),
                                            IconButton(
  padding: EdgeInsets.zero,
  constraints: const BoxConstraints(),
  onPressed: () => _favoriDegistir(belge.id),
  icon: Icon(
    favoriler.contains(belge.id)
        ? Icons.favorite
        : Icons.favorite_border,
    color: favoriler.contains(belge.id)
        ? Colors.red
        : const Color(0xFF52617D),
  ),
),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        _ilanBilgiSatiri(
                                          Icons.business_center,
                                          company,
                                        ),
                                        _ilanBilgiSatiri(
                                          Icons.location_on,
                                          city,
                                        ),
                                        _ilanBilgiSatiri(
                                          Icons.sell,
                                          category,
                                        ),
                                        
                                                    
                                         if (salary.isNotEmpty && salary != 'Belirtilmemiş')
  Align(
    alignment: Alignment.centerRight,
    child: Container(
      padding: const EdgeInsets.symmetric(
  horizontal: 10,
  vertical: 6,
),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F3FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.monetization_on,
            color: Color(0xFF087CF0),
            size: 17,
          ),
          const SizedBox(width: 5),
          Text(
            salary,
            style: const TextStyle(
              color: Color(0xFF087CF0),
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  ),   
                                        const SizedBox(height: 3),
                                        Text(
                                          description,
                                          maxLines: 2,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color:
                                                Color(0xFF52617D),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
Align(
  alignment: Alignment.centerRight,
  child: SizedBox(
    width: 155,
    child: ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IlanDetaySayfasi(
              jobId: belge.id,
              data: data,
            ),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(155, 36),
padding: const EdgeInsets.symmetric(
  horizontal: 10,
  vertical: 6,
),
        backgroundColor: const Color(0xFF087CF0),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text(
        'Detayları Gör  →',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),
),   
                                              ],
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
      bottomNavigationBar: BottomNavigationBar(
  type: BottomNavigationBarType.fixed,
  currentIndex: 1,
  onTap: (index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AnaSayfa(),
        ),
      );
    }

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const IlanVerSayfasi(),
        ),
      );
    }
    if (index == 3) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const MesajlarSayfasi(),
    ),
  );
}
    if (index == 4) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const AyarlarSayfasi(),
    ),
  );
}
  },
  selectedItemColor: const Color(0xFF087CF0),
  unselectedItemColor: const Color(0xFF7A869F),
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Ana Sayfa',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.search),
      label: 'İş Ara',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.add_circle, size: 38),
      label: 'İlan Ver',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.message),
      label: 'Mesajlar',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Profilim',
    ),
  ],
),                     
    );
  }

  Widget _kategoriButonu(
    IconData icon,
    String yazi,
    bool secili,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 7),
      child: ElevatedButton.icon(
        onPressed: () {
  setState(() {
    seciliKategori = yazi;
  });
},
        icon: Icon(icon, size: 18),
        label: Text(yazi),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor:
              secili ? const Color(0xFF087CF0) : Colors.white,
          foregroundColor:
              secili ? Colors.white : const Color(0xFF08163B),
          side: BorderSide(
            color: secili
                ? const Color(0xFF087CF0)
                : const Color(0xFFE1E8F0),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    );
  }

  Widget _ilanBilgiSatiri(
    IconData icon,
    String yazi,
  ) {
    if (yazi.isEmpty || yazi == 'Belirtilmemiş') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: const Color(0xFF52617D),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              yazi,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF52617D),
              ),
            ),
          ),
        ],
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

class KendiIlanlarimSayfasi extends StatefulWidget {
  const KendiIlanlarimSayfasi({super.key});

  @override
  State<KendiIlanlarimSayfasi> createState() =>
      _KendiIlanlarimSayfasiState();
}

class _KendiIlanlarimSayfasiState
    extends State<KendiIlanlarimSayfasi> {
  int seciliSekme = 0;

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
Future<void> ikinciElIlanSil(
  BuildContext context,
  String id,
) async {
  final cevap = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('İkinci El İlanını Sil'),
        content: const Text(
          'Bu ikinci el ilanını silmek istediğinize emin misiniz?',
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
        .collection('secondhand_posts')
        .doc(id)
        .delete();

    if (context.mounted) {
      mesaj(context, 'İkinci el ilanı silindi.');
    }
  } catch (_) {
    if (context.mounted) {
      mesaj(context, 'İkinci el ilanı silinemedi.');
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

  final isIlanlariStream = FirebaseFirestore.instance
      .collection('jobs')
      .where('ownerUid', isEqualTo: user.uid)
      .snapshots();

  final ikinciElIlanlariStream = FirebaseFirestore.instance
      .collection('secondhand_posts')
      .where('ownerUid', isEqualTo: user.uid)
      .snapshots();

  return Scaffold(
    backgroundColor: const Color(0xFFF7F9FC),
    appBar: AppBar(
      title: const Text('Kendi İlanlarım'),
    ),
    body: Column(
      children: [

        // İKİ SEKME
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              children: [

                // İŞ İLANLARIM
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        seciliSekme = 0;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: seciliSekme == 0
                            ? const Color(0xFF1976D2)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.work,
                              color: seciliSekme == 0
                                  ? Colors.white
                                  : const Color(0xFF1976D2),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'İş İlanlarım',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: seciliSekme == 0
                                    ? Colors.white
                                    : const Color(0xFF1976D2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // İKİNCİ EL İLANLARIM
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        seciliSekme = 1;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: seciliSekme == 1
                            ? const Color(0xFF18A957)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.storefront,
                              color: seciliSekme == 1
                                  ? Colors.white
                                  : const Color(0xFF18A957),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'İkinci El İlanlarım',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: seciliSekme == 1
                                    ? Colors.white
                                    : const Color(0xFF18A957),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // SEÇİLEN SEKME
        Expanded(
          child: seciliSekme == 0

              // =========================
              // İŞ İLANLARI
              // =========================
              ? StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                  stream: isIlanlariStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final ilanlar = snapshot.data!.docs;

                    if (ilanlar.isEmpty) {
                      return const Center(
                        child: Text(
                          'Henüz iş ilanınız yok.',
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: ilanlar.length,
                      itemBuilder: (context, index) {
                        final belge = ilanlar[index];
                        final data = belge.data();

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
                                const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bilgi(data['title']),
                                  style:
                                      const TextStyle(
                                    fontSize: 19,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  durumYazisi(durum),
                                ),

                                if (featured) ...[
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Text(
                                    '★ ÖNE ÇIKAN İLAN - ${kalanSure(data)}',
                                  ),
                                ],

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
                                        ElevatedButton.icon(
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
                                      label: const Text(
                                        'ÜCRETLİ ÖNE ÇIKAR',
                                      ),
                                    ),
                                  ),

                                const SizedBox(
                                  height: 8,
                                ),

                                SizedBox(
                                  width:
                                      double.infinity,
                                  child:
                                      ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              IlanDuzenleSayfasi(
                                            ilanId:
                                                belge.id,
                                            data: data,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.edit,
                                    ),
                                    label: const Text(
                                      'İLANI DÜZENLE',
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                SizedBox(
                                  width:
                                      double.infinity,
                                  child:
                                      OutlinedButton.icon(
                                    onPressed: () {
                                      ilanSil(
                                        context,
                                        belge.id,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.delete,
                                    ),
                                    label: const Text(
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
                )

              // =========================
              // İKİNCİ EL İLANLARI
              // =========================
              : StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                  stream: ikinciElIlanlariStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final ilanlar = snapshot.data!.docs;

                    if (ilanlar.isEmpty) {
                      return const Center(
                        child: Text(
                          'Henüz ikinci el ilanınız yok.',
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: ilanlar.length,
                      itemBuilder: (context, index) {
                        final belge = ilanlar[index];
                        final data = belge.data();

                        final resimler =
                            data['imageUrls'] is List
                                ? List<String>.from(
                                    data['imageUrls'],
                                  )
                                : <String>[];

                        return Card(
                          margin:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius
                                              .circular(10),
                                      child:
                                          resimler.isNotEmpty
                                              ? Image.network(
                                                  resimler
                                                      .first,
                                                  width: 90,
                                                  height:
                                                      90,
                                                  fit: BoxFit
                                                      .cover,
                                                )
                                              : Container(
                                                  width: 90,
                                                  height:
                                                      90,
                                                  color:
                                                      const Color(
                                                    0xFFE2F7E9,
                                                  ),
                                                  child:
                                                      const Icon(
                                                    Icons
                                                        .storefront,
                                                    color:
                                                        Color(
                                                      0xFF18A957,
                                                    ),
                                                  ),
                                                ),
                                    ),

                                    const SizedBox(
                                      width: 12,
                                    ),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            bilgi(
                                              data[
                                                  'title'],
                                            ),
                                            style:
                                                const TextStyle(
                                              fontSize:
                                                  18,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),

                                          const SizedBox(
                                            height: 6,
                                          ),

                                          Text(
                                            '${bilgi(data['price'])} TL',
                                            style:
                                                const TextStyle(
                                              color: Color(
                                                0xFF18A957,
                                              ),
                                              fontSize:
                                                  17,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),

                                          const SizedBox(
                                            height: 5,
                                          ),

                                          Text(
                                            '${bilgi(data['city'])} / ${bilgi(data['district'])}',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                  height: 12,
                                ),

                                SizedBox(
                                  width:
                                      double.infinity,
                                  child:
                                      OutlinedButton.icon(
                                    onPressed: () {
                                      ikinciElIlanSil(
                                        context,
                                        belge.id,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    label: const Text(
                                      'İLANI SİL',
                                      style: TextStyle(
                                        color: Colors.red,
                                      ),
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
        ),
      ],
    ),
  );
}
}
class IlanDuzenleSayfasi extends StatefulWidget {
  final String ilanId;
  final Map<String, dynamic> data;

  const IlanDuzenleSayfasi({
    super.key,
    required this.ilanId,
    required this.data,
  });

  @override
  State<IlanDuzenleSayfasi> createState() => _IlanDuzenleSayfasiState();
}

class _IlanDuzenleSayfasiState extends State<IlanDuzenleSayfasi> {
  late final TextEditingController baslik;
  late final TextEditingController firma;
  late final TextEditingController konum;
  late final TextEditingController telefon;
  late final TextEditingController whatsapp;
  late final TextEditingController ucret;
  late final TextEditingController aciklama;

  bool bekle = false;

  @override
  void initState() {
    super.initState();

    baslik = TextEditingController(
      text: widget.data['title']?.toString() ?? '',
    );
    firma = TextEditingController(
      text: widget.data['company']?.toString() ?? '',
    );
    konum = TextEditingController(
      text: widget.data['city']?.toString() ?? '',
    );
    telefon = TextEditingController(
      text: widget.data['phone']?.toString() ?? '',
    );
    whatsapp = TextEditingController(
      text: widget.data['whatsapp']?.toString() ?? '',
    );
    ucret = TextEditingController(
      text: widget.data['salary']?.toString() ?? '',
    );
    aciklama = TextEditingController(
      text: widget.data['description']?.toString() ?? '',
    );
  }

  Future<void> kaydet() async {
    if (baslik.text.trim().isEmpty ||
        firma.text.trim().isEmpty ||
        konum.text.trim().isEmpty ||
        ucret.text.trim().isEmpty ||
        aciklama.text.trim().isEmpty) {
      mesaj(context, 'Zorunlu alanları doldurun.');
      return;
    }

    setState(() {
      bekle = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.ilanId)
          .update({
        'title': baslik.text.trim(),
        'company': firma.text.trim(),
        'city': konum.text.trim(),
        'phone': telefon.text.trim(),
        'whatsapp': whatsapp.text.trim(),
        'salary': ucret.text.trim(),
        'description': aciklama.text.trim(),
      });

      if (!mounted) return;

      mesaj(context, 'İlan güncellendi.');
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        mesaj(context, 'İlan güncellenemedi.');
      }
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
        title: const Text('İlanı Düzenle'),
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
            controller: telefon,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telefon',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: whatsapp,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'WhatsApp',
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
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: bekle ? null : kaydet,
            icon: const Icon(Icons.save),
            label: Text(
              bekle ? 'KAYDEDİLİYOR...' : 'DEĞİŞİKLİKLERİ KAYDET',
            ),
          ),
        ],
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
        ),         ),

        Card(
  child: ListTile(
    leading: const Icon(Icons.delete_forever),
    title: const Text('Tüm Bildirimleri Sil'),
    onTap: () async {
      final onay = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Tüm Bildirimleri Sil'),
          content: const Text(
            'Bütün bildirimleri silmek istediğinize emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('VAZGEÇ'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('SİL'),
            ),
          ],
        ),
      );

      if (onay != true) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('bildirimler')
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tüm bildirimler silindi'),
          ),
        );
      }
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

        // Önce Firestore kullanıcı kaydını sil.
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .delete();

    // Sonra Firebase Authentication hesabını sil.
    await user.delete();
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
    .where('hedefUid', isEqualTo: 'all')
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
class MesajlasmaSayfasi extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final String ownerUid;

  const MesajlasmaSayfasi({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.ownerUid,
  });

  @override
  State<MesajlasmaSayfasi> createState() => _MesajlasmaSayfasiState();
}

class _MesajlasmaSayfasiState extends State<MesajlasmaSayfasi> {
  final TextEditingController mesajController = TextEditingController();
  bool gonderiliyor = false;

  String conversationIdOlustur(String uid1, String uid2) {
    final kullanicilar = [uid1, uid2]..sort();
    return '${widget.jobId}_${kullanicilar[0]}_${kullanicilar[1]}';
  }

  Future<void> mesajGonder() async {
    final user = FirebaseAuth.instance.currentUser;
    final mesaj = mesajController.text.trim();

    if (user == null || mesaj.isEmpty || gonderiliyor) {
      return;
    }

    final conversationId =
        conversationIdOlustur(user.uid, widget.ownerUid);

    setState(() {
      gonderiliyor = true;
    });

    try {
      final sohbetRef = FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId);

      await sohbetRef.set({
        'jobId': widget.jobId,
        'jobTitle': widget.jobTitle,
        'ownerUid': widget.ownerUid,
        'participants': [user.uid, widget.ownerUid],
        'lastMessage': mesaj,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await sohbetRef.collection('messages').add({
        'senderUid': user.uid,
        'text': mesaj,
        'createdAt': FieldValue.serverTimestamp(),
      });

      mesajController.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Mesaj gönderilemedi.')),
);
      }
    } finally {
      if (mounted) {
        setState(() {
          gonderiliyor = false;
        });
      }
    }
  }

  @override
  void dispose() {
    mesajController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mesajlaşma'),
        ),
        body: const Center(
          child: Text('Mesajlaşmak için giriş yapmalısınız.'),
        ),
      );
    }

    final conversationId =
        conversationIdOlustur(user.uid, widget.ownerUid);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.jobTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('conversations')
                  .doc(conversationId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Mesajlar yüklenemedi.'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final mesajlar = snapshot.data!.docs;

                if (mesajlar.isEmpty) {
                  return const Center(
                    child: Text('Henüz mesaj yok. İlk mesajı gönder.'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: mesajlar.length,
                  itemBuilder: (context, index) {
                    final data =
                        mesajlar[index].data() as Map<String, dynamic>;

                    final benim =
                        data['senderUid'] == user.uid;

                    return Align(
                      alignment: benim
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(
                          maxWidth: 280,
                        ),
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: benim
                              ? Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          data['text']?.toString() ?? '',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: mesajController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => mesajGonder(),
                      decoration: const InputDecoration(
                        hintText: 'Mesaj yaz...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed:
                        gonderiliyor ? null : mesajGonder,
                    icon: gonderiliyor
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class MesajlarSayfasi extends StatelessWidget {
  const MesajlarSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Giriş yapmalısınız.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mesajlar')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .where('participants', arrayContains: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sohbetler = snapshot.data!.docs;

          if (sohbetler.isEmpty) {
            return const Center(child: Text('Henüz mesaj yok.'));
          }

          return ListView.builder(
            itemCount: sohbetler.length,
            itemBuilder: (context, index) {
              final doc = sohbetler[index];
              final data = doc.data() as Map<String, dynamic>;

              final participants =
                  List<String>.from(data['participants'] ?? []);
              final digerUid = participants.firstWhere(
                (uid) => uid != user.uid,
                orElse: () => '',
              );

              return ListTile(
                leading: const Icon(Icons.message),
                title: Text(data['jobTitle']?.toString() ?? 'İlan'),
                subtitle: Text(data['lastMessage']?.toString() ?? ''),
                onTap: digerUid.isEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MesajlasmaSayfasi(
                              jobId: data['jobId']?.toString() ?? '',
                              jobTitle:
                                  data['jobTitle']?.toString() ?? 'Mesajlaşma',
                              ownerUid: digerUid,
                            ),
                          ),
                        );
                      },
              );
            },
          );
        },
      ),
    );
  }
}
class IlanDetaySayfasi extends StatelessWidget {
  final String jobId;
  final Map<String, dynamic> data;

  const IlanDetaySayfasi({
    super.key,
    required this.jobId,
    required this.data,
  });

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

  String tarihYazisi(dynamic deger) {
    if (deger is! Timestamp) return '';

    final tarih = deger.toDate();

    return '${tarih.day.toString().padLeft(2, '0')}.'
        '${tarih.month.toString().padLeft(2, '0')}.'
        '${tarih.year} '
        '${tarih.hour.toString().padLeft(2, '0')}:'
        '${tarih.minute.toString().padLeft(2, '0')}';
  }
void fotografGalerisiniAc(
  BuildContext context,
  List<String> fotograflar,
  int baslangicIndex,
) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text('${baslangicIndex + 1}/${fotograflar.length}'),
        ),
        body: PageView.builder(
          controller: PageController(
            initialPage: baslangicIndex,
          ),
          itemCount: fotograflar.length,
          itemBuilder: (context, index) {
            return InteractiveViewer(
              child: Center(
                child: Image.network(
                  fotograflar[index],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 60,
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    final telefon = bilgi(data['phone']);
    final whatsapp = bilgi(data['whatsapp']);
    final tarih = tarihYazisi(data['createdAt']);
final List<String> fotograflar =
    (data['imageUrls'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ??
    [];
    return Scaffold(
  backgroundColor: const Color(0xFFF7F8FA),
  appBar: AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    surfaceTintColor: Colors.white,
    foregroundColor: const Color(0xFF111827),
    titleSpacing: 0,
    title: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İlan Detayı',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        Text(
          'İş fırsatını incele',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    ),
  ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        children: [
          Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (fotograflar.isNotEmpty) ...[
  SizedBox(
    height: 160,
    child: Row(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
            GestureDetector(
  onTap: () => fotografGalerisiniAc(
    context,
    fotograflar,
    0,
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Image.network(
      fotograflar[0],
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.broken_image, size: 50),
        );
      },
    ),
  ),
),
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x99000000),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '1/${fotograflar.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (fotograflar.length > 1) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Column(
              children: [
                Expanded(
  child: GestureDetector(
                
  onTap: () => fotografGalerisiniAc(
    context,
    fotograflar,
    1,
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Image.network(
      fotograflar[1],
      width: double.infinity,
      fit: BoxFit.cover,
    ),
  ),
),
),
                if (fotograflar.length > 2) ...[
                  const SizedBox(height: 8),
                 Expanded(
  child: GestureDetector(
    onTap: () => fotografGalerisiniAc(
      context,
      fotograflar,
      2,
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            fotograflar[2],
            fit: BoxFit.cover,
          ),
        ),
        if (fotograflar.length > 3)
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0x88000000),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '+${fotograflar.length - 3} Fotoğraf',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    ),
  ),
), 
              ],
],            ),
          ),
        ],
      ],
    ),
  ),
  const SizedBox(height: 8),
],
                 Row(
  children: [
    Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F3FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Yeni İlan',
        style: TextStyle(
          color: Color(0xFF087CF0),
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    const Spacer(),
    IconButton(
      onPressed: () async {
  final prefs = await SharedPreferences.getInstance();
  final liste =
      prefs.getStringList('favori_ilanlar') ?? [];

  final eklendi;

  if (liste.contains(jobId)) {
    liste.remove(jobId);
    eklendi = false;
  } else {
    liste.add(jobId);
    eklendi = true;
  }

  await prefs.setStringList(
    'favori_ilanlar',
    liste,
  );

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        eklendi
            ? 'İlan favorilere eklendi.'
            : 'İlan favorilerden çıkarıldı.',
      ),
    ),
  );
},
      icon: const Icon(
        Icons.favorite_border,
        color: Color(0xFF087CF0),
      ),
    ),
    IconButton(
      onPressed: () async {
  final paylasimMetni =
      '${bilgi(data['title'])}\n'
      'Firma: ${bilgi(data['company'])}\n'
      'Konum: ${bilgi(data['city'])}\n'
      'Ücret / Maaş: ${bilgi(data['salary'])}\n\n'
      '${bilgi(data['description'])}';

  await Clipboard.setData(
    ClipboardData(text: paylasimMetni),
  );

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('İlan bilgileri kopyalandı.'),
    ),
  );
},
      icon: const Icon(
        Icons.share_outlined,
        color: Color(0xFF087CF0),
      ),
    ),
  ],
),
const SizedBox(height: 4), 
                  Text(
  bilgi(data['title']),
  style: const TextStyle(
    fontSize:19 ,
    fontWeight: FontWeight.w800,
    color: Color(0xFF111827),
  ),
),

const SizedBox(height: 3),

Text(
  'İlan No: ${data['ilanNo'] ?? 'Eski İlan'}',
  style: const TextStyle(
    fontSize: 11,
    color: Color(0xFF6B7280),
    fontWeight: FontWeight.w500,
  ),
),

const SizedBox(height: 6),

Container(
  width: double.infinity,
  padding: const EdgeInsets.all(4),
  decoration: BoxDecoration(
    color: const Color(0xFFF8FAFC),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: const Color(0xFFE5E7EB),
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(
            Icons.business_outlined,
            color: Color(0xFF087CF0),
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              bilgi(data['company']),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 5),

      Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: Color(0xFF087CF0),
            size: 18,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              bilgi(data['city']),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 5),

      Row(
        children: [
          const Icon(
            Icons.work_outline,
            color: Color(0xFF087CF0),
            size: 18,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              bilgi(data['category']),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 6),

      Text(
        '${bilgi(data['salary'])} TL / Gün',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF087CF0),
        ),
      ),

      if (tarih.isNotEmpty) ...[
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.access_time,
              size: 15,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(width: 7),
            Text(
              tarih,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    ],
  ),
),

const SizedBox(height: 6),

                 Container(
  width: double.infinity,
  padding: const EdgeInsets.all(4),
  decoration: BoxDecoration(
    color: const Color(0xFFF8FAFC),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: const Color(0xFFE3E8EF),
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'İlan Açıklaması',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF111827),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        bilgi(data['description']),
        style: const TextStyle(
          fontSize: 12,
          height: 1.3,
          color: Color(0xFF374151),
        ),
      ),
    ],
  ),
),

const SizedBox(height: 6),

const Text(
  'İletişim',
  style: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Color(0xFF111827),
  ),
),

const SizedBox(height: 5), 

                  Row(
  children: [
    Expanded(
      child: ElevatedButton.icon(
        onPressed: telefon == 'Belirtilmemiş'
            ? null
            : () => telefonAra(telefon),
        icon: const Icon(Icons.phone),
        label: const Text('ARA'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF087CF0),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: ElevatedButton.icon(
        onPressed: whatsapp == 'Belirtilmemiş'
            ? null
            : () => whatsappAc(whatsapp),
        icon: const Icon(Icons.chat),
        label: const Text('WHATSAPP'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
  ],
),

                  const SizedBox(height: 5),

                  Row(
  children: [
    Expanded(
      child: ElevatedButton.icon(
        onPressed: () {
          final user = FirebaseAuth.instance.currentUser;
          final ownerUid =
              data['ownerUid']?.toString().trim() ?? '';

          if (user == null) {
            mesaj(
              context,
              'Mesaj göndermek için giriş yapmalısınız.',
            );
            return;
          }

          if (ownerUid.isEmpty) {
            mesaj(
              context,
              'İlan sahibi bulunamadı.',
            );
            return;
          }

          if (user.uid == ownerUid) {
            mesaj(
              context,
              'Kendi ilanınıza mesaj gönderemezsiniz.',
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MesajlasmaSayfasi(
                jobId: jobId,
                jobTitle: bilgi(data['title']),
                ownerUid: ownerUid,
              ),
            ),
          );
        },
        icon: const Icon(Icons.message, size: 18),
        label: const Text(
          'MESAJ GÖNDER',
          style: TextStyle(fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF087CF0),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SikayetEtSayfasi(
                jobId: jobId,
                jobTitle: bilgi(data['title']),
              ),
            ),
          );
        },
        icon: const Icon(Icons.flag, size: 18),
        label: const Text(
          'ŞİKAYET ET',
          style: TextStyle(fontSize: 12),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          backgroundColor: const Color(0xFFFFF5F5),
          side: const BorderSide(
            color: Color(0xFFFF3B30),
            width: 1.2,
          ),
          padding: const EdgeInsets.symmetric(vertical: 7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    ),
  ],
),

                        
                      
                    
                  

                  
                    
                  
                
              
          
          
        
      
const SizedBox(height: 12),

// FİRMA BİLGİLERİ
Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  ),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: const Color(0xFFE5E7EB),
      width: 1,
    ),
  ),
  child: Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F7FC),
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Icon(
          Icons.business_outlined,
          size: 19,
          color: Color(0xFF087CF0),
        ),
      ),

      const SizedBox(width: 10),

      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firma Bilgileri',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),

            const SizedBox(height: 3),

            Text(
              bilgi(data['company']),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),

            if (telefon != 'Belirtilmemiş') ...[
              const SizedBox(height: 2),
              Text(
                telefon,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ],
        ),
      ),

      const Icon(
        Icons.chevron_right,
        size: 20,
        color: Color(0xFF9CA3AF),
      ),
    ],
  ),
),

const SizedBox(height: 10),

// KONUM
Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  ),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: const Color(0xFFE5E7EB),
      width: 1,
    ),
  ),
  child: Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F7FC),
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Icon(
          Icons.location_on_outlined,
          size: 20,
          color: Color(0xFF087CF0),
        ),
      ),

      const SizedBox(width: 10),

      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Konum',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),

            const SizedBox(height: 3),

            Text(
              bilgi(data['city']),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4B5563),
              ),
            ),

            if ((data['address'] ?? '')
                .toString()
                .trim()
                .isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                data['address'].toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ],
        ),
      ),

      const SizedBox(width: 8),

      OutlinedButton.icon(
        onPressed: () async {
          final mapsUrl =
              (data['mapsUrl'] ?? '').toString().trim();

          final adres =
              (data['address'] ?? '').toString().trim();

          final sehir =
              (data['city'] ?? '').toString().trim();

          final hedef = [adres, sehir]
              .where((e) => e.isNotEmpty)
              .join(', ');

          Uri? uri;

          if (mapsUrl.isNotEmpty) {
            final link = Uri.tryParse(mapsUrl);

            if (link != null &&
                (link.scheme == 'http' ||
                    link.scheme == 'https')) {
              uri = link;
            }
          }

          if (uri == null && hedef.isNotEmpty) {
            uri = Uri.parse(
              'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(hedef)}',
            );
          }

          if (uri == null) return;

          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        },

        icon: const Icon(
          Icons.map_outlined,
          size: 16,
        ),

        label: const Text(
          'Haritada Gör',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),

        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF087CF0),
          backgroundColor: const Color(0xFFF0F7FF),
          side: BorderSide.none,
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
      ),
    ],
  ),
),          

const SizedBox(height: 16),
      Row(
  children: [
    const Expanded(
      child: Text(
        'Diğer İlanlar',
        style: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const IsAraSayfasi(),
          ),
        );
      },
      child: const Text('TÜMÜNÜ GÖR'),
    ),
  ],
),
const SizedBox(height: 8),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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

              final digerIlanlar = snapshot.data!.docs
                  .where((doc) => doc.id != jobId)
                  .take(4)
                  .toList();

              if (digerIlanlar.isEmpty) {
                return const Text(
                  'Başka ilan bulunamadı.',
                );
              }

              return Column(
                children: digerIlanlar.map((belge) {
                  final digerData = belge.data();

                  return Card(
  elevation: 0,
  margin: const EdgeInsets.only(bottom: 10),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
    side: const BorderSide(
      color: Color(0xFFE3ECF7),
    ),
  ),
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                bilgi(digerData['title']),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              bilgi(digerData['salary']),
              style: const TextStyle(
                color: Color(0xFF087CF0),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          bilgi(digerData['company']),
          style: const TextStyle(
            color: Color(0xFF52617D),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 17,
              color: Color(0xFF7A869F),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                bilgi(digerData['city']),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IlanDetaySayfasi(
                    jobId: belge.id,
                    data: digerData,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF087CF0),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('DETAYLARI GÖR'),
          ),
        ),
      ],
    ),
  ),
);
                }).toList(),  
              );
            },
          ),

          
const SizedBox(height: 30),
        ],
      ),
],
),
);
  }
}
      
 class IkinciElSayfasi extends StatelessWidget {
  const IkinciElSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('secondhand_posts')
        .where('status', isEqualTo: 'approved')
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F6),
      appBar: AppBar(
        title: const Text('İkinci El'),
        backgroundColor: const Color(0xFF18A957),
        foregroundColor: Colors.white,
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
                'Henüz ikinci el ilanı yok.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: ilanlar.length,
            itemBuilder: (context, index) {
              final belge = ilanlar[index];
              final data = belge.data();
             final resimler = data['imageUrls'] is List
    ? List<String>.from(data['imageUrls'])
    : <String>[]; 

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => IkinciElDetaySayfasi(
        data: data,
      ),
    ),
  );
},
leading: ClipRRect(
  borderRadius: BorderRadius.circular(10),
  child: resimler.isNotEmpty
      ? Image.network(
          resimler.first,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 70,
            height: 70,
            color: const Color(0xFFE2F7E9),
            child: const Icon(
              Icons.broken_image,
              color: Color(0xFF18A957),
            ),
          ),
        )
      : Container(
          width: 70,
          height: 70,
          color: const Color(0xFFE2F7E9),
          child: const Icon(
            Icons.shopping_bag_outlined,
            color: Color(0xFF18A957),
          ),
        ),
),
                  
                    
                  
                  title: Text(
                    bilgi(data['title']),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${bilgi(data['category'])}\n'
                    '${bilgi(data['city'])}',
                  ),
                  trailing: Text(
                    '${bilgi(data['price'])} TL',
                    style: const TextStyle(
                      color: Color(0xFF18A957),
                      fontWeight: FontWeight.bold,
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
 class IkinciElIlanVerSayfasi extends StatefulWidget {
  const IkinciElIlanVerSayfasi({super.key});

  @override
  State<IkinciElIlanVerSayfasi> createState() =>
      _IkinciElIlanVerSayfasiState();
}

class _IkinciElIlanVerSayfasiState
    extends State<IkinciElIlanVerSayfasi> {
  final baslik = TextEditingController();
  final fiyat = TextEditingController();
  final konum = TextEditingController();
  final ilce = TextEditingController();
final mahalle = TextEditingController();
final mapsLink = TextEditingController();
  final aciklama = TextEditingController();
  final telefon = TextEditingController();
  final whatsapp = TextEditingController();
  final ImagePicker _ikinciElImagePicker = ImagePicker();
final List<XFile> _ikinciElFotograflar = [];

  String? kategori;
  bool bekle = false;

  final kategoriler = [
    'Araç',
    'Motosiklet',
    'Telefon',
    'Bilgisayar',
    'Elektronik',
    'Ev Eşyası',
    'İnşaat Malzemesi',
    'Giyim',
    'Hobi',
    'Diğer',
  ];
Future<void> ikinciElGaleridenFotografSec() async {
  if (_ikinciElFotograflar.length >= 10) {
    mesaj(context, 'En fazla 10 fotoğraf ekleyebilirsiniz.');
    return;
  }

  final List<XFile> fotograflar =
      await _ikinciElImagePicker.pickMultiImage(
    imageQuality: 75,
  );

  if (fotograflar.isNotEmpty) {
    setState(() {
      final kalan = 10 - _ikinciElFotograflar.length;

      _ikinciElFotograflar.addAll(
        fotograflar.take(kalan),
      );
    });
  }
}
  Future<void> ikinciElKameradanFotografCek() async {
  if (_ikinciElFotograflar.length >= 10) {
    mesaj(context, 'En fazla 10 fotoğraf ekleyebilirsiniz.');
    return;
  }

  final XFile? fotograf =
      await _ikinciElImagePicker.pickImage(
    source: ImageSource.camera,
    imageQuality: 75,
  );

  if (fotograf != null) {
    setState(() {
      _ikinciElFotograflar.add(fotograf);
    });
  }
}
  void ikinciElFotografSil(int index) {
  setState(() {
    _ikinciElFotograflar.removeAt(index);
  });
}
  Future<void> ilanYayinla() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      mesaj(context, 'Önce giriş yapmalısınız.');
      return;
    }

    if (baslik.text.trim().isEmpty ||
        fiyat.text.trim().isEmpty ||
        konum.text.trim().isEmpty ||
        ilce.text.trim().isEmpty ||
        aciklama.text.trim().isEmpty ||
        kategori == null) {
      mesaj(context, 'Zorunlu alanları doldurun.');
      return;
    }

    setState(() {
      bekle = true;
    });
    try {
final List<String> fotografUrlListesi = [];

for (int i = 0; i < _ikinciElFotograflar.length; i++) {
  final fotograf = _ikinciElFotograflar[i];

  final bytes = await fotograf.readAsBytes();
final contentType = fotograf.mimeType ?? 'image/jpeg';

final extension = contentType == 'image/png'
    ? 'png'
    : contentType == 'image/webp'
        ? 'webp'
        : 'jpg';

const supabaseUrl =
    'https://jwdqmfbbbwzjcgmenzdd.supabase.co';

const supabaseKey =
    'sb_publishable_aX-ufKnmFxI57G8t7Tznnw_4SWJ0EOs';

final dosyaYolu =
    '${user.uid}/${DateTime.now().microsecondsSinceEpoch}_$i.$extension';

final response = await http.post(
  Uri.parse(
    '$supabaseUrl/storage/v1/object/ikinci-el-fotograflari/$dosyaYolu',
  ),
  headers: {
    'apikey': supabaseKey,
    'Content-Type': contentType,
  },
  body: bytes,
);

if (response.statusCode < 200 ||
    response.statusCode >= 300) {
  throw Exception(
    'İkinci el fotoğrafı yüklenemedi: ${response.body}',
  );
}

final publicPath =
    dosyaYolu.split('/').map(Uri.encodeComponent).join('/');

final url =
    '$supabaseUrl/storage/v1/object/public/ikinci-el-fotograflari/$publicPath';

fotografUrlListesi.add(url);
}
    
      await FirebaseFirestore.instance
          .collection('secondhand_posts')
          .add({
        'title': baslik.text.trim(),
        'category': kategori,
        'price': fiyat.text.trim(),
        'city': konum.text.trim(),
            'district': ilce.text.trim(),
'neighborhood': mahalle.text.trim(),
'mapsLink': mapsLink.text.trim(),
        'description': aciklama.text.trim(),
        'phone': telefon.text.trim(),
        'whatsapp': whatsapp.text.trim(),
        'ownerUid': user.uid,
        'ownerEmail': user.email ?? '',
        'status': 'approved',
        'featured': false,
        'imageUrls': fotografUrlListesi,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      mesaj(context, 'İkinci el ilanınız yayınlandı.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        mesaj(context, 'İlan yayınlanamadı: $e');
      }
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
    fiyat.dispose();
    konum.dispose();
    ilce.dispose();
mahalle.dispose();
mapsLink.dispose();
    aciklama.dispose();
    telefon.dispose();
    whatsapp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F6),
      appBar: AppBar(
        title: const Text('İkinci El İlanı Ver'),
        backgroundColor: const Color(0xFF18A957),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: baslik,
            decoration: const InputDecoration(
              labelText: 'Ürün Başlığı',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: kategori,
            decoration: const InputDecoration(
              labelText: 'Kategori',
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
            controller: fiyat,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Fiyat',
              suffixText: 'TL',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: konum,
            decoration: const InputDecoration(
              labelText: 'İl',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),
          TextField(
  controller: ilce,
  decoration: const InputDecoration(
    labelText: 'İlçe',
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 12),

TextField(
  controller: mahalle,
  decoration: const InputDecoration(
    labelText: 'Mahalle (isteğe bağlı)',
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 12),

TextField(
  controller: mapsLink,
  decoration: const InputDecoration(
    labelText: 'Google Maps Konum Linki (isteğe bağlı)',
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 12),

          TextField(
            controller: aciklama,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Ürün Açıklaması',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: telefon,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telefon (isteğe bağlı)',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: whatsapp,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'WhatsApp (isteğe bağlı)',
              border: OutlineInputBorder(),
            ),
          ),
          
Row(
  children: [
    Expanded(
      child: ElevatedButton.icon(
        onPressed: ikinciElGaleridenFotografSec,
        icon: const Icon(Icons.photo_library),
        label: const Text('GALERİDEN'),
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: ElevatedButton.icon(
        onPressed: ikinciElKameradanFotografCek,
        icon: const Icon(Icons.camera_alt),
        label: const Text('KAMERA'),
      ),
    ),
  ],
),

const SizedBox(height: 10),

Text(
  'Seçilen fotoğraf: ${_ikinciElFotograflar.length}/10',
  style: const TextStyle(
    fontWeight: FontWeight.bold,
  ),
),
          if (_ikinciElFotograflar.isNotEmpty) ...[
  const SizedBox(height: 10),

  SizedBox(
    height: 95,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _ikinciElFotograflar.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(_ikinciElFotograflar[index].path),
                width: 95,
                height: 95,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              right: -4,
              top: -4,
              child: GestureDetector(
                onTap: () => ikinciElFotografSil(index),
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  ),
],
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: bekle ? null : ilanYayinla,
            icon: const Icon(Icons.publish),
            label: Text(
              bekle
                  ? 'YAYINLANIYOR...'
                  : 'İKİNCİ EL İLANINI YAYINLA',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF18A957),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 55),
            ),
          ),
        ],
      ),
    );
  }
} 
class IkinciElDetaySayfasi extends StatelessWidget {
  final Map<String, dynamic> data;

  const IkinciElDetaySayfasi({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final resimler = data['imageUrls'] is List
        ? List<String>.from(data['imageUrls'])
        : <String>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F6),
      appBar: AppBar(
        title: const Text('İlan Detayı'),
        backgroundColor: const Color(0xFF18A957),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (resimler.isNotEmpty)
  SizedBox(
    height: 280,
    child: PageView.builder(
      itemCount: resimler.length > 10 ? 10 : resimler.length,
      itemBuilder: (context, index) {
        return Stack(
  children: [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          resimler[index],
          width: double.infinity,
          height: 280,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 280,
            color: const Color(0xFFE2F7E9),
            alignment: Alignment.center,
            child: const Icon(
              Icons.broken_image,
              size: 60,
              color: Color(0xFF18A957),
            ),
          ),
        ),
      ),
    ),

    Positioned(
      top: 12,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${index + 1}/${resimler.length > 10 ? 10 : resimler.length}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  ],
);
      },
    ),
  ),

          const SizedBox(height: 18),

          Text(
            bilgi(data['title']),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '${bilgi(data['price'])} TL',
            style: const TextStyle(
              fontSize: 22,
              color: Color(0xFF18A957),
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          Text('Kategori: ${bilgi(data['category'])}'),
          Text('Konum: ${bilgi(data['city'])}'),
          Text('İlçe: ${bilgi(data['district'])}'),

if (bilgi(data['neighborhood']).isNotEmpty)
  Text('Mahalle: ${bilgi(data['neighborhood'])}'),
          
        TextButton.icon(
  onPressed: () async {
    final mapsLink =
        data['mapsLink']?.toString().trim() ?? '';

    Uri uri;

    if (mapsLink.isNotEmpty) {
      var link = mapsLink;

      if (!link.startsWith('http://') &&
          !link.startsWith('https://')) {
        link = 'https://$link';
      }

      uri = Uri.parse(link);
    } else {
      final il =
          data['city']?.toString().trim() ?? '';

      final ilce =
          data['district']?.toString().trim() ?? '';

      final mahalle =
          data['neighborhood']?.toString().trim() ?? '';

      final konumMetni = [
        il,
        ilce,
        mahalle,
      ].where((e) => e.isNotEmpty).join(' ');

      uri = Uri.https(
        'www.google.com',
        '/maps/search/',
        {
          'api': '1',
          'query': konumMetni,
        },
      );
    }

    final acildi = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!acildi && context.mounted) {
      mesaj(
        context,
        'Konum açılamadı.',
      );
    }
  },
  icon: const Icon(Icons.location_on),
  label: const Text('Konumu Haritada Aç'),
), 

          const SizedBox(height: 18),

          const Text(
            'Açıklama',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            bilgi(data['description']),
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
