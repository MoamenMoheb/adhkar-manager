/**
 * Serene Adhkar Sanctuary - Supabase Integration Client
 * Manages Authentication, Profiles, Gamified Daily Worship Logs, Friendships & Leaderboards
 */

// ================= WORSHIP TASKS DEFINITIONS =================
const WORSHIP_TASKS = [
  {
    key: 'fajr',
    title: 'صلاة الفجر',
    subtitle: 'في أول وقتها مع ركعتي الفجر',
    points: 10,
    category: 'prayers',
    categoryName: 'الصلوات المفروضة',
    icon: 'wb_twilight'
  },
  {
    key: 'dhuhr',
    title: 'صلاة الظهر',
    subtitle: 'الفريضة والسنن الرواتب القبلية والبعدية',
    points: 10,
    category: 'prayers',
    categoryName: 'الصلوات المفروضة',
    icon: 'light_mode'
  },
  {
    key: 'asr',
    title: 'صلاة العصر',
    subtitle: 'الصلاة الوسطى في أول وقتها',
    points: 10,
    category: 'prayers',
    categoryName: 'الصلوات المفروضة',
    icon: 'wb_sunny'
  },
  {
    key: 'maghrib',
    title: 'صلاة المغرب',
    subtitle: 'الفريضة وركعتا السُنّة البعدية',
    points: 10,
    category: 'prayers',
    categoryName: 'الصلوات المفروضة',
    icon: 'wb_twilight'
  },
  {
    key: 'isha',
    title: 'صلاة العشاء',
    subtitle: 'الفريضة وسُنّة العشاء وركعة الوتر',
    points: 10,
    category: 'prayers',
    categoryName: 'الصلوات المفروضة',
    icon: 'bedtime'
  },
  {
    key: 'qiyam',
    title: 'قيام الليل والتهجد',
    subtitle: 'ركعتان في جوف الليل وسؤال الله المغفرة',
    points: 30,
    category: 'nawafil',
    categoryName: 'النوافل والسنن',
    icon: 'nights_stay'
  },
  {
    key: 'morning_adhkar',
    title: 'أذكار الصباح',
    subtitle: 'حرز المؤمن وحصنه المنيع طوال نهاره',
    points: 15,
    category: 'adhkar',
    categoryName: 'الأذكار المأثورة',
    icon: 'wb_sunny',
    linkCategoryId: 'morning_evening'
  },
  {
    key: 'evening_adhkar',
    title: 'أذكار المساء',
    subtitle: 'سكينة وطمأنينة وحفظ تام حتى الصباح',
    points: 15,
    category: 'adhkar',
    categoryName: 'الأذكار المأثورة',
    icon: 'nights_stay',
    linkCategoryId: 'morning_evening'
  },
  {
    key: 'quran_wird',
    title: 'الورد القرآني اليومي',
    subtitle: 'تلاوة جزء أو حزب بتدبر وحضور قلب',
    points: 25,
    category: 'quran',
    categoryName: 'القرآن الكريم',
    icon: 'menu_book'
  },
  {
    key: 'daily_sadaqah',
    title: 'صدقة اليوم',
    subtitle: 'إطعام، تفريج كربة، أو كلمة طيبة وتبسم',
    points: 20,
    category: 'charity',
    categoryName: 'البر والإنفاق',
    icon: 'volunteer_activism'
  }
];

const TOTAL_DAILY_MAX_POINTS = WORSHIP_TASKS.reduce((acc, t) => acc + t.points, 0); // 155 pts

// Central Supabase Production Config (Client-Safe Publishable Key)
const DEFAULT_SUPABASE_CONFIG = {
  url: 'https://chzzvopkxajurwkbdijq.supabase.co',
  anonKey: 'sb_publishable_8lkNqSSfDjRzxhAbniPwmA_G8qaL6A2'
};

class SupabaseService {
  constructor() {
    this.client = null;
    this.currentUser = null;
    this.currentProfile = null;
    this.authListeners = [];
    this.isConfigured = false;
    this.init();
  }

  // Load config from localStorage or defaults
  loadConfig() {
    try {
      const stored = localStorage.getItem('adhkar_supabase_config');
      if (stored) {
        const parsed = JSON.parse(stored);
        if (parsed.url && parsed.anonKey) {
          return parsed;
        }
      }
    } catch (e) {
      console.warn('Failed to load supabase config from storage:', e);
    }
    return DEFAULT_SUPABASE_CONFIG;
  }

  saveConfig(url, anonKey) {
    const config = {
      url: (url || '').trim().replace(/\/+$/, ''),
      anonKey: (anonKey || '').trim()
    };
    try {
      localStorage.setItem('adhkar_supabase_config', JSON.stringify(config));
    } catch (e) {}
    this.init();
    return this.isConfigured;
  }

  init() {
    const config = this.loadConfig();
    if (config.url && config.anonKey && window.supabase && window.supabase.createClient) {
      try {
        this.client = window.supabase.createClient(config.url, config.anonKey, {
          auth: {
            persistSession: true,
            autoRefreshToken: true,
            detectSessionInUrl: true
          }
        });
        this.isConfigured = true;
        this.setupAuthListener();
      } catch (err) {
        console.error('Supabase client init error:', err);
        this.isConfigured = false;
        this.client = null;
      }
    } else {
      this.isConfigured = false;
      this.client = null;
    }
  }

  setupAuthListener() {
    if (!this.client) return;
    this.client.auth.onAuthStateChange(async (event, session) => {
      this.currentUser = session ? session.user : null;
      if (this.currentUser) {
        await this.loadCurrentProfile();
      } else {
        this.currentProfile = null;
      }
      this.notifyAuthListeners();
    });
  }

  onAuthStateChange(listener) {
    if (typeof listener === 'function') {
      this.authListeners.push(listener);
      // Call immediately with current state
      listener(this.currentUser, this.currentProfile);
    }
  }

  notifyAuthListeners() {
    this.authListeners.forEach(fn => {
      try {
        fn(this.currentUser, this.currentProfile);
      } catch (e) {
        console.error('Auth listener error:', e);
      }
    });
  }

  async loadCurrentProfile() {
    if (!this.client || !this.currentUser) return null;
    try {
      const { data, error } = await this.client
        .from('profiles')
        .select('*')
        .eq('id', this.currentUser.id)
        .single();

      if (error) {
        console.warn('Error fetching profile:', error);
        // If trigger hasn't finished yet or table empty, build basic fallback
        this.currentProfile = {
          id: this.currentUser.id,
          email: this.currentUser.email,
          display_name: this.currentUser.user_metadata?.display_name || this.currentUser.email?.split('@')[0] || 'مستخدم',
          avatar_url: this.currentUser.user_metadata?.avatar_url || '',
          friend_code: 'ADK-' + this.currentUser.id.substring(0, 4).toUpperCase(),
          role: this.currentUser.user_metadata?.role || 'user',
          privacy_level: 'public',
          total_points: 0,
          streak_count: 0
        };
      } else {
        this.currentProfile = data;
      }
      return this.currentProfile;
    } catch (e) {
      console.error('Profile fetch exception:', e);
      return null;
    }
  }

  isAdmin() {
    return this.currentProfile?.role === 'admin';
  }

  getPrivacyLevel() {
    return this.currentProfile?.privacy_level || 'public';
  }

  async updatePrivacyLevel(level) {
    if (!['public', 'friends', 'private'].includes(level)) level = 'public';
    if (!this.client || !this.currentUser) {
      if (this.currentProfile) this.currentProfile.privacy_level = level;
      return true;
    }
    const { error } = await this.client
      .from('profiles')
      .update({ privacy_level: level, updated_at: new Date().toISOString() })
      .eq('id', this.currentUser.id);
    if (error) throw error;
    if (this.currentProfile) this.currentProfile.privacy_level = level;
    this.notifyAuthListeners();
    return true;
  }

  // ================= AUTH METHODS =================
  async signUp(email, password, displayName) {
    if (!this.isConfigured || !this.client) {
      throw new Error('لم يتم ربط مشروع Supabase بعد. يرجى إدخال الرابط ومفتاح API في الإعدادات.');
    }

    const { data, error } = await this.client.auth.signUp({
      email,
      password,
      options: {
        data: {
          display_name: displayName,
          full_name: displayName
        }
      }
    });

    if (error) throw error;
    this.currentUser = data.user;
    if (this.currentUser) {
      await this.loadCurrentProfile();
    }
    return data;
  }

  async signIn(email, password) {
    if (!this.isConfigured || !this.client) {
      throw new Error('لم يتم ربط مشروع Supabase بعد. يرجى إدخال الرابط ومفتاح API في الإعدادات.');
    }

    const { data, error } = await this.client.auth.signInWithPassword({
      email,
      password
    });

    if (error) throw error;
    this.currentUser = data.user;
    await this.loadCurrentProfile();
    return data;
  }

  async signOut() {
    if (this.client) {
      await this.client.auth.signOut();
    }
    this.currentUser = null;
    this.currentProfile = null;
    this.notifyAuthListeners();
  }

  async updateProfileDisplayName(newName) {
    if (!this.client || !this.currentUser) return;
    const { error } = await this.client
      .from('profiles')
      .update({ display_name: newName, updated_at: new Date().toISOString() })
      .eq('id', this.currentUser.id);
    if (error) throw error;
    if (this.currentProfile) this.currentProfile.display_name = newName;
    this.notifyAuthListeners();
  }

  // ================= DAILY WORSHIP LOGS =================
  getTodayDateString() {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  async getTodayWorshipStatus() {
    const todayStr = this.getTodayDateString();

    // If logged in to Supabase
    if (this.isConfigured && this.currentUser && this.client) {
      try {
        const { data, error } = await this.client
          .from('daily_worship_logs')
          .select('worship_key, points, created_at')
          .eq('user_id', this.currentUser.id)
          .eq('log_date', todayStr);

        if (error) {
          console.warn('Error fetching daily logs from Supabase:', error);
          return this.getLocalWorshipStatus(todayStr);
        }

        const map = {};
        (data || []).forEach(row => {
          map[row.worship_key] = true;
        });

        // Also sync local cache
        localStorage.setItem(`adhkar_worship_${todayStr}`, JSON.stringify(map));
        return map;
      } catch (err) {
        console.warn('Fallback to local storage for worship status:', err);
        return this.getLocalWorshipStatus(todayStr);
      }
    }

    // Guest / Offline mode
    return this.getLocalWorshipStatus(todayStr);
  }

  getLocalWorshipStatus(todayStr) {
    try {
      const stored = localStorage.getItem(`adhkar_worship_${todayStr}`);
      return stored ? JSON.parse(stored) : {};
    } catch (e) {
      return {};
    }
  }

  async toggleWorshipTask(worshipKey, isCompleted) {
    const task = WORSHIP_TASKS.find(t => t.key === worshipKey);
    if (!task) return { success: false };

    const todayStr = this.getTodayDateString();

    // Update local storage first for instant feedback
    const localStatus = this.getLocalWorshipStatus(todayStr);
    if (isCompleted) {
      localStatus[worshipKey] = true;
    } else {
      delete localStatus[worshipKey];
    }
    try {
      localStorage.setItem(`adhkar_worship_${todayStr}`, JSON.stringify(localStatus));
    } catch (e) {}

    // If logged in, sync to Supabase
    if (this.isConfigured && this.currentUser && this.client) {
      try {
        if (isCompleted) {
          const { error } = await this.client
            .from('daily_worship_logs')
            .upsert({
              user_id: this.currentUser.id,
              log_date: todayStr,
              worship_key: worshipKey,
              points: task.points
            }, { onConflict: 'user_id,log_date,worship_key' });
          if (error) throw error;
        } else {
          const { error } = await this.client
            .from('daily_worship_logs')
            .delete()
            .eq('user_id', this.currentUser.id)
            .eq('log_date', todayStr)
            .eq('worship_key', worshipKey);
          if (error) throw error;
        }

        // Refresh profile to update total points & streaks
        await this.loadCurrentProfile();
      } catch (err) {
        console.error('Failed to sync worship task to Supabase:', err);
      }
    }

    return {
      success: true,
      worshipKey,
      isCompleted,
      points: task.points,
      localStatus
    };
  }

  // ================= FRIENDSHIPS =================
  async sendFriendRequestByCode(friendCode) {
    if (!this.isConfigured || !this.currentUser || !this.client) {
      throw new Error('يجب تسجيل الدخول لإرسال طلبات الصداقة.');
    }

    const cleanCode = (friendCode || '').trim().toUpperCase();
    if (!cleanCode) throw new Error('يرجى إدخال كود الصداقة.');

    // 1. Find target user by friend code
    const { data: targetProfile, error: profileErr } = await this.client
      .from('profiles')
      .select('id, display_name, friend_code')
      .eq('friend_code', cleanCode)
      .single();

    if (profileErr || !targetProfile) {
      throw new Error('لم يتم العثور على مستخدم بهذا الكود، تأكد من صحة الكود.');
    }

    if (targetProfile.id === this.currentUser.id) {
      throw new Error('لا يمكنك إرسال طلب صداقة لنفسك!');
    }

    // 2. Check if friendship already exists
    const { data: existing } = await this.client
      .from('friendships')
      .select('id, status, user_id, friend_id')
      .or(`and(user_id.eq.${this.currentUser.id},friend_id.eq.${targetProfile.id}),and(user_id.eq.${targetProfile.id},friend_id.eq.${this.currentUser.id})`)
      .maybeSingle();

    if (existing) {
      if (existing.status === 'accepted') {
        throw new Error(`أنت و ${targetProfile.display_name} أصدقاء بالفعل!`);
      } else if (existing.status === 'pending') {
        if (existing.user_id === this.currentUser.id) {
          throw new Error('طلب الصداقة قيد الانتظار بالفعل.');
        } else {
          // The other user sent a request to me! Accept it directly
          await this.respondToFriendRequest(existing.id, true);
          return { acceptedDirectly: true, targetProfile };
        }
      }
    }

    // 3. Insert friendship request
    const { data, error: insertErr } = await this.client
      .from('friendships')
      .insert({
        user_id: this.currentUser.id,
        friend_id: targetProfile.id,
        status: 'pending'
      })
      .select()
      .single();

    if (insertErr) throw insertErr;
    return { data, targetProfile };
  }

  async fetchFriendRequests() {
    if (!this.isConfigured || !this.currentUser || !this.client) return [];
    try {
      const { data, error } = await this.client
        .from('friendships')
        .select(`
          id,
          user_id,
          status,
          created_at,
          sender:profiles!friendships_user_id_fkey(id, display_name, avatar_url, friend_code, total_points, streak_count)
        `)
        .eq('friend_id', this.currentUser.id)
        .eq('status', 'pending');

      if (error) {
        console.warn('Error fetching friend requests:', error);
        return [];
      }
      return data || [];
    } catch (e) {
      console.error('Fetch requests exception:', e);
      return [];
    }
  }

  async respondToFriendRequest(friendshipId, accept) {
    if (!this.isConfigured || !this.currentUser || !this.client) return false;
    const newStatus = accept ? 'accepted' : 'declined';
    const { error } = await this.client
      .from('friendships')
      .update({ status: newStatus, updated_at: new Date().toISOString() })
      .eq('id', friendshipId);

    if (error) throw error;
    return true;
  }

  async fetchFriendsList() {
    if (!this.isConfigured || !this.currentUser || !this.client) return [];
    try {
      const { data, error } = await this.client
        .from('friendships')
        .select(`
          id,
          user_id,
          friend_id,
          status,
          created_at,
          requester:profiles!friendships_user_id_fkey(id, display_name, avatar_url, friend_code, total_points, streak_count),
          recipient:profiles!friendships_friend_id_fkey(id, display_name, avatar_url, friend_code, total_points, streak_count)
        `)
        .eq('status', 'accepted')
        .or(`user_id.eq.${this.currentUser.id},friend_id.eq.${this.currentUser.id}`);

      if (error) {
        console.warn('Error fetching friends list:', error);
        return [];
      }

      return (data || []).map(f => {
        const friend = f.user_id === this.currentUser.id ? f.recipient : f.requester;
        return {
          friendshipId: f.id,
          ...friend
        };
      });
    } catch (e) {
      console.error('Fetch friends list exception:', e);
      return [];
    }
  }

  async removeFriend(friendshipId) {
    if (!this.isConfigured || !this.currentUser || !this.client) return false;
    const { error } = await this.client
      .from('friendships')
      .delete()
      .eq('id', friendshipId);
    if (error) throw error;
    return true;
  }

  // ================= LEADERBOARD =================
  async fetchLeaderboard(timeframe = 'today', onlyFriends = false) {
    // If Supabase is connected
    if (this.isConfigured && this.client) {
      try {
        const userId = this.currentUser ? this.currentUser.id : null;

        // Try Stored Procedure RPC first
        const { data, error } = await this.client.rpc('get_leaderboard', {
          p_timeframe: timeframe,
          p_user_id: userId,
          p_only_friends: onlyFriends
        });

        if (!error && Array.isArray(data)) {
          return data;
        }

        // Fallback: direct query on profiles
        console.warn('RPC get_leaderboard fallback to direct query:', error?.message);
        let query = this.client
          .from('profiles')
          .select('id, display_name, avatar_url, friend_code, total_points, streak_count')
          .order('total_points', { ascending: false })
          .limit(50);

        const { data: fallbackProfiles, error: fbErr } = await query;
        if (fbErr) throw fbErr;

        return (fallbackProfiles || []).map((p, idx) => ({
          user_id: p.id,
          display_name: p.display_name,
          avatar_url: p.avatar_url,
          friend_code: p.friend_code,
          points: p.total_points || 0,
          streak_count: p.streak_count || 0,
          rank: idx + 1,
          is_friend: false
        }));
      } catch (err) {
        console.warn('Failed to fetch leaderboard from Supabase:', err);
      }
    }

    // Demo / Offline Mock Leaderboard to showcase the stunning UI
    return this.getMockLeaderboard(timeframe, onlyFriends);
  }

  getMockLeaderboard(timeframe, onlyFriends) {
    const todayStr = this.getTodayDateString();
    const localStatus = this.getLocalWorshipStatus(todayStr);
    let myCurrentPoints = 0;
    Object.keys(localStatus).forEach(key => {
      const task = WORSHIP_TASKS.find(t => t.key === key);
      if (task) myCurrentPoints += task.points;
    });

    const mockData = [
      {
        user_id: 'mock-1',
        display_name: 'عبدالرحمن محمد',
        avatar_url: '',
        friend_code: 'ADK-7A8B',
        points: timeframe === 'today' ? 145 : (timeframe === 'week' ? 980 : 4200),
        streak_count: 14,
        rank: 1,
        is_friend: true
      },
      {
        user_id: 'mock-2',
        display_name: 'أحمد الفاروق',
        avatar_url: '',
        friend_code: 'ADK-3X9P',
        points: timeframe === 'today' ? 130 : (timeframe === 'week' ? 890 : 3850),
        streak_count: 9,
        rank: 2,
        is_friend: true
      },
      {
        user_id: 'mock-3',
        display_name: 'عمر بن الخطاب (محب للخير)',
        avatar_url: '',
        friend_code: 'ADK-9K2L',
        points: timeframe === 'today' ? 120 : (timeframe === 'week' ? 810 : 3400),
        streak_count: 7,
        rank: 3,
        is_friend: false
      },
      {
        user_id: 'current-guest-user',
        display_name: this.currentProfile?.display_name || 'أنت (حساب محلي)',
        avatar_url: '',
        friend_code: this.currentProfile?.friend_code || 'ADK-ME01',
        points: myCurrentPoints > 0 ? myCurrentPoints : (timeframe === 'today' ? 85 : 550),
        streak_count: 3,
        rank: 4,
        is_friend: false,
        is_me: true
      },
      {
        user_id: 'mock-4',
        display_name: 'يوسف الصديق',
        avatar_url: '',
        friend_code: 'ADK-4R5T',
        points: timeframe === 'today' ? 70 : (timeframe === 'week' ? 490 : 2100),
        streak_count: 5,
        rank: 5,
        is_friend: true
      },
      {
        user_id: 'mock-5',
        display_name: 'سارة خالد',
        avatar_url: '',
        friend_code: 'ADK-6H8J',
        points: timeframe === 'today' ? 50 : (timeframe === 'week' ? 380 : 1850),
        streak_count: 2,
        rank: 6,
        is_friend: true
      }
    ];

    if (onlyFriends) {
      return mockData.filter(u => u.is_friend || u.is_me);
    }
    return mockData;
  }
}

// Global Singleton Instance
window.supabaseService = new SupabaseService();

