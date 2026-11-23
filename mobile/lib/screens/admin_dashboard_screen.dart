import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final SupabaseService _service = SupabaseService.instance;
  List<DhikrModel> _adhkar = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _service.fetchAdhkar();
    setState(() {
      _adhkar = data;
      _loading = false;
    });
  }

  void _showAddEditDialog([DhikrModel? dhikr]) {
    final titleController = TextEditingController(text: dhikr?.adminTitle ?? '');
    final textController = TextEditingController(text: dhikr?.text ?? '');
    final virtueController = TextEditingController(text: dhikr?.virtue ?? '');
    final repeatsController = TextEditingController(text: (dhikr?.repeats ?? 1).toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(dhikr == null ? 'إضافة ذكر جديد' : 'تعديل الذكر', style: GoogleFonts.ibmPlexSansArabic()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'العنوان الإداري')),
                TextField(controller: textController, decoration: const InputDecoration(labelText: 'متن الذكر بالتشكيل'), maxLines: 3),
                TextField(controller: virtueController, decoration: const InputDecoration(labelText: 'فضل وثواب الذكر')),
                TextField(controller: repeatsController, decoration: const InputDecoration(labelText: 'عدد التكرار'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final newDhikr = DhikrModel(
                  id: dhikr?.id ?? 'dhikr-${DateTime.now().millisecondsSinceEpoch}',
                  adminTitle: titleController.text,
                  text: textController.text,
                  category: dhikr?.category ?? 'general',
                  repeats: int.tryParse(repeatsController.text) ?? 1,
                  virtue: virtueController.text,
                  status: 'active',
                );
                await _service.saveDhikr(newDhikr);
                Navigator.pop(context);
                _load();
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة تحكم المسؤول', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _adhkar.length,
              itemBuilder: (context, idx) {
                final item = _adhkar[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(item.adminTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showAddEditDialog(item)),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _service.deleteDhikr(item.id);
                            _load();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
