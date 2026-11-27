import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';
import '../core/constants/constants.dart';
import '../widgets/dhikr_info_actions.dart';

class AdhkarLibraryScreen extends StatefulWidget {
  const AdhkarLibraryScreen({super.key});

  @override
  State<AdhkarLibraryScreen> createState() => _AdhkarLibraryScreenState();
}

class _AdhkarLibraryScreenState extends State<AdhkarLibraryScreen> {
  final SupabaseService _service = SupabaseService.instance;
  List<DhikrModel> _adhkar = [];
  String _selectedCategory = 'all';
  String _morningEveningSubFilter = 'all';
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
    final primaryTxt = AppConstants.textPrimary(context);
    final secondaryTxt = AppConstants.textSecondary(context);
    final selectedBg = AppConstants.accentBg(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('مكتبة الأذكار والأحاديث', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 18)),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث في متن الذكر أو فضله أو الحديث...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppConstants.cardSurface(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

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
                  label: Text(
                    cat['name']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : secondaryTxt,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: selectedBg,
                  backgroundColor: AppConstants.cardSurface(context),
                  side: BorderSide(color: AppConstants.borderColor(context)),
                  onSelected: (_) => setState(() {
                    _selectedCategory = cat['id']!;
                    _morningEveningSubFilter = 'all';
                  }),
                );
              },
            ),
          ),

          if (_selectedCategory == 'morning_evening') ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          'الكل',
                          style: TextStyle(color: _morningEveningSubFilter == 'all' ? Colors.white : secondaryTxt, fontSize: 12),
                        ),
                      ),
                      selected: _morningEveningSubFilter == 'all',
                      selectedColor: selectedBg,
                      backgroundColor: AppConstants.cardSurface(context),
                      side: BorderSide(color: AppConstants.borderColor(context)),
                      onSelected: (_) => setState(() => _morningEveningSubFilter = 'all'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          'الصباح',
                          style: TextStyle(color: _morningEveningSubFilter == 'morning' ? Colors.white : secondaryTxt, fontSize: 12),
                        ),
                      ),
                      selected: _morningEveningSubFilter == 'morning',
                      selectedColor: selectedBg,
                      backgroundColor: AppConstants.cardSurface(context),
                      side: BorderSide(color: AppConstants.borderColor(context)),
                      onSelected: (_) => setState(() => _morningEveningSubFilter = 'morning'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          'المساء',
                          style: TextStyle(color: _morningEveningSubFilter == 'evening' ? Colors.white : secondaryTxt, fontSize: 12),
                        ),
                      ),
                      selected: _morningEveningSubFilter == 'evening',
                      selectedColor: selectedBg,
                      backgroundColor: AppConstants.cardSurface(context),
                      side: BorderSide(color: AppConstants.borderColor(context)),
                      onSelected: (_) => setState(() => _morningEveningSubFilter = 'evening'),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? Center(child: Text('لا توجد أذكار مطابقة للبحث', style: TextStyle(color: secondaryTxt)))
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
                            color: AppConstants.cardSurface(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: isDone ? primaryTxt.withOpacity(0.5) : AppConstants.borderColor(context),
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
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: secondaryTxt),
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
                                            color: isDone ? selectedBg : AppConstants.activeSurface(context),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            isDone ? 'تم ($currentCount/${item.repeats})' : '$currentCount / ${item.repeats}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isDone ? Colors.white : primaryTxt,
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
                                      style: GoogleFonts.notoNaskhArabic(
                                        fontSize: 19,
                                        height: 1.85,
                                        fontWeight: FontWeight.bold,
                                        color: primaryTxt,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  if (item.virtue.trim().isNotEmpty || item.hadiths.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    DhikrInfoButtons(dhikr: item, centered: false),
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
