import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// Gemini API Bilgileri
const String _geminiApiKey = 'AIzaSyCFN7euMTUqk1QOklh8LtUr-VnnEzYqTyk';
const String _geminiEndpoint =
    'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash-lite:generateContent';

class SuggestorPage extends StatefulWidget {
  final String ingredients;

  const SuggestorPage({super.key, required this.ingredients});

  @override
  State<SuggestorPage> createState() => _SuggestorPageState();
}

class _SuggestorPageState extends State<SuggestorPage> {
  List<String> _recipes = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getRecipes();
  }

  // Gemini API'den yemek isimlerini çek
  Future<void> _getRecipes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prompt = """
      Aşağıdaki malzemelerle yapılabilecek 5 farklı yemek öner.
      Yanıtı yalnızca JSON formatında string listesi olarak döndür.
      Örnek:
      ["Yemek 1", "Yemek 2", "Yemek 3", "Yemek 4", "Yemek 5"]
      Malzemeler: ${widget.ingredients}
      """;

      final response = await http.post(
        Uri.parse('$_geminiEndpoint?key=$_geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      print('📬 Gemini yanıt kodu: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var text =
            data['candidates'][0]['content']['parts'][0]['text'] ?? '[]';

        // 🧹 Gereksiz biçimlendirmeleri temizle (```json, '''json, vb.)
        text = text
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .replaceAll("'''json", '')
            .replaceAll("'''", '')
            .trim();

        // 🧠 Denemeli parse: önce JSON olarak parse et, hata olursa fallback
        try {
          final List<dynamic> decoded = jsonDecode(text);
          setState(() => _recipes = decoded.cast<String>());
        } catch (jsonError) {
          print('⚠️ JSON parse hatası: $jsonError');
          // JSON formatı bozuksa düz metin olarak göster
          setState(() => _errorMessage =
              'Gemini yanıtı JSON formatında değil:\n$text');
        }
      } else {
        setState(() {
          _errorMessage =
              'Tarif API hatası: ${response.statusCode}\nYanıt: ${response.body}';
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'İstek hatası: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  // yemek.com arama URL’si (doğru format)
  String _buildRecipeUrl(String recipeName) {
    final query = Uri.encodeComponent(recipeName);
    return 'https://yemek.com/tarif/?q=$query';
  }

  // Link açma fonksiyonu
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlantı açılamadı')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Yemek Önerileri', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                        color: Theme.of(context).primaryColor),
                    const SizedBox(height: 10),
                    const Text('Sizin için tarifler hazırlanıyor...',
                        style: TextStyle(color: Colors.black54)),
                  ],
                ),
              )
            : _errorMessage != null
                ? Text('Hata: $_errorMessage',
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold))
                : _recipes.isEmpty
                    ? const Center(
                        child: Text('Henüz öneri bulunamadı.'),
                      )
                    : ListView.builder(
                        itemCount: _recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = _recipes[index];
                          final url = _buildRecipeUrl(recipe);
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                recipe,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              subtitle: const Text('Kaynak: yemek.com'),
                              trailing:
                                  const Icon(Icons.open_in_new, color: Colors.orange),
                              onTap: () => _openUrl(url),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
