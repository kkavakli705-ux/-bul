import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WebAnaSayfa extends StatefulWidget {
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
  State<WebAnaSayfa> createState() => _WebAnaSayfaState();
}

class _WebAnaSayfaState extends State<WebAnaSayfa> {
  final TextEditingController _arama = TextEditingController();

  static const double _maxGenislik = 1180;

  @override
  void dispose() {
    _arama.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FD),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _ustMenu(),
            _hero(),
            _anaKartlar(),
            _hizliIslemler(),
            _ilanBolumu(
              baslik: 'Öne Çıkan İş İlanları',
              ikon: Icons.work_rounded,
              renk: const Color(0xFF0D6EFD),
              ikinciEl: false,
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              tumunuGor: widget.onIsIlanlari,
            ),
            _ilanBolumu(
              baslik: 'Öne Çıkan İkinci El İlanları',
              ikon: Icons.shopping_cart_rounded,
              renk: const Color(0xFF18A84C),
              ikinciEl: true,
              stream: FirebaseFirestore.instance
                  .collection('secondhand_posts')
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              tumunuGor: widget.onIkinciEl,
            ),
            _guvenBolumu(),
            _footer(),
          ],
        ),
      ),
    );
  }

  double _yatayBosluk(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 600) return 14;
    if (width < 900) return 18;
    return 24;
  }

  Widget _ustMenu() {
    final width = MediaQuery.of(context).size.width;
    final mobil = width < 720;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: _yatayBosluk(context),
        vertical: mobil ? 11 : 14,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxGenislik),
          child: Row(
            children: [
              const _GozatLogo(),
              const Spacer(),

              if (!mobil) ...[
                _menuButon(
                  'Ana Sayfa',
                  () {},
                ),
                _menuButon(
                  'İş İlanları',
                  widget.onIsIlanlari,
                ),
                _menuButon(
                  'İkinci El',
                  widget.onIkinciEl,
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: widget.onGiris,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D6EFD),
                    side: const BorderSide(
                      color: Color(0xFF0D6EFD),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Giriş Yap'),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: widget.onGiris,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Kayıt Ol'),
                ),
              ] else ...[
                IconButton(
                  tooltip: 'Giriş Yap',
                  onPressed: widget.onGiris,
                  icon: const Icon(
                    Icons.account_circle_outlined,
                    size: 30,
                    color: Color(0xFF0D6EFD),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuButon(
    String yazi,
    VoidCallback onTap,
  ) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF172033),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 17,
        ),
      ),
      child: Text(
        yazi,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _hero() {
    final width = MediaQuery.of(context).size.width;
    final mobil = width < 600;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF06386F),
            Color(0xFF087CF0),
            Color(0xFF0CA487),
          ],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: _yatayBosluk(context),
        vertical: mobil ? 42 : 62,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _maxGenislik,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gözat360',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: mobil ? 42 : 62,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 720,
                ),
                child: Text(
                  'İş ilanları ve ikinci el ürünleri\nkolayca bul, ilan ver.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: mobil ? 20 : 28,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  maxWidth: 880,
                ),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.search,
                      color: Color(0xFF718096),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _arama,
                        onSubmitted: (_) {
                          widget.onIsIlanlari();
                        },
                        decoration: const InputDecoration(
                          hintText: 'Ne arıyorsunuz?',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: widget.onIsIlanlari,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        padding: EdgeInsets.symmetric(
                          horizontal: mobil ? 20 : 32,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
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
                children: const [
                  _Etiket(
                    icon: Icons.work_outline,
                    yazi: 'İş İlanları',
                  ),
                  _Etiket(
                    icon: Icons.people_outline,
                    yazi: 'Personel',
                  ),
                  _Etiket(
                    icon: Icons.directions_car_outlined,
                    yazi: 'Otomobil',
                  ),
                  _Etiket(
                    icon: Icons.home_outlined,
                    yazi: 'Ev & Yaşam',
                  ),
                  _Etiket(
                    icon: Icons.devices_outlined,
                    yazi: 'Elektronik',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _anaKartlar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _yatayBosluk(context),
        26,
        _yatayBosluk(context),
        14,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _maxGenislik,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final dar = constraints.maxWidth < 760;
              const gap = 18.0;

              final kartGenisligi = dar
                  ? constraints.maxWidth
                  : (constraints.maxWidth - gap) / 2;

              return Wrap(
                spacing: gap,
                runSpacing: dar ? 14 : gap,
                children: [
                  SizedBox(
                    width: kartGenisligi,
                    child: _buyukKart(
                      baslik: 'İş İlanları',
                      aciklama:
                          'Binlerce iş ilanını incele, sana uygun işi kolayca bul.',
                      ikon: Icons.work_rounded,
                      renk1: const Color(0xFF0666EA),
                      renk2: const Color(0xFF19B5F8),
                      buton1: 'İş İlanlarını İncele',
                      onButon1: widget.onIsIlanlari,
                      buton2: 'İş İlanı Ver',
                      onButon2: widget.onIsIlaniVer,
                    ),
                  ),
                  SizedBox(
                    width: kartGenisligi,
                    child: _buyukKart(
                      baslik: 'İkinci El',
                      aciklama:
                          'İkinci el ürünleri keşfet, al, sat ve ilanını yayınla.',
                      ikon: Icons.shopping_cart_rounded,
                      renk1: const Color(0xFF12A83E),
                      renk2: const Color(0xFF48D962),
                      buton1: 'İkinci El İlanlarını İncele',
                      onButon1: widget.onIkinciEl,
                      buton2: 'İkinci El İlanı Ver',
                      onButon2: widget.onIkinciElIlanVer,
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
    required IconData ikon,
    required Color renk1,
    required Color renk2,
    required String buton1,
    required VoidCallback onButon1,
    required String buton2,
    required VoidCallback onButon2,
  }) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            renk1,
            renk2,
          ],
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
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  ikon,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  baslik,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            aciklama,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.4,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
                child: Text(buton1),
              ),
              FilledButton(
                onPressed: onButon2,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.13),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
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

  Widget _hizliIslemler() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _yatayBosluk(context),
        4,
        _yatayBosluk(context),
        26,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _maxGenislik,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              int kolon;

              if (constraints.maxWidth >= 1000) {
                kolon = 4;
              } else if (constraints.maxWidth >= 600) {
                kolon = 2;
              } else {
                kolon = 1;
              }

              const gap = 14.0;

              final kartGenislik =
                  (constraints.maxWidth - ((kolon - 1) * gap)) / kolon;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: kartGenislik,
                    child: _hizliKart(
                      Icons.search_rounded,
                      'İş İlanları',
                      'Yeni iş fırsatlarını keşfet.',
                      widget.onIsIlanlari,
                    ),
                  ),
                  SizedBox(
                    width: kartGenislik,
                    child: _hizliKart(
                      Icons.edit_note_rounded,
                      'İş İlanı Ver',
                      'İş fırsatını herkese duyur.',
                      widget.onIsIlaniVer,
                    ),
                  ),
                  SizedBox(
                    width: kartGenislik,
                    child: _hizliKart(
                      Icons.shopping_cart_outlined,
                      'İkinci El',
                      'Satılık ürünleri incele.',
                      widget.onIkinciEl,
                    ),
                  ),
                  SizedBox(
                    width: kartGenislik,
                    child: _hizliKart(
                      Icons.add_box_outlined,
                      'İkinci El İlanı Ver',
                      'Ürününü satışa çıkar.',
                      widget.onIkinciElIlanVer,
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

  Widget _hizliKart(
    IconData ikon,
    String baslik,
    String aciklama,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFE8EDF5),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
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
                  ikon,
                  color: const Color(0xFF0D6EFD),
                ),
              ),
              const SizedBox(width: 13),
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
                    const SizedBox(height: 4),
                    Text(
                      aciklama,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF768196),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ilanBolumu({
    required String baslik,
    required IconData ikon,
    required Color renk,
    required bool ikinciEl,
    required Stream<QuerySnapshot<Map<String, dynamic>>> stream,
    required VoidCallback tumunuGor,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _yatayBosluk(context),
        16,
        _yatayBosluk(context),
        26,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _maxGenislik,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    ikon,
                    color: renk,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      baslik,
                      style: const TextStyle(
                        color: Color(0xFF172033),
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: tumunuGor,
                    child: const Text('Tümünü Gör →'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _bilgiKutusu(
                      'İlanlar şu anda yüklenemedi.',
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(35),
                      child: CircularProgressIndicator(),
                    );
                  }

                  final ilanlar = [...snapshot.data!.docs];

                  ilanlar.sort(
                    (a, b) {
                      final aFeatured = _oneCikan(a.data()) ? 1 : 0;
                      final bFeatured = _oneCikan(b.data()) ? 1 : 0;

                      if (aFeatured != bFeatured) {
                        return bFeatured.compareTo(aFeatured);
                      }

                      final aCreated = a.data()['createdAt'];
                      final bCreated = b.data()['createdAt'];

                      final aTime = aCreated is Timestamp
                          ? aCreated.millisecondsSinceEpoch
                          : 0;

                      final bTime = bCreated is Timestamp
                          ? bCreated.millisecondsSinceEpoch
                          : 0;

                      return bTime.compareTo(aTime);
                    },
                  );

                  final secilen = ilanlar.take(4).toList();

                  if (secilen.isEmpty) {
                    return _bilgiKutusu(
                      'Henüz yayınlanmış ilan bulunmuyor.',
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      int kolon;

                      if (constraints.maxWidth >= 1000) {
                        kolon = 4;
                      } else if (constraints.maxWidth >= 600) {
                        kolon = 2;
                      } else {
                        kolon = 1;
                      }

                      const gap = 16.0;

                      final kartGenisligi =
                          (constraints.maxWidth -
                                  ((kolon - 1) * gap)) /
                              kolon;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: secilen.map(
                          (doc) {
                            return SizedBox(
                              width: kartGenisligi,
                              child: _ilanKarti(
                                data: doc.data(),
                                ikinciEl: ikinciEl,
                                renk: renk,
                                onTap: tumunuGor,
                              ),
                            );
                          },
                        ).toList(),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ilanKarti({
    required Map<String, dynamic> data,
    required bool ikinciEl,
    required Color renk,
    required VoidCallback onTap,
  }) {
    final baslik =
        (data['title'] ?? 'İlan').toString().trim();

    final konum =
        (data['city'] ?? '').toString().trim();

    final altBilgi = ikinciEl
        ? _fiyat(data['price'])
        : (data['company'] ?? data['salary'] ?? '')
            .toString()
            .trim();

    String? foto;

    final imageUrls = data['imageUrls'];

    if (imageUrls is List && imageUrls.isNotEmpty) {
      foto = imageUrls.first?.toString();
    }

    final oneCikan = _oneCikan(data);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFE6ECF4),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (foto != null && foto.isNotEmpty)
                      Image.network(
                        foto,
                        fit: BoxFit.cover,
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return _fotoYok(renk);
                        },
                      )
                    else
                      _fotoYok(renk),

                    if (oneCikan)
                      Positioned(
                        left: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Öne Çıkan',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baslik,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    if (altBilgi.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        altBilgi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ikinciEl
                              ? renk
                              : const Color(0xFF5F6B7D),
                          fontWeight: ikinciEl
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                    ],

                    if (konum.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 17,
                            color: Color(0xFF718096),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              konum,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF718096),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fotoYok(Color renk) {
    return Container(
      color: renk.withOpacity(0.08),
      child: Icon(
        Icons.image_outlined,
        color: renk,
        size: 48,
      ),
    );
  }

  String _fiyat(dynamic deger) {
    final yazi = deger?.toString().trim() ?? '';

    if (yazi.isEmpty) {
      return 'Fiyat belirtilmemiş';
    }

    if (yazi.toLowerCase().contains('tl')) {
      return yazi;
    }

    return '$yazi TL';
  }

  bool _oneCikan(
    Map<String, dynamic> data,
  ) {
    if (data['featured'] != true) {
      return false;
    }

    final until = data['featuredUntil'];

    if (until is Timestamp) {
      return until.toDate().isAfter(
            DateTime.now(),
          );
    }

    return true;
  }

  Widget _bilgiKutusu(
    String yazi,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5EAF2),
        ),
      ),
      child: Text(
        yazi,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF667085),
        ),
      ),
    );
  }

  Widget _guvenBolumu() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        _yatayBosluk(context),
        28,
        _yatayBosluk(context),
        34,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _maxGenislik,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              int kolon;

              if (constraints.maxWidth >= 1000) {
                kolon = 4;
              } else if (constraints.maxWidth >= 600) {
                kolon = 2;
              } else {
                kolon = 1;
              }

              const gap = 14.0;

              final kartGenisligi =
                  (constraints.maxWidth -
                          ((kolon - 1) * gap)) /
                      kolon;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: kartGenisligi,
                    child: const _BilgiKart(
                      icon: Icons.shield_outlined,
                      baslik: 'Güvenli İlanlar',
                      aciklama:
                          'Güvenli ve kolay kullanım',
                    ),
                  ),
                  SizedBox(
                    width: kartGenisligi,
                    child: const _BilgiKart(
                      icon: Icons.groups_outlined,
                      baslik: 'Geniş Kullanıcı Ağı',
                      aciklama:
                          'İş ve alışveriş tek yerde',
                    ),
                  ),
                  SizedBox(
                    width: kartGenisligi,
                    child: const _BilgiKart(
                      icon: Icons.bolt_outlined,
                      baslik: 'Kolay ve Hızlı',
                      aciklama:
                          'Hızlıca ilan ver ve keşfet',
                    ),
                  ),
                  SizedBox(
                    width: kartGenisligi,
                    child: const _BilgiKart(
                      icon: Icons.location_on_outlined,
                      baslik: 'Bölgesel İlanlar',
                      aciklama:
                          'Bulunduğun bölgede ara',
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

  Widget _footer() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF07172C),
      padding: EdgeInsets.symmetric(
        horizontal: _yatayBosluk(context),
        vertical: 34,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _maxGenislik,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final dar =
                  constraints.maxWidth < 700;

              if (dar) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _GozatLogo(
                      koyuArkaPlan: true,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'İş ilanları ve ikinci el ürünler tek yerde.',
                      style: TextStyle(
                        color: Color(0xFFB7C2D4),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      children: [
                        TextButton(
                          onPressed: widget.onIsIlanlari,
                          child: const Text(
                            'İş İlanları',
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onIkinciEl,
                          child: const Text(
                            'İkinci El',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '© 2026 Gözat360',
                      style: TextStyle(
                        color: Color(0xFF8E9CB2),
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _GozatLogo(
                          koyuArkaPlan: true,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'İş ilanları ve ikinci el ürünler tek yerde.',
                          style: TextStyle(
                            color: Color(0xFFB7C2D4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  TextButton(
                    onPressed: widget.onIsIlanlari,
                    child: const Text(
                      'İş İlanları',
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onIkinciEl,
                    child: const Text(
                      'İkinci El',
                    ),
                  ),

                  const SizedBox(width: 35),

                  const Text(
                    '© 2026 Gözat360',
                    style: TextStyle(
                      color: Color(0xFF8E9CB2),
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
}

class _GozatLogo extends StatelessWidget {
  const _GozatLogo({
    this.koyuArkaPlan = false,
  });

  final bool koyuArkaPlan;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 29,
          fontWeight: FontWeight.w900,
          color: koyuArkaPlan
              ? Colors.white
              : const Color(0xFF0D6EFD),
        ),
        children: const [
          TextSpan(
            text: 'Gözat',
          ),
          TextSpan(
            text: '360',
            style: TextStyle(
              color: Color(0xFF20B947),
            ),
          ),
        ],
      ),
    );
  }
}

class _Etiket extends StatelessWidget {
  const _Etiket({
    required this.icon,
    required this.yazi,
  });

  final IconData icon;
  final String yazi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.20),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white24,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            yazi,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _BilgiKart extends StatelessWidget {
  const _BilgiKart({
    required this.icon,
    required this.baslik,
    required this.aciklama,
  });

  final IconData icon;
  final String baslik;
  final String aciklama;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8EDF5),
        ),
      ),
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
                    color: Color(0xFF758197),
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
