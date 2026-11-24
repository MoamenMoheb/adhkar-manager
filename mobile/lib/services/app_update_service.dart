import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants/constants.dart';

class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;
  final int sizeBytes;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.sizeBytes,
  });
}

class AppUpdateService {
  static final AppUpdateService instance = AppUpdateService._internal();
  AppUpdateService._internal();

  static const String _latestReleaseApi =
      'https://api.github.com/repos/MoamenMoheb/adhkar-manager/releases/latest';

  bool _checkedThisSession = false;

  Future<String> getCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '1.0.0';
    }
  }

  /// Compares two semver strings like "1.0.12" > "1.0.5".
  bool _isNewerVersion(String latest, String current) {
    List<int> parse(String v) {
      final clean = v.replaceAll(RegExp(r'^[vV]'), '').split('+').first.split('-').first;
      return clean.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    }

    final l = parse(latest);
    final c = parse(current);
    final maxLen = l.length > c.length ? l.length : c.length;
    for (int i = 0; i < maxLen; i++) {
      final lv = i < l.length ? l[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (lv > cv) return true;
      if (lv < cv) return false;
    }
    return false;
  }

  /// Checks GitHub Releases for a newer APK build. Returns [AppUpdateInfo] if available, otherwise null.
  Future<AppUpdateInfo?> checkForUpdate({bool force = false}) async {
    if (!force && _checkedThisSession) return null;
    _checkedThisSession = true;

    try {
      final currentVersion = await getCurrentVersion();
      final resp = await http
          .get(
            Uri.parse(_latestReleaseApi),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final tagName = (data['tag_name'] ?? '').toString().trim();
      final latestVersion = tagName.replaceAll(RegExp(r'^[vV]'), '');
      if (latestVersion.isEmpty || !_isNewerVersion(latestVersion, currentVersion)) {
        return null;
      }

      final assets = (data['assets'] as List<dynamic>? ?? []);
      Map<String, dynamic>? apkAsset;
      for (final a in assets) {
        final name = (a['name'] ?? '').toString().toLowerCase();
        if (name.endsWith('.apk')) {
          apkAsset = a as Map<String, dynamic>;
          break;
        }
      }
      if (apkAsset == null) return null;

      final downloadUrl = (apkAsset['browser_download_url'] ?? '').toString();
      if (downloadUrl.isEmpty) return null;

      return AppUpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        releaseNotes: (data['body'] ?? 'يتوفر إصدار أحدث مع تحسينات ومميزات جديدة.').toString(),
        downloadUrl: downloadUrl,
        sizeBytes: (apkAsset['size'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('Update check error: $e');
      return null;
    }
  }

  /// Downloads the APK directly inside the app and triggers the Android installer.
  Future<void> downloadAndInstall(
    AppUpdateInfo update, {
    required void Function(double progress, int received, int total) onProgress,
    required void Function(String message) onError,
  }) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(update.downloadUrl));
      final response = await client.send(request);
      if (response.statusCode != 200) {
        onError('تعذر تحميل التحديث (رمز ${response.statusCode})');
        return;
      }

      final total = response.contentLength ?? update.sizeBytes;
      final dir = await getTemporaryDirectory();
      final apkPath = '${dir.path}/adhkar-sanctuary-v${update.latestVersion}.apk';
      final file = File(apkPath);
      if (await file.exists()) {
        await file.delete();
      }

      final sink = file.openWrite();
      int received = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        final progress = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;
        onProgress(progress, received, total);
      }

      await sink.flush();
      await sink.close();

      final result = await OpenFilex.open(
        apkPath,
        type: 'application/vnd.android.package-archive',
      );
      if (result.type != ResultType.done) {
        onError('تم تحميل الملف. يرجى السماح بتثبيت التطبيقات من هذا المصدر ثم المحاولة مجدداً (${result.message}).');
      }
    } catch (e) {
      onError('حدث خطأ أثناء تحميل أو تثبيت التحديث: $e');
    } finally {
      client.close();
    }
  }

  /// Presents a clean in-app update dialog with live download progress bar.
  Future<void> showUpdateDialog(BuildContext context, AppUpdateInfo update) async {
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UpdateDialog(update: update),
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  final AppUpdateInfo update;
  const _UpdateDialog({required this.update});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _downloading = false;
  double _progress = 0.0;
  int _received = 0;
  int _total = 0;
  String? _error;

  String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

  Future<void> _startUpdate() async {
    setState(() {
      _downloading = true;
      _error = null;
      _progress = 0.0;
    });

    await AppUpdateService.instance.downloadAndInstall(
      widget.update,
      onProgress: (p, r, t) {
        if (!mounted) return;
        setState(() {
          _progress = p;
          _received = r;
          _total = t;
        });
      },
      onError: (msg) {
        if (!mounted) return;
        setState(() {
          _downloading = false;
          _error = msg;
        });
      },
    );

    if (mounted && _error == null) {
      setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizeText = widget.update.sizeBytes > 0 ? '(${_mb(widget.update.sizeBytes)} MB)' : '';
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.activeSurface(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.system_update, color: AppConstants.textPrimary(context)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'يتوفر تحديث جديد v${widget.update.latestVersion}',
              style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.textPrimary(context)),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإصدار الحالي: ${widget.update.currentVersion} ➔ الجديد: ${widget.update.latestVersion} $sizeText',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.textSecondary(context)),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 140),
            child: SingleChildScrollView(
              child: Text(
                widget.update.releaseNotes,
                style: TextStyle(fontSize: 12, height: 1.5, color: AppConstants.textPrimary(context)),
              ),
            ),
          ),
          if (_downloading) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 8,
                color: AppConstants.textPrimary(context),
                backgroundColor: AppConstants.borderColor(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _total > 0
                  ? 'جاري التحميل: ${(_progress * 100).toInt()}% (${_mb(_received)} / ${_mb(_total)} MB)'
                  : 'جاري تحميل التحديث من داخل التطبيق...',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConstants.textPrimary(context)),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
          ],
        ],
      ),
      actions: [
        if (!_downloading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لاحقاً'),
          ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.accentBg(context),
            foregroundColor: Colors.white,
          ),
          onPressed: _downloading ? null : _startUpdate,
          icon: const Icon(Icons.download, size: 18),
          label: Text(_downloading ? 'جاري التحميل...' : 'تحديث وتثبيت الآن'),
        ),
      ],
    );
  }
}
