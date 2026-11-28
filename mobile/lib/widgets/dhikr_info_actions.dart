import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/constants.dart';
import '../core/utils/app_locale.dart';
import '../models/models.dart';

/// Compact action buttons for viewing a dhikr's virtue ("الفضل") and hadith
/// sources ("الأحاديث") in a bottom sheet without cluttering the main dhikr view.
class DhikrInfoButtons extends StatelessWidget {
  final DhikrModel dhikr;
  final bool centered;

  const DhikrInfoButtons({
    super.key,
    required this.dhikr,
    this.centered = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasVirtue = dhikr.virtue.trim().isNotEmpty;
    final hasHadiths = dhikr.hadiths.isNotEmpty;
    if (!hasVirtue && !hasHadiths) return const SizedBox.shrink();

    final primaryTxt = AppConstants.textPrimary(context);
    final secondaryTxt = AppConstants.textSecondary(context);
    final tr = AppLocale.instance.tr;

    Widget buildBtn({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTxt,
          backgroundColor: AppConstants.activeSurface(context),
          side: BorderSide(color: AppConstants.borderColor(context)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: const Size(0, 34),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, size: 15, color: secondaryTxt),
        label: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryTxt),
        ),
        onPressed: onTap,
      );
    }

    return Wrap(
      alignment: centered ? WrapAlignment.center : WrapAlignment.start,
      spacing: 8,
      runSpacing: 6,
      children: [
        if (hasVirtue)
          buildBtn(
            icon: Icons.auto_awesome_outlined,
            label: tr('الفضل', 'Virtue'),
            onTap: () => showDhikrVirtueSheet(context, dhikr),
          ),
        if (hasHadiths)
          buildBtn(
            icon: Icons.menu_book_outlined,
            label: tr('الأحاديث (${dhikr.hadiths.length})', 'Hadith (${dhikr.hadiths.length})'),
            onTap: () => showDhikrHadithsSheet(context, dhikr),
          ),
      ],
    );
  }
}

void showDhikrVirtueSheet(BuildContext context, DhikrModel dhikr) {
  final primaryTxt = AppConstants.textPrimary(context);
  final secondaryTxt = AppConstants.textSecondary(context);
  final tr = AppLocale.instance.tr;

  showModalBottomSheet(
    context: context,
    backgroundColor: AppConstants.cardSurface(context),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppConstants.borderColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.auto_awesome_outlined, size: 19, color: primaryTxt),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dhikr.adminTitle.isNotEmpty
                        ? '${tr("فضل الذكر", "Virtue of Dhikr")} • ${dhikr.adminTitle}'
                        : tr('فضل الذكر', 'Virtue of Dhikr'),
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primaryTxt,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppConstants.activeSurface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppConstants.borderColor(context)),
              ),
              child: Text(
                dhikr.virtue,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: GoogleFonts.notoNaskhArabic(
                  fontSize: 15,
                  height: 1.8,
                  color: primaryTxt,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr('إغلاق', 'Close'), style: TextStyle(color: secondaryTxt, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void showDhikrHadithsSheet(BuildContext context, DhikrModel dhikr) {
  final primaryTxt = AppConstants.textPrimary(context);
  final secondaryTxt = AppConstants.textSecondary(context);
  final tr = AppLocale.instance.tr;

  showModalBottomSheet(
    context: context,
    backgroundColor: AppConstants.cardSurface(context),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.72,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppConstants.borderColor(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.menu_book_outlined, size: 19, color: primaryTxt),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr(
                        'التخريج والأحاديث (${dhikr.hadiths.length})',
                        'Hadith & Sources (${dhikr.hadiths.length})',
                      ),
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primaryTxt,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: dhikr.hadiths.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, idx) {
                    final h = dhikr.hadiths[idx];
                    final hText = (h['text'] ?? '').toString();
                    final sources = (h['sources'] as List<dynamic>? ?? []);
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstants.activeSurface(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppConstants.borderColor(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            hText,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.notoNaskhArabic(
                              fontSize: 14,
                              height: 1.75,
                              color: primaryTxt,
                            ),
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
                                    color: AppConstants.cardSurface(context),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppConstants.borderColor(context)),
                                  ),
                                  child: Text(
                                    label,
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: secondaryTxt,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(tr('إغلاق', 'Close'), style: TextStyle(color: secondaryTxt, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
