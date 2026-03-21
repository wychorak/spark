# SPARK v1.0 – ONE-SHOT TECHNICAL BLUEPRINT (Flutter + Supabase + App Store Ready)

---

## 1. PROJECT SUMMARY

Spark to nowoczesna aplikacja randkowa z estetyką Y2K neon, łącząca trzy tryby relacji – **Związek** (pink), **Znajomi** (green) i **FWB** (orange) – w jednym interfejsie z kartami do przesuwania. Wyróżniki Spark to: podgląd 30-sekundowy piosenek Spotify na profilach, system weryfikacji zdjęć zapobiegający catfishingowi, algorytm dopasowywania oparty na PostGIS (1-150 km) + 30 predefiniowanych zainteresowań + boost aktywności, oraz realtime chat z Supabase Realtime. Monetyzacja: Spark Premium (unlimited swipes, superlike 10/miesiąc, "kto cię polubił", rewind, filtry zaawansowane) przez subskrypcję In-App Purchase. Cały stack to Flutter 3.24+ single codebase (iOS+Android) z Supabase jako backend (PostgreSQL + Auth + PostGIS + Realtime + Edge Functions + Storage + RLS).

**Kluczowe wyróżniki:**
- 3 tryby relacji z kolorowym systemem wizualnym
- Spotify preview na karcie profilu (30s snippet)
- Weryfikacja zdjęć (selfie + AI porównanie)
- PostGIS-based discovery z algorytmem distance + interests + activity
- Y2K neon aesthetic (chrome, holographic, particle effects, gradients)
- Polski język interfejsu, polski support

---

## 2. FULL SUPABASE SCHEMA

> Patrz: `supabase/schema.sql` – kompletny SQL z tabelami, indexami, RLS, triggerami i funkcjami.

### Tabele (podsumowanie):

| Tabela | Opis |
|--------|------|
| `user_profiles` | Profil użytkownika – bio, zdjęcia, lokalizacja (PostGIS), tryb, preferencje |
| `user_photos` | Zdjęcia profilowe (max 6), kolejność, weryfikacja |
| `user_interests` | Zainteresowania użytkownika (M2M z `interests`) |
| `interests` | 30 predefiniowanych zainteresowań |
| `swipe_actions` | Swipe left/right/superlike z timestampem |
| `matches` | Matched pary (tworzone triggerem po mutual swipe) |
| `messages` | Wiadomości czatu (realtime) |
| `conversations` | Konwersacje między matchami |
| `reports` | Zgłoszenia użytkowników |
| `blocks` | Blokady użytkowników |
| `user_verifications` | Status weryfikacji zdjęć |
| `premium_subscriptions` | Subskrypcje premium |
| `daily_limits` | Dzienne limity (swipes, superlikes) |
| `user_spotify` | Powiązanie Spotify (track URI, preview URL) |
| `push_tokens` | Tokeny FCM/APNs |
| `user_preferences` | Preferencje wyszukiwania (wiek, dystans, tryb) |
| `activity_scores` | Score aktywności do algorytmu boost |

---

## 3. CLAUDE.md

> Patrz: `CLAUDE.md` w root projektu – zawiera pełne reguły architektury, konwencje, security rules, folder structure, coding standards.

---

## 4. IMPLEMENTATION SEQUENCE

### Phase 0: Project Setup (Dni 1-2)
- [x] Inicjalizacja Flutter project (`flutter create spark --org com.spark`)
- [x] Konfiguracja Supabase project (region: eu-central)
- [x] Setup repo, CLAUDE.md, CI/CD (GitHub Actions)
- [x] Packages: `supabase_flutter`, `riverpod`, `go_router`, `freezed`, `envied`
- [x] Theme setup (Y2K neon, fonty, kolory, gradients)
- [x] Konfiguracja `flutter_lints`, analysis_options.yaml

### Phase 1: Auth & Age Gate (Dni 3-5)
- Supabase Auth setup (email + Apple Sign In + Google Sign In)
- Age gate screen (DatePicker, musi być 18+, walidacja server-side via RLS)
- Biometric login setup (local_auth + flutter_secure_storage)
- Auth flow: Splash → Age Gate → Login/Register → Onboarding OR Home
- Packages: `supabase_flutter`, `local_auth`, `flutter_secure_storage`, `sign_in_with_apple`, `google_sign_in`

### Phase 2: Onboarding (Dni 6-9)
- Multi-step onboarding: Imię → Data urodzenia → Płeć → Zdjęcia (min 2) → Bio → Zainteresowania → Tryb → Lokalizacja
- Photo upload to Supabase Storage (max 6, image_picker + image_cropper)
- Interest selection (30 predefiniowanych, grid chips)
- Mode selection (Związek/Znajomi/FWB z color coding)
- Location permission + initial PostGIS point
- Packages: `image_picker`, `image_cropper`, `geolocator`, `permission_handler`

### Phase 3: Discovery & Swipe Engine (Dni 10-16)
- Swipe card stack (flutter_card_swipe lub custom z AnimationController)
- PostGIS query: users within radius + age range + gender pref + mode match
- Algorithm: distance score + shared interests score + activity boost
- Swipe actions: left (pass), right (like), up (superlike)
- Lottie animations: heart burst (like), star explosion (superlike), neon glow pulse
- Daily limits enforcement (50 swipes free, unlimited premium)
- Packages: `flutter_card_swipe`, `lottie`, `shimmer`

### Phase 4: Matching System (Dni 17-19)
- Supabase trigger: on mutual swipe → create match + conversation
- Match notification (push + in-app Lottie celebration animation)
- "It's a Match!" fullscreen overlay z Y2K neon explosion
- Match list screen z avatarami i ostatnią wiadomością
- Instant match: premium feature, skip waiting
- Edge Function: `fn_check_match` (runs after swipe insert)

### Phase 5: Realtime Chat (Dni 20-26)
- Supabase Realtime subscription na `messages` table
- Chat UI: bubbles z gradient (sender pink, receiver dark grey)
- Media messages: photo sharing (Supabase Storage)
- Typing indicator (Realtime presence)
- Read receipts (premium only)
- Block/Report z chatu
- Message input: text + camera + gallery
- Packages: `supabase_flutter` (realtime), `cached_network_image`, `image_picker`

### Phase 6: Profile & Spotify (Dni 27-31)
- Profile view/edit screen
- Photo reordering (drag & drop)
- Spotify integration: OAuth → select favorite track → 30s preview on card
- Profile card preview ("jak widzą Cię inni")
- Packages: `spotify_sdk`, `just_audio`, `reorderable_grid_view`

### Phase 7: Premium & Payments (Dni 32-36)
- Paywall screen z animated crown (Rive) + feature comparison
- In-App Purchase setup (StoreKit 2 / Google Play Billing)
- Subscription plans: Monthly / Yearly
- Premium features unlock logic (Riverpod providers)
- Receipt validation via Supabase Edge Function
- Packages: `in_app_purchase`, `rive`

### Phase 8: Safety & Verification (Dni 37-40)
- Photo verification flow: take selfie + match pose → Edge Function AI comparison
- Report user flow (categories: fake profile, inappropriate, harassment, underage)
- Block user (hides from discovery + blocks chat)
- Content moderation Edge Function (nudity detection on uploaded photos)
- Safety center screen (tips, guidelines, emergency contacts)

### Phase 9: Notifications & Settings (Dni 41-44)
- FCM setup (Android) + APNs (iOS)
- Push categories: new match, new message, superlike received, profile boost
- Notification preferences screen
- Settings: account, privacy, notifications, blocked users, delete account
- Packages: `firebase_messaging`, `flutter_local_notifications`

### Phase 10: Polish & Launch (Dni 45-56)
- UI polish: micro-animations, transitions, shimmer loading
- Performance profiling (DevTools, reduce rebuilds)
- App Store assets: screenshots (6.7" + 5.5"), App Preview video
- Privacy Policy + Terms of Service (Polish)
- TestFlight beta → feedback → fixes
- App Store submission
- Google Play submission

---

## 5. KEY SCREENS & FEATURES (16 Screens)

### 5.1 Splash Screen
- Logo Spark z neon glow animation (Lottie)
- Czarne tło, #FF1493 gradient pulse
- Auto-login check (biometric if enabled)

### 5.2 Age Gate Screen
- "Czy masz ukończone 18 lat?" z DatePicker
- Odmowa = blokada + komunikat
- Server-side validation via Supabase RLS (born_at <= now() - 18 years)

### 5.3 Login Screen
- Email/hasło + Apple Sign In + Google Sign In
- Neon input fields z glow on focus
- "Zapomniałeś hasła?" link
- Biometric toggle po pierwszym loginie

### 5.4 Register Screen
- Email + hasło (min 8 znaków, 1 cyfra, 1 wielka litera)
- Checkbox: regulamin + polityka prywatności
- Age verification (data urodzenia)

### 5.5 Onboarding Flow (multi-step)
- Step 1: Imię + data urodzenia
- Step 2: Płeć (Kobieta/Mężczyzna/Niebinarnie) + preferencje
- Step 3: Zdjęcia (min 2, max 6) z drag-to-reorder
- Step 4: Bio (max 500 znaków)
- Step 5: Zainteresowania (wybierz min 3 z 30)
- Step 6: Tryb (Związek 💕 / Znajomi 💚 / FWB 🧡) – multi-select
- Step 7: Lokalizacja (permission request + PostGIS save)
- Progress bar na górze z neon gradient

### 5.6 Discovery Screen (Swipe Cards) ⭐
- Karty profilowe z zdjęciem, imieniem, wiekiem, dystansem
- Border color = tryb (pink/green/orange)
- Spotify mini-player na karcie (30s preview, tap to play/pause)
- Zainteresowania jako chips na dole karty
- Swipe left = pass, right = like, up = superlike
- Bottom bar: undo (premium), X, heart, star, boost (premium)
- Lottie: heart burst on like, star explosion on superlike
- Filter icon → Discovery Filters sheet

### 5.7 Discovery Filters (Bottom Sheet)
- Dystans: slider 1-150 km
- Wiek: range slider 18-65
- Tryb: checkboxes (Związek/Znajomi/FWB)
- Premium filters: wzrost, edukacja, znak zodiaku
- "Zastosuj" button z neon glow

### 5.8 Match Screen (It's a Match!)
- Fullscreen overlay z neon explosion animation (Rive)
- Oba zdjęcia profilowe z holographic border
- "Wyślij wiadomość" + "Kontynuuj przeglądanie" buttons
- Confetti particle effect

### 5.9 Matches List Screen
- Horizontal scroll: nowe matche (bez wiadomości jeszcze)
- Vertical list: aktywne konwersacje (sorted by last message)
- Avatar z colored ring (tryb)
- Unread badge
- Premium: "Kto Cię polubił" section na górze z blurred photos

### 5.10 Chat Screen ⭐
- Realtime messages (Supabase Realtime)
- Bubbles: sender = gradient pink, receiver = dark grey
- Typing indicator (3 pulsing dots)
- Send: text, photo, emoji
- Long press: copy, delete (own messages)
- Header: avatar, name, video call icon (future), menu (report/block)
- Read receipts (premium): double checkmark blue
- Input bar: text field + camera + gallery + send button

### 5.11 Profile View Screen
- Own profile card preview (jak widzą Cię inni)
- Edit button → Profile Edit
- Stats: polubienia, matche, superliki (premium)
- Spotify track display z play button
- Verification badge if verified

### 5.12 Profile Edit Screen
- Photo grid z add/remove/reorder
- Bio edycja
- Zainteresowania edycja
- Spotify track change
- Tryb zmiany
- Lokalizacja update

### 5.13 Other User Profile (Expanded Card)
- Full profile view po tap na kartę w discovery
- Wszystkie zdjęcia (swipeable gallery)
- Bio, zainteresowania, Spotify, dystans
- Report/Block options w menu

### 5.14 Premium Paywall Screen ⭐
- Animated crown (Rive) z golden neon glow
- Feature comparison: Free vs Premium
- Price cards: Miesięcznie / Rocznie (z "oszczędzasz X%")
- "Rozpocznij darmowy okres próbny" CTA
- Y2K holographic background za price cards
- Restore purchases link

### 5.15 Settings Screen
- Account: email, hasło, biometrics toggle
- Notifications: matches, messages, superlikes, marketing
- Privacy: widoczność profilu, dystans visibility
- Blocked users list
- Pomoc: FAQ, kontakt (sparksupportpolska@gmail.com)
- Prawne: regulamin, polityka prywatności
- Wyloguj / Usuń konto (z potwierdzeniem)

### 5.16 Photo Verification Screen
- Instrukcja: "Zrób selfie w podanej pozie"
- Kamera z overlay z wzorem pozy
- Przesłanie → Edge Function analiza → wynik (verified ✓ / retry)
- Verification badge na profilu

---

## 6. ALGORITHM DETAILS

### 6.1 PostGIS Distance Query
```sql
-- Find users within radius, matching preferences
SELECT up.*,
  ST_Distance(
    up.location::geography,
    ST_SetSRID(ST_MakePoint($lon, $lat), 4326)::geography
  ) / 1000 AS distance_km
FROM user_profiles up
WHERE up.id != $current_user_id
  AND up.is_active = true
  AND up.is_verified = true
  AND ST_DWithin(
    up.location::geography,
    ST_SetSRID(ST_MakePoint($lon, $lat), 4326)::geography,
    $radius_meters
  )
  AND up.age BETWEEN $min_age AND $max_age
  AND up.gender = ANY($preferred_genders)
  AND up.mode && $preferred_modes  -- array overlap
  AND up.id NOT IN (SELECT target_id FROM swipe_actions WHERE user_id = $current_user_id)
  AND up.id NOT IN (SELECT blocked_id FROM blocks WHERE blocker_id = $current_user_id)
  AND up.id NOT IN (SELECT blocker_id FROM blocks WHERE blocked_id = $current_user_id)
ORDER BY score DESC
LIMIT 50;
```

### 6.2 Scoring Algorithm
```
score = (distance_score * 0.4) + (interest_score * 0.35) + (activity_score * 0.15) + (premium_boost * 0.10)

distance_score = 1 - (distance_km / max_radius)           -- 0.0 to 1.0
interest_score = shared_interests / max(total_interests, 1) -- 0.0 to 1.0
activity_score = CASE
  WHEN last_active < 1h  THEN 1.0
  WHEN last_active < 24h THEN 0.7
  WHEN last_active < 72h THEN 0.4
  ELSE 0.1
END
premium_boost = CASE WHEN has_active_boost THEN 1.0 ELSE 0.0 END
```

### 6.3 Match Logic (Trigger)
```sql
-- After INSERT on swipe_actions where action = 'like' or 'superlike'
-- Check if reverse swipe exists → create match + conversation
CREATE OR REPLACE FUNCTION fn_check_match()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.action IN ('like', 'superlike') THEN
    IF EXISTS (
      SELECT 1 FROM swipe_actions
      WHERE user_id = NEW.target_id
        AND target_id = NEW.user_id
        AND action IN ('like', 'superlike')
    ) THEN
      INSERT INTO matches (user1_id, user2_id, matched_at)
      VALUES (LEAST(NEW.user_id, NEW.target_id), GREATEST(NEW.user_id, NEW.target_id), NOW())
      ON CONFLICT DO NOTHING;

      INSERT INTO conversations (match_id)
      SELECT id FROM matches
      WHERE user1_id = LEAST(NEW.user_id, NEW.target_id)
        AND user2_id = GREATEST(NEW.user_id, NEW.target_id);
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 6.4 30 Predefiniowanych Zainteresowań
1. Podróże ✈️  2. Muzyka 🎵  3. Gotowanie 🍳  4. Fitness 💪  5. Fotografia 📸
6. Gaming 🎮  7. Film 🎬  8. Książki 📚  9. Taniec 💃  10. Sztuka 🎨
11. Joga 🧘  12. Bieganie 🏃  13. Rower 🚴  14. Psy 🐕  15. Koty 🐈
16. Kawa ☕  17. Wino 🍷  18. Piwo 🍺  19. Siłownia 🏋️  20. Pływanie 🏊
21. Hiking ⛰️  22. Koszykówka 🏀  23. Piłka nożna ⚽  24. Technologia 💻  25. Moda 👗
26. Astrologia ♈  27. Netflix 📺  28. Stand-up 😂  29. Wolontariat ❤️  30. Języki 🌍

---

## 7. APP STORE DEPLOYMENT CHECKLIST

### Pre-Submission
- [ ] Apple Developer Account ($99/rok) – Team ID, Bundle ID: `com.spark.dating`
- [ ] Google Play Developer Account ($25 jednorazowo)
- [ ] Provisioning Profiles: Development + Distribution (App Store)
- [ ] Push Notification entitlement (APNs key)
- [ ] In-App Purchase products configured in App Store Connect
- [ ] Privacy Manifest (PrivacyInfo.xcprivacy) – required od iOS 17.5
- [ ] App Tracking Transparency (ATT) dialog
- [ ] NSLocationWhenInUseUsageDescription (lokalizacja)
- [ ] NSCameraUsageDescription (zdjęcia + weryfikacja)
- [ ] NSPhotoLibraryUsageDescription (wybór zdjęć)
- [ ] NSMicrophoneUsageDescription (future: voice messages)
- [ ] NSFaceIDUsageDescription (biometric login)

### TestFlight
- [ ] Upload build via Xcode / `flutter build ipa`
- [ ] Internal testing group (min 5 testerów)
- [ ] External testing (25+ testerów, Apple review ~24-48h)
- [ ] Crash-free rate > 99%
- [ ] Test all IAP flows (sandbox environment)

### App Store Review Guidelines (kluczowe)
- [ ] 4.3: Nie jest spam/klon – unikalna wartość (3 tryby, Spotify, Y2K aesthetic)
- [ ] 1.2: User Generated Content – moderacja + report system
- [ ] 5.1.1: Privacy – zbieramy lokalizację, zdjęcia, dane osobowe → Privacy Policy
- [ ] 3.1.1: In-App Purchase – subskrypcja musi być jasno opisana
- [ ] 1.1.4: Dating apps – wymagana weryfikacja 18+

### Screenshots (wymagane)
- 6.7" (iPhone 15 Pro Max): 1290 x 2796 px – min 3 screenshots
- 5.5" (iPhone 8 Plus): 1242 x 2208 px – min 3 screenshots
- App Preview video (opcjonalne, ale zalecane): 30s max
- iPad screenshots jeśli universal

### Google Play
- [ ] App signing key (Google manages)
- [ ] Feature graphic: 1024 x 500 px
- [ ] Screenshots: min 2 per device type
- [ ] Data Safety form
- [ ] Content rating questionnaire (IARC – dating = parental advisory)
- [ ] Target audience: 18+ only

---

## 8. MONTHLY COST ESTIMATE

| Service | Plan | Cost/month |
|---------|------|-----------|
| Supabase | Pro | $25 |
| Supabase (extra compute if needed) | - | $0-50 |
| Firebase (FCM) | Free tier (Spark plan) | $0 |
| Sentry | Developer | $0 (free tier) |
| Mixpanel | Free tier (up to 20M events) | $0 |
| Apple Developer | Annual $99 | ~$8.25 |
| Google Play Developer | One-time $25 | ~$2.08 (first year) |
| Domain + email | - | ~$5 |
| Cloudflare (CDN, optional) | Free | $0 |
| **TOTAL (start)** | | **~$40-90/month** |

### Scale estimates:
- 1K users: Supabase Pro ($25) wystarczy
- 10K users: Supabase Pro + extra compute (~$75)
- 50K+ users: Supabase Team ($599) + dedicated infra
- Stripe fees: 2.9% + $0.30 per transaction (web payments only)
- Apple/Google take: 15-30% of IAP revenue

---

## 9. ONE-SHOT CODE STARTERS

> Patrz: `lib/` folder – pełne code starters w projekcie Flutter.

### 9.1 Swipe Card z Lottie Animation
`lib/features/discovery/presentation/screens/discovery_screen.dart`

### 9.2 Realtime Chat
`lib/features/chat/presentation/screens/chat_screen.dart`

### 9.3 Premium Paywall z Animated Crown
`lib/features/premium/presentation/screens/paywall_screen.dart`

---

*Blueprint created: 2026-03-21*
*Stack: Flutter 3.24+ | Supabase | Riverpod 2.0 | go_router*
*Target: App Store + Google Play | Language: Polish*
