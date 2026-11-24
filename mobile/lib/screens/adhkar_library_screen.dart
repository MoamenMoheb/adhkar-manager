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
  String _morningEveningSubFilter = 'all'; // 'all', 'morning', 'evening'
  String _searchQuery = '';
  bool _loading = true;
  final Map<String, int> _localCounters = {};

  final List<Map<String, String>> _categories = const [
    {'id': 'all', 'name': 'الكل'},
    {'id': 'morning_evening', 'name': 'الصباح والمساء'},
    {'id': 'general', 'name': 'أذكار عامة'},
    {'id': 'prayer', 'name': 'بعد الصلاة'},
    {'id': 'sleep', 'name': 'النوم'},
    {'id': 'quranic', 'name': 'أدعية قرآنية'},
    {'id': 'travel', 'name': 'السفر'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAdhkar();
  }

  Future<void> _loadAdhkar() async {
    setState(() => _loading = true);
    final data = await _service.fetchAdhkar();
    if (!mounted) return;
    setState(() {
      _adhkar = data;
      _loading = false;
    });
  }

  bool _matchesSubFilter(DhikrModel d) {
    if (_selectedCategory != 'morning_evening' || _morningEveningSubFilter == 'all') {
      return true;
    }
    final title = d.adminTitle;
    if (_morningEveningSubFilter == 'morning') {
      return title.contains('الصباح') || (!title.contains('المساء'));
    }
    if (_morningEveningSubFilter == 'evening') {
      return title.contains('المساء') || (!title.contains('الصباح'));
    }
    return true;
  }

  List<DhikrModel> get _filteredList {
    return _adhkar.where((d) {
      final matchesCat = _selectedCategory == 'all' || d.category == _selectedCategory;
      final matchesSub = _matchesSubFilter(d);
      final matchesQuery = _searchQuery.isEmpty ||
          d.text.contains(_searchQuery) ||
          d.adminTitle.contains(_searchQuery) ||
          d.virtue.contains(_searchQuery) ||
          d.hadiths.any((h) => (h['text'] ?? '').toString().contains(_searchQuery));
      return matchesCat && matchesSub && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مكتبة الأذكار والأحاديث', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAdhkar,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث في متن الذكر أو فضله أو الحديث...',
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
                  onSelected: (_) => setState(() {
                    _selectedCategory = cat['id']!;
                    _morningEveningSubFilter = 'all';
                  }),
                );
              },
            ),
          ),

          // Sub-filter for Morning vs Evening when morning_evening is selected
          if (_selectedCategory == 'morning_evening') ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('الكل')),
                      selected: _morningEveningSubFilter == 'all',
                      selectedColor: AppConstants.secondary,
                      labelStyle: TextStyle(color: _morningEveningSubFilter == 'all' ? Colors.white : null, fontSize: 12),
                      onSelected: (_) => setState(() => _morningEveningSubFilter = 'all'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('☀️ أذكار الصباح')),
                      selected: _morningEveningSubFilter == 'morning',
                      selectedColor: AppConstants.tertiary,
                      labelStyle: TextStyle(color: _morningEveningSubFilter == 'morning' ? Colors.white : null, fontSize: 12),
                      onSelected: (_) => setState(() => _morningEveningSubFilter = 'morning'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('🌙 أذكار المساء')),
                      selected: _morningEveningSubFilter == 'evening',
                      selectedColor: AppConstants.primary,
                      labelStyle: TextStyle(color: _morningEveningSubFilter == 'evening' ? Colors.white : null, fontSize: 12),
                      onSelected: (_) => setState(() => _morningEveningSubFilter = 'evening'),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Adhkar List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? const Center(child: Text('لا توجد أذكار مطابقة للبحث'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredList.length,
                        itemBuilder: (context, idx) {
                          final item = _filteredList[idx];
                          final currentCount = _localCounters[item.id] ?? 0;
                          final isDone = currentCount >= item.repeats;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: isDone ? AppConstants.secondary : Colors.grey.withOpacity(0.2),
                                width: isDone ? 1.5 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.adminTitle,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConstants.secondary),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (currentCount < item.repeats) {
                                              _localCounters[item.id] = currentCount + 1;
                                            } else {
                                              _localCounters[item.id] = 0;
                                            }
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: isDone
                                                ? AppConstants.secondary
                                                : AppConstants.primary.withOpacity(0.09),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            isDone ? '✓ تم ($currentCount/${item.repeats})' : '$currentCount / ${item.repeats}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isDone ? Colors.white : AppConstants.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (currentCount < item.repeats) {
                                          _localCounters[item.id] = currentCount + 1;
                                        }
                                      });
                                    },
                                    child: Text(
                                      item.text,
                                      style: GoogleFonts.notoNaskhArabic(fontSize: 18, height: 1.85, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  if (item.virtue.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.09),
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
                                  if (item.hadiths.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Theme(
                                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                      child: ExpansionTile(
                                        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                                        childrenPadding: const EdgeInsets.only(bottom: 6),
                                        leading: const Icon(Icons.menu_book, size: 18, color: AppConstants.primary),
                                        title: Text(
                                          'التخريج والحديث النبوي (${item.hadiths.length})',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.primary),
                                        ),
                                        children: item.hadiths.map((h) {
                                          final hText = (h['text'] ?? '').toString();
                                          final sources = (h['sources'] as List<dynamic>? ?? []);
                                          return Container(
                                            margin: const EdgeInsets.only(top: 6),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppConstants.primary.withOpacity(0.04),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: AppConstants.primary.withOpacity(0.12)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Text(
                                                  hText,
                                                  style: GoogleFonts.notoNaskhArabic(fontSize: 13, height: 1.7),
                                                ),
                                                if (sources.isNotEmpty) ...[
                                                  const SizedBox(height: 8),
                                                  Wrap(
                                                    spacing: 6,
                                                    runSpacing: 6,
                                                    children: sources.map((s) {
                                                      final book = (s['book'] ?? '').toString();
                                                      final num = (s['number'] ?? '').toString();
                                                      final label = num.isNotEmpty ? '$book ($num)' : book;
                                                      return Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: AppConstants.secondary.withOpacity(0.12),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          label,
                                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConstants.secondary),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          );
                                        }).toList(),
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
