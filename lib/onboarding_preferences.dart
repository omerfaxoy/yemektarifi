import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart'; // Tercihler kaydedildikten sonra gidilecek sayfa

class OnboardingPreferencesPage extends StatefulWidget {
  const OnboardingPreferencesPage({super.key});

  @override
  State<OnboardingPreferencesPage> createState() => _OnboardingPreferencesPageState();
}

class _OnboardingPreferencesPageState extends State<OnboardingPreferencesPage> {
  final TextEditingController _preferencesController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _preferencesController.dispose();
    super.dispose();
  }

  // Kullanıcı tercihlerini Firestore'a kaydetme
  Future<void> _savePreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _errorMessage = 'Oturum açık değil. Lütfen tekrar giriş yapın.');
      return;
    }

    if (_preferencesController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Lütfen tercihlerinizi yazın.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Mevcut kullanıcının Firestore dokümanını güncelleme
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'food_preferences': _preferencesController.text.trim(),
        'onboarding_completed': true, // Bu adımı tamamladığına dair işaret
      });

      // Kayıt başarılı, ana sayfaya yönlendir
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Tercih kaydı başarısız: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tercihlerini Belirle', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        automaticallyImplyLeading: false, // Geri butonunu kaldır
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Başlık
            Text(
              'Seni Tanıyalım!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sevdiğin yemekleri, alerjilerini veya diyet tercihlerini (vegan, glutensiz vb.) yazarak daha isabetli tarifler alabilirsin.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 30),

            // Tercih Giriş Alanı
            TextField(
              controller: _preferencesController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Örn: Veganım, acı severim, mantar sevmem...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
                fillColor: Colors.grey[100],
                filled: true,
              ),
            ),
            const SizedBox(height: 30),

            // Hata Mesajı
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),

            // Kaydet Butonu
            ElevatedButton(
              onPressed: _isLoading ? null : _savePreferences,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Tercihleri Kaydet ve Başla',
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}