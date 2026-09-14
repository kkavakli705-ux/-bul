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
  }

  Future<void> giris() async {
    if (email.text.trim().isEmpty || sifre.text.trim().isEmpty) {
      mesaj(context, 'E-posta ve şifreyi doldurun.');
      return;
    }

    if (kayit) {
      if (sifreTekrar.text.trim().isEmpty) {
        mesaj(context, 'Şifrenizi tekrar yazın.');
        return;
      }

      if (sifre.text.trim() != sifreTekrar.text.trim()) {
        mesaj(context, 'Şifreler aynı değil.');
        return;
      }

      if (sifre.text.trim().length < 6) {
        mesaj(context, 'Şifre en az 6 karakter olmalı.');
        return;
      }
    }

    setState(() {
      bekle = true;
    });

    try {
      if (kayit) {
        final sonuc =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: sifre.text.trim(),
        );

        if (sonuc.user != null) {
          await kullaniciKaydiOlustur(sonuc.user!);

          await sonuc.user!.sendEmailVerification();

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
          email: email.text.trim(),
          password: sifre.text.trim(),
        );

        final user = sonuc.user;

        if (user != null) {
          await user.reload();

          final yenilenenUser = FirebaseAuth.instance.currentUser;

          if (yenilenenUser != null &&
              !yenilenenUser.emailVerified) {
            try {
              await yenilenenUser.sendEmailVerification();
            } catch (_) {}

            await FirebaseAuth.instance.signOut();

            if (mounted) {
              mesaj(
                context,
                'E-posta adresin henüz doğrulanmamış. '
                'Doğrulama bağlantısı tekrar gönderildi.',
              );
            }

            return;
          }

          await kullaniciKaydiOlustur(yenilenenUser ?? user);

          if (mounted) {
            Navigator.pop(context);
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String hata = 'İşlem yapılamadı.';

      if (e.code == 'email-already-in-use') {
        hata = 'Bu e-posta adresi zaten kayıtlı.';
      } else if (e.code == 'invalid-email') {
        hata = 'Geçerli bir e-posta adresi yazın.';
      } else if (e.code == 'weak-password') {
        hata = 'Şifre çok zayıf.';
      } else if (e.code == 'user-not-found') {
        hata = 'Bu e-posta ile kayıtlı hesap bulunamadı.';
      } else if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        hata = 'E-posta veya şifre yanlış.';
      } else if (e.code == 'too-many-requests') {
        hata = 'Çok fazla deneme yapıldı. Biraz sonra tekrar deneyin.';
      } else if (e.message != null) {
        hata = e.message!;
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

  Future<void> smsGonder() async {
    String numara = telefon.text.trim().replaceAll(' ', '');

    if (numara.isEmpty) {
      mesaj(context, 'Telefon numaranızı yazın.');
      return;
    }

    if (numara.startsWith('0')) {
      numara = '+90${numara.substring(1)}';
    } else if (!numara.startsWith('+')) {
      numara = '+90$numara';
    }

    setState(() {
      bekle = true;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: numara,
      timeout: const Duration(seconds: 60),

      verificationCompleted:
          (PhoneAuthCredential credential) async {
        try {
          final sonuc =
              await FirebaseAuth.instance.signInWithCredential(
            credential,
          );

          if (sonuc.user != null) {
            await kullaniciKaydiOlustur(sonuc.user!);

            if (mounted) {
              Navigator.pop(context);
            }
          }
        } catch (_) {
          if (mounted) {
            mesaj(context, 'Telefon doğrulaması yapılamadı.');
          }
        }

        if (mounted) {
          setState(() {
            bekle = false;
          });
        }
      },

      verificationFailed: (FirebaseAuthException e) {
        String hata = 'SMS gönderilemedi.';

        if (e.code == 'invalid-phone-number') {
          hata = 'Telefon numarası geçersiz.';
        } else if (e.code == 'too-many-requests') {
          hata = 'Çok fazla SMS istendi. Daha sonra tekrar deneyin.';
        } else if (e.message != null) {
          hata = e.message!;
        }

        if (mounted) {
          mesaj(context, hata);

          setState(() {
            bekle = false;
          });
        }
      },

      codeSent: (String id, int? resendToken) {
        if (mounted) {
          setState(() {
            verificationId = id;
            smsGonderildi = true;
            bekle = false;
          });

          mesaj(context, 'SMS doğrulama kodu gönderildi.');
        }
      },

      codeAutoRetrievalTimeout: (String id) {
        verificationId = id;

        if (mounted) {
          setState(() {
            bekle = false;
          });
        }
      },
    );
  }

  Future<void> smsDogrula() async {
    if (smsKodu.text.trim().length != 6) {
      mesaj(context, '6 haneli SMS kodunu yazın.');
      return;
    }

    if (verificationId.isEmpty) {
      mesaj(context, 'Önce SMS kodu gönderin.');
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

        if (mounted) {
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      String hata = 'SMS kodu doğrulanamadı.';

      if (e.code == 'invalid-verification-code') {
        hata = 'SMS kodu yanlış.';
      } else if (e.code == 'session-expired') {
        hata = 'SMS kodunun süresi doldu. Yeniden kod gönderin.';
      } else if (e.message != null) {
        hata = e.message!;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          telefonModu
              ? 'Telefon ile Giriş'
              : kayit
                  ? 'Kayıt Ol'
                  : 'Giriş Yap',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: bekle
                      ? null
                      : () {
                          setState(() {
                            telefonModu = false;
                            smsGonderildi = false;
                          });
                        },
                  icon: const Icon(Icons.email),
                  label: const Text('E-POSTA'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: bekle
                      ? null
                      : () {
                          setState(() {
                            telefonModu = true;
                          });
                        },
                  icon: const Icon(Icons.phone),
                  label: const Text('TELEFON'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          if (!telefonModu) ...[
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

            if (kayit) ...[
              const SizedBox(height: 15),
              TextField(
                controller: sifreTekrar,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Şifre Tekrar',
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            const SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed: bekle ? null : giris,
              icon: bekle
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      kayit ? Icons.person_add : Icons.login,
                    ),
              label: Text(
                kayit ? 'KAYIT OL' : 'GİRİŞ YAP',
              ),
            ),

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
                    ? 'Zaten hesabım var'
                    : 'Hesabım yok, kayıt ol',
              ),
            ),

            if (kayit)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Kayıt tamamlanınca e-posta adresine doğrulama '
                  'bağlantısı gönderilir. E-posta doğrulanmadan '
                  'hesaba giriş yapılamaz.',
                  textAlign: TextAlign.center,
                ),
              ),
          ],

          if (telefonModu) ...[
            TextField(
              controller: telefon,
              enabled: !smsGonderildi,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefon Numarası',
                hintText: '05XX XXX XX XX',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),

            const SizedBox(height: 15),

            if (!smsGonderildi)
              ElevatedButton.icon(
                onPressed: bekle ? null : smsGonder,
                icon: bekle
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.sms),
                label: const Text('SMS KODU GÖNDER'),
              ),

            if (smsGonderildi) ...[
              TextField(
                controller: smsKodu,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'SMS Doğrulama Kodu',
                  hintText: '6 haneli kod',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),

              const SizedBox(height: 10),

              ElevatedButton.icon(
                onPressed: bekle ? null : smsDogrula,
                icon: bekle
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.verified),
                label: const Text('KODU DOĞRULA'),
              ),

              TextButton(
                onPressed: bekle
                    ? null
                    : () {
                        setState(() {
                          smsGonderildi = false;
                          smsKodu.clear();
                          verificationId = '';
                        });
                      },
                child: const Text(
                  'Telefon numarasını değiştir / Yeni kod iste',
                ),
              ),
            ],

            const Padding(
              padding: EdgeInsets.only(top: 15),
              child: Text(
                'Telefon ile girişte ayrıca şifre gerekmez. '
                'Telefonuna gelen SMS kodu hesabı doğrular.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
