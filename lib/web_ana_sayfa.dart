import 'package:flutter/material.dart';

class WebAnaSayfa extends StatelessWidget {
  const WebAnaSayfa({
    super.key,
    required this.onGiris,
    required this.onIsIlanlari,
    required this.onIsIlaniVer,
    required this.onIkinciEl,
    required this.onIkinciElIlanVer,
  });

  final VoidCallback onGiris;
  final VoidCallback onIsIlanlari;
  final VoidCallback onIsIlaniVer;
  final VoidCallback onIkinciEl;
  final VoidCallback onIkinciElIlanVer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FD),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _ustMenu(context),
            _hero(context),
            _anaKartlar(context),
            _hizliBolum(context),
            _altBilgi(),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _ustMenu(BuildContext context) {
    final genislik = MediaQuery.of(context).size.width;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 14,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                  children: [
                    TextSpan(
                      text: 'Gözat',
                      style: TextStyle(
                        color: Color(0xFF0D6EFD),
                      ),
                    ),
                    TextSpan(
                      text: '360',
                      style: TextStyle(
                        color: Color(0xFF21B84B),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              if (genislik > 750) ...[
                TextButton(
                  onPressed: () {},
                  child: const Text('Ana Sayfa'),
                ),
                TextButton(
                  onPressed: onIsIlanlari,
                  child: const Text('İş İlanları'),
                ),
                TextButton(
                  onPressed: onIkinciEl,
                  child: const Text('İkinci El'),
                ),
                const SizedBox(width: 12),
              ],

              OutlinedButton(
                onPressed: onGiris,
                child: const Text('Giriş Yap'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onGiris,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6EFD),
                ),
                child: const Text('Kayıt Ol'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 65,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF063B79),
            Color(0xFF087CF0),
            Color(0xFF16AD72),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gözat360',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'İş ilanları ve ikinci el ürünleri\nkolayca bul, ilan ver.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 28),

              Container(
                constraints: const BoxConstraints(maxWidth: 850),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.search,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Ne arıyorsunuz?',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: onIsIlanlari,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 18,
                        ),
                      ),
                      child: const Text('Ara'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _etiket(Icons.work_outline, 'İş İlanları'),
                  _etiket(Icons.people_outline, 'Personel'),
                  _etiket(Icons.directions_car, 'Otomobil'),
                  _etiket(Icons.home_outlined, 'Ev & Yaşam'),
                  _etiket(Icons.devices, 'Elektronik'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _etiket(IconData icon, String yazi) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 6),
          Text(
            yazi,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _anaKartlar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1150),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final dar = constraints.maxWidth < 750;

              return Flex(
                direction: dar ? Axis.vertical : Axis.horizontal,
                children: [
                  Expanded(
                    flex: dar ? 0 : 1,
                    child: _buyukKart(
                      baslik: 'İş İlanları',
                      aciklama:
                          'Sana uygun iş fırsatlarını kolayca keşfet.',
                      icon: Icons.work_rounded,
                      renk1: const Color(0xFF0666EA),
                      renk2: const Color(0xFF18B4F8),
                      buton1: 'İş İlanlarını İncele',
                      onButon1: onIsIlanlari,
                      buton2: 'İş İlanı Ver',
                      onButon2: onIsIlaniVer,
                    ),
                  ),

                  SizedBox(
                    width: dar ? 0 : 18,
                    height: dar ? 18 : 0,
                  ),

                  Expanded(
                    flex: dar ? 0 : 1,
                    child: _buyukKart(
                      baslik: 'İkinci El',
                      aciklama:
                          'İkinci el ürünleri keşfet, al, sat ve ilan ver.',
                      icon: Icons.shopping_cart_rounded,
                      renk1: const Color(0xFF12A83E),
                      renk2: const Color(0xFF46D65E),
                      buton1: 'İkinci El İlanlarını İncele',
                      onButon1: onIkinciEl,
                      buton2: 'İkinci El İlanı Ver',
                      onButon2: onIkinciElIlanVer,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buyukKart({
    required String baslik,
    required String aciklama,
    required IconData icon,
    required Color renk1,
    required Color renk2,
    required String buton1,
    required VoidCallback onButon1,
    required String buton2,
    required VoidCallback onButon2,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [renk1, renk2],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 14),
          Text(
            baslik,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            aciklama,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: onButon1,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: renk1,
                ),
                child: Text(buton1),
              ),
              OutlinedButton(
                onPressed: onButon2,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(
                    color: Colors.white,
                  ),
                ),
                child: Text(buton2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hizliBolum(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        10,
        24,
        40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gözat360 ile her şey tek yerde',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),

              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _kucukKart(
                    Icons.work_outline,
                    'İş İlanları',
                    'Yeni iş fırsatlarını keşfet.',
                    onIsIlanlari,
                  ),
                  _kucukKart(
                    Icons.add_business,
                    'İş İlanı Ver',
                    'İş ilanını yayınla.',
                    onIsIlaniVer,
                  ),
                  _kucukKart(
                    Icons.shopping_cart_outlined,
                    'İkinci El',
                    'Ürünleri incele.',
                    onIkinciEl,
                  ),
                  _kucukKart(
                    Icons.add_box_outlined,
                    'İkinci El İlanı Ver',
                    'Ürününü satışa çıkar.',
                    onIkinciElIlanVer,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kucukKart(
    IconData icon,
    String baslik,
    String aciklama,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: 270,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF0D6EFD),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        baslik,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        aciklama,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _altBilgi() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1150),
          child: Wrap(
            spacing: 18,
            runSpacing: 18,
            children: const [
              _BilgiKutusu(
                icon: Icons.shield_outlined,
                baslik: 'Güvenli İlanlar',
                aciklama: 'Kolay ve güvenli kullanım',
              ),
              _BilgiKutusu(
                icon: Icons.groups_outlined,
                baslik: 'Geniş Kullanıcı Ağı',
                aciklama: 'İş ve alışveriş tek yerde',
              ),
              _BilgiKutusu(
                icon: Icons.bolt_outlined,
                baslik: 'Kolay ve Hızlı',
                aciklama: 'Hızlıca ilan ver ve keşfet',
              ),
              _BilgiKutusu(
                icon: Icons.location_on_outlined,
                baslik: 'Bölgesel İlanlar',
                aciklama: 'Bulunduğun bölgede ara',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF08182E),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 35,
      ),
      child: const Center(
        child: Text(
          'Gözat360  •  İş ilanları ve ikinci el ürünler tek yerde.  © 2026',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _BilgiKutusu extends StatelessWidget {
  const _BilgiKutusu({
    required this.icon,
    required this.baslik,
    required this.aciklama,
  });

  final IconData icon;
  final String baslik;
  final String aciklama;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 265,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF0D6EFD),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  aciklama,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
