# SafeChat AI - API Contract

This document defines the communication between the Flutter client, FastAPI backend, database, and AI/NLP module.

The goal of this file is to make the work between team members clear before writing the full code.

---

# 1. General System Architecture

```text
Flutter Client
      |
      | HTTP Requests
      v
FastAPI Backend
      |
      | Calls internal function
      v
AI / NLP Module
      |
      | Stores and reads data
      v
Database
```

---

# 2. Base URL

During development:

```text
http://localhost:8000
```

All API routes will start with:

```text
/api
```

Example:

```text
POST http://localhost:8000/api/analyze
```

---

# 3. User Roles

The system supports the following roles:

```text
Parent
Admin
Child
```

For the MVP version, the most important role is:

```text
Parent
```

---

# 4. Authentication APIs

## 4.1 Register User

### Endpoint

```http
POST /api/auth/register
```

### Description

Create a new user account.

### Request Body

```json
{
  "full_name": "Parent Name",
  "email": "parent@example.com",
  "password": "123456",
  "role": "Parent"
}
```

### Response

```json
{
  "user_id": 1,
  "full_name": "Parent Name",
  "email": "parent@example.com",
  "role": "Parent",
  "message": "User registered successfully"
}
```

---

## 4.2 Login User

### Endpoint

```http
POST /api/auth/login
```

### Description

Login user and return an authentication token.

### Request Body

```json
{
  "email": "parent@example.com",
  "password": "123456"
}
```

### Response

```json
{
  "access_token": "jwt_token_here",
  "token_type": "bearer",
  "user": {
    "user_id": 1,
    "full_name": "Parent Name",
    "email": "parent@example.com",
    "role": "Parent"
  }
}
```

---

# 5. Children APIs

## 5.1 Add Child Profile

### Endpoint

```http
POST /api/children
```

### Description

Add a child profile under the logged-in parent.

### Request Body

```json
{
  "full_name": "Child Name",
  "age": 13
}
```

### Response

```json
{
  "child_id": 1,
  "parent_id": 1,
  "full_name": "Child Name",
  "age": 13,
  "message": "Child profile created successfully"
}
```

---

## 5.2 Get Children

### Endpoint

```http
GET /api/children
```

### Description

Return all children profiles for the logged-in parent.

### Response

```json
[
  {
    "child_id": 1,
    "full_name": "Child Name",
    "age": 13
  },
  {
    "child_id": 2,
    "full_name": "Second Child",
    "age": 15
  }
]
```

---

# 6. Message Analysis APIs

## 6.1 Analyze Single Message

### Endpoint

```http
POST /api/analyze
```

### Description

Analyze a single message and return the cyberbullying classification result.

### Request Body

```json
{
  "child_id": 1,
  "message": "אתה אפס ואף אחד לא אוהב אותך"
}
```

### Response

```json
{
  "message_id": 15,
  "child_id": 1,
  "message": "אתה אפס ואף אחד לא אוהב אותך",
  "category": "Bullying",
  "risk_level": "High",
  "confidence": 0.87,
  "explanation": "The message contains insulting and humiliating language.",
  "created_at": "2026-07-01T12:00:00"
}
```

---

## 6.2 Analyze Multiple Messages

### Endpoint

```http
POST /api/analyze/batch
```

### Description

Analyze multiple messages in one request.

This can be used later for CSV upload or bulk analysis.

### Request Body

```json
{
  "child_id": 1,
  "messages": [
    "אתה אפס",
    "מה קורה?",
    "אף אחד לא אוהב אותך"
  ]
}
```

### Response

```json
[
  {
    "message_id": 15,
    "message": "אתה אפס",
    "category": "Insult",
    "risk_level": "High",
    "confidence": 0.91,
    "explanation": "The message contains offensive language."
  },
  {
    "message_id": 16,
    "message": "מה קורה?",
    "category": "Normal",
    "risk_level": "Low",
    "confidence": 0.98,
    "explanation": "No harmful content was detected."
  },
  {
    "message_id": 17,
    "message": "אף אחד לא אוהב אותך",
    "category": "Bullying",
    "risk_level": "High",
    "confidence": 0.88,
    "explanation": "The message contains humiliating language."
  }
]
```

---

# 7. Messages APIs

## 7.1 Get All Messages

### Endpoint

```http
GET /api/messages
```

### Description

Return all analyzed messages for the logged-in parent.

### Response

```json
[
  {
    "message_id": 15,
    "child_id": 1,
    "message": "אתה אפס ואף אחד לא אוהב אותך",
    "category": "Bullying",
    "risk_level": "High",
    "confidence": 0.87,
    "created_at": "2026-07-01T12:00:00"
  },
  {
    "message_id": 16,
    "child_id": 1,
    "message": "מה קורה?",
    "category": "Normal",
    "risk_level": "Low",
    "confidence": 0.98,
    "created_at": "2026-07-01T12:05:00"
  }
]
```

---

## 7.2 Get Messages By Child

### Endpoint

```http
GET /api/messages/child/{child_id}
```

### Example

```http
GET /api/messages/child/1
```

### Description

Return all analyzed messages for a specific child.

### Response

```json
[
  {
    "message_id": 15,
    "child_id": 1,
    "message": "אתה אפס ואף אחד לא אוהב אותך",
    "category": "Bullying",
    "risk_level": "High",
    "confidence": 0.87,
    "created_at": "2026-07-01T12:00:00"
  }
]
```

---

# 8. Alerts APIs

## 8.1 Get Alerts

### Endpoint

```http
GET /api/alerts
```

### Description

Return all alerts for dangerous messages.

### Response

```json
[
  {
    "alert_id": 4,
    "message_id": 15,
    "child_id": 1,
    "alert_type": "High Risk Message",
    "status": "Open",
    "created_at": "2026-07-01T12:00:00"
  }
]
```

---

## 8.2 Update Alert Status

### Endpoint

```http
PUT /api/alerts/{alert_id}
```

### Example

```http
PUT /api/alerts/4
```

### Description

Update alert status.

### Request Body

```json
{
  "status": "Closed"
}
```

### Response

```json
{
  "alert_id": 4,
  "status": "Closed",
  "message": "Alert updated successfully"
}
```

---

# 9. Dashboard APIs

## 9.1 Get Dashboard Statistics

### Endpoint

```http
GET /api/dashboard/stats
```

### Description

Return statistics for the parent dashboard.

### Response

```json
{
  "total_messages": 120,
  "normal_messages": 95,
  "dangerous_messages": 25,
  "high_risk_messages": 7,
  "medium_risk_messages": 12,
  "low_risk_messages": 6
}
```

---

## 9.2 Get Category Statistics

### Endpoint

```http
GET /api/dashboard/categories
```

### Description

Return number of messages per category.

### Response

```json
{
  "Normal": 95,
  "Insult": 10,
  "Threat": 3,
  "Harassment": 5,
  "Bullying": 7
}
```

---

## 9.3 Get Risk Level Statistics

### Endpoint

```http
GET /api/dashboard/risk-levels
```

### Description

Return number of messages per risk level.

### Response

```json
{
  "Low": 95,
  "Medium": 18,
  "High": 7
}
```

---

# 10. AI / NLP Function Contract

The backend will call an internal AI function.

## Function Name

```python
analyze_message(text)
```

## Input

```python
"אתה אפס ואף אחד לא אוהב אותך"
```

## Output

```python
{
    "category": "Bullying",
    "risk_level": "High",
    "confidence": 0.87,
    "explanation": "The message contains insulting and humiliating language."
}
```

---

# 11. Categories

The AI/NLP module should return one of these categories:

```text
Normal
Insult
Threat
Harassment
Bullying
```

## Category Explanation

```text
Normal      - Safe message without harmful content
Insult      - Offensive words or direct insult
Threat      - Message that includes danger or threat
Harassment  - Repeated annoying or harmful behavior
Bullying    - Humiliation, social exclusion, or emotional harm
```

---

# 12. Risk Levels

The system should return one of these risk levels:

```text
Low
Medium
High
```

## Risk Level Explanation

```text
Low     - Safe or very low risk message
Medium  - Suspicious or harmful message
High    - Dangerous, threatening, or clearly bullying message
```

---

# 13. Database Tables - Initial Plan

## users

```text
id
full_name
email
password_hash
role
created_at
```

## children

```text
id
parent_id
full_name
age
created_at
```

## messages

```text
id
child_id
sender_name
receiver_name
message_text
source
created_at
uploaded_by
```

## predictions

```text
id
message_id
category
risk_level
confidence
explanation
created_at
```

## alerts

```text
id
child_id
message_id
alert_type
status
created_at
```

## audit_logs

```text
id
user_id
action
details
created_at
```

---

# 14. Error Response Format

All errors should follow this format:

```json
{
  "error": true,
  "message": "Error description here"
}
```

## Example

```json
{
  "error": true,
  "message": "Child profile not found"
}
```

---

# 15. MVP API List

For the first working version, we need these APIs:

```text
POST /api/auth/register
POST /api/auth/login
POST /api/children
GET  /api/children
POST /api/analyze
GET  /api/messages
GET  /api/alerts
GET  /api/dashboard/stats
```

---

# 16. Notes For Team Members

- The Flutter client should only communicate with the FastAPI backend.
- The Flutter client should not call the AI/NLP module directly.
- The backend is responsible for calling the AI/NLP module.
- The backend is responsible for saving messages, predictions, and alerts in the database.
- The AI/NLP module receives text and returns category, risk level, confidence, and explanation.
- All API responses should be simple and clear so the frontend can display them easily.

