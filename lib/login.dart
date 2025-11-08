import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'home_page.dart'; // yönlendirme için ekledik

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLogin = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  // 🔐 Firebase Giriş İşlemi
  Future<void> _handleLogin() async {
    setState(() => _errorMessage = null);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // ✅ Başarılıysa yönlendir
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      print('🔥 FirebaseAuthException: ${e.code} - ${e.message}');
      setState(() {
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          _errorMessage = 'E-posta veya şifre hatalı.';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'Geçersiz e-posta formatı.';
        } else if (e.code == 'too-many-requests') {
          _errorMessage = 'Çok fazla deneme yaptınız. Lütfen biraz bekleyin.';
        } else {
          _errorMessage = 'Bir hata oluştu: ${e.message ?? e.code}';
        }
      });
    } on PlatformException catch (e) {
      _errorMessage = 'Cihaz bağlantı hatası: ${e.message ?? "Platform hatası"}';
    } catch (e) {
      _errorMessage = 'Beklenmeyen bir hata oluştu: $e';
    }
  }

  // 🧾 Firebase Kayıt İşlemi
  Future<void> _handleSignup() async {
    setState(() => _errorMessage = null);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final username = _usernameController.text.trim();

      if (username.isEmpty) {
        setState(() => _errorMessage = 'Kullanıcı adı boş olamaz.');
        return;
      }

      // 1. Kullanıcıyı Firebase Authentication'a kaydet
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // 2. Firestore'a ek profil verilerini ve başlangıç durumunu kaydet
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'username': username,
        'email': email,
        'created_at': FieldValue.serverTimestamp(),
        // Kullanıcının tercih sayfasını görmesi için başlangıç değeri:
        'onboarding_completed': false, 
        'food_preferences': '', // Boş bir tercih alanı ekleyebiliriz
      });

      // 3. Yönlendirmeyi Kaldırıyoruz. 
      // Authentication durumu değiştiği için main.dart'taki AuthStatusChecker
      // devreye girecek ve kullanıcıyı 'onboarding_completed: false' olduğu için
      // OnboardingPreferencesPage sayfasına yönlendirecektir.
      
      // NOT: Hızlı bir deneyim için direkt yönlendirme yapmak isterseniz:
      if (mounted) {
        // Yönlendirmeyi Onboarding sayfasına yapıyoruz, ancak 
        // AuthStatusChecker'ın devreye girmesi tercih edilir. 
        // Aşağıdaki kod bloğu yerine yorum satırı eklenmiştir.
        
        /* Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingPreferencesPage()),
        ); 
        */
      }
    } on FirebaseAuthException catch (e) {
      print('🔥 FirebaseAuthException: ${e.code} - ${e.message}');
      setState(() {
        if (e.code == 'weak-password') {
          _errorMessage = 'Şifre çok zayıf.';
        } else if (e.code == 'email-already-in-use') {
          _errorMessage = 'Bu e-posta zaten kullanılıyor.';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'Geçersiz e-posta adresi.';
        } else {
          _errorMessage = 'FirebaseAuth hatası: ${e.message ?? e.code}';
        }
      });
    } on FirebaseException catch (e) {
      _errorMessage = 'Firestore hatası: ${e.message}';
    } catch (e) {
      _errorMessage = 'Beklenmeyen bir hata oluştu: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Afiapp',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 50),
              Container(
                padding: const EdgeInsets.all(25.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (!_isLogin)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: TextFormField(
                          controller: _usernameController,
                          decoration: _inputDecoration.copyWith(
                            hintText: 'Kullanıcı Adı',
                            prefixIcon:
                                const Icon(Icons.person, color: Colors.grey),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration.copyWith(
                          hintText: 'E-posta',
                          prefixIcon:
                              const Icon(Icons.email, color: Colors.grey),
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: _inputDecoration.copyWith(
                        hintText: 'Şifre',
                        prefixIcon:
                            const Icon(Icons.lock, color: Colors.grey),
                      ),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        onPressed: _isLogin ? _handleLogin : _handleSignup,
                        child: Text(
                          _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _errorMessage = null;
                        });
                      },
                      child: Text(
                        _isLogin
                            ? 'Hesabın yok mu? Hemen Kayıt Ol'
                            : 'Zaten hesabın var mı? Giriş Yap',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
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

  final InputDecoration _inputDecoration = const InputDecoration(
    contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
    fillColor: Color(0xFFF0F0F0),
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      borderSide:
          BorderSide(color: Color(0xFFC00000), width: 2),
    ),
  );
}
