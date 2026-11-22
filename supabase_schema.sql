-- ==============================================================================
-- Serene Adhkar Sanctuary: Supabase Database Schema
-- Includes User Profiles, Gamified Daily Worship Logs, Friendships & Leaderboards
-- ==============================================================================

-- 1. Profiles Table (Extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    display_name TEXT NOT NULL,
    avatar_url TEXT DEFAULT '',
    friend_code TEXT UNIQUE NOT NULL,
    total_points BIGINT DEFAULT 0,
    streak_count INT DEFAULT 0,
    last_active_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for friend code lookup
CREATE INDEX IF NOT EXISTS idx_profiles_friend_code ON public.profiles(friend_code);

-- 2. Daily Worship Logs Table
CREATE TABLE IF NOT EXISTS public.daily_worship_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    log_date DATE NOT NULL DEFAULT CURRENT_DATE,
    worship_key TEXT NOT NULL,
    points INT NOT NULL DEFAULT 10,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_user_daily_worship UNIQUE (user_id, log_date, worship_key)
);

CREATE INDEX IF NOT EXISTS idx_daily_worship_user_date ON public.daily_worship_logs(user_id, log_date);

-- 3. Friendships Table (Social & Competitive Requests)
CREATE TABLE IF NOT EXISTS public.friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_friendship UNIQUE (user_id, friend_id),
    CONSTRAINT no_self_friendship CHECK (user_id != friend_id)
);

CREATE INDEX IF NOT EXISTS idx_friendships_users ON public.friendships(user_id, friend_id);

-- ==============================================================================
-- Row Level Security (RLS) Policies
-- ==============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_worship_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;

-- Profiles Policies
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone"
    ON public.profiles FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- Daily Worship Logs Policies
DROP POLICY IF EXISTS "Logs are viewable by everyone for leaderboard" ON public.daily_worship_logs;
CREATE POLICY "Logs are viewable by everyone for leaderboard"
    ON public.daily_worship_logs FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Users can insert own logs" ON public.daily_worship_logs;
CREATE POLICY "Users can insert own logs"
    ON public.daily_worship_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own logs" ON public.daily_worship_logs;
CREATE POLICY "Users can delete own logs"
    ON public.daily_worship_logs FOR DELETE
    USING (auth.uid() = user_id);

-- Friendships Policies
DROP POLICY IF EXISTS "Users can view friendships involving them" ON public.friendships;
CREATE POLICY "Users can view friendships involving them"
    ON public.friendships FOR SELECT
    USING (auth.uid() = user_id OR auth.uid() = friend_id);

DROP POLICY IF EXISTS "Users can send friend requests" ON public.friendships;
CREATE POLICY "Users can send friend requests"
    ON public.friendships FOR INSERT
    WITH CHECK (auth.uid() = user_id AND user_id != friend_id);

DROP POLICY IF EXISTS "Receivers can update friendship status" ON public.friendships;
CREATE POLICY "Receivers can update friendship status"
    ON public.friendships FOR UPDATE
    USING (auth.uid() = friend_id);

DROP POLICY IF EXISTS "Users can delete friendship" ON public.friendships;
CREATE POLICY "Users can delete friendship"
    ON public.friendships FOR DELETE
    USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- ==============================================================================
-- Triggers & Auto Profile Provisioning
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    new_code TEXT;
BEGIN
    -- Generate unique friend code (e.g. ADK-7A2B)
    LOOP
        new_code := 'ADK-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 4));
        EXIT WHEN NOT EXISTS (SELECT 1 FROM public.profiles WHERE friend_code = new_code);
    END LOOP;

    INSERT INTO public.profiles (id, email, display_name, avatar_url, friend_code)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(
            NEW.raw_user_meta_data->>'full_name',
            NEW.raw_user_meta_data->>'name',
            SPLIT_PART(NEW.email, '@', 1)
        ),
        COALESCE(
            NEW.raw_user_meta_data->>'avatar_url',
            NEW.raw_user_meta_data->>'picture',
            ''
        ),
        new_code
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Trigger to recalculate total points & streak on daily log changes
CREATE OR REPLACE FUNCTION public.update_profile_gamification()
RETURNS TRIGGER AS $$
DECLARE
    target_user_id UUID;
    calculated_total BIGINT;
    today_active BOOLEAN;
    yesterday_active BOOLEAN;
    current_streak INT;
    last_act DATE;
BEGIN
    IF TG_OP = 'DELETE' THEN
        target_user_id := OLD.user_id;
    ELSE
        target_user_id := NEW.user_id;
    END IF;

    -- Calculate total points from all logs
    SELECT COALESCE(SUM(points), 0) INTO calculated_total
    FROM public.daily_worship_logs
    WHERE user_id = target_user_id;

    -- Calculate streak
    SELECT last_active_date, streak_count INTO last_act, current_streak
    FROM public.profiles
    WHERE id = target_user_id;

    IF TG_OP = 'INSERT' THEN
        IF last_act = CURRENT_DATE THEN
            -- already recorded today, keep streak
            NULL;
        ELSIF last_act = CURRENT_DATE - INTERVAL '1 day' THEN
            -- continued streak
            current_streak := COALESCE(current_streak, 0) + 1;
        ELSE
            -- streak broken or brand new
            current_streak := 1;
        END IF;

        UPDATE public.profiles
        SET total_points = calculated_total,
            streak_count = current_streak,
            last_active_date = CURRENT_DATE,
            updated_at = NOW()
        WHERE id = target_user_id;
    ELSE
        UPDATE public.profiles
        SET total_points = calculated_total,
            updated_at = NOW()
        WHERE id = target_user_id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_update_points_insert ON public.daily_worship_logs;
CREATE TRIGGER trg_update_points_insert
    AFTER INSERT OR DELETE ON public.daily_worship_logs
    FOR EACH ROW EXECUTE FUNCTION public.update_profile_gamification();

-- ==============================================================================
-- Stored Procedure: RPC Leaderboard
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.get_leaderboard(
    p_timeframe TEXT DEFAULT 'today',
    p_user_id UUID DEFAULT NULL,
    p_only_friends BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    user_id UUID,
    display_name TEXT,
    avatar_url TEXT,
    friend_code TEXT,
    points BIGINT,
    streak_count INT,
    rank BIGINT,
    is_friend BOOLEAN
) AS $$
DECLARE
    start_date DATE;
BEGIN
    IF p_timeframe = 'today' THEN
        start_date := CURRENT_DATE;
    ELSIF p_timeframe = 'week' THEN
        start_date := DATE_TRUNC('week', CURRENT_DATE)::DATE;
    ELSIF p_timeframe = 'month' THEN
        start_date := DATE_TRUNC('month', CURRENT_DATE)::DATE;
    ELSE
        start_date := '2000-01-01'::DATE;
    END IF;

    RETURN QUERY
    WITH user_points AS (
        SELECT 
            p.id,
            p.display_name,
            p.avatar_url,
            p.friend_code,
            p.streak_count,
            COALESCE(SUM(l.points), 0)::BIGINT AS period_points,
            EXISTS (
                SELECT 1 FROM public.friendships f
                WHERE f.status = 'accepted'
                AND (
                    (f.user_id = p_user_id AND f.friend_id = p.id) OR
                    (f.friend_id = p_user_id AND f.user_id = p.id)
                )
            ) AS friend_flag
        FROM public.profiles p
        LEFT JOIN public.daily_worship_logs l 
            ON l.user_id = p.id 
            AND l.log_date >= start_date
        WHERE 
            (NOT p_only_friends OR p.id = p_user_id OR EXISTS (
                SELECT 1 FROM public.friendships f
                WHERE f.status = 'accepted'
                AND (
                    (f.user_id = p_user_id AND f.friend_id = p.id) OR
                    (f.friend_id = p_user_id AND f.user_id = p.id)
                )
            ))
        GROUP BY p.id, p.display_name, p.avatar_url, p.friend_code, p.streak_count
    )
    SELECT 
        up.id,
        up.display_name,
        up.avatar_url,
        up.friend_code,
        up.period_points,
        up.streak_count,
        DENSE_RANK() OVER (ORDER BY up.period_points DESC, up.id ASC) AS rank,
        up.friend_flag
    FROM user_points up
    ORDER BY rank ASC, up.display_name ASC
    LIMIT 100;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

