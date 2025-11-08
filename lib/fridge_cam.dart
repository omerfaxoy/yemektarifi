import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'suggestor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

// Gemini API Bilgileri
const String _geminiApiKey = 'AIzaSyCFN7euMTUqk1QOklh8LtUr-VnnEzYqTyk';
const String _geminiEndpoint =
    'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash-lite:generateContent';

class FridgeCamPage extends StatefulWidget {
  const FridgeCamPage({super.key});

  @override
  State<FridgeCamPage> createState() => _FridgeCamPageState();
}

class _FridgeCamPageState extends State<FridgeCamPage> {
  File? _imageFile;
  bool _isLoading = false;
  String? _errorMessage;
  String? _resultText; // Gemini cevabı metin olarak saklanacak

  // Fotoğraf çekme veya galeriden seçme
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _errorMessage = null;
        _resultText = null;
      });
      _sendToGemini(); // Seçildikten sonra direkt analiz
    }
  }

  // Gemini API'ye gönderim
  Future<void> _sendToGemini() async {
    if (_imageFile == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bytes = await _imageFile!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final prompt =
          "Bu fotoğraftaki buzdolabında hangi yiyecekler var? Görseli analiz edip malzemeleri listele.";

      final response = await http.post(
        Uri.parse('$_geminiEndpoint?key=$_geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
                {
                  "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": base64Image,
                  }
                }
              ]
            }
          ]
        }),
      );

      print('📬 Gemini yanıt kodu: ${response.statusCode}');
      print('📦 Yanıt gövdesi: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text =
            data['candidates'][0]['content']['parts'][0]['text'] ?? 'Sonuç alınamadı';
        setState(() => _resultText = text);
      } else {
        setState(() {
          _errorMessage =
              'Gemini API hatası: ${response.statusCode}\n${response.body}';
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'İstek hatası: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buzdolabı Kamerası', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ... (Görsel Alanı widget'ı aynı kalıyor) ...
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Theme.of(context).primaryColor, width: 2),
              ),
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Theme.of(context).primaryColor),
                          const SizedBox(height: 10),
                          const Text('Görsel analiz ediliyor...', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    )
                  : _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : Center(
                          child: Text(
                            'Buzdolabının fotoğrafını çekin.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
            ),

            const SizedBox(height: 20),

            // Hata Mesajı
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),

            // Sonuç
            if (_resultText != null)
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _resultText!,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),

            const SizedBox(height: 20),
            
            // Yeni Buton: Yemek Öner (Sadece sonuç varsa göster)
            if (_resultText != null && !_isLoading)
              ElevatedButton.icon(
                icon: const Icon(Icons.restaurant_menu, color: Colors.white),
                label: const Text(
                  'Bu Malzemelerle Yemek Öner',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  // Yemek öneri sayfasına yönlendirme ve analiz sonucunu aktarma
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SuggestorPage(ingredients: _resultText!),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Farklı renk
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

            // Butonlar
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text('Kamera ile Fotoğraf Çek',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library, color: Colors.grey),
              label: const Text('Galeriden Seç',
                  style: TextStyle(color: Colors.black54, fontSize: 16)),
              onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.grey[300]!),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}