# SafeChat AI - API Contract

## 1. Purpose

This document defines the communication contract between:

- Flutter client.
- FastAPI backend.
- Database layer.
- AI/NLP module.

The client must communicate only with the FastAPI backend.

The client must not access the database or AI module directly.

---

## 2. Development Base URL

```text
http://127.0.0.1:8000
```

All application API endpoints begin with:

```text
/api
```

Example:

```text
POST http://127.0.0.1:8000/api/analyze
```

---

## 3. Data Format

Requests and responses use JSON unless otherwise specified.

Request header:

```http
Content-Type: application/json
```

Protected endpoints require:

```http
Authorization: Bearer ACCESS_TOKEN
```

---

## 4. Authentication Overview

Authentication uses JWT Bearer tokens.

Flow:

```text
Register
   ↓
Login
   ↓
Receive access_token
   ↓
Send token with protected requests
```

Example authentication header:

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

The client must not store the user's password.

The client stores the access token securely and sends it only to the backend.

---

# 5. System Endpoints

## 5.1 Root Status

### Endpoint

```http
GET /
```

### Authentication

Not required.

### Response

```json
{
  "message": "SafeChat AI Backend is running"
}
```

---

## 5.2 Health Check

### Endpoint

```http
GET /api/health
```

### Authentication

Not required.

### Response

```json
{
  "status": "ok"
}
```

---

# 6. Authentication Endpoints

## 6.1 Register User

### Endpoint

```http
POST /api/auth/register
```

### Authentication

Not required.

### Description

Register a new parent account.

### Request Body

```json
{
  "full_name": "Amjad Parent",
  "email": "amjad.parent@example.com",
  "password": "StrongPassword123"
}
```

### Validation Rules

- `full_name` must contain between 2 and 120 characters.
- `email` must be a valid email address.
- `password` must contain between 8 and 128 characters.
- The email must not already exist.

### Successful Response

Status:

```text
201 Created
```

Body:

```json
{
  "user_id": 1,
  "full_name": "Amjad Parent",
  "email": "amjad.parent@example.com",
  "role": "Parent",
  "created_at": "2026-07-08T14:24:15.108454"
}
```

The password and password hash are never returned.

### Duplicate Email Response

Status:

```text
409 Conflict
```

Body:

```json
{
  "detail": "Email is already registered"
}
```

---

## 6.2 Login User

### Endpoint

```http
POST /api/auth/login
```

### Authentication

Not required.

### Description

Authenticate a user and return a JWT access token.

### Request Body

```json
{
  "email": "amjad.parent@example.com",
  "password": "StrongPassword123"
}
```

### Successful Response

Status:

```text
200 OK
```

Body:

```json
{
  "access_token": "JWT_ACCESS_TOKEN",
  "token_type": "bearer",
  "user": {
    "user_id": 1,
    "full_name": "Amjad Parent",
    "email": "amjad.parent@example.com",
    "role": "Parent",
    "created_at": "2026-07-08T14:24:15.108454"
  }
}
```

### Incorrect Login Response

Status:

```text
401 Unauthorized
```

Body:

```json
{
  "detail": "Incorrect email or password"
}
```

---

## 6.3 Get Current User

### Endpoint

```http
GET /api/auth/me
```

### Authentication

Required.

```http
Authorization: Bearer ACCESS_TOKEN
```

### Description

Return the currently authenticated user.

### Successful Response

```json
{
  "user_id": 1,
  "full_name": "Amjad Parent",
  "email": "amjad.parent@example.com",
  "role": "Parent",
  "created_at": "2026-07-08T14:24:15.108454"
}
```

### Invalid or Expired Token Response

Status:

```text
401 Unauthorized
```

Body:

```json
{
  "detail": "Invalid or expired authentication token"
}
```

---

# 7. Children Endpoints

## 7.1 Create Child Profile

### Endpoint

```http
POST /api/children
```

### Authentication

Required.

```http
Authorization: Bearer ACCESS_TOKEN
```

### Description

Create a child profile under the currently logged-in parent.

The client must not send `parent_id`.

The backend extracts the parent ID from the JWT token.

### Request Body

```json
{
  "full_name": "Ahmad",
  "age": 13
}
```

### Validation Rules

- `full_name` must contain between 2 and 120 characters.
- `age` must be between 1 and 18.

### Successful Response

Status:

```text
201 Created
```

Body:

```json
{
  "child_id": 1,
  "parent_id": 1,
  "full_name": "Ahmad",
  "age": 13,
  "created_at": "2026-07-08T14:30:00"
}
```

The `parent_id` is taken automatically from the authenticated user.

---

## 7.2 Get Current Parent's Children

### Endpoint

```http
GET /api/children
```

### Authentication

Required.

### Description

Return only children belonging to the currently logged-in parent.

### Successful Response

```json
[
  {
    "child_id": 1,
    "parent_id": 1,
    "full_name": "Ahmad",
    "age": 13,
    "created_at": "2026-07-08T14:30:00"
  },
  {
    "child_id": 2,
    "parent_id": 1,
    "full_name": "Maya",
    "age": 15,
    "created_at": "2026-07-08T14:35:00"
  }
]
```

---

## 7.3 Get One Child

### Endpoint

```http
GET /api/children/{child_id}
```

### Example

```http
GET /api/children/1
```

### Authentication

Required.

### Description

Return one child only when that child belongs to the logged-in parent.

### Successful Response

```json
{
  "child_id": 1,
  "parent_id": 1,
  "full_name": "Ahmad",
  "age": 13,
  "created_at": "2026-07-08T14:30:00"
}
```

### Child Not Found or Not Owned by User

Status:

```text
404 Not Found
```

Body:

```json
{
  "detail": "Child not found"
}
```

The backend intentionally returns the same result for a missing child and another parent's child.

---

# 8. Message Analysis Endpoint

## 8.1 Analyze Message

### Endpoint

```http
POST /api/analyze
```

### Authentication

Required.

### Description

Analyze a message for a child owned by the logged-in parent.

The endpoint:

1. Validates the request.
2. Verifies that the child belongs to the current parent.
3. Sends the message to the classifier.
4. Stores the original message.
5. Stores the prediction.
6. Returns the analysis result.

### Request Body

```json
{
  "child_id": 1,
  "message": "אף אחד לא אוהב אותך"
}
```

### Validation Rules

- `child_id` must be an integer greater than or equal to 1.
- `message` must not be empty.
- The child must belong to the logged-in parent.

### Successful Response

```json
{
  "message_id": 1,
  "child_id": 1,
  "message": "אף אחד לא אוהב אותך",
  "category": "Bullying",
  "risk_level": "High",
  "confidence": 0.88,
  "explanation": "The message contains humiliating or socially harmful language."
}
```

### Child Not Found or Not Owned by User

Status:

```text
404 Not Found
```

Body:

```json
{
  "detail": "Child not found"
}
```

---

# 9. Message History Endpoints

## 9.1 Get Current Parent's Messages

### Endpoint

```http
GET /api/messages
```

### Authentication

Required.

### Description

Return analyzed messages belonging only to children owned by the current parent.

### Successful Response

```json
[
  {
    "message_id": 1,
    "child_id": 1,
    "message": "אף אחד לא אוהב אותך",
    "category": "Bullying",
    "risk_level": "High",
    "confidence": 0.88,
    "explanation": "The message contains humiliating or socially harmful language.",
    "created_at": "2026-07-08T14:40:00"
  }
]
```

---

## 9.2 Filter Messages by Child

### Endpoint

```http
GET /api/messages?child_id={child_id}
```

### Example

```http
GET /api/messages?child_id=1
```

### Authentication

Required.

### Description

Return messages for a specific child only when that child belongs to the current parent.

### Successful Response

```json
[
  {
    "message_id": 1,
    "child_id": 1,
    "message": "אף אחד לא אוהב אותך",
    "category": "Bullying",
    "risk_level": "High",
    "confidence": 0.88,
    "explanation": "The message contains humiliating or socially harmful language.",
    "created_at": "2026-07-08T14:40:00"
  }
]
```

---

# 10. Message Categories

The classifier returns one of the following categories:

```text
Normal
Insult
Threat
Harassment
Bullying
```

Descriptions:

```text
Normal
Safe message without detected harmful content.

Insult
A message containing offensive or insulting language.

Threat
A message containing threatening or dangerous language.

Harassment
A message indicating repeated unwanted or harmful behavior.

Bullying
A message containing humiliation, social exclusion, or emotional harm.
```

---

# 11. Risk Levels

The classifier returns one of the following risk levels:

```text
Low
Medium
High
```

Descriptions:

```text
Low
No harmful content or very low risk.

Medium
Suspicious, insulting, or potentially harmful content.

High
Clearly threatening, dangerous, humiliating, or bullying content.
```

---

# 12. AI/NLP Function Contract

The backend calls an internal function:

```python
analyze_message(text: str) -> dict
```

### Input

```python
"אף אחד לא אוהב אותך"
```

### Output

```python
{
    "category": "Bullying",
    "risk_level": "High",
    "confidence": 0.88,
    "explanation": "The message contains humiliating or socially harmful language."
}
```

Required output fields:

```text
category
risk_level
confidence
explanation
```

The current implementation is rule-based.

The final AI/NLP model must preserve the same output structure so that the FastAPI backend does not require major changes.

---

# 13. Current Database Contract

## 13.1 Users

```text
id
full_name
email
password_hash
role
created_at
```

## 13.2 Children

```text
id
parent_id
full_name
age
created_at
```

`parent_id` references:

```text
users.id
```

## 13.3 Messages

```text
id
child_id
message_text
created_at
```

`child_id` references:

```text
children.id
```

## 13.4 Predictions

```text
id
message_id
category
risk_level
confidence
explanation
created_at
```

`message_id` references:

```text
messages.id
```

---

# 14. Authorization Rules

The backend currently enforces these rules:

- Protected endpoints require a valid JWT token.
- A user can create children only under their own account.
- A user can retrieve only their own children.
- A user cannot retrieve another user's child.
- A user can analyze messages only for their own children.
- A user can retrieve only messages belonging to their own children.
- Password hashes are never returned.
- Access tokens must not be committed to Git.
- Secret keys must remain in the local `.env` file.

---

# 15. Validation and Error Responses

## 15.1 Validation Error

Status:

```text
422 Unprocessable Entity
```

Example causes:

- Invalid email.
- Password shorter than 8 characters.
- Empty message.
- Invalid child ID.
- Child age outside the allowed range.
- Missing required field.

FastAPI returns a detailed validation response.

---

## 15.2 Unauthorized Request

Status:

```text
401 Unauthorized
```

or, depending on the authentication layer:

```text
403 Forbidden
```

Example causes:

- Missing token.
- Invalid token.
- Expired token.

---

## 15.3 Not Found

Status:

```text
404 Not Found
```

Example:

```json
{
  "detail": "Child not found"
}
```

---

## 15.4 Duplicate Resource

Status:

```text
409 Conflict
```

Example:

```json
{
  "detail": "Email is already registered"
}
```

---

# 16. Current Automated Test Status

The backend currently has automated tests for:

- Classifier behavior.
- Authentication.
- JWT.
- Child management.
- Child ownership.
- Message analysis.
- Message history.
- Authorization.
- Request validation.
- Protected endpoints.

Current result:

```text
29 passed
```

Tests are executed with:

```bash
python -m pytest -q
```

---

# 17. Currently Implemented Endpoint Summary

| Method | Endpoint | Authentication | Status |
|---|---|---|---|
| GET | `/` | No | Implemented |
| GET | `/api/health` | No | Implemented |
| POST | `/api/auth/register` | No | Implemented |
| POST | `/api/auth/login` | No | Implemented |
| GET | `/api/auth/me` | Yes | Implemented |
| POST | `/api/children` | Yes | Implemented |
| GET | `/api/children` | Yes | Implemented |
| GET | `/api/children/{child_id}` | Yes | Implemented |
| POST | `/api/analyze` | Yes | Implemented |
| GET | `/api/messages` | Yes | Implemented |
| GET | `/api/messages?child_id={id}` | Yes | Implemented |

---

# 18. Planned Endpoints

The following endpoints are planned but not yet implemented:

```text
GET  /api/dashboard/stats
GET  /api/dashboard/categories
GET  /api/dashboard/risk-levels
GET  /api/alerts
PUT  /api/alerts/{alert_id}
POST /api/analyze/batch
POST /api/messages/upload
```

These endpoints must not be treated as available until their implementation and tests are completed.

---

# 19. Flutter Integration Notes

The Flutter client should:

1. Register or log in the user.
2. Save the returned JWT access token securely.
3. Add the token to every protected request.
4. Call `GET /api/auth/me` to restore the user session.
5. Call `POST /api/children` without sending `parent_id`.
6. Use the returned `child_id` for message analysis.
7. Call `POST /api/analyze` to analyze a message.
8. Call `GET /api/messages` to show message history.
9. Handle 401 responses by requiring login again.
10. Never communicate directly with the database or AI module.

