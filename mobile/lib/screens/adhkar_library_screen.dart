import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';
import '../core/constants/constants.dart';

class AdhkarLibraryScreen extends StatefulWidget {
  const AdhkarLibraryScreen({super.key});

  @override
  State<AdhkarLibraryScreen> createState() => _AdhkarLibraryScreenState();
}

class _AdhkarLibraryScreenState extends State<AdhkarLibraryScreen> {
  final SupabaseService _service = SupabaseService.instance;
  List<DhikrModel> _adhkar = [];
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _loading = true;

  final List<Map<String, String>> _categories = const [
    {'id': 'all', 'name': 'الكل'},
    {'id': 'morning_evening', 'name': 'الصباح والمساء'},
    {'id': 'general', 'name': 'أذكار عامة'},
    {'id': 'prayer', 'name': 'بعد الصلاة'},
    {'id': 'sleep', 'name': 'النوم'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAdhkar();
  }

  Future<void> _loadAdhkar() async {
    setState(() => _loading = true);
    final data = await _service.fetchAdhkar();
    setState(() {
      _adhkar = data;
      _loading = false;
    });
  }

  List<DhikrModel> get _filteredList {
    return _adhkar.where((d) {
      final matchesCat = _selectedCategory == 'all' || d.category == _selectedCategory;
      final matchesQuery = _searchQuery.isEmpty ||
          d.text.contains(_searchQuery) ||
          d.adminTitle.contains(_searchQuery) ||
          d.virtue.contains(_searchQuery);
      return matchesCat && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مكتبة الأذكار', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث في متن الذكر أو فضله...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Categories Filter Tabs
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final cat = _categories[idx];
                final isSelected = _selectedCategory == cat['id'];
                return ChoiceChip(
                  label: Text(cat['name']!),
                  selected: isSelected,
                  selectedColor: AppConstants.primary,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : null, fontWeight: FontWeight.bold),
                  onSelected: (_) => setState(() => _selectedCategory = cat['id']!),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Adhkar List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredList.length,
                    itemBuilder: (context, idx) {
                      final item = _filteredList[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.adminTitle,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConstants.secondary),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppConstants.primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('${item.repeats} مرات', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item.text,
                                style: GoogleFonts.notoNaskhArabic(fontSize: 18, height: 1.8, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                              if (item.virtue.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.star, size: 16, color: Colors.amber),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          item.virtue,
                                          style: const TextStyle(fontSize: 12, color: Colors.brown),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
