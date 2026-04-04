# Report — Applicant Showcase App (Journalist Articles)

## 1) Introduction

When I first opened this project, my initial reaction was a mix of excitement and pressure. The scope was very clear (build a journalist article system on top of an existing news app), but the expectations were high: clean architecture, Firebase integration, BLoC state management, and production-like rules enforcement.

My goal for this challenge was not only to “make it work”, but to make it **maintainable**, **secure** (rules), and **pleasant to use** (reactive UI + good UX).

---

## 2) Learning Journey

Before starting, I had experience with Flutter, but I had to quickly ramp up in a few areas to meet the project’s standards:

### Firebase (Firestore + Storage + Auth)
I focused on understanding:
- Firestore modeling (collections/subcollections, counters, querying with indexes)
- Security rules (schema enforcement and authorization)
- Firebase Storage rules and path-based access control
- Auth state and how to build a clean auth flow

**Resources used**
- Firebase docs (Firestore, Auth, Storage)
- Rules examples and best practices
- Emulator workflow (to iterate quickly on rules without deploying)

### Flutter BLoC / Cubits
I leaned on Cubit-based state management to keep the UI responsive and deterministic. I used clear states for loading, loaded, and error, and ensured subscriptions were cleaned up correctly.

### Clean Architecture alignment
The project already had a clean architecture structure. I kept the feature modular and tried to respect the boundaries:
- Domain entities/usecases
- Data sources/services and repositories
- Presentation with Cubits + pages/widgets

---

## 3) Challenges Faced

### Challenge A — Likes were “shared” between different accounts on the same device
**Problem:** When I liked an article with Account A and then logged into Account B, the article still appeared liked.  
**Root cause:** Reactions were stored using a device identifier as the reaction document id (`reactions/{deviceId}`), so different users on the same device shared the same reaction doc.

**Solution:** I migrated likes to be **per-user**, using:
- `articles/{articleId}/reactions/{uid}`

This ensures each authenticated user can like an article once, independent of device.

**Lesson learned:** In social interactions, identity must be tied to the user, not the device. Device identifiers are useful for analytics, but not for ownership.

---

### Challenge B — Permission denied errors after tightening security rules
**Problem:** After enforcing Firestore rules, writing comments failed with `permission-denied`.  
**Root cause:** The app started writing new fields (`uid`) that were not allowed by rules, and the article `commentCount` update was not allowed as a “counter-only” update.

**Solution:** I updated Firestore rules to:
- Allow `uid` in comments and validate `uid == request.auth.uid`
- Allow counter-only updates for `commentCount` and `likeCount` (auth-only)
- Restrict delete of reactions/comments to the owner only

**Lesson learned:** Rules enforcement must evolve together with the data model. When data changes, rules must change too.

---

### Challenge C — UI/UX issue: comment input was too close to gesture navigation / keyboard
**Problem:** The comment input field could be partially obstructed by gesture navigation and keyboard behavior.  
**Solution:** I improved the sheet layout using:
- `AnimatedPadding` + `viewInsets.bottom` + `viewPadding.bottom`
- `SafeArea(top: false)` for the composer row

**Lesson learned:** Small UX details matter, especially in mobile apps where keyboard + gesture areas differ across devices.

---

## 4) Reflection and Future Directions

### What I learned
- How to design a simple but scalable Firestore schema with subcollections and counters.
- How to enforce a schema and authorization model using Firestore rules.
- How to build reactive UI flows with streams and Cubits while avoiding leaks (cleaning subscriptions).
- How to reason about user identity and ownership for reactions/comments.

### What I would improve next
If I had more time, I would add:
- **Automated tests**:
  - model serialization tests (`toFirestore/fromFirestore`)
  - Cubit tests with repository mocks
- **Pagination** for the feed (Firestore query paging)
- **Comment deletion UX** with consistent decrement of `commentCount` (and/or disable comment deletion entirely)
- Better error messages mapping (`permission-denied`, offline, timeouts)
- A stronger Storage rules policy (auth-only uploads + path restrictions per user/article)

---

## 5) Proof of the Project (Screenshots / Videos)

> Replace the placeholders below with real screenshots and/or short recordings (GIF/MP4).  
> The goal is to make it easy for reviewers to verify core flows quickly.

### Auth flow
- Sign up / sign in screens:
  - Screenshot: `./assets/report/auth_signup.png`
  - Screenshot: `./assets/report/auth_signin.png`

### Article creation & publishing
- Create draft + upload thumbnail:
  - Screenshot: `./assets/report/article_create.png`
- Draft list and publish action:
  - Screenshot: `./assets/report/my_articles_drafts.png`
- Published list in profile:
  - Screenshot: `./assets/report/my_articles_published.png`

### Global feed + interactions
- Global feed:
  - Screenshot: `./assets/report/feed.png`
- Like animation / like count:
  - Screenshot: `./assets/report/feed_like.png`
- Comments bottom sheet:
  - Screenshot: `./assets/report/comments_sheet.png`

### Short demo video (recommended)
- Video: `./assets/report/demo.mp4`
  - Includes: sign in → create draft → publish → view in feed → like/comment → log into another account → like state is independent.

---

## 6) Overdelivery

This section documents extra improvements beyond the strict minimum.

### 6.1 New Features Implemented

#### Feature 1 — Likes per user (not per device)
**Purpose:** Ensure social interactions are tied to the authenticated user.  
**Implementation:**
- Reactions stored at `articles/{articleId}/reactions/{uid}`
- Firestore rules enforce `uid == request.auth.uid`
- Owner-only delete for reactions

**How to test:**
1. Login as user A, like an article.
2. Logout, login as user B.
3. The same article should not appear liked for user B.

#### Feature 2 — Reactive lists that update automatically
**Purpose:** Improve UX: lists update without manual refresh.  
**Implementation:**
- Stream-based watchers for published articles and profile-scoped lists
- Cubits manage subscriptions and loading/error states

**How to test:**
1. Publish an article.
2. Observe feed / profile updates without restarting the app.

#### Feature 3 — Improved comment composer UX
**Purpose:** Ensure the comment input is always accessible above gestures and keyboard.  
**Implementation:**
- `AnimatedPadding` with `viewInsets.bottom + viewPadding.bottom`
- `SafeArea(top: false)` for composer row

---

### 6.2 Prototypes Created

#### Prototype — Firestore schema documentation
- File: `backend/docs/DB_SCHEMA.md`
- Purpose: Make the backend model explicit (fields, types, required/optional, subcollections)

---

### 6.3 How can I improve this further?
Ideas:
- Add an admin moderation flow for reported comments/articles.
- Add richer profile pages (followers, journalist bio, verification badges).
- Add offline-first caching (where appropriate).
- Add analytics events for publishing, reading completion, and interactions.

---

## 7) Extra (Optional)
### Notes on rules enforcement
- Firestore rules enforce:
  - Author-only update/delete for article content
  - Counter-only updates for likes/comments (auth-only)
  - Reaction/comment ownership
  - Users can only read/write their own profile doc

### Local development
- Firebase emulators configured for Firestore/Auth/Storage
- Android emulator uses `10.0.2.2` for host access

---