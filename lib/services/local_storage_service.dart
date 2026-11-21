import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/pizza.dart';

class LocalStorageService {
  // Kunci penyimpanan internal
  static const String _counterKey = 'appCounter';
  static const String _tokenKey = 'userToken';
  static const String _pizzaFileName = 'pizzas_backup.json';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // =========================================================================
  // 1. JSON PARSING (Tahan terhadap JSON korup / broken JSON)[cite: 22, 23]
  // =========================================================================

  /// Memuat dan mem-parsing daftar Pizza dari berkas asset JSON secara aman[cite: 22, 23]
  Future<List<Pizza>> loadPizzasFromAsset(String assetPath) async {
    try {
      final String jsonString = await rootBundle.loadString(assetPath);
      final dynamic decoded = jsonDecode(jsonString);

      if (decoded is List) {
        final List<Pizza> pizzas = [];
        for (final item in decoded) {
          if (item is Map) {
            pizzas.add(Pizza.fromJson(Map<String, dynamic>.from(item)));
          }
        }
        return pizzas;
      }
      return [];
    } catch (e) {
      // Menangkap error jika format JSON rusak total (syntax error)[cite: 22, 23]
      return [];
    }
  }

  // =========================================================================
  // 2. SHARED PREFERENCES (Key-Value sederhana)[cite: 4, 22]
  // =========================================================================

  /// Menyimpan jumlah pembukaan aplikasi ke SharedPreferences[cite: 16, 22]
  Future<void> saveAppCounter(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_counterKey, count);
  }

  /// Mengambil jumlah pembukaan aplikasi dari SharedPreferences (default: 0)[cite: 16, 22]
  Future<int> getAppCounter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_counterKey) ?? 0;
  }

  // =========================================================================
  // 3. FILE STORAGE (path_provider + dart:io)[cite: 18, 19, 22]
  // =========================================================================

  /// Mendapatkan referensi objek File di direktori Documents aplikasi[cite: 18, 19]
  Future<File> _getLocalPizzaFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_pizzaFileName');
  }

  /// Menulis daftar Pizza dalam format JSON ke file lokal dengan try-catch[cite: 19, 22, 23]
  Future<bool> writePizzaFile(List<Pizza> pizzas) async {
    try {
      final file = await _getLocalPizzaFile();
      final String jsonContent =
          jsonEncode(pizzas.map((pizza) => pizza.toJson()).toList());
      await file.writeAsString(jsonContent);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Membaca isi file pizza lokal; mengembalikan pesan default jika gagal/belum ada[cite: 19, 22, 23]
  Future<String> readPizzaFile() async {
    try {
      final file = await _getLocalPizzaFile();
      if (!await file.exists()) {
        return 'File belum dibuat.';
      }
      return await file.readAsString();
    } catch (e) {
      return 'Gagal membaca file: $e';
    }
  }

  // =========================================================================
  // 4. SECURE STORAGE (Data sensitif terenkripsi)[cite: 4, 20, 22]
  // =========================================================================

  /// Menyimpan token pengguna secara aman menggunakan FlutterSecureStorage[cite: 4, 20, 22]
  Future<void> saveUserToken(String token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
    } catch (_) {
      // Tangani potensi exception platform keystore[cite: 23]
    }
  }

  /// Membaca token pengguna dari FlutterSecureStorage[cite: 20, 22]
  Future<String> getUserToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey) ?? '';
    } catch (_) {
      return '';
    }
  }
}