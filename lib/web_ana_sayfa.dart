import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WebAnaSayfa extends StatelessWidget {
  const WebAnaSayfa({
    super.key,
    required this.onGiris,
    required this.onCikis,
    required this.onIsIlanlari,
    required this.onIsIlaniVer,
    required this.onIkinciEl,
    required this.onIkinciElIlanVer,
    required this.onKendiIlanlarim,
    required this.onIsDetay,
    required this.onIkinciElDetay,
  });

  final VoidCallback onGiris;
  final VoidCallback onCikis;
  final VoidCallback onIsIlanlari;
  final VoidCallback onIsIlaniVer;
  final VoidCallback onIkinciEl;
  final VoidCallback onIkinciElIlanVer;
  final VoidCallback onKendiIlanlarim;
  final void Function(String id, Map<String, dynamic> data) onIsDetay;
  final void Function(String id, Map<String, dynamic> data) onIkinciElDetay;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final girisVar = user != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Gözat360',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (girisVar)
            IconButton(
              tooltip: 'Çıkış Yap',
              onPressed: onCikis,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
            children: [
              const Text(
                'Gözat360',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF087CF0), Color(0xFF18A84C)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Text(
                      'İş ve İkinci El Bir Arada',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'İş fırsatlarını keşfet, ikinci el ürünleri bul veya kolayca ilan ver.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (girisVar)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        const Text('Giriş yapıldı', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(user.email ?? ''),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: onGiris,
                    icon: const Icon(Icons.login),
                    label: const Text('GİRİŞ YAP / KAYIT OL'),
                  ),
                ),
              const SizedBox(height: 14),
              _AnaKart(
                renk1: const Color(0xFF1194FF),
                renk2: const Color(0xFF087CF0),
                ikon: Icons.search,
                baslik: 'İŞ İLANLARI',
                alt: 'Sana uygun iş fırsatlarını keşfet',
                onTap: onIsIlanlari,
              ),
              const SizedBox(height: 12),
              _AnaKart(
                renk1: const Color(0xFF38A9FF),
                renk2: const Color(0xFF1688F5),
                ikon: Icons.edit_note,
                baslik: 'İŞ İLANI VER',
                alt: 'İş fırsatını herkese duyur',
                onTap: girisVar ? onIsIlaniVer : onGiris,
              ),
              const SizedBox(height: 12),
              _AnaKart(
                renk1: const Color(0xFF2DD56F),
                renk2: const Color(0xFF12AD50),
                ikon: Icons.shopping_cart_outlined,
                baslik: 'İKİNCİ EL',
                alt: 'Aradığın ikinci el ürünü bul',
                onTap: onIkinciEl,
              ),
              const SizedBox(height: 12),
              _AnaKart(
                renk1: const Color(0xFF43DB76),
                renk2: const Color(0xFF20BA58),
                ikon: Icons.sell_outlined,
                baslik: 'İKİNCİ EL İLANI VER',
                alt: 'Ürününü kolayca ilanla',
                onTap: girisVar ? onIkinciElIlanVer : onGiris,
              ),
              if (girisVar) ...[
                const SizedBox(height: 14),
                _AltKart(
                  ikon: Icons.list_alt,
                  baslik: 'KENDİ İLANLARIM',
                  alt: 'Tüm ilanlarını görüntüle ve yönet',
                  onTap: onKendiIlanlarim,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AnaKart extends StatelessWidget {
  const _AnaKart({
    required this.renk1,
    required this.renk2,
    required this.ikon,
    required this.baslik,
    required this.alt,
    required this.onTap,
  });

  final Color renk1;
  final Color renk2;
  final IconData ikon;
  final String baslik;
  final String alt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        height: 82,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [renk1, renk2]),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: Colors.white.withOpacity(.15), shape: BoxShape.circle),
              child: Icon(ikon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(baslik, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(alt, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 34),
          ],
        ),
      ),
    );
  }
}

class _AltKart extends StatelessWidget {
  const _AltKart({required this.ikon, required this.baslik, required this.alt, required this.onTap});

  final IconData ikon;
  final String baslik;
  final String alt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Row(
          children: [
            Icon(ikon, size: 28, color: const Color(0xFF405A7A)),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(baslik, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF142A4A))),
                  const SizedBox(height: 3),
                  Text(alt, style: const TextStyle(fontSize: 11, color: Color(0xFF63738A))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF63738A)),
          ],
        ),
      ),
    );
  }
}
