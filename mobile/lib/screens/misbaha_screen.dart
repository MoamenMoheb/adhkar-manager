import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/constants.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

class MisbahaScreen extends StatefulWidget {
  const MisbahaScreen({super.key});

  @override
  State<MisbahaScreen> createState() => _MisbahaScreenState();
}

class _MisbahaScreenState extends State<MisbahaScreen> {
  final SupabaseService _supabase = SupabaseService.instance;
  final NotificationService _notif = NotificationService.instance;

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

  // Free tasbeeh fallback options
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
    // Default mode based on time of day unless a notification set pendingMisbahaMode
    final pending = _notif.pendingMisbahaMode.value;
    if (pending == 'morning' || pending == 'evening') {
      _mode = pending!;
      _notif.pendingMisbahaMode.value = null;
    } else {
      _mode = DateTime.now().hour < 14 ? 'morning' : 'evening';
    }
    _notif.pendingMisbahaMode.addListener(_onNotificationModeRequested);
    _loadAdhkar();
  }

  @override
  void dispose() {
    _notif.pendingMisbahaMode.removeListener(_onNotificationModeRequested);
    super.dispose();
  }

  void _onNotificationModeRequested() {
    final pending = _notif.pendingMisbahaMode.value;
    if (pending == 'morning' || pending == 'evening') {
      _notif.pendingMisbahaMode.value = null;
      _switchMode(pending!);
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
          SnackBar(content: Text('أتممت $_freeTarget تسبيحة! تقبل الله 🌟'), duration: const Duration(seconds: 2)),
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

    // Automatically mark morning_adhkar or evening_adhkar in daily points!
    final worshipKey = _mode == 'morning' ? 'morning_adhkar' : (_mode == 'evening' ? 'evening_adhkar' : null);
    if (worshipKey != null) {
      await _supabase.toggleWorshipTask(worshipKey, true);
      if (!mounted) return;
      setState(() => _autoMarkedPoints = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppConstants.secondary,
          content: Text(
            _mode == 'morning'
                ? 'ما شاء الله! أتممت أذكار الصباح وتم احتساب +١٥ نقطة تلقائياً في الورد اليومي ⭐'
                : 'ما شاء الله! أتممت أذكار المساء وتم احتساب +١٥ نقطة تلقائياً في الورد اليومي ⭐',
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

    return Scaffold(
      appBar: AppBar(
        title: Text('المسبحة والأذكار', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
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
                  // Mode Selector Tabs (Morning / Evening / Free Tasbeeh)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('☀️ الصباح')),
                            selected: _mode == 'morning',
                            selectedColor: AppConstants.tertiary,
                            labelStyle: TextStyle(
                              color: _mode == 'morning' ? Colors.white : null,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (_) => _switchMode('morning'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('🌙 المساء')),
                            selected: _mode == 'evening',
                            selectedColor: AppConstants.primary,
                            labelStyle: TextStyle(
                              color: _mode == 'evening' ? Colors.white : null,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (_) => _switchMode('evening'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('📿 تسبيح حر')),
                            selected: _mode == 'free',
                            selectedColor: AppConstants.secondary,
                            labelStyle: TextStyle(
                              color: _mode == 'free' ? Colors.white : null,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (_) => _switchMode('free'),
                          ),
                        ),
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
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _freeDhikrText,
                            items: _freeOptions.map((opt) {
                              return DropdownMenuItem<String>(
                                value: opt['text'],
                                child: Text(opt['text'], style: GoogleFonts.notoNaskhArabic(fontSize: 14), overflow: TextOverflow.ellipsis),
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
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.secondary),
                              ),
                              if (currentDhikr != null)
                                Expanded(
                                  child: Text(
                                    currentDhikr.adminTitle,
                                    textAlign: TextAlign.left,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
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
                              backgroundColor: Colors.grey.withOpacity(0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _mode == 'morning' ? AppConstants.tertiary : AppConstants.primary,
                              ),
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
                          color: AppConstants.secondary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppConstants.secondary.withOpacity(0.35)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.verified, size: 64, color: AppConstants.secondary),
                            const SizedBox(height: 16),
                            Text(
                              _mode == 'morning'
                                  ? 'أتممت أذكار الصباح كاملة!'
                                  : 'أتممت أذكار المساء كاملة!',
                              style: GoogleFonts.ibmPlexSansArabic(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.primary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            if (_autoMarkedPoints)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '⭐ تم احتساب +١٥ نقطة تلقائياً في الورد اليومي!',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF8B5A00)),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            const SizedBox(height: 12),
                            Text(
                              'عدد الأذكار: ${_sequenceList.length} • إجمالي التسبيحات: $_totalTaps',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primary),
                              onPressed: _reset,
                              icon: const Icon(Icons.replay, color: Colors.white),
                              label: const Text('إعادة القراءة من البداية', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                  ] else ...[
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _activeText,
                              style: GoogleFonts.notoNaskhArabic(
                                fontSize: _activeText.length > 180 ? 16 : 20,
                                fontWeight: FontWeight.bold,
                                height: 1.8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (currentDhikr != null && currentDhikr.virtue.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '✨ ${currentDhikr.virtue}',
                                  style: const TextStyle(fontSize: 11, color: Colors.brown),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Large Circular Counter Tap Area
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
                                backgroundColor: Colors.grey.withOpacity(0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _mode == 'morning' ? AppConstants.tertiary : AppConstants.secondary,
                                ),
                              ),
                            ),
                            Container(
                              width: 174,
                              height: 174,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppConstants.primary,
                                    AppConstants.primaryContainer,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppConstants.primary.withOpacity(0.32),
                                    blurRadius: 18,
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

                    // Navigation controls + total taps
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
                            style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
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
