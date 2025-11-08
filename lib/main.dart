import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'home_page.dart';
import 'onboarding_preferences.dart';

// Bu satırı ekle:
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i oluşturulan ayarlarla başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}


// ... diğer kodlar ...

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Material 3 için ana rengi tanımlıyoruz
  static const Color _kSeedColor = Color(0xFFC00000); // Koyu Kırmızı

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bite App',
      theme: ThemeData(
        // Tema verilerini Material 3'e uygun şekilde oluştur
        
        // 1. colorScheme: Ana renk ve parlaklık ayarlanır
        colorScheme: ColorScheme.fromSeed(
          seedColor: _kSeedColor, // Tüm temayı bu renge göre oluştur
          brightness: Brightness.dark, // Koyu tema modu
        ).copyWith(
          // İhtiyaç duyarsanız 'secondary' (vurgu) rengini manuel olarak beyaz yapabilirsiniz
          secondary: Colors.white,
        ),
        
        // 2. scaffoldBackgroundColor: Arka plan rengini manuel olarak ayarla
        scaffoldBackgroundColor: _kSeedColor,

        // 3. AppBar teması: AppBar'ın rengini ayarla (isteğe bağlı)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // AppBar rengi
          foregroundColor: _kSeedColor, // Başlık ve ikon rengi
        ),

        useMaterial3: true,
      ),
      // AuthStatusChecker: Oturum durumunu dinler ve yönlendirir
      home: const AuthStatusChecker(), 
    );
  }
}

// ... diğer kodlar ...

// main.dart (AuthStatusChecker sınıfı güncelleniyor)
// NOT: Firestore importunu main.dart'a eklediğinizden emin olun!
// import 'package:cloud_firestore/cloud_firestore.dart';

class AuthStatusChecker extends StatelessWidget {
  const AuthStatusChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          // Oturum Açmamışsa -> Login Sayfası
          return const LoginPage(); 
        } else {
          // Oturum Açmışsa -> Tercihleri Kontrol Et
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator(color: Colors.white)),
                );
              }
              
              if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                // Hata veya kullanıcı dokümanı yoksa (Bu durum nadir olmalı)
                return const LoginPage(); 
              }

              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              final onboardingCompleted = userData['onboarding_completed'] ?? false;

              if (onboardingCompleted == true) {
                // Tercihler tamamlanmışsa -> Ana Sayfa
                return const HomePage(); 
              } else {
                // Tercihler tamamlanmamışsa -> Onboarding Sayfası
                return const OnboardingPreferencesPage(); 
              }
            },
          );
        }
      },
    );
  }
}