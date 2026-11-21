import 'package:flutter/material.dart';
import 'model/pizza.dart';
import 'services/local_storage_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Challenge Persistensi - NamaPanggilan',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: false,
      ),
      home: const StorageChallengePage(),
    );
  }
}

class StorageChallengePage extends StatefulWidget {
  const StorageChallengePage({super.key});

  @override
  State<StorageChallengePage> createState() => _StorageChallengePageState();
}

class _StorageChallengePageState extends State<StorageChallengePage> {
  final LocalStorageService _storageService = LocalStorageService();
  final TextEditingController _tokenController = TextEditingController();

  List<Pizza> _pizzas = [];
  int _appCounter = 0;
  String _fileContent = 'Belum ada data file yang dibaca';
  String _savedToken = '';

  @override
  void initState() {
    super.initState();
    _initAllData();
  }

  Future<void> _initAllData() async {
    // 1. Tambah dan simpan appCounter[cite: 16, 22]
    int currentCount = await _storageService.getAppCounter();
    currentCount++;
    await _storageService.saveAppCounter(currentCount);

    // 2. Muat data dari pizzalist_broken.json untuk menguji ketahanan parsing[cite: 22, 23]
    final loadedPizzas =
        await _storageService.loadPizzasFromAsset('assets/pizzalist_broken.json');

    // 3. Simpan hasil parsing bersih ke file lokal[cite: 19, 22]
    await _storageService.writePizzaFile(loadedPizzas);

    // 4. Baca token tersimpan[cite: 20, 22]
    final token = await _storageService.getUserToken();

    setState(() {
      _appCounter = currentCount;
      _pizzas = loadedPizzas;
      _savedToken = token;
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Challenge: LocalStorageService'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bagian 1: SharedPreferences Counter[cite: 16, 17, 22]
          Card(
            child: ListTile(
              title: Text('App dibuka sebanyak: $_appCounter kali'),
              trailing: ElevatedButton(
                onPressed: () async {
                  await _storageService.saveAppCounter(0);
                  setState(() => _appCounter = 0);
                },
                child: const Text('Reset'),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Bagian 2: Secure Storage Token[cite: 20, 22]
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Secure Storage (User Token)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _tokenController,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan token rahasia...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await _storageService
                              .saveUserToken(_tokenController.text);
                          final updated = await _storageService.getUserToken();
                          setState(() => _savedToken = updated);
                        },
                        child: const Text('Simpan Token'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Token tersimpan: ${_savedToken.isEmpty ? "(kosong)" : _savedToken}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Bagian 3: File I/O (path_provider + dart:io)[cite: 18, 19, 22]
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final content = await _storageService.readPizzaFile();
                      setState(() => _fileContent = content);
                    },
                    child: const Text('Baca File Backup JSON'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _fileContent,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bagian 4: Hasil Parsing Broken JSON[cite: 22, 23]
          const Text(
            'Hasil Parsing pizzalist_broken.json:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._pizzas.map(
            (pizza) => Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${pizza.id}')),
                title: Text(pizza.pizzaName),
                subtitle: Text('${pizza.description}\nHarga: \$${pizza.price}'),
                isThreeLine: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}