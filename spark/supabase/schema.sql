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
CREATE TYPE moderation_status AS ENUM ('pending', 'in_review', 'resolved', 'dismissed');
CREATE TYPE verification_status AS ENUM ('pending', 'in_review', 'verified', 'rejected');
CREATE TYPE subscription_plan AS ENUM ('weekly', 'monthly', 'yearly');
CREATE TYPE subscription_status AS ENUM ('active', 'grace_period', 'billing_issue', 'expired', 'cancelled');
CREATE TYPE account_status AS ENUM ('active', 'under_review', 'suspended', 'banned');
CREATE TYPE message_type AS ENUM ('text', 'image', 'gif');
CREATE TYPE chat_request_status AS ENUM ('pending', 'accepted', 'rejected');

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
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  city TEXT,
  desired_interests TEXT[] DEFAULT '{}',
  instagram_handle TEXT,
  tiktok_handle TEXT,
  snapchat_handle TEXT,
  profile_gradient_start TEXT,
  profile_gradient_end TEXT,
  spotify_track_uri TEXT,
  spotify_preview_url TEXT,
  spotify_track_name TEXT,
  spotify_artist_name TEXT,
  spotify_artwork_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  is_admin BOOLEAN DEFAULT FALSE,
  is_verified BOOLEAN DEFAULT FALSE,
  is_premium BOOLEAN DEFAULT FALSE,
  account_status account_status NOT NULL DEFAULT 'active',
  shadow_ban_until TIMESTAMPTZ,
  moderation_notes TEXT,
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
CREATE INDEX idx_user_profiles_account_status ON user_profiles (account_status);

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
-- CHAT REQUESTS
-- ============================================================

CREATE TABLE chat_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  message TEXT NOT NULL CHECK (char_length(message) BETWEEN 1 AND 500),
  status chat_request_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CHECK (sender_id <> receiver_id)
);

CREATE INDEX idx_chat_requests_sender ON chat_requests (sender_id, created_at DESC);
CREATE INDEX idx_chat_requests_receiver ON chat_requests (receiver_id, created_at DESC);
CREATE UNIQUE INDEX idx_chat_requests_conversation
  ON chat_requests (conversation_id)
  WHERE conversation_id IS NOT NULL;

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
  status moderation_status NOT NULL DEFAULT 'pending',
  reviewed_by UUID REFERENCES user_profiles(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  resolution_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_reports_reported ON reports (reported_id);
CREATE INDEX idx_reports_status ON reports (status);

-- ============================================================
-- USER VERIFICATIONS
-- ============================================================

CREATE TABLE user_verifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  selfie_path TEXT NOT NULL,
  status verification_status DEFAULT 'pending',
  reviewed_by UUID REFERENCES user_profiles(id) ON DELETE SET NULL,
  review_notes TEXT,
  rejection_reason TEXT,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_verifications_user ON user_verifications (user_id);
CREATE INDEX idx_verifications_status ON user_verifications (status);

-- ============================================================
-- PREMIUM SUBSCRIPTIONS
-- ============================================================

CREATE TABLE premium_subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  plan subscription_plan NOT NULL,
  store_product_id TEXT NOT NULL,
  store_transaction_id TEXT,
  provider TEXT NOT NULL DEFAULT 'revenuecat',
  entitlement_id TEXT NOT NULL DEFAULT 'premium',
  starts_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  status subscription_status NOT NULL DEFAULT 'active',
  is_active BOOLEAN DEFAULT TRUE,
  auto_renew BOOLEAN DEFAULT TRUE,
  environment TEXT NOT NULL DEFAULT 'production',
  last_synced_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_subscriptions_user ON premium_subscriptions (user_id) WHERE is_active = TRUE;
CREATE INDEX idx_subscriptions_status ON premium_subscriptions (status);

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

CREATE TRIGGER trg_chat_requests_updated
  BEFORE UPDATE ON chat_requests
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

CREATE OR REPLACE FUNCTION fn_submit_swipe_action(
  p_target_id UUID,
  p_action swipe_type
)
RETURNS BOOLEAN AS $$
DECLARE
  v_sender_status account_status;
  v_target_status account_status;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF auth.uid() = p_target_id THEN
    RAISE EXCEPTION 'Cannot swipe yourself';
  END IF;

  SELECT account_status INTO v_sender_status
  FROM user_profiles
  WHERE id = auth.uid();

  SELECT account_status INTO v_target_status
  FROM user_profiles
  WHERE id = p_target_id;

  IF COALESCE(v_sender_status, 'active') <> 'active' THEN
    RAISE EXCEPTION 'Sender account is not active';
  END IF;

  IF COALESCE(v_target_status, 'active') <> 'active' THEN
    RAISE EXCEPTION 'Target account is not active';
  END IF;

  IF EXISTS (
    SELECT 1 FROM blocks
    WHERE (blocker_id = auth.uid() AND blocked_id = p_target_id)
       OR (blocker_id = p_target_id AND blocked_id = auth.uid())
  ) THEN
    RAISE EXCEPTION 'Cannot swipe blocked user';
  END IF;

  IF EXISTS (
    SELECT 1 FROM swipe_actions
    WHERE user_id = auth.uid()
      AND target_id = p_target_id
  ) THEN
    RETURN TRUE;
  END IF;

  IF NOT fn_increment_daily_limit(auth.uid(), p_action) THEN
    RETURN FALSE;
  END IF;

  INSERT INTO swipe_actions (
    user_id,
    target_id,
    action
  ) VALUES (
    auth.uid(),
    p_target_id,
    p_action
  );

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_upsert_profile(
  p_display_name TEXT,
  p_born_at DATE,
  p_gender gender_type,
  p_bio TEXT DEFAULT NULL,
  p_modes relationship_mode[] DEFAULT '{relationship}',
  p_city TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  INSERT INTO user_profiles (
    id,
    display_name,
    born_at,
    gender,
    bio,
    modes,
    city
  )
  VALUES (
    auth.uid(),
    p_display_name,
    p_born_at,
    p_gender,
    NULLIF(p_bio, ''),
    COALESCE(p_modes, '{relationship}'::relationship_mode[]),
    NULLIF(p_city, '')
  )
  ON CONFLICT (id) DO UPDATE
  SET
    display_name = EXCLUDED.display_name,
    born_at = EXCLUDED.born_at,
    gender = EXCLUDED.gender,
    bio = EXCLUDED.bio,
    modes = EXCLUDED.modes,
    city = EXCLUDED.city;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_save_user_interests(p_interest_names TEXT[])
RETURNS VOID AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  DELETE FROM user_interests
  WHERE user_id = auth.uid();

  INSERT INTO user_interests (user_id, interest_id)
  SELECT auth.uid(), i.id
  FROM interests i
  WHERE i.name = ANY(COALESCE(p_interest_names, '{}'::TEXT[]));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_save_user_photo(
  p_storage_path TEXT,
  p_position SMALLINT,
  p_is_primary BOOLEAN DEFAULT FALSE
)
RETURNS VOID AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_is_primary THEN
    UPDATE user_photos
    SET is_primary = FALSE
    WHERE user_id = auth.uid();
  END IF;

  INSERT INTO user_photos (
    user_id,
    storage_path,
    position,
    is_primary
  )
  VALUES (
    auth.uid(),
    p_storage_path,
    p_position,
    p_is_primary
  )
  ON CONFLICT (user_id, position) DO UPDATE
  SET
    storage_path = EXCLUDED.storage_path,
    is_primary = EXCLUDED.is_primary;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_update_user_location(
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  city_name TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  UPDATE user_profiles
  SET
    latitude = lat,
    longitude = lng,
    city = COALESCE(NULLIF(TRIM(city_name), ''), city),
    location = ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
  WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_delete_account()
RETURNS BOOLEAN AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  DELETE FROM auth.users
  WHERE id = auth.uid();

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_submit_report(
  p_reported_id UUID,
  p_reason report_reason,
  p_description TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_report_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF auth.uid() = p_reported_id THEN
    RAISE EXCEPTION 'Cannot report yourself';
  END IF;

  SELECT id
  INTO v_report_id
  FROM reports
  WHERE reporter_id = auth.uid()
    AND reported_id = p_reported_id
    AND reason = p_reason
    AND status IN ('pending', 'in_review')
    AND created_at > NOW() - INTERVAL '24 hours'
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_report_id IS NOT NULL THEN
    RETURN v_report_id;
  END IF;

  INSERT INTO reports (
    reporter_id,
    reported_id,
    reason,
    description
  ) VALUES (
    auth.uid(),
    p_reported_id,
    p_reason,
    NULLIF(TRIM(p_description), '')
  )
  RETURNING id INTO v_report_id;

  RETURN v_report_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_submit_photo_verification(
  p_selfie_path TEXT
)
RETURNS UUID AS $$
DECLARE
  v_verification_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT id
  INTO v_verification_id
  FROM user_verifications
  WHERE user_id = auth.uid()
    AND status IN ('pending', 'in_review')
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_verification_id IS NULL THEN
    INSERT INTO user_verifications (
      user_id,
      selfie_path,
      status
    ) VALUES (
      auth.uid(),
      p_selfie_path,
      'pending'
    )
    RETURNING id INTO v_verification_id;
  ELSE
    UPDATE user_verifications
    SET selfie_path = p_selfie_path,
        status = 'pending',
        reviewed_at = NULL,
        reviewed_by = NULL,
        review_notes = NULL,
        rejection_reason = NULL
    WHERE id = v_verification_id;
  END IF;

  UPDATE user_profiles
  SET is_verified = FALSE
  WHERE id = auth.uid();

  RETURN v_verification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_is_admin(
  p_user_id UUID DEFAULT auth.uid()
)
RETURNS BOOLEAN AS $$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT is_admin
  INTO v_is_admin
  FROM user_profiles
  WHERE id = p_user_id;

  RETURN COALESCE(v_is_admin, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_submit_chat_request(
  p_receiver_id UUID,
  p_message TEXT,
  p_conversation_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_request_id UUID;
  v_sender_status account_status;
  v_receiver_status account_status;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF auth.uid() = p_receiver_id THEN
    RAISE EXCEPTION 'Cannot create chat request to yourself';
  END IF;

  SELECT account_status INTO v_sender_status
  FROM user_profiles
  WHERE id = auth.uid();

  SELECT account_status INTO v_receiver_status
  FROM user_profiles
  WHERE id = p_receiver_id;

  IF COALESCE(v_sender_status, 'active') <> 'active' THEN
    RAISE EXCEPTION 'Sender account is not active';
  END IF;

  IF COALESCE(v_receiver_status, 'active') <> 'active' THEN
    RAISE EXCEPTION 'Receiver account is not active';
  END IF;

  IF EXISTS (
    SELECT 1 FROM blocks
    WHERE (blocker_id = auth.uid() AND blocked_id = p_receiver_id)
       OR (blocker_id = p_receiver_id AND blocked_id = auth.uid())
  ) THEN
    RAISE EXCEPTION 'Cannot create chat request for blocked relationship';
  END IF;

  IF (
    SELECT COUNT(*)
    FROM chat_requests
    WHERE sender_id = auth.uid()
      AND created_at > NOW() - INTERVAL '10 minutes'
  ) >= 5 THEN
    RAISE EXCEPTION 'Too many chat requests, try again later';
  END IF;

  SELECT id
  INTO v_request_id
  FROM chat_requests
  WHERE sender_id = auth.uid()
    AND receiver_id = p_receiver_id
    AND status = 'pending'
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_request_id IS NOT NULL THEN
    RETURN v_request_id;
  END IF;

  INSERT INTO chat_requests (
    sender_id,
    receiver_id,
    conversation_id,
    message,
    status
  ) VALUES (
    auth.uid(),
    p_receiver_id,
    p_conversation_id,
    LEFT(TRIM(p_message), 500),
    'pending'
  )
  RETURNING id INTO v_request_id;

  RETURN v_request_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_send_message(
  p_conversation_id UUID,
  p_content TEXT,
  p_message_type message_type DEFAULT 'text',
  p_image_path TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_message_id UUID;
  v_sender_status account_status;
  v_clean_content TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT account_status
  INTO v_sender_status
  FROM user_profiles
  WHERE id = auth.uid();

  IF COALESCE(v_sender_status, 'active') <> 'active' THEN
    RAISE EXCEPTION 'Sender account is not active';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM conversations c
    JOIN matches m ON m.id = c.match_id
    WHERE c.id = p_conversation_id
      AND m.is_active = TRUE
      AND (m.user1_id = auth.uid() OR m.user2_id = auth.uid())
  ) THEN
    RAISE EXCEPTION 'Conversation not accessible';
  END IF;

  IF (
    SELECT COUNT(*)
    FROM messages
    WHERE sender_id = auth.uid()
      AND created_at > NOW() - INTERVAL '1 minute'
  ) >= 12 THEN
    RAISE EXCEPTION 'Too many messages sent, try again later';
  END IF;

  v_clean_content := NULLIF(TRIM(p_content), '');

  IF p_message_type = 'text' AND v_clean_content IS NULL THEN
    RAISE EXCEPTION 'Message content is required';
  END IF;

  IF v_clean_content IS NOT NULL
    AND EXISTS (
      SELECT 1
      FROM messages
      WHERE conversation_id = p_conversation_id
        AND sender_id = auth.uid()
        AND content = v_clean_content
        AND created_at > NOW() - INTERVAL '30 seconds'
    ) THEN
    RAISE EXCEPTION 'Duplicate message detected';
  END IF;

  INSERT INTO messages (
    conversation_id,
    sender_id,
    content,
    message_type,
    image_path,
    is_read
  ) VALUES (
    p_conversation_id,
    auth.uid(),
    v_clean_content,
    p_message_type,
    p_image_path,
    FALSE
  )
  RETURNING id INTO v_message_id;

  RETURN v_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_respond_to_chat_request(
  p_conversation_id UUID,
  p_status chat_request_status
)
RETURNS UUID AS $$
DECLARE
  v_request chat_requests%ROWTYPE;
  v_message_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_status NOT IN ('accepted', 'rejected') THEN
    RAISE EXCEPTION 'Unsupported chat request status';
  END IF;

  SELECT *
  INTO v_request
  FROM chat_requests
  WHERE conversation_id = p_conversation_id
    AND receiver_id = auth.uid()
    AND status = 'pending'
  ORDER BY created_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No pending chat request found';
  END IF;

  UPDATE chat_requests
  SET status = p_status,
      updated_at = NOW()
  WHERE id = v_request.id;

  IF p_status = 'accepted' AND NULLIF(TRIM(v_request.message), '') IS NOT NULL THEN
    INSERT INTO messages (
      conversation_id,
      sender_id,
      content,
      message_type,
      is_read
    ) VALUES (
      p_conversation_id,
      v_request.sender_id,
      TRIM(v_request.message),
      'text',
      FALSE
    )
    RETURNING id INTO v_message_id;
  END IF;

  RETURN v_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_review_report(
  p_report_id UUID,
  p_status moderation_status,
  p_resolution_notes TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  IF NOT fn_is_admin() THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  UPDATE reports
  SET status = p_status,
      reviewed_by = auth.uid(),
      reviewed_at = NOW(),
      resolved_at = CASE
        WHEN p_status IN ('resolved', 'dismissed') THEN NOW()
        ELSE NULL
      END,
      resolution_notes = NULLIF(TRIM(p_resolution_notes), '')
  WHERE id = p_report_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_get_support_dashboard()
RETURNS TABLE (
  pending_reports BIGINT,
  pending_verifications BIGINT,
  under_review_accounts BIGINT,
  active_premium BIGINT,
  open_chat_requests BIGINT
) AS $$
BEGIN
  IF NOT fn_is_admin() THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  RETURN QUERY
  SELECT
    (SELECT COUNT(*) FROM reports WHERE status IN ('pending', 'in_review')),
    (SELECT COUNT(*) FROM user_verifications WHERE status IN ('pending', 'in_review')),
    (SELECT COUNT(*) FROM user_profiles WHERE account_status = 'under_review'),
    (SELECT COUNT(*) FROM premium_subscriptions WHERE is_active = TRUE AND status IN ('active', 'grace_period')),
    (SELECT COUNT(*) FROM chat_requests WHERE status = 'pending');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_get_moderation_queue(
  p_limit INT DEFAULT 50
)
RETURNS TABLE (
  queue_type TEXT,
  item_id UUID,
  user_id UUID,
  created_at TIMESTAMPTZ,
  status TEXT,
  summary TEXT
) AS $$
BEGIN
  IF NOT fn_is_admin() THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  RETURN QUERY
  SELECT *
  FROM (
    SELECT
      'report'::TEXT AS queue_type,
      r.id AS item_id,
      r.reported_id AS user_id,
      r.created_at,
      r.status::TEXT AS status,
      COALESCE(r.description, r.reason::TEXT) AS summary
    FROM reports r
    WHERE r.status IN ('pending', 'in_review')

    UNION ALL

    SELECT
      'verification'::TEXT AS queue_type,
      uv.id AS item_id,
      uv.user_id,
      uv.created_at,
      uv.status::TEXT AS status,
      COALESCE(uv.review_notes, uv.selfie_path) AS summary
    FROM user_verifications uv
    WHERE uv.status IN ('pending', 'in_review')
  ) queue_items
  ORDER BY created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_review_verification(
  p_verification_id UUID,
  p_status verification_status,
  p_review_notes TEXT DEFAULT NULL,
  p_rejection_reason TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  v_user_id UUID;
BEGIN
  IF NOT fn_is_admin() THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  SELECT user_id
  INTO v_user_id
  FROM user_verifications
  WHERE id = p_verification_id;

  UPDATE user_verifications
  SET status = p_status,
      reviewed_by = auth.uid(),
      reviewed_at = NOW(),
      review_notes = NULLIF(TRIM(p_review_notes), ''),
      rejection_reason = CASE
        WHEN p_status = 'rejected' THEN NULLIF(TRIM(p_rejection_reason), '')
        ELSE NULL
      END
  WHERE id = p_verification_id;

  IF v_user_id IS NOT NULL THEN
    UPDATE user_profiles
    SET is_verified = (p_status = 'verified')
    WHERE id = v_user_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_set_account_status(
  p_user_id UUID,
  p_status account_status,
  p_shadow_ban_until TIMESTAMPTZ DEFAULT NULL,
  p_moderation_notes TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  IF NOT fn_is_admin() THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  UPDATE user_profiles
  SET account_status = p_status,
      shadow_ban_until = p_shadow_ban_until,
      moderation_notes = NULLIF(TRIM(p_moderation_notes), ''),
      is_active = (p_status <> 'banned')
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_run_maintenance()
RETURNS VOID AS $$
BEGIN
  UPDATE premium_subscriptions
  SET is_active = FALSE,
      status = 'expired',
      last_synced_at = NOW()
  WHERE is_active = TRUE
    AND status IN ('active', 'grace_period', 'billing_issue')
    AND expires_at <= NOW();

  UPDATE user_profiles up
  SET is_premium = FALSE
  WHERE up.is_premium = TRUE
    AND NOT EXISTS (
      SELECT 1
      FROM premium_subscriptions ps
      WHERE ps.user_id = up.id
        AND ps.is_active = TRUE
        AND ps.status IN ('active', 'grace_period')
        AND ps.expires_at > NOW()
    );

  UPDATE chat_requests
  SET status = 'rejected',
      updated_at = NOW()
  WHERE status = 'pending'
    AND created_at < NOW() - INTERVAL '14 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_sync_premium_subscription(
  p_plan subscription_plan,
  p_store_product_id TEXT,
  p_expires_at TIMESTAMPTZ,
  p_store_transaction_id TEXT DEFAULT NULL,
  p_provider TEXT DEFAULT 'revenuecat',
  p_entitlement_id TEXT DEFAULT 'premium',
  p_status subscription_status DEFAULT 'active',
  p_auto_renew BOOLEAN DEFAULT TRUE,
  p_environment TEXT DEFAULT 'production'
)
RETURNS UUID AS $$
DECLARE
  v_subscription_id UUID;
  v_is_premium BOOLEAN;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  UPDATE premium_subscriptions
  SET is_active = FALSE,
      status = CASE
        WHEN status IN ('cancelled', 'expired') THEN status
        ELSE 'expired'
      END,
      last_synced_at = NOW()
  WHERE user_id = auth.uid()
    AND is_active = TRUE
    AND (
      p_store_transaction_id IS NULL
      OR COALESCE(store_transaction_id, '') <> COALESCE(p_store_transaction_id, '')
    );

  SELECT id
  INTO v_subscription_id
  FROM premium_subscriptions
  WHERE user_id = auth.uid()
    AND (
      (p_store_transaction_id IS NOT NULL AND store_transaction_id = p_store_transaction_id)
      OR (
        p_store_transaction_id IS NULL
        AND store_product_id = p_store_product_id
        AND is_active = TRUE
      )
    )
  ORDER BY created_at DESC
  LIMIT 1;

  v_is_premium := p_status IN ('active', 'grace_period') AND p_expires_at > NOW();

  IF v_subscription_id IS NULL THEN
    INSERT INTO premium_subscriptions (
      user_id,
      plan,
      store_product_id,
      store_transaction_id,
      provider,
      entitlement_id,
      starts_at,
      expires_at,
      status,
      is_active,
      auto_renew,
      environment,
      last_synced_at
    ) VALUES (
      auth.uid(),
      p_plan,
      p_store_product_id,
      p_store_transaction_id,
      p_provider,
      p_entitlement_id,
      NOW(),
      p_expires_at,
      p_status,
      v_is_premium,
      p_auto_renew,
      p_environment,
      NOW()
    )
    RETURNING id INTO v_subscription_id;
  ELSE
    UPDATE premium_subscriptions
    SET plan = p_plan,
        store_product_id = p_store_product_id,
        store_transaction_id = COALESCE(p_store_transaction_id, store_transaction_id),
        provider = p_provider,
        entitlement_id = p_entitlement_id,
        expires_at = p_expires_at,
        status = p_status,
        is_active = v_is_premium,
        auto_renew = p_auto_renew,
        environment = p_environment,
        last_synced_at = NOW()
    WHERE id = v_subscription_id;
  END IF;

  UPDATE user_profiles
  SET is_premium = v_is_premium
  WHERE id = auth.uid();

  RETURN v_subscription_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_set_premium_inactive(
  p_status subscription_status DEFAULT 'expired'
)
RETURNS VOID AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  UPDATE premium_subscriptions
  SET is_active = FALSE,
      status = p_status,
      last_synced_at = NOW()
  WHERE user_id = auth.uid()
    AND is_active = TRUE;

  UPDATE user_profiles
  SET is_premium = FALSE
  WHERE id = auth.uid();
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
      (1.0 - LEAST(ST_Distance(up.location::geography, ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326)::geography) / 1000 / p_radius_km, 1.0)) * 0.30
      + (SELECT COUNT(*)::DOUBLE PRECISION / GREATEST((SELECT COUNT(*) FROM user_interests WHERE user_id = p_user_id), 1)
         FROM user_interests ui2 WHERE ui2.user_id = up.id
         AND ui2.interest_id IN (SELECT interest_id FROM user_interests WHERE user_id = p_user_id)
        ) * 0.28
      + CASE
          WHEN up.last_active_at > NOW() - INTERVAL '1 hour' THEN 1.0
          WHEN up.last_active_at > NOW() - INTERVAL '24 hours' THEN 0.7
          WHEN up.last_active_at > NOW() - INTERVAL '72 hours' THEN 0.4
          ELSE 0.1
        END * 0.14
      + CASE WHEN COALESCE((SELECT boost_until FROM activity_scores WHERE activity_scores.user_id = up.id), NOW() - INTERVAL '1 day') > NOW() THEN 1.0 ELSE 0.0 END * 0.08
      + CASE WHEN up.is_verified THEN 1.0 ELSE 0.0 END * 0.08
      + CASE WHEN up.is_premium THEN 1.0 ELSE 0.0 END * 0.05
      + CASE WHEN up.bio IS NOT NULL AND char_length(TRIM(up.bio)) >= 20 THEN 1.0 ELSE 0.0 END * 0.03
      + CASE WHEN up.city IS NOT NULL AND char_length(TRIM(up.city)) > 0 THEN 1.0 ELSE 0.0 END * 0.02
      + CASE WHEN (SELECT COUNT(*) FROM user_photos WHERE user_id = up.id) >= 2 THEN 1.0 ELSE 0.0 END * 0.02
    ) AS score,
    up.is_verified,
    up.spotify_track_name,
    up.spotify_artist_name,
    up.spotify_preview_url,
    up.city
  FROM user_profiles up
  WHERE up.id != p_user_id
    AND up.is_active = TRUE
    AND up.account_status = 'active'
    AND (up.shadow_ban_until IS NULL OR up.shadow_ban_until <= NOW())
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
ALTER TABLE chat_requests ENABLE ROW LEVEL SECURITY;
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

-- Chat Requests
CREATE POLICY chat_requests_select_participant ON chat_requests
  FOR SELECT TO authenticated
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY chat_requests_insert_sender ON chat_requests
  FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = sender_id
    AND auth.uid() <> receiver_id
  );

CREATE POLICY chat_requests_update_receiver ON chat_requests
  FOR UPDATE TO authenticated
  USING (auth.uid() = receiver_id)
  WITH CHECK (auth.uid() = receiver_id);

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

CREATE POLICY reports_select_admin ON reports
  FOR SELECT TO authenticated USING (fn_is_admin());

-- User Verifications
CREATE POLICY verifications_insert_own ON user_verifications
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY verifications_select_own ON user_verifications
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

CREATE POLICY verifications_select_admin ON user_verifications
  FOR SELECT TO authenticated USING (fn_is_admin());

-- Premium Subscriptions
CREATE POLICY subscriptions_select_own ON premium_subscriptions
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

CREATE POLICY subscriptions_select_admin ON premium_subscriptions
  FOR SELECT TO authenticated USING (fn_is_admin());

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
