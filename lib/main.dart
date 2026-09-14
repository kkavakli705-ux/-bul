import 'package:flutter/material.dart';

void main() {
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
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F8FF),
      ),
      home: const SettingsScreen(),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;

  final String email = "kkavakli705@gmail.com";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 34,
                    ),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(width: 22),
                  const Text(
                    "Ayarlar",
                    style: TextStyle(
                      fontSize: 31,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 38),

              settingsCard(
                height: 125,
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_circle,
                      size: 44,
                      color: Color(0xFF555960),
                    ),
                    const SizedBox(width: 25),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Hesabım",
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF555960),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              settingsButton(
                icon: Icons.lock_reset,
                title: "Şifremi Değiştir",
                subtitle:
                    "E-posta adresine şifre sıfırlama bağlantısı gönder",
                onTap: showPasswordDialog,
              ),

              const SizedBox(height: 14),

              settingsCard(
                height: 125,
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications,
                      size: 38,
                      color: Color(0xFF555960),
                    ),
                    const SizedBox(width: 27),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Bildirimler",
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            notificationsEnabled
                                ? "Bildirimler açık"
                                : "Bildirimler kapalı",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF555960),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: notificationsEnabled,
                      activeTrackColor: const Color(0xFF3478A8),
                      onChanged: (value) {
                        setState(() {
                          notificationsEnabled = value;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            duration: const Duration(seconds: 1),
                            content: Text(
                              value
                                  ? "Bildirimler açıldı"
                                  : "Bildirimler kapatıldı",
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              settingsButton(
                icon: Icons.security,
                title: "Gizlilik Politikası",
                onTap: showPrivacyDialog,
              ),

              const SizedBox(height: 14),

              settingsButton(
                icon: Icons.description,
                title: "Kullanım Koşulları",
                onTap: showTermsDialog,
              ),

              const SizedBox(height: 14),

              settingsButton(
                icon: Icons.info,
                title: "Uygulama Hakkında",
                subtitle: "İş Bul - Sürüm 0.4.0",
                onTap: showAboutDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget settingsCard({
    required Widget child,
    double? height,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F8),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget settingsButton({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: 105,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 25,
            vertical: 20,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F8),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 38,
                color: const Color(0xFF555960),
              ),
              const SizedBox(width: 27),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF555960),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 26,
                color: Color(0xFF555960),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Şifremi Değiştir"),
          content: Text(
            "$email adresine şifre sıfırlama bağlantısı gönderilecek.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("İptal"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Şifre sıfırlama sistemi hazırlanıyor.",
                    ),
                  ),
                );
              },
              child: const Text("Gönder"),
            ),
          ],
        );
      },
    );
  }

  void showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Gizlilik Politikası"),
          content: const SingleChildScrollView(
            child: Text(
              "İş Bul uygulaması, iş arayanlar ile işverenleri "
              "buluşturmak amacıyla geliştirilmiştir.\n\n"
              "Kullanıcı bilgileri izinsiz olarak üçüncü kişilerle "
              "paylaşılmaz.\n\n"
              "Uygulamanın çalışması için gerekli kullanıcı bilgileri "
              "güvenli şekilde işlenir.",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Tamam"),
            ),
          ],
        );
      },
    );
  }

  void showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Kullanım Koşulları"),
          content: const SingleChildScrollView(
            child: Text(
              "İş Bul uygulamasında yayınlanan ilanların doğruluğundan "
              "ilanı oluşturan kullanıcı sorumludur.\n\n"
              "Sahte, yanıltıcı, yasa dışı veya kötüye kullanım içeren "
              "ilanlar kaldırılabilir.\n\n"
              "Uygulamayı kullanan kullanıcılar bu koşulları kabul "
              "etmiş sayılır.",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Tamam"),
            ),
          ],
        );
      },
    );
  }

  void showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("İş Bul"),
          content: const Text(
            "İş Bul\n\n"
            "Sürüm: 0.4.0\n\n"
            "İş arayanlar ile işverenleri hızlı ve kolay şekilde "
            "buluşturmak için geliştirilmektedir.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Tamam"),
            ),
          ],
        );
      },
    );
  }
}
