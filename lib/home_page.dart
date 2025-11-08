import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'fridge_cam.dart'; // Buzdolabı kamera sayfamız

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Tema rengi main.dart'ta belirlendi (koyu kırmızı)
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bite', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Theme.of(context).primaryColor, // Koyu Kırmızı
        elevation: 0, // AppBar'ın gölgesini kaldırır
        actions: [
          // Oturum Kapatma Butonu (Sağ üstteki profil ikonuna benzer)
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () {
              // Firebase oturumunu kapatma
              FirebaseAuth.instance.signOut();
              // main.dart'taki AuthStatusChecker otomatik olarak LoginPage'e yönlendirecektir.
            },
          ),
        ],
      ),
      // Resimdeki gibi koyu kırmızı arka plan
      backgroundColor: Theme.of(context).primaryColor, 
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Uygulama Adı/Motto
              const Text(
                'Ne pişireceğini mi düşünüyorsun?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 50),

              // Buzdolabı Kamerasına Git Butonu
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt, color: Color(0xFFC00000), size: 30), // Koyu Kırmızı ikon
                label: const Text(
                  'Buzdolabını Tara',
                  style: TextStyle(
                    color: Color(0xFFC00000), // Koyu Kırmızı yazı
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  // FridgeCamPage sayfasına yönlendirme
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FridgeCamPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // Beyaz buton
                  padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0), // Yuvarlak köşeler
                  ),
                  elevation: 5, // Hafif gölge
                ),
              ),
              
              const SizedBox(height: 10),

              // Diğer menü öğeleri için yer tutucu
              const Text(
                'Favoriler, sipariş geçmişi ve profilin burada yer alacak.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}