# Firestore DB Schema — Applicant Showcase App (Articles)

This document defines the NoSQL schema for the **Articles** feature. The goal is to allow authenticated users (journalists) to create articles and upload a thumbnail image to **Firebase Cloud Storage** under `media/articles/`, while storing the article metadata in **Firestore**.

---

## 1) Design goals

- **Fast reads** for the article list screen (title, thumbnail, summary, published date).
- Support **draft vs published**.
- Thumbnails are stored in **Cloud Storage**, and Firestore stores a **reference** to them.
- Keep the schema simple, extensible, and rule-enforceable.

---

## 2) Collections overview

### Top-level collections
- `/articles` — main collection with all article documents.

(Optional for future extensions)
- `/users` — author profile data (not required for this assignment).
- `/articles/{articleId}/comments` — if you add comments later.

For this assignment, **only `/articles` is required**.

---

## 3) Collection: `articles`

### Path
`/articles/{articleId}`

### Document ID
- `articleId` can be Firestore auto-id.
- Recommended: generate it on create, then use it for the thumbnail path.

---

## 4) Article document fields (required + optional)

Below is the canonical schema. If you add fields, keep them backward compatible.

### Required fields

| Field | Type | Example | Notes |
|------|------|---------|------|
| `title` | `string` | `"How I Learned Flutter in 72 Hours"` | 5–120 chars recommended |
| `content` | `string` | `"Long form article content..."` | Markdown or plain text is fine |
| `status` | `string` | `"draft"` / `"published"` | Allowed values: `draft`, `published` |
| `authorId` | `string` | `"uid_123"` | Firebase Auth `request.auth.uid` |
| `authorName` | `string` | `"Juan Vides"` | Display name (can be empty but recommended) |
| `thumbnailPath` | `string` | `"media/articles/abc123/thumbnail.jpg"` | Must be under `media/articles/` in Storage |
| `createdAt` | `timestamp` | server timestamp | Set on creation (prefer serverTimestamp) |
| `updatedAt` | `timestamp` | server timestamp | Update on every edit |

### Optional fields (recommended)

| Field | Type | Example | Notes |
|------|------|---------|------|
| `subtitle` | `string` | `"A practical roadmap"` | Short summary |
| `excerpt` | `string` | `"This is what I did day by day..."` | Useful for list cards |
| `tags` | `array<string>` | `["flutter","firebase"]` | Keep tags lowercase |
| `publishedAt` | `timestamp` | server timestamp | Only present/used when `status == "published"` |
| `readingTimeMinutes` | `number` | `6` | Computed client-side ok |
| `thumbnailUrl` | `string` | `"https://firebasestorage.googleapis.com/..."` | Optional; URL can rotate, so `thumbnailPath` is the source of truth |
| `language` | `string` | `"es"` | e.g. `en`, `es` |
| `source` | `string` | `"original"` | e.g. `original`, `imported` |

### Example document

```json
{
  "title": "How I Learned Flutter in 72 Hours",
  "subtitle": "A practical roadmap",
  "excerpt": "Here is the plan I followed to ship a clean architecture app fast...",
  "content": "Full article text...",
  "status": "published",
  "authorId": "uid_123",
  "authorName": "Juan Vides",
  "tags": ["flutter", "firebase", "clean-architecture"],
  "thumbnailPath": "media/articles/abc123/thumbnail.jpg",
  "thumbnailUrl": "https://firebasestorage.googleapis.com/v0/b/.../o/media%2Farticles%2Fabc123%2Fthumbnail.jpg?...",
  "readingTimeMinutes": 6,
  "language": "es",
  "createdAt": "2026-04-02T00:00:00Z",
  "updatedAt": "2026-04-02T00:10:00Z",
  "publishedAt": "2026-04-02T00:10:00Z"
}

```
