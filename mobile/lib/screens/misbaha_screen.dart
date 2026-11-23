import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/constants.dart';

class MisbahaScreen extends StatefulWidget {
  const MisbahaScreen({super.key});

  @override
  State<MisbahaScreen> createState() => _MisbahaScreenState();
}

class _MisbahaScreenState extends State<MisbahaScreen> {
  int _counter = 0;
  int _target = 33;
  int _totalTaps = 0;
  String _currentDhikr = 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ';

  final List<Map<String, dynamic>> _dhikrOptions = [
    {'text': 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ', 'target': 100},
    {'text': 'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ', 'target': 33},
    {'text': 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ', 'target': 100},
    {'text': 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ', 'target': 10},
    {'text': 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ', 'target': 33},
  ];

  void _tap() {
    HapticFeedback.lightImpact();
    setState(() {
      _counter++;
      _totalTaps++;
      if (_counter == _target) {
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _reset() {
    setState(() {
      _counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_counter / _target).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text('المسبحة الإلكترونية', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
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
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Dhikr Selector Dropdown
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
                    value: _currentDhikr,
                    items: _dhikrOptions.map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt['text'],
                        child: Text(opt['text'], style: GoogleFonts.notoNaskhArabic(fontSize: 14), overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final found = _dhikrOptions.firstWhere((e) => e['text'] == val);
                        setState(() {
                          _currentDhikr = val;
                          _target = found['target'];
                          _counter = 0;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Dhikr Text Display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _currentDhikr,
                style: GoogleFonts.notoNaskhArabic(fontSize: 22, fontWeight: FontWeight.bold, height: 1.8),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            // Large Circular Counter Tap Area
            GestureDetector(
              onTap: _tap,
              child: SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.withOpacity(0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.secondary),
                      ),
                    ),
                    Container(
                      width: 200,
                      height: 200,
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
                            color: AppConstants.primary.withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_counter',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 54,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '/ $_target',
                            style: const TextStyle(fontSize: 16, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Total session stats
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.touch_app, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'إجمالي تسبيحات الجلسة: $_totalTaps',
                    style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
