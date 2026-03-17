# Share API Specification

## Overview

The Share API enables users to share programs and templates with other users via shareable links. When a user shares an item, the backend creates a frozen snapshot of the item at that point in time. Subsequent edits to the original do not affect existing shares.

Share links use the format: `nippardation://share/{token}`

---

## Endpoints

### POST /api/shares

Creates a new share for a program or template.

**Authentication:** Required (Bearer token)

**Request Body:**
```json
{
  "type": "program" | "template",
  "itemId": "string"
}
```

| Field    | Type   | Required | Description                                    |
|----------|--------|----------|------------------------------------------------|
| `type`   | string | Yes      | The type of item being shared: `program` or `template` |
| `itemId` | string | Yes      | The server ID of the program or template       |

**Success Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "token": "abc123def456",
    "shareUrl": "nippardation://share/abc123def456",
    "expiresAt": null
  }
}
```

| Field       | Type        | Description                                     |
|-------------|-------------|-------------------------------------------------|
| `token`     | string      | Unique share token for the link                 |
| `shareUrl`  | string      | Full share URL ready to distribute              |
| `expiresAt` | string/null | ISO 8601 expiration date, or null if no expiry  |

**Error Responses:**

| Status | Condition                       | Body                                          |
|--------|---------------------------------|-----------------------------------------------|
| 401    | Missing or invalid auth token   | `{ "error": "Unauthorized" }`                 |
| 404    | Item not found or not owned     | `{ "error": "Item not found" }`               |
| 422    | Invalid type or missing itemId  | `{ "error": "Validation failed", "details": [...] }` |

---

### GET /api/shares/{token}

Fetches the share details for previewing before import. Does NOT require authentication so recipients can preview before logging in.

**Authentication:** Optional

**Path Parameters:**

| Parameter | Type   | Description       |
|-----------|--------|-------------------|
| `token`   | string | The share token   |

**Success Response (200 OK):**

For a **template** share:
```json
{
  "success": true,
  "data": {
    "id": "share_001",
    "token": "abc123def456",
    "type": "template",
    "sharedBy": {
      "id": "user_001",
      "displayName": "Jeff Nippard",
      "avatarUrl": "https://example.com/avatar.jpg"
    },
    "sharedAt": "2026-03-08T12:00:00Z",
    "template": {
      "id": "tmpl_001",
      "name": "Push Day",
      "description": "Chest, shoulders, and triceps",
      "exercises": [
        {
          "id": "te_001",
          "exerciseId": "ex_001",
          "exercise": {
            "id": "ex_001",
            "name": "Barbell Bench Press",
            "primaryMuscles": ["chest"],
            "equipment": "barbell"
          },
          "orderIndex": 0,
          "warmupSets": 2,
          "workingSets": 4,
          "targetReps": "8-10",
          "restSeconds": 180,
          "notes": null
        }
      ],
      "isPublic": false,
      "isAiGenerated": false,
      "createdAt": "2026-01-01T00:00:00Z",
      "updatedAt": "2026-01-01T00:00:00Z"
    },
    "program": null
  }
}
```

For a **program** share:
```json
{
  "success": true,
  "data": {
    "id": "share_002",
    "token": "xyz789ghi012",
    "type": "program",
    "sharedBy": {
      "id": "user_001",
      "displayName": "Jeff Nippard",
      "avatarUrl": "https://example.com/avatar.jpg"
    },
    "sharedAt": "2026-03-08T12:00:00Z",
    "template": null,
    "program": {
      "id": "prog_001",
      "name": "Upper/Lower Split",
      "description": "4-day strength program",
      "daysPerWeek": 4,
      "durationWeeks": 8,
      "workouts": [
        {
          "id": "pw_001",
          "dayNumber": 1,
          "dayLabel": "Upper A",
          "templateId": "tmpl_001",
          "template": {
            "id": "tmpl_001",
            "name": "Upper Body A",
            "description": "Heavy compound upper",
            "exercises": [...],
            "isPublic": false,
            "isAiGenerated": false,
            "createdAt": "2026-01-01T00:00:00Z",
            "updatedAt": "2026-01-01T00:00:00Z"
          }
        }
      ],
      "isPublic": false,
      "isAiGenerated": false,
      "createdAt": "2026-01-01T00:00:00Z",
      "updatedAt": "2026-01-01T00:00:00Z"
    }
  }
}
```

**Error Responses:**

| Status | Condition                  | Body                                    |
|--------|----------------------------|-----------------------------------------|
| 404    | Token not found or expired | `{ "error": "Share not found" }`        |

---

## Database Schema

### shares table

| Column        | Type         | Constraints          | Description                                |
|---------------|--------------|----------------------|--------------------------------------------|
| `id`          | UUID/String  | PRIMARY KEY          | Unique share ID                            |
| `token`       | VARCHAR(64)  | UNIQUE, NOT NULL, INDEX | URL-safe share token                    |
| `type`        | ENUM         | NOT NULL             | `program` or `template`                    |
| `item_id`     | VARCHAR(255) | NOT NULL             | Server ID of the shared item               |
| `shared_by`   | VARCHAR(255) | NOT NULL, FK(users)  | User ID of the sharer                      |
| `snapshot`    | JSONB/TEXT   | NOT NULL             | Frozen JSON snapshot of the item at share time |
| `expires_at`  | TIMESTAMP    | NULL                 | Optional expiration (null = no expiry)     |
| `created_at`  | TIMESTAMP    | NOT NULL, DEFAULT NOW | When the share was created                |

### Indexes

- `idx_shares_token` on `token` (unique) - Primary lookup
- `idx_shares_shared_by` on `shared_by` - User's shares listing
- `idx_shares_item` on `(type, item_id)` - Find shares for an item

---

## Token Generation

- Tokens should be URL-safe alphanumeric strings
- Recommended length: 12-16 characters
- Must be globally unique
- Example: `a3Bf9kLm2xQz`

---

## Snapshot Strategy

When `POST /api/shares` is called:

1. Fetch the full item (program or template) with all nested data
2. For programs: include all workouts and their full template snapshots (with exercises)
3. Serialize to JSON and store in the `snapshot` column
4. The `GET /api/shares/{token}` endpoint returns the snapshot data directly

This ensures:
- Edits to the original don't affect existing shares
- Deleted items don't break existing share links
- The share is fully self-contained

---

## Notes

- **No weight data**: Templates only store structure (exercises, sets, reps, rest). No user weight data is included.
- **Exercise library references**: Exercise IDs reference the global exercise library. Recipients have access to the same library.
- **No deduplication**: Each share creates a new token. Sharing the same item twice creates two independent shares.
- **No expiration (MVP)**: Shares do not expire. Future enhancement can add optional TTL.
- **Authentication for creation only**: Creating a share requires auth. Viewing a share does not, allowing link previews.
