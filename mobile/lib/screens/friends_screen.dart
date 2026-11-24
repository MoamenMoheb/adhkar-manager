import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/constants.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import 'auth_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final SupabaseService _service = SupabaseService.instance;
  final TextEditingController _codeController = TextEditingController();

  bool _loading = true;
  bool _sending = false;
  List<Map<String, dynamic>> _incomingRequests = [];
  List<Map<String, dynamic>> _sentRequests = [];
  List<Map<String, dynamic>> _friends = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (_service.currentUser == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final incoming = await _service.fetchFriendRequests();
    final sent = await _service.fetchSentFriendRequests();
    final friends = await _service.fetchFriendsWithIds();
    if (!mounted) return;
    setState(() {
      _incomingRequests = incoming;
      _sentRequests = sent;
      _friends = friends;
      _loading = false;
    });
  }

  Future<void> _sendRequest() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _sending = true);
    try {
      final msg = await _service.sendFriendRequestByCode(code);
      _codeController.clear();
      await _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _respond(String id, bool accept) async {
    try {
      await _service.respondToFriendRequest(id, accept);
      await _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accept ? 'تم قبول طلب الصداقة' : 'تم رفض طلب الصداقة')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء تنفيذ الطلب')));
      }
    }
  }

  Future<void> _cancelSent(String id) async {
    try {
      await _service.removeFriend(id);
      await _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الطلب')));
      }
    } catch (_) {}
  }

  Future<void> _confirmAndRemoveFriend(String friendshipId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('إزالة صديق', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
        content: Text('هل تريد إزالة "$name" من قائمة أصدقائك؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إزالة'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.removeFriend(friendshipId);
      await _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إزالة الصديق')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر إزالة الصديق')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryTxt = AppConstants.textPrimary(context);
    final secondaryTxt = AppConstants.textSecondary(context);
    final selectedBg = AppConstants.accentBg(context);
    final user = _service.currentUser;
    final profile = _service.currentProfile;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('الأصدقاء والطلبات', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_add, size: 72, color: secondaryTxt),
                const SizedBox(height: 16),
                Text('سجل دخولك لإضافة الأصدقاء وقبول طلبات الصداقة', style: TextStyle(color: primaryTxt, fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: selectedBg, foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())).then((_) => _loadAll());
                  },
                  child: const Text('تسجيل الدخول / إنشاء حساب'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final myCode = profile?.friendCode ?? 'ADK-${user.id.substring(0, 4).toUpperCase()}';

    return Scaffold(
      appBar: AppBar(
        title: Text('الأصدقاء وطلبات الصداقة', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. My Friend Code Card
                  Card(
                    elevation: 0,
                    color: AppConstants.cardSurface(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: AppConstants.borderColor(context)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('كود الصداقة الخاص بك', style: TextStyle(fontSize: 12, color: secondaryTxt)),
                              const SizedBox(height: 4),
                              Text(myCode, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTxt, letterSpacing: 1)),
                            ],
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('نسخ'),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: myCode));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ كود الصداقة')));
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 2. Add Friend by Code Card
                  Card(
                    elevation: 0,
                    color: AppConstants.cardSurface(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: AppConstants.borderColor(context)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('إضافة صديق جديد', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 15, color: primaryTxt)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _codeController,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: InputDecoration(
                                    hintText: 'أدخل كود الصديق (مثل ADK-7A2B)',
                                    prefixIcon: const Icon(Icons.person_add_alt_1),
                                    filled: true,
                                    fillColor: AppConstants.activeSurface(context),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: selectedBg,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _sending ? null : _sendRequest,
                                child: _sending
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('إرسال', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Incoming Friend Requests
                  if (_incomingRequests.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      'طلبات الصداقة الواردة (${_incomingRequests.length})',
                      style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 15, color: primaryTxt),
                    ),
                    const SizedBox(height: 8),
                    ..._incomingRequests.map((req) {
                      final sender = (req['sender'] as Map<String, dynamic>?) ?? {};
                      final name = (sender['display_name'] ?? 'مستخدم').toString();
                      final code = (sender['friend_code'] ?? '').toString();
                      final avatar = (sender['avatar_id'] ?? 'm1').toString();
                      final reqId = req['id'].toString();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        color: AppConstants.cardSurface(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppConstants.borderColor(context)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  'assets/avatars/$avatar.png',
                                  width: 42,
                                  height: 42,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 42),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryTxt)),
                                    Text(code, style: TextStyle(fontSize: 11, color: secondaryTxt)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: selectedBg,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                ),
                                onPressed: () => _respond(reqId, true),
                                child: const Text('قبول', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 6),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                ),
                                onPressed: () => _respond(reqId, false),
                                child: const Text('رفض', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  // 4. Sent Requests (Pending)
                  if (_sentRequests.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      'طلبات مرسلة بانتظار الموافقة (${_sentRequests.length})',
                      style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 14, color: secondaryTxt),
                    ),
                    const SizedBox(height: 8),
                    ..._sentRequests.map((req) {
                      final rec = (req['recipient'] as Map<String, dynamic>?) ?? {};
                      final name = (rec['display_name'] ?? 'مستخدم').toString();
                      final code = (rec['friend_code'] ?? '').toString();
                      final reqId = req['id'].toString();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        color: AppConstants.cardSurface(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: AppConstants.borderColor(context)),
                        ),
                        child: ListTile(
                          title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryTxt)),
                          subtitle: Text(code, style: TextStyle(fontSize: 11, color: secondaryTxt)),
                          trailing: TextButton(
                            onPressed: () => _cancelSent(reqId),
                            child: const Text('إلغاء الطلب', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                          ),
                        ),
                      );
                    }),
                  ],

                  // 5. Accepted Friends List with Remove Option
                  const SizedBox(height: 18),
                  Text(
                    'أصدقائي (${_friends.length})',
                    style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 15, color: primaryTxt),
                  ),
                  const SizedBox(height: 8),
                  if (_friends.isEmpty)
                    Card(
                      elevation: 0,
                      color: AppConstants.cardSurface(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppConstants.borderColor(context)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text('لا يوجد أصدقاء بعد. أضف أصدقاءك بالكود أعلاه!', style: TextStyle(fontSize: 13, color: secondaryTxt)),
                        ),
                      ),
                    )
                  else
                    ..._friends.map((row) {
                      final f = row['profile'] as ProfileModel;
                      final fId = row['friendship_id'] as String;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        color: AppConstants.cardSurface(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppConstants.borderColor(context)),
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/avatars/${f.avatarId}.png',
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 42),
                            ),
                          ),
                          title: Text(f.displayName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryTxt)),
                          subtitle: Text('${f.friendCode} • ${f.totalPoints} نقطة', style: TextStyle(fontSize: 12, color: secondaryTxt)),
                          trailing: IconButton(
                            icon: const Icon(Icons.person_remove, color: Colors.redAccent),
                            tooltip: 'إزالة الصديق',
                            onPressed: () => _confirmAndRemoveFriend(fId, f.displayName),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
