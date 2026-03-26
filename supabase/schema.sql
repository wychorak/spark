-- ============================================================
-- SPARK v1.0 – Complete Supabase Schema
-- PostgreSQL 15 + PostGIS + RLS
-- ============================================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE gender_type AS ENUM ('female', 'male', 'nonbinary');
CREATE TYPE relationship_mode AS ENUM ('relationship', 'friends', 'fwb');
CREATE TYPE swipe_type AS ENUM ('like', 'pass', 'superlike');
CREATE TYPE report_reason AS ENUM ('fake_profile', 'inappropriate_content', 'harassment', 'underage', 'spam', 'other');
CREATE TYPE verification_status AS ENUM ('pending', 'verified', 'rejected');
CREATE TYPE subscription_plan AS ENUM ('monthly', 'yearly');
CREATE TYPE message_type AS ENUM ('text', 'image', 'gif');

-- ============================================================
-- INTERESTS (30 predefined)
-- ============================================================

CREATE TABLE interests (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  emoji TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO interests (name, emoji) VALUES
  ('Podróże', '✈️'), ('Muzyka', '🎵'), ('Gotowanie', '🍳'), ('Fitness', '💪'), ('Fotografia', '📸'),
  ('Gaming', '🎮'), ('Film', '🎬'), ('Książki', '📚'), ('Taniec', '💃'), ('Sztuka', '🎨'),
  ('Joga', '🧘'), ('Bieganie', '🏃'), ('Rower', '🚴'), ('Psy', '🐕'), ('Koty', '🐈'),
  ('Kawa', '☕'), ('Wino', '🍷'), ('Piwo', '🍺'), ('Siłownia', '🏋️'), ('Pływanie', '🏊'),
  ('Hiking', '⛰️'), ('Koszykówka', '🏀'), ('Piłka nożna', '⚽'), ('Technologia', '💻'), ('Moda', '👗'),
  ('Astrologia', '♈'), ('Netflix', '📺'), ('Stand-up', '😂'), ('Wolontariat', '❤️'), ('Języki', '🌍');

-- ============================================================
-- USER PROFILES
-- ============================================================

CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL CHECK (char_length(display_name) BETWEEN 2 AND 30),
  bio TEXT CHECK (char_length(bio) <= 500),
  born_at DATE NOT NULL,
  gender gender_type NOT NULL,
  modes relationship_mode[] NOT NULL DEFAULT '{relationship}',
  location GEOGRAPHY(POINT, 4326),
  city TEXT,
  spotify_track_uri TEXT,
  spotify_preview_url TEXT,
  spotify_track_name TEXT,
  spotify_artist_name TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  is_verified BOOLEAN DEFAULT FALSE,
  is_premium BOOLEAN DEFAULT FALSE,
  last_active_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Computed age check (must be 18+)
  CONSTRAINT age_check CHECK (born_at <= CURRENT_DATE - INTERVAL '18 years')
);

CREATE INDEX idx_user_profiles_location ON user_profiles USING GIST (location);
CREATE INDEX idx_user_profiles_modes ON user_profiles USING GIN (modes);
CREATE INDEX idx_user_profiles_gender ON user_profiles (gender);
CREATE INDEX idx_user_profiles_active ON user_profiles (is_active) WHERE is_active = TRUE;
CREATE INDEX idx_user_profiles_last_active ON user_profiles (last_active_at DESC);

-- ============================================================
-- USER PHOTOS
-- ============================================================

CREATE TABLE user_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  position SMALLINT NOT NULL CHECK (position BETWEEN 0 AND 5),
  is_primary BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE (user_id, position)
);

CREATE INDEX idx_user_photos_user ON user_photos (user_id);

-- ============================================================
-- USER INTERESTS (M2M)
-- ============================================================

CREATE TABLE user_interests (
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  interest_id INT NOT NULL REFERENCES interests(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, interest_id)
);

CREATE INDEX idx_user_interests_user ON user_interests (user_id);

-- ============================================================
-- USER PREFERENCES (discovery filters)
-- ============================================================

CREATE TABLE user_preferences (
  user_id UUID PRIMARY KEY REFERENCES user_profiles(id) ON DELETE CASCADE,
  min_age INT DEFAULT 18 CHECK (min_age >= 18),
  max_age INT DEFAULT 50 CHECK (max_age <= 100),
  max_distance_km INT DEFAULT 50 CHECK (max_distance_km BETWEEN 1 AND 150),
  preferred_genders gender_type[] DEFAULT '{female,male,nonbinary}',
  preferred_modes relationship_mode[] DEFAULT '{relationship,friends,fwb}',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- SWIPE ACTIONS
-- ============================================================

CREATE TABLE swipe_actions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  target_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  action swipe_type NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE (user_id, target_id)
);

CREATE INDEX idx_swipe_actions_user ON swipe_actions (user_id);
CREATE INDEX idx_swipe_actions_target ON swipe_actions (target_id);
CREATE INDEX idx_swipe_actions_mutual ON swipe_actions (target_id, user_id, action);

-- ============================================================
-- MATCHES
-- ============================================================

CREATE TABLE matches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user1_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  user2_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  matched_at TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE,

  UNIQUE (user1_id, user2_id),
  CONSTRAINT ordered_users CHECK (user1_id < user2_id)
);

CREATE INDEX idx_matches_user1 ON matches (user1_id) WHERE is_active = TRUE;
CREATE INDEX idx_matches_user2 ON matches (user2_id) WHERE is_active = TRUE;

-- ============================================================
-- CONVERSATIONS
-- ============================================================

CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  match_id UUID NOT NULL UNIQUE REFERENCES matches(id) ON DELETE CASCADE,
  last_message_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_conversations_last_msg ON conversations (last_message_at DESC NULLS LAST);

-- ============================================================
-- MESSAGES
-- ============================================================

CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  content TEXT,
  message_type message_type DEFAULT 'text',
  image_path TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation ON messages (conversation_id, created_at DESC);
CREATE INDEX idx_messages_sender ON messages (sender_id);

-- ============================================================
-- BLOCKS
-- ============================================================

CREATE TABLE blocks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  blocker_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE (blocker_id, blocked_id)
);

CREATE INDEX idx_blocks_blocker ON blocks (blocker_id);
CREATE INDEX idx_blocks_blocked ON blocks (blocked_id);

-- ============================================================
-- REPORTS
-- ============================================================

CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  reported_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  reason report_reason NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_reports_reported ON reports (reported_id);

-- ============================================================
-- USER VERIFICATIONS
-- ============================================================

CREATE TABLE user_verifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  selfie_path TEXT NOT NULL,
  status verification_status DEFAULT 'pending',
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_verifications_user ON user_verifications (user_id);

-- ============================================================
-- PREMIUM SUBSCRIPTIONS
-- ============================================================

CREATE TABLE premium_subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  plan subscription_plan NOT NULL,
  store_product_id TEXT NOT NULL,
  store_transaction_id TEXT,
  starts_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_subscriptions_user ON premium_subscriptions (user_id) WHERE is_active = TRUE;

-- ============================================================
-- DAILY LIMITS
-- ============================================================

CREATE TABLE daily_limits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  swipe_count INT DEFAULT 0,
  superlike_count INT DEFAULT 0,

  UNIQUE (user_id, date)
);

CREATE INDEX idx_daily_limits_user_date ON daily_limits (user_id, date);

-- ============================================================
-- PUSH TOKENS
-- ============================================================

CREATE TABLE push_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_push_tokens_user ON push_tokens (user_id);

-- ============================================================
-- ACTIVITY SCORES (for algorithm boost)
-- ============================================================

CREATE TABLE activity_scores (
  user_id UUID PRIMARY KEY REFERENCES user_profiles(id) ON DELETE CASCADE,
  score NUMERIC(4,2) DEFAULT 0.5,
  boost_until TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION fn_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_user_profiles_updated
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();

CREATE TRIGGER trg_user_preferences_updated
  BEFORE UPDATE ON user_preferences
  FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();

-- Match check trigger
CREATE OR REPLACE FUNCTION fn_check_match()
RETURNS TRIGGER AS $$
DECLARE
  v_match_id UUID;
  v_user1 UUID;
  v_user2 UUID;
BEGIN
  IF NEW.action IN ('like', 'superlike') THEN
    IF EXISTS (
      SELECT 1 FROM swipe_actions
      WHERE user_id = NEW.target_id
        AND target_id = NEW.user_id
        AND action IN ('like', 'superlike')
    ) THEN
      v_user1 := LEAST(NEW.user_id, NEW.target_id);
      v_user2 := GREATEST(NEW.user_id, NEW.target_id);

      INSERT INTO matches (user1_id, user2_id)
      VALUES (v_user1, v_user2)
      ON CONFLICT (user1_id, user2_id) DO NOTHING
      RETURNING id INTO v_match_id;

      IF v_match_id IS NOT NULL THEN
        INSERT INTO conversations (match_id)
        VALUES (v_match_id);
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_swipe_check_match
  AFTER INSERT ON swipe_actions
  FOR EACH ROW EXECUTE FUNCTION fn_check_match();

-- Update conversation last_message_at
CREATE OR REPLACE FUNCTION fn_update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations
  SET last_message_at = NEW.created_at
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_messages_update_conversation
  AFTER INSERT ON messages
  FOR EACH ROW EXECUTE FUNCTION fn_update_conversation_last_message();

-- Update last_active_at on profile
CREATE OR REPLACE FUNCTION fn_update_last_active()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE user_profiles
  SET last_active_at = NOW()
  WHERE id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_swipe_update_active
  AFTER INSERT ON swipe_actions
  FOR EACH ROW EXECUTE FUNCTION fn_update_last_active();

-- Increment daily limits
CREATE OR REPLACE FUNCTION fn_increment_daily_limit(p_user_id UUID, p_action swipe_type)
RETURNS BOOLEAN AS $$
DECLARE
  v_is_premium BOOLEAN;
  v_swipe_count INT;
  v_superlike_count INT;
BEGIN
  SELECT is_premium INTO v_is_premium FROM user_profiles WHERE id = p_user_id;

  INSERT INTO daily_limits (user_id, date, swipe_count, superlike_count)
  VALUES (p_user_id, CURRENT_DATE, 0, 0)
  ON CONFLICT (user_id, date) DO NOTHING;

  SELECT swipe_count, superlike_count INTO v_swipe_count, v_superlike_count
  FROM daily_limits WHERE user_id = p_user_id AND date = CURRENT_DATE;

  -- Check limits
  IF NOT v_is_premium THEN
    IF p_action IN ('like', 'pass') AND v_swipe_count >= 50 THEN
      RETURN FALSE;
    END IF;
    IF p_action = 'superlike' AND v_superlike_count >= 1 THEN
      RETURN FALSE;
    END IF;
  ELSE
    IF p_action = 'superlike' AND v_superlike_count >= 10 THEN
      RETURN FALSE;
    END IF;
  END IF;

  -- Increment
  IF p_action = 'superlike' THEN
    UPDATE daily_limits SET superlike_count = superlike_count + 1
    WHERE user_id = p_user_id AND date = CURRENT_DATE;
  ELSE
    UPDATE daily_limits SET swipe_count = swipe_count + 1
    WHERE user_id = p_user_id AND date = CURRENT_DATE;
  END IF;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Discovery function (PostGIS + scoring)
CREATE OR REPLACE FUNCTION fn_discover_profiles(
  p_user_id UUID,
  p_lon DOUBLE PRECISION,
  p_lat DOUBLE PRECISION,
  p_radius_km INT DEFAULT 50,
  p_min_age INT DEFAULT 18,
  p_max_age INT DEFAULT 50,
  p_genders gender_type[] DEFAULT '{female,male,nonbinary}',
  p_modes relationship_mode[] DEFAULT '{relationship,friends,fwb}',
  p_limit INT DEFAULT 20
)
RETURNS TABLE (
  profile_id UUID,
  display_name TEXT,
  bio TEXT,
  age INT,
  gender gender_type,
  modes relationship_mode[],
  distance_km DOUBLE PRECISION,
  score DOUBLE PRECISION,
  is_verified BOOLEAN,
  spotify_track_name TEXT,
  spotify_artist_name TEXT,
  spotify_preview_url TEXT,
  city TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    up.id AS profile_id,
    up.display_name,
    up.bio,
    EXTRACT(YEAR FROM age(up.born_at))::INT AS age,
    up.gender,
    up.modes,
    ROUND((ST_Distance(
      up.location::geography,
      ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326)::geography
    ) / 1000)::numeric, 1)::DOUBLE PRECISION AS distance_km,
    -- Scoring
    (
      (1.0 - LEAST(ST_Distance(up.location::geography, ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326)::geography) / 1000 / p_radius_km, 1.0)) * 0.4
      + (SELECT COUNT(*)::DOUBLE PRECISION / GREATEST((SELECT COUNT(*) FROM user_interests WHERE user_id = p_user_id), 1)
         FROM user_interests ui2 WHERE ui2.user_id = up.id
         AND ui2.interest_id IN (SELECT interest_id FROM user_interests WHERE user_id = p_user_id)
        ) * 0.35
      + CASE
          WHEN up.last_active_at > NOW() - INTERVAL '1 hour' THEN 1.0
          WHEN up.last_active_at > NOW() - INTERVAL '24 hours' THEN 0.7
          WHEN up.last_active_at > NOW() - INTERVAL '72 hours' THEN 0.4
          ELSE 0.1
        END * 0.15
      + CASE WHEN COALESCE((SELECT boost_until FROM activity_scores WHERE activity_scores.user_id = up.id), NOW() - INTERVAL '1 day') > NOW() THEN 1.0 ELSE 0.0 END * 0.10
    ) AS score,
    up.is_verified,
    up.spotify_track_name,
    up.spotify_artist_name,
    up.spotify_preview_url,
    up.city
  FROM user_profiles up
  WHERE up.id != p_user_id
    AND up.is_active = TRUE
    AND up.location IS NOT NULL
    AND ST_DWithin(
      up.location::geography,
      ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326)::geography,
      p_radius_km * 1000
    )
    AND EXTRACT(YEAR FROM age(up.born_at))::INT BETWEEN p_min_age AND p_max_age
    AND up.gender = ANY(p_genders)
    AND up.modes && p_modes
    AND up.id NOT IN (SELECT sa.target_id FROM swipe_actions sa WHERE sa.user_id = p_user_id)
    AND up.id NOT IN (SELECT b.blocked_id FROM blocks b WHERE b.blocker_id = p_user_id)
    AND up.id NOT IN (SELECT b.blocker_id FROM blocks b WHERE b.blocked_id = p_user_id)
  ORDER BY score DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE swipe_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE premium_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE interests ENABLE ROW LEVEL SECURITY;

-- Interests: anyone authenticated can read
CREATE POLICY interests_select_authenticated ON interests
  FOR SELECT TO authenticated USING (TRUE);

-- User Profiles
CREATE POLICY user_profiles_select_authenticated ON user_profiles
  FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY user_profiles_insert_own ON user_profiles
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

CREATE POLICY user_profiles_update_own ON user_profiles
  FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- User Photos
CREATE POLICY user_photos_select_authenticated ON user_photos
  FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY user_photos_insert_own ON user_photos
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY user_photos_update_own ON user_photos
  FOR UPDATE TO authenticated USING (auth.uid() = user_id);

CREATE POLICY user_photos_delete_own ON user_photos
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- User Interests
CREATE POLICY user_interests_select_authenticated ON user_interests
  FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY user_interests_insert_own ON user_interests
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY user_interests_delete_own ON user_interests
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- User Preferences
CREATE POLICY user_preferences_select_own ON user_preferences
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

CREATE POLICY user_preferences_insert_own ON user_preferences
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY user_preferences_update_own ON user_preferences
  FOR UPDATE TO authenticated USING (auth.uid() = user_id);

-- Swipe Actions
CREATE POLICY swipe_actions_insert_own ON swipe_actions
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY swipe_actions_select_own ON swipe_actions
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

-- Matches (both users can see)
CREATE POLICY matches_select_participant ON matches
  FOR SELECT TO authenticated
  USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Conversations (both matched users)
CREATE POLICY conversations_select_participant ON conversations
  FOR SELECT TO authenticated
  USING (
    match_id IN (
      SELECT id FROM matches
      WHERE (user1_id = auth.uid() OR user2_id = auth.uid()) AND is_active = TRUE
    )
  );

-- Messages (participants of conversation)
CREATE POLICY messages_select_participant ON messages
  FOR SELECT TO authenticated
  USING (
    conversation_id IN (
      SELECT c.id FROM conversations c
      JOIN matches m ON m.id = c.match_id
      WHERE (m.user1_id = auth.uid() OR m.user2_id = auth.uid()) AND m.is_active = TRUE
    )
  );

CREATE POLICY messages_insert_participant ON messages
  FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = sender_id
    AND conversation_id IN (
      SELECT c.id FROM conversations c
      JOIN matches m ON m.id = c.match_id
      WHERE (m.user1_id = auth.uid() OR m.user2_id = auth.uid()) AND m.is_active = TRUE
    )
  );

CREATE POLICY messages_update_read ON messages
  FOR UPDATE TO authenticated
  USING (
    sender_id != auth.uid()
    AND conversation_id IN (
      SELECT c.id FROM conversations c
      JOIN matches m ON m.id = c.match_id
      WHERE (m.user1_id = auth.uid() OR m.user2_id = auth.uid()) AND m.is_active = TRUE
    )
  );

-- Blocks
CREATE POLICY blocks_insert_own ON blocks
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY blocks_select_own ON blocks
  FOR SELECT TO authenticated USING (auth.uid() = blocker_id);

CREATE POLICY blocks_delete_own ON blocks
  FOR DELETE TO authenticated USING (auth.uid() = blocker_id);

-- Reports
CREATE POLICY reports_insert_own ON reports
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY reports_select_own ON reports
  FOR SELECT TO authenticated USING (auth.uid() = reporter_id);

-- User Verifications
CREATE POLICY verifications_insert_own ON user_verifications
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY verifications_select_own ON user_verifications
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

-- Premium Subscriptions
CREATE POLICY subscriptions_select_own ON premium_subscriptions
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

-- Daily Limits
CREATE POLICY daily_limits_select_own ON daily_limits
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

-- Push Tokens
CREATE POLICY push_tokens_insert_own ON push_tokens
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY push_tokens_select_own ON push_tokens
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

CREATE POLICY push_tokens_delete_own ON push_tokens
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- Activity Scores
CREATE POLICY activity_scores_select_authenticated ON activity_scores
  FOR SELECT TO authenticated USING (TRUE);

-- ============================================================
-- STORAGE BUCKETS
-- ============================================================
-- Create via Supabase Dashboard or API:
-- 1. "avatars" bucket (public) – profile photos
-- 2. "chat-images" bucket (private) – chat media
-- 3. "verifications" bucket (private) – selfie verification photos
--
-- Storage policies:
-- avatars: authenticated can upload to own folder (user_id/), public read
-- chat-images: authenticated can upload, only conversation participants can read
-- verifications: authenticated can upload to own folder, only service_role can read

-- ============================================================
-- REALTIME PUBLICATION
-- ============================================================
-- Enable realtime on these tables via Supabase Dashboard:
-- - messages (INSERT)
-- - matches (INSERT)
-- - conversations (UPDATE – last_message_at)
