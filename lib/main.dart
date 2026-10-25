import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OkulAjandasiApp());
}

class OkulAjandasiApp extends StatelessWidget {
  const OkulAjandasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ders Asistanım',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
          surface: const Color(0xFF0F172A),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0F1D),
      ),
      home: const AnaEkran(),
    );
  }
}

class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  int _seciliSekme = 0;
  List<Map<String, dynamic>> _dersler = [];
  List<Map<String, dynamic>> _odevler = [];
  List<Map<String, dynamic>> _sinavlar = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dersler = List<Map<String, dynamic>>.from(
          jsonDecode(prefs.getString('dersler') ?? '[]'));
      _odevler = List<Map<String, dynamic>>.from(
          jsonDecode(prefs.getString('odevler') ?? '[]'));
      _sinavlar = List<Map<String, dynamic>>.from(
          jsonDecode(prefs.getString('sinavlar') ?? '[]'));
      _yukleniyor = false;
    });
  }

  Future<void> _kaydet(String anahtar, List<Map<String, dynamic>> liste) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(anahtar, jsonEncode(liste));
  }

  String _bugunkuGunAdi() {
    const gunler = [
      'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'
    ];
    return gunler[DateTime.now().weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

    final sayfalar = [
      _ozetSayfasi(),
      _dersProgramiSayfasi(),
      _odevlerSayfasi(),
      _sinavlarSayfasi(),
    ];

    return Scaffold(
      body: SafeArea(child: sayfalar[_seciliSekme]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _seciliSekme,
        backgroundColor: const Color(0xFF131C31),
        indicatorColor: const Color(0xFF6366F1).withOpacity(0.3),
        onDestinationSelected: (idx) => setState(() => _seciliSekme = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Özet'),
          NavigationDestination(icon: Icon(Icons.calendar_today_rounded), label: 'Program'),
          NavigationDestination(icon: Icon(Icons.assignment_rounded), label: 'Ödevler'),
          NavigationDestination(icon: Icon(Icons.timer_rounded), label: 'Sınavlar'),
        ],
      ),
    );
  }

  // --- 1. ÖZET SAYFASI (Günün Dersleri ve Bekleyen Ödevler) ---
  Widget _ozetSayfasi() {
    final bugun = _bugunkuGunAdi();
    final bugunkuDersler = _dersler.where((d) => d['gun'] == bugun).toList();
    final bekleyenOdevler = _odevler.where((o) => !(o['tamam'] ?? false)).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bugünün Özeti',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(DateFormat('dd MMMM yyyy').format(DateTime.now()),
                    style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF6366F1)),
              ),
              child: Text(bugun,
                  style: const TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Bugünün Dersleri Kartı
        _bolumBasligi('Bugünkü Dersler (${bugunkuDersler.length})', Icons.menu_book_rounded),
        const SizedBox(height: 10),
        if (bugunkuDersler.isEmpty)
          _bosKutucuk('Bugün için kayıtlı ders yok 🎉')
        else
          ...bugunkuDersler.map((ders) => Card(
                color: const Color(0xFF1E293B),
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school, color: Color(0xFF818CF8)),
                  ),
                  title: Text(ders['ad'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text(
                      '${ders['saatBasla'] ?? ''} - ${ders['saatBitis'] ?? ''} • ${ders['derslik'] ?? 'Sınıf belirtilmedi'}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ),
              )),

        const SizedBox(height: 24),

        // Bekleyen Ödevler Kartı
        _bolumBasligi('Bekleyen Ödevler (${bekleyenOdevler.length})', Icons.pending_actions_rounded),
        const SizedBox(height: 10),
        if (bekleyenOdevler.isEmpty)
          _bosKutucuk('Tüm ödevler tamamlandı!')
        else
          ...bekleyenOdevler.map((odev) => Card(
                color: const Color(0xFF1E293B),
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Checkbox(
                    value: odev['tamam'] ?? false,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (val) {
                      setState(() {
                        odev['tamam'] = val;
                        _kaydet('odevler', _odevler);
                      });
                    },
                  ),
                  title: Text(odev['ad'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('Ders: ${odev['ders'] ?? ''} • Son: ${odev['tarih'] ?? ''}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ),
              )),
      ],
    );
  }

  // --- 2. DERS PROGRAMI SAYFASI ---
  Widget _dersProgramiSayfasi() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Haftalık Program', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6366F1),
        onPressed: _yeniDersEkleDiyalog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _dersler.isEmpty
          ? _bosKutucuk('Henüz ders eklenmedi. Sağ alttaki butondan ekle.')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _dersler.length,
              itemBuilder: (ctx, i) {
                final d = _dersler[i];
                return Dismissible(
                  key: Key(d['ad'] + i.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.redAccent,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    setState(() {
                      _dersler.removeAt(i);
                      _kaydet('dersler', _dersler);
                    });
                  },
                  child: Card(
                    color: const Color(0xFF1E293B),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(d['ad'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('${d['gun']} • ${d['saatBasla']} - ${d['saatBitis']} (${d['derslik'] ?? ''})'),
                      trailing: const Icon(Icons.drag_indicator, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // --- 3. ÖDEVLER SAYFASI ---
  Widget _odevlerSayfasi() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Ödev Listesi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6366F1),
        onPressed: _yeniOdevEkleDiyalog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _odevler.isEmpty
          ? _bosKutucuk('Ödev yok! Keyfine bak.')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _odevler.length,
              itemBuilder: (ctx, i) {
                final o = _odevler[i];
                final bool tamam = o['tamam'] ?? false;
                return Dismissible(
                  key: Key(o['ad'] + i.toString()),
                  onDismissed: (_) {
                    setState(() {
                      _odevler.removeAt(i);
                      _kaydet('odevler', _odevler);
                    });
                  },
                  background: Container(color: Colors.redAccent, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                  child: Card(
                    color: const Color(0xFF1E293B),
                    child: ListTile(
                      leading: Checkbox(
                        value: tamam,
                        activeColor: const Color(0xFF10B981),
                        onChanged: (val) {
                          setState(() {
                            o['tamam'] = val;
                            _kaydet('odevler', _odevler);
                          });
                        },
                      ),
                      title: Text(o['ad'] ?? '',
                          style: TextStyle(
                            color: tamam ? Colors.grey : Colors.white,
                            decoration: tamam ? TextDecoration.lineThrough : null,
                            fontWeight: FontWeight.bold,
                          )),
                      subtitle: Text('${o['ders']} • Teslim: ${o['tarih']}'),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // --- 4. SINAVLAR SAYFASI ---
  Widget _sinavlarSayfasi() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Sınav Takvimi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6366F1),
        onPressed: _yeniSinavEkleDiyalog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _sinavlar.isEmpty
          ? _bosKutucuk('Yaklaşan sınavın yok.')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sinavlar.length,
              itemBuilder: (ctx, i) {
                final s = _sinavlar[i];
                return Card(
                  color: const Color(0xFF1E293B),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.event_note, color: Colors.amber),
                    title: Text(s['ders'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text('Tarih: ${s['tarih']} • Notlar: ${s['not'] ?? '-'}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _sinavlar.removeAt(i);
                          _kaydet('sinavlar', _sinavlar);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  // --- YARDIMCI BİLEŞENLER ---
  Widget _bolumBasligi(String baslik, IconData ikon) {
    return Row(
      children: [
        Icon(ikon, size: 20, color: const Color(0xFF818CF8)),
        const SizedBox(width: 8),
        Text(baslik, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _bosKutucuk(String mesaj) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF131C31),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(mesaj, style: TextStyle(color: Colors.grey[500])),
    );
  }

  // --- DİYALOGLAR (EKLEME PENCERELERİ) ---
  void _yeniDersEkleDiyalog() {
    final adKontrol = TextEditingController();
    final derslikKontrol = TextEditingController();
    final baslaKontrol = TextEditingController(text: '08:30');
    final bitisKontrol = TextEditingController(text: '09:10');
    String seciliGun = 'Pazartesi';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Yeni Ders Ekle', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: adKontrol, decoration: const InputDecoration(labelText: 'Ders Adı (Örn: Fizik)')),
                DropdownButton<String>(
                  value: seciliGun,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E293B),
                  items: ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (val) => setDialogState(() => seciliGun = val!),
                ),
                TextField(controller: derslikKontrol, decoration: const InputDecoration(labelText: 'Derslik / Sınıf')),
                Row(
                  children: [
                    Expanded(child: TextField(controller: baslaKontrol, decoration: const InputDecoration(labelText: 'Başlangıç'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: bitisKontrol, decoration: const InputDecoration(labelText: 'Bitiş'))),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () {
                if (adKontrol.text.isNotEmpty) {
                  setState(() {
                    _dersler.add({
                      'ad': adKontrol.text,
                      'gun': seciliGun,
                      'derslik': derslikKontrol.text,
                      'saatBasla': baslaKontrol.text,
                      'saatBitis': bitisKontrol.text,
                    });
                    _kaydet('dersler', _dersler);
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _yeniOdevEkleDiyalog() {
    final adKontrol = TextEditingController();
    final dersKontrol = TextEditingController();
    final tarihKontrol = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Yeni Ödev Ekle', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: dersKontrol, decoration: const InputDecoration(labelText: 'Ders Adı')),
            TextField(controller: adKontrol, decoration: const InputDecoration(labelText: 'Ödev Konusu / Açıklama')),
            TextField(controller: tarihKontrol, decoration: const InputDecoration(labelText: 'Teslim Tarihi (Örn: Cuma)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              if (adKontrol.text.isNotEmpty) {
                setState(() {
                  _odevler.add({
                    'ad': adKontrol.text,
                    'ders': dersKontrol.text,
                    'tarih': tarihKontrol.text,
                    'tamam': false,
                  });
                  _kaydet('odevler', _odevler);
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _yeniSinavEkleDiyalog() {
    final dersKontrol = TextEditingController();
    final tarihKontrol = TextEditingController();
    final notKontrol = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Sınav Tarihi Ekle', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: dersKontrol, decoration: const InputDecoration(labelText: 'Ders Adı')),
            TextField(controller: tarihKontrol, decoration: const InputDecoration(labelText: 'Sınav Tarihi (Örn: 15 Kasım)')),
            TextField(controller: notKontrol, decoration: const InputDecoration(labelText: 'Konular / Not')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              if (dersKontrol.text.isNotEmpty) {
                setState(() {
                  _sinavlar.add({
                    'ders': dersKontrol.text,
                    'tarih': tarihKontrol.text,
                    'not': notKontrol.text,
                  });
                  _kaydet('sinavlar', _sinavlar);
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
