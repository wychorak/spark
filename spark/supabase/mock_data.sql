-- SPARK demo mock data
-- Requires at least 3 users in auth.users.

DO $$
DECLARE
  v_user_1 UUID;
  v_user_2 UUID;
  v_user_3 UUID;
  v_match_id UUID;
  v_conversation_id UUID;
BEGIN
  SELECT id INTO v_user_1 FROM auth.users ORDER BY created_at ASC LIMIT 1;
  SELECT id INTO v_user_2 FROM auth.users ORDER BY created_at ASC OFFSET 1 LIMIT 1;
  SELECT id INTO v_user_3 FROM auth.users ORDER BY created_at ASC OFFSET 2 LIMIT 1;

  IF v_user_1 IS NULL OR v_user_2 IS NULL OR v_user_3 IS NULL THEN
    RAISE NOTICE 'mock_data.sql skipped: need at least 3 users in auth.users';
    RETURN;
  END IF;

  INSERT INTO user_profiles (
    id,
    display_name,
    bio,
    born_at,
    gender,
    modes,
    location,
    latitude,
    longitude,
    city,
    desired_interests,
    profile_gradient_start,
    profile_gradient_end,
    spotify_track_name,
    spotify_artist_name,
    is_admin,
    is_verified,
    is_premium,
    account_status,
    last_active_at
  ) VALUES
    (
      v_user_1,
      'Maja',
      'Kawa, city breaki i dlugie spacery po miescie.',
      DATE '1998-04-14',
      'female',
      ARRAY['relationship', 'friends']::relationship_mode[],
      ST_SetSRID(ST_MakePoint(21.0122, 52.2297), 4326)::geography,
      52.2297,
      21.0122,
      'Warszawa',
      ARRAY['Podróże', 'Muzyka', 'Kawa'],
      '#FF1493',
      '#FF8C00',
      'Midnight City',
      'M83',
      TRUE,
      TRUE,
      FALSE,
      'active',
      NOW() - INTERVAL '12 minutes'
    ),
    (
      v_user_2,
      'Kuba',
      'Lubię koncerty, rower i spontaniczne wypady za miasto.',
      DATE '1996-09-03',
      'male',
      ARRAY['relationship', 'fwb']::relationship_mode[],
      ST_SetSRID(ST_MakePoint(19.9445, 50.0647), 4326)::geography,
      50.0647,
      19.9445,
      'Kraków',
      ARRAY['Muzyka', 'Fitness', 'Podróże'],
      '#00C2FF',
      '#FF1493',
      'Electric Feel',
      'MGMT',
      FALSE,
      TRUE,
      TRUE,
      'active',
      NOW() - INTERVAL '3 minutes'
    ),
    (
      v_user_3,
      'Ola',
      'Szukam kogos na planszowki, kino i dobre jedzenie.',
      DATE '1999-12-21',
      'female',
      ARRAY['friends']::relationship_mode[],
      ST_SetSRID(ST_MakePoint(17.0385, 51.1079), 4326)::geography,
      51.1079,
      17.0385,
      'Wrocław',
      ARRAY['Film', 'Gotowanie', 'Gaming'],
      '#7B61FF',
      '#FF1493',
      'Good Days',
      'SZA',
      FALSE,
      FALSE,
      FALSE,
      'under_review',
      NOW() - INTERVAL '1 hour'
    )
  ON CONFLICT (id) DO UPDATE
  SET display_name = EXCLUDED.display_name,
      bio = EXCLUDED.bio,
      born_at = EXCLUDED.born_at,
      gender = EXCLUDED.gender,
      modes = EXCLUDED.modes,
      location = EXCLUDED.location,
      latitude = EXCLUDED.latitude,
      longitude = EXCLUDED.longitude,
      city = EXCLUDED.city,
      desired_interests = EXCLUDED.desired_interests,
      profile_gradient_start = EXCLUDED.profile_gradient_start,
      profile_gradient_end = EXCLUDED.profile_gradient_end,
      spotify_track_name = EXCLUDED.spotify_track_name,
      spotify_artist_name = EXCLUDED.spotify_artist_name,
      is_admin = EXCLUDED.is_admin,
      is_verified = EXCLUDED.is_verified,
      is_premium = EXCLUDED.is_premium,
      account_status = EXCLUDED.account_status,
      last_active_at = EXCLUDED.last_active_at;

  INSERT INTO user_preferences (
    user_id,
    min_age,
    max_age,
    max_distance_km,
    preferred_genders,
    preferred_modes
  ) VALUES
    (
      v_user_1,
      23,
      36,
      80,
      ARRAY['male', 'female']::gender_type[],
      ARRAY['relationship', 'friends']::relationship_mode[]
    ),
    (
      v_user_2,
      21,
      34,
      120,
      ARRAY['female']::gender_type[],
      ARRAY['relationship', 'fwb']::relationship_mode[]
    ),
    (
      v_user_3,
      22,
      35,
      60,
      ARRAY['female', 'male']::gender_type[],
      ARRAY['friends']::relationship_mode[]
    )
  ON CONFLICT (user_id) DO UPDATE
  SET min_age = EXCLUDED.min_age,
      max_age = EXCLUDED.max_age,
      max_distance_km = EXCLUDED.max_distance_km,
      preferred_genders = EXCLUDED.preferred_genders,
      preferred_modes = EXCLUDED.preferred_modes;

  DELETE FROM user_interests
  WHERE user_id IN (v_user_1, v_user_2, v_user_3);

  INSERT INTO user_interests (user_id, interest_id)
  VALUES
    (v_user_1, 1),
    (v_user_1, 2),
    (v_user_1, 16)
  ON CONFLICT DO NOTHING;

  INSERT INTO user_interests (user_id, interest_id)
  VALUES
    (v_user_2, 2),
    (v_user_2, 4),
    (v_user_2, 13)
  ON CONFLICT DO NOTHING;

  INSERT INTO user_interests (user_id, interest_id)
  VALUES
    (v_user_3, 7),
    (v_user_3, 3),
    (v_user_3, 6)
  ON CONFLICT DO NOTHING;

  INSERT INTO activity_scores (user_id, score, boost_until, updated_at)
  VALUES
    (v_user_1, 0.82, NULL, NOW()),
    (v_user_2, 0.94, NOW() + INTERVAL '2 days', NOW()),
    (v_user_3, 0.68, NULL, NOW())
  ON CONFLICT (user_id) DO UPDATE
  SET score = EXCLUDED.score,
      boost_until = EXCLUDED.boost_until,
      updated_at = EXCLUDED.updated_at;

  INSERT INTO user_photos (user_id, storage_path, position, is_primary)
  VALUES
    (v_user_1, 'profile-photos/demo-maja-1.jpg', 0, TRUE),
    (v_user_1, 'profile-photos/demo-maja-2.jpg', 1, FALSE),
    (v_user_2, 'profile-photos/demo-kuba-1.jpg', 0, TRUE),
    (v_user_2, 'profile-photos/demo-kuba-2.jpg', 1, FALSE),
    (v_user_3, 'profile-photos/demo-ola-1.jpg', 0, TRUE)
  ON CONFLICT (user_id, position) DO UPDATE
  SET storage_path = EXCLUDED.storage_path,
      is_primary = EXCLUDED.is_primary;

  IF NOT EXISTS (
    SELECT 1 FROM user_verifications
    WHERE user_id = v_user_1 AND status = 'verified'
  ) THEN
    INSERT INTO user_verifications (
      user_id,
      selfie_path,
      status,
      reviewed_at,
      review_notes
    ) VALUES (
      v_user_1,
      'verifications/demo-maja-selfie.jpg',
      'verified',
      NOW() - INTERVAL '5 days',
      'Demo account approved'
    );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM user_verifications
    WHERE user_id = v_user_3 AND status IN ('pending', 'in_review')
  ) THEN
    INSERT INTO user_verifications (
      user_id,
      selfie_path,
      status,
      review_notes
    ) VALUES (
      v_user_3,
      'verifications/demo-ola-selfie.jpg',
      'pending',
      'Awaiting moderation review'
    );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM premium_subscriptions
    WHERE user_id = v_user_2 AND is_active = TRUE
  ) THEN
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
      v_user_2,
      'monthly',
      'spark_premium_monthly',
      'demo-monthly-kuba',
      'revenuecat',
      'premium',
      NOW() - INTERVAL '5 days',
      NOW() + INTERVAL '25 days',
      'active',
      TRUE,
      TRUE,
      'sandbox',
      NOW()
    );
  END IF;

  INSERT INTO reports (
    reporter_id,
    reported_id,
    reason,
    description,
    status,
    created_at
  )
  SELECT
    v_user_1,
    v_user_3,
    'spam',
    'Demo report for moderation queue',
    'pending',
    NOW() - INTERVAL '6 hours'
  WHERE NOT EXISTS (
    SELECT 1 FROM reports
    WHERE reporter_id = v_user_1
      AND reported_id = v_user_3
      AND reason = 'spam'
  );

  INSERT INTO matches (user1_id, user2_id, matched_at, is_active)
  VALUES (
    LEAST(v_user_1, v_user_2),
    GREATEST(v_user_1, v_user_2),
    NOW() - INTERVAL '2 days',
    TRUE
  )
  ON CONFLICT (user1_id, user2_id) DO NOTHING;

  SELECT id
  INTO v_match_id
  FROM matches
  WHERE user1_id = LEAST(v_user_1, v_user_2)
    AND user2_id = GREATEST(v_user_1, v_user_2)
  LIMIT 1;

  IF v_match_id IS NOT NULL THEN
    INSERT INTO conversations (match_id, last_message_at)
    VALUES (v_match_id, NOW() - INTERVAL '30 minutes')
    ON CONFLICT (match_id) DO NOTHING;

    SELECT id
    INTO v_conversation_id
    FROM conversations
    WHERE match_id = v_match_id
    LIMIT 1;

    IF v_conversation_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM messages WHERE conversation_id = v_conversation_id
      ) THEN
      INSERT INTO messages (conversation_id, sender_id, content, message_type, is_read, created_at)
      VALUES
        (v_conversation_id, v_user_1, 'Hej, kawa w tym tygodniu?', 'text', TRUE, NOW() - INTERVAL '45 minutes'),
        (v_conversation_id, v_user_2, 'Jasne, brzmi super.', 'text', FALSE, NOW() - INTERVAL '30 minutes');
    END IF;
  END IF;

  INSERT INTO chat_requests (
    sender_id,
    receiver_id,
    message,
    status,
    created_at,
    updated_at
  )
  SELECT
    v_user_3,
    v_user_1,
    'Hej, chetnie poznam kogos na planszowki i kino.',
    'pending',
    NOW() - INTERVAL '3 hours',
    NOW() - INTERVAL '3 hours'
  WHERE NOT EXISTS (
    SELECT 1 FROM chat_requests
    WHERE sender_id = v_user_3
      AND receiver_id = v_user_1
      AND status = 'pending'
  );
END;
$$;
