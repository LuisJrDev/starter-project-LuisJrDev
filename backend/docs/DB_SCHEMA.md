# Firestore DB Schema — Journalist Articles

This document describes the Firestore schema used for the “Journalist Articles” functionality.

## Collections overview

- `/articles/{articleId}`
  - Subcollections:
    - `/articles/{articleId}/reactions/{uid}`
    - `/articles/{articleId}/comments/{commentId}`
- `/users/{uid}`

---

## 1) `articles` collection

### Path

`/articles/{articleId}`

### Purpose

Stores journalist-authored articles, including drafts and published articles. The feed reads published articles from this collection.

### Document fields

| Field | Type | Required | Notes |

|------|------|----------|------|
| `title` | `string` | ✅ | 5–120 chars |
| `content` | `string` | ✅ | Markdown text |
| `status` | `string` | ✅ | `"draft"` or `"published"` |
| `authorId` | `string` | ✅ | Must match `request.auth.uid` on create/update (author-only) |
| `authorName` | `string` | ✅ | 2–50 chars; display name shown in UI |
| `thumbnailPath` | `string` | ✅ | Storage path, must match `media/articles/...` |
| `category` | `string` | ✅ | One of: `General`, `Sports`, `Technology`, `Business`, `Health`, `Entertainment`, `Politics` |
| `createdAt` | `timestamp` | ✅ | Creation time (immutable) |
| `updatedAt` | `timestamp` | ✅ | Updated on edits/likes/comments |
| `publishedAt` | `timestamp` | optional | Present when published (or null/not set for drafts) |
| `likeCount` | `number` | ✅ | Counter; non-negative |
| `commentCount` | `number` | ✅ | Counter; non-negative |

### Example document

```json
{
  "title": "Un día de playa: guía para desconectar sin complicarte",
  "content": "## La playa como pausa...\n\nTexto en Markdown...",
  "status": "published",
  "authorId": "firebase-auth-uid",
  "authorName": "Luis Lemus",
  "thumbnailPath": "media/articles/7c1b.../thumb.jpg",
  "category": "General",
  "createdAt": "2026-04-04T12:00:00Z",
  "updatedAt": "2026-04-04T12:30:00Z",
  "publishedAt": "2026-04-04T12:10:00Z",
  "likeCount": 3,
  "commentCount": 1
}
```

---

## 2) `reactions` subcollection (likes)

### Path

`/articles/{articleId}/reactions/{uid}`

### Purpose

Stores a **single like per authenticated user per article**.  
The document id is the user uid to enforce uniqueness.

### Document fields

| Field | Type | Required | Notes |

|------|------|----------|------|
| `uid` | `string` | ✅ | Must equal `request.auth.uid` |
| `type` | `string` | ✅ | `"like"` |
| `createdAt` | `timestamp` | ✅ | Like timestamp |

### Example

```json
{
  "uid": "firebase-auth-uid",
  "type": "like",
  "createdAt": "2026-04-04T12:20:00Z"
}
```

### Notes

- `likeCount` is stored at the article doc (`/articles/{articleId}.likeCount`) and updated via transaction whenever a reaction is created/deleted.

---

## 3) `comments` subcollection

### Path

`/articles/{articleId}/comments/{commentId}`

### Purpose

Stores comments for an article.

### Document fields

| Field | Type | Required | Notes |

|------|------|----------|------|
| `uid` | `string` | ✅ | Must equal `request.auth.uid` |
| `deviceId` | `string` | ✅ | Local device identifier (non-PII) used by client |
| `authorName` | `string` | ✅ | Displayed in UI |
| `text` | `string` | ✅ | 1–500 chars |
| `createdAt` | `timestamp` | ✅ | Comment timestamp |

### Example

```json
{
  "uid": "firebase-auth-uid",
  "deviceId": "local-device-id",
  "authorName": "Zharick Galindo",
  "text": "Muy buen artículo, gracias por compartir.",
  "createdAt": "2026-04-04T12:25:00Z"
}
```

### Notes

- `commentCount` is stored at the article doc (`/articles/{articleId}.commentCount`) and incremented via transaction when a comment is created.

---

## 4) `users` collection (profiles)

### Path

`/users/{uid}`

### Purpose

Stores user profile fields used by the app (e.g. display name).

### Example

```json
{
  "name": "Luis Lemus",
  "email": "luis@example.com",
  "createdAt": "2026-04-04T11:00:00Z"
}
```

### Notes

- Access is restricted so users can only read/write their own profile document.

---

## Storage schema (thumbnails)

### Path

`/media/articles/{...}`

### Purpose

Stores uploaded thumbnail images for articles.

### Notes

- Firestore stores a reference to the storage path in `articles.thumbnailPath`.

- Example: `media/articles/7c1b.../thumb.jpg`