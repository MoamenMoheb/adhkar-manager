import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/constants.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../widgets/dhikr_info_actions.dart';

class MisbahaScreen extends StatefulWidget {
  const MisbahaScreen({super.key});

  @override
  State<MisbahaScreen> createState() => MisbahaScreenState();
}

class MisbahaScreenState extends State<MisbahaScreen> {
  final SupabaseService _supabase = SupabaseService.instance;

  /// Modes: 'morning' (أذكار الصباح), 'evening' (أذكار المساء), 'free' (تسبيح حر)
  String _mode = 'morning';
  List<DhikrModel> _allAdhkar = [];
  List<DhikrModel> _sequenceList = [];
  int _currentIndex = 0;
  int _counter = 0;
  int _totalTaps = 0;
  bool _loading = true;
  bool _sessionCompleted = false;
  bool _autoMarkedPoints = false;
  bool _isTransitioning = false;

  String _freeDhikrText = 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ';
  int _freeTarget = 100;
  final List<Map<String, dynamic>> _freeOptions = const [
    {'text': 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ', 'target': 100},
    {'text': 'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ', 'target': 33},
    {'text': 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ', 'target': 100},
    {'text': 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ', 'target': 10},
    {'text': 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ', 'target': 33},
  ];

  @override
  void initState() {
    super.initState();
    _mode = DateTime.now().hour < 14 ? 'morning' : 'evening';
    _loadAdhkar();
  }

  /// Called directly by [MainShell] when user taps an Azkar notification.
  void openFromNotification(String mode) {
    if (mode != 'morning' && mode != 'evening') return;
    if (!mounted) return;
    setState(() {
      _mode = mode;
      _rebuildSequence();
    });
    if (_allAdhkar.isEmpty && !_loading) {
      _loadAdhkar();
    }
  }

  Future<void> _loadAdhkar() async {
    setState(() => _loading = true);
    final data = await _supabase.fetchAdhkar();
    if (!mounted) return;
    _allAdhkar = data;
    _rebuildSequence();
    setState(() => _loading = false);
  }

  void _rebuildSequence() {
    final morningEvening = _allAdhkar.where((d) => d.category == 'morning_evening').toList();
    if (_mode == 'morning') {
      _sequenceList = morningEvening.where((d) {
        final t = d.adminTitle;
        return t.contains('الصباح') || !t.contains('المساء');
      }).toList();
    } else if (_mode == 'evening') {
      _sequenceList = morningEvening.where((d) {
        final t = d.adminTitle;
        return t.contains('المساء') || !t.contains('الصباح');
      }).toList();
    } else {
      _sequenceList = [];
    }
    _currentIndex = 0;
    _counter = 0;
    _totalTaps = 0;
    _sessionCompleted = false;
    _autoMarkedPoints = false;
    _isTransitioning = false;
  }

  void _switchMode(String newMode) {
    setState(() {
      _mode = newMode;
      _rebuildSequence();
    });
  }

  int get _activeTarget {
    if (_mode == 'free') return _freeTarget;
    if (_sequenceList.isEmpty || _currentIndex >= _sequenceList.length) return 1;
    return _sequenceList[_currentIndex].repeats > 0 ? _sequenceList[_currentIndex].repeats : 1;
  }

  String get _activeText {
    if (_mode == 'free') return _freeDhikrText;
    if (_sequenceList.isEmpty || _currentIndex >= _sequenceList.length) return '';
    return _sequenceList[_currentIndex].text;
  }

  Future<void> _tap() async {
    if (_isTransitioning || _sessionCompleted) return;
    HapticFeedback.lightImpact();

    final target = _activeTarget;
    setState(() {
      _counter++;
      _totalTaps++;
    });

    if (_counter >= target) {
      HapticFeedback.heavyImpact();
      if (_mode == 'free') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('أتممت $_freeTarget تسبيحة! تقبل الله'), duration: const Duration(seconds: 2)),
        );
        setState(() => _counter = 0);
        return;
      }

      if (_currentIndex < _sequenceList.length - 1) {
        _isTransitioning = true;
        await Future.delayed(const Duration(milliseconds: 350));
        if (!mounted) return;
        setState(() {
          _currentIndex++;
          _counter = 0;
          _isTransitioning = false;
        });
      } else {
        await _completeSequence();
      }
    }
  }

  Future<void> _completeSequence() async {
    setState(() {
      _sessionCompleted = true;
      _isTransitioning = false;
    });

    final worshipKey = _mode == 'morning' ? 'morning_adhkar' : (_mode == 'evening' ? 'evening_adhkar' : null);
    if (worshipKey != null) {
      await _supabase.toggleWorshipTask(worshipKey, true);
      if (!mounted) return;
      setState(() => _autoMarkedPoints = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mode == 'morning'
                ? 'تم إتمام أذكار الصباح واحتسابها في الورد اليومي'
                : 'تم إتمام أذكار المساء واحتسابها في الورد اليومي',
          ),
        ),
      );
    }
  }

  void _nextDhikr() {
    if (_mode == 'free' || _sequenceList.isEmpty) return;
    if (_currentIndex < _sequenceList.length - 1) {
      setState(() {
        _currentIndex++;
        _counter = 0;
      });
    } else {
      _completeSequence();
    }
  }

  void _prevDhikr() {
    if (_mode == 'free' || _sequenceList.isEmpty) return;
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _counter = 0;
      });
    }
  }

  void _reset() {
    setState(() {
      _counter = 0;
      if (_sessionCompleted) {
        _currentIndex = 0;
        _totalTaps = 0;
        _sessionCompleted = false;
        _autoMarkedPoints = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final target = _activeTarget;
    final progress = target > 0 ? (_counter / target).clamp(0.0, 1.0) : 0.0;
    final currentDhikr = (_mode != 'free' && _sequenceList.isNotEmpty && _currentIndex < _sequenceList.length)
        ? _sequenceList[_currentIndex]
        : null;

    final primaryTxt = AppConstants.textPrimary(context);
    final secondaryTxt = AppConstants.textSecondary(context);
    final isDark = AppConstants.isDark(context);
    final selectedBg = AppConstants.accentBg(context);

    Widget modeChip(String id, String label) {
      final selected = _mode == id;
      return Expanded(
        child: ChoiceChip(
          label: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Colors.white : secondaryTxt,
              ),
            ),
          ),
          selected: selected,
          selectedColor: selectedBg,
          backgroundColor: AppConstants.cardSurface(context),
          side: BorderSide(color: AppConstants.borderColor(context)),
          onSelected: (_) => _switchMode(id),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('المسبحة والأذكار', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
            tooltip: 'إعادة العداد',
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        modeChip('morning', 'الصباح'),
                        const SizedBox(width: 6),
                        modeChip('evening', 'المساء'),
                        const SizedBox(width: 6),
                        modeChip('free', 'تسبيح حر'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (_mode == 'free')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppConstants.cardSurface(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppConstants.borderColor(context)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _freeDhikrText,
                            items: _freeOptions.map((opt) {
                              return DropdownMenuItem<String>(
                                value: opt['text'],
                                child: Text(opt['text'], style: GoogleFonts.notoNaskhArabic(fontSize: 14, color: primaryTxt), overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                final found = _freeOptions.firstWhere((e) => e['text'] == val);
                                setState(() {
                                  _freeDhikrText = val;
                                  _freeTarget = found['target'];
                                  _counter = 0;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    )
                  else if (_sequenceList.isNotEmpty && !_sessionCompleted)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'الذكر ${_currentIndex + 1} من ${_sequenceList.length}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryTxt),
                              ),
                              if (currentDhikr != null)
                                Expanded(
                                  child: Text(
                                    currentDhikr.adminTitle,
                                    textAlign: TextAlign.left,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 11, color: secondaryTxt),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (_currentIndex + 1) / _sequenceList.length,
                              minHeight: 6,
                              backgroundColor: AppConstants.borderColor(context),
                              valueColor: AlwaysStoppedAnimation<Color>(primaryTxt),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_sessionCompleted) ...[
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppConstants.cardSurface(context),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppConstants.borderColor(context)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.verified, size: 64, color: primaryTxt),
                            const SizedBox(height: 16),
                            Text(
                              _mode == 'morning' ? 'أتممت أذكار الصباح كاملة!' : 'أتممت أذكار المساء كاملة!',
                              style: GoogleFonts.ibmPlexSansArabic(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTxt),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            if (_autoMarkedPoints)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppConstants.activeSurface(context),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'تم تسجيل الإتمام في الورد اليومي (+١٥ نقطة)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryTxt),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            const SizedBox(height: 12),
                            Text(
                              'عدد الأذكار: ${_sequenceList.length} • إجمالي التسبيحات: $_totalTaps',
                              style: TextStyle(fontSize: 12, color: secondaryTxt),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedBg,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _reset,
                              icon: const Icon(Icons.replay),
                              label: const Text('إعادة القراءة من البداية'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                  ] else ...[
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Text(
                            _activeText,
                            style: GoogleFonts.notoNaskhArabic(
                              fontSize: _activeText.length > 180 ? 18 : 22,
                              fontWeight: FontWeight.bold,
                              height: 1.85,
                              color: primaryTxt,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),

                    if (currentDhikr != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: DhikrInfoButtons(dhikr: currentDhikr),
                      ),
                      const SizedBox(height: 4),
                    ],

                    GestureDetector(
                      onTap: _tap,
                      child: SizedBox(
                        width: 210,
                        height: 210,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 210,
                              height: 210,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 11,
                                backgroundColor: AppConstants.borderColor(context),
                                valueColor: AlwaysStoppedAnimation<Color>(primaryTxt),
                              ),
                            ),
                            Container(
                              width: 174,
                              height: 174,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isDark
                                    ? const LinearGradient(
                                        colors: [Color(0xFF262C36), Color(0xFF171B22)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : const LinearGradient(
                                        colors: [AppConstants.primary, AppConstants.primaryContainer],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                border: isDark ? Border.all(color: Colors.white.withOpacity(0.15)) : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.28),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$_counter',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '/ $target',
                                    style: const TextStyle(fontSize: 15, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_mode != 'free')
                            IconButton(
                              onPressed: _currentIndex > 0 ? _prevDhikr : null,
                              icon: const Icon(Icons.arrow_back_ios),
                              tooltip: 'الذكر السابق',
                            )
                          else
                            const SizedBox(width: 48),
                          Text(
                            'إجمالي الجلسة: $_totalTaps',
                            style: TextStyle(color: secondaryTxt, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          if (_mode != 'free')
                            IconButton(
                              onPressed: _nextDhikr,
                              icon: const Icon(Icons.arrow_forward_ios),
                              tooltip: 'الذكر التالي',
                            )
                          else
                            const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
