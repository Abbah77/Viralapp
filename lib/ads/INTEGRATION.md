# Adsterra Ad Integration — Reelz

## Step 1: Get Your Zone IDs from Adsterra

1. Log into your Adsterra publisher dashboard
2. Create **Interstitial** ad unit → copy the **Zone ID**
3. Create **Native Banner** (300×250) ad unit → copy the **Zone ID**
4. Open `lib/ads/ad_engine.dart` and replace:
   ```dart
   static const String interstitialZoneId = 'YOUR_INTERSTITIAL_ZONE_ID';
   static const String bannerZoneId       = 'YOUR_BANNER_ZONE_ID';
   ```

## Step 2: iOS Setup (SFSafariViewController)

In `ios/Runner/Info.plist`, add:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>https</string>
    <string>http</string>
    <string>itms-apps</string>
</array>
```

## Step 3: Run flutter pub get

```bash
flutter pub get
```

---

## How the Ad Timing Math Works

### Dynamic Cooldown Formula
```
cooldown(n) = 180s × (1 + 0.4 × ln(n+1))

n=0 (first ad):   180s  (3 min)
n=1 (second ad):  205s  (~3.4 min)
n=2 (third ad):   218s  (~3.6 min)
n=5 (sixth ad):   248s  (~4.1 min)
```
Gaps grow logarithmically — never linear, never random.

### Engagement Score
```
score = baseTriggerScore - fatiguePenalty + cooldownBonus

Base scores by trigger:
  Cold open:            100
  Episode transition:    85  (every 3rd episode change)
  Feed idle 45s+:        70
  Player paused 12s+:    60
  Mid-seek:               0  ← NEVER
  Buffering:              0  ← NEVER
  Landscape:              0  ← NEVER

Fatigue penalty = 25 × (1 - e^(-0.0055 × n × 1000))
Cooldown bonus  = min(20, extraSeconds / 30)

Threshold: ≥75 → interstitial, ≥55 → banner
```

### Session Hard Caps
- Max 8 ads per session (then engine goes silent)
- No two ads closer than dynamic cooldown
- Interstitial and banner never overlap

---

## Ad Placement Map

```
App cold open (2s grace)
  └─ score=100 → Interstitial ✓

Feed browsing → idle 45s
  └─ score=70 → Banner (slides up from bottom)

Player → episode 3 → episode 4 → episode 5
           [2nd change counts as 3rd] → score=85 → Interstitial

Player paused 12+ seconds
  └─ score=60 → Banner (only portrait)

Landscape mode
  └─ All ads suppressed ✗

Search tap
  └─ All ads suppressed ✗ (never interrupt intent)

Buffering
  └─ All ads suppressed ✗ (worst possible UX)
```

---

## Ad UX Spec

### Interstitial
- **Skip delay:** 5 seconds (animated countdown ring)
- **Auto-dismiss:** 20 seconds
- **Progress bar:** thin 2px brand-color bar at top
- **Portrait & landscape:** both supported, safe-area aware
- **WebView fails:** graceful fallback banner with tap-to-open

### Banner
- **Height:** 92px with glassmorphic frame
- **Position:** 80px above bottom nav (never covers controls)
- **Auto-dismiss:** 15 seconds
- **Landscape:** completely hidden (preserves immersion)
- **Close button:** always visible

### URL handling
- `https://` → Android Custom Tabs / iOS SFSafariViewController
- `play.google.com` → Native Play Store app
- `apps.apple.com` → Native App Store
- Fallback: external browser (last resort, never crashes app)
