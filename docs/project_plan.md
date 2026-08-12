# SafeChat AI - Project Plan

## 1. Project Name

**SafeChat AI**

## 2. Project Description

SafeChat AI is a smart system for detecting cyberbullying and harmful messages in Hebrew.

The system allows a parent to register, log in, create child profiles, submit messages for analysis, view the message classification and risk level, view dashboard statistics, and receive alerts for high-risk messages.

The backend analyzes each message, stores the original message and its analysis result in a database, creates alerts when needed, and returns structured responses to the client application.

The current system uses Gemini API as the main AI classifier for Hebrew message analysis. It also includes a local rule-based fallback classifier, so the backend continues working even if the external AI provider is unavailable.

---

## 3. Problem Statement

Cyberbullying can include insults, threats, harassment, humiliation, social exclusion, and repeated harmful behavior.

Parents and school staff may not always identify dangerous messages early enough.

SafeChat AI aims to provide an early-warning system that:

- Analyzes Hebrew messages.
- Detects potentially harmful content.
- Classifies the type of harmful behavior.
- Calculates a risk level.
- Stores message history.
- Creates alerts for high-risk messages.
- Allows each parent to access only their own children, messages, alerts, statistics, and reports.
- Provides report data, notification foundation, and dashboard statistics.

---

## 4. Main Goal

The main goal of the project is to build a secure full-stack platform that helps identify possible cyberbullying incidents by combining:

- Flutter client application.
- FastAPI backend.
- Authentication and authorization.
- Relational database.
- Hebrew text analysis.
- AI/NLP model integration.
- Automated testing.

---

## 5. System Type

SafeChat AI is designed as a client-server system.

The client is built with Flutter and can support:

- Android.
- iOS.
- Web.
- Desktop platforms.

The server is built with Python and FastAPI.

---

## 6. Current System Architecture

```text
Flutter Client
      |
      | HTTP/JSON requests
      | JWT Bearer token for protected endpoints
      v
FastAPI Backend
      |
      ├── Authentication
      ├── Authorization
      ├── Child profile management
      ├── Message analysis
      ├── Message history
      ├── Dashboard statistics
      ├── Alerts management
      ├── Request validation
      └── Database operations
      |
      v
Gemini AI Classifier
      |
      ├── Returns category, risk level, confidence, and Hebrew explanation
      └── Falls back to local rule-based classifier if unavailable
      |
      v
SQLite Database
      |
      ├── Users
      ├── Children
      ├── Messages
      ├── Predictions
      └── Alerts
```

---

## 7. Main System Components

### 7.1 Flutter Client

Technology:

- Flutter.
- Dart.

Responsibilities:

- Registration screen.
- Login screen.
- Parent dashboard.
- Child profile management.
- Message submission form.
- Display analysis results.
- Display message history.
- Display alerts.
- Display dashboard statistics.
- Store and send the JWT access token.
- Communicate only with the FastAPI backend.

### 7.2 FastAPI Backend

Technology:

- Python.
- FastAPI.
- Pydantic.
- SQLAlchemy.
- JWT authentication.

Responsibilities:

- Register users.
- Authenticate users.
- Hash and verify passwords.
- Generate JWT access tokens.
- Identify the currently logged-in user.
- Validate API requests.
- Manage child profiles.
- Verify child ownership.
- Receive messages from the client.
- Call the message classifier.
- Save messages and predictions.
- Create alerts for high-risk messages.
- Return message history.
- Return dashboard statistics.
- Return alerts and unread alert counts.
- Mark alerts as read.
- Prevent users from accessing another user's data.

### 7.3 AI/NLP Module

Technology:

- Python.
- Gemini API.
- google-genai SDK.
- Prompt-based Hebrew text classification.
- Local rule-based fallback classifier.

Responsibilities:

- Analyze Hebrew messages using Gemini API.
- Classify messages into Normal, Insult, Threat, Harassment, or Bullying.
- Calculate confidence.
- Return a risk level: Low, Medium, or High.
- Return a Hebrew explanation for the parent dashboard.
- Fall back to a local rule-based classifier if Gemini is unavailable.

### 7.4 Database

Current technology:

- SQLite for local development.

Possible future technology:

- PostgreSQL for deployment.

Current tables:

- Users.
- Children.
- Messages.
- Predictions.
- Alerts.

Future tables may include:

- Audit logs.
- Reports.
- Refresh tokens.

---

## 8. Current Backend Implementation Status

The following backend features have already been implemented:

- FastAPI project structure.
- Automatic Swagger documentation.
- Health-check endpoint.
- SQLite database integration.
- SQLAlchemy models.
- User registration.
- User login.
- Secure password hashing.
- JWT access token generation.
- Current-user identification.
- Protected API endpoints.
- Child profile creation.
- Automatic child ownership using the authenticated parent.
- Child profile retrieval.
- Prevention of access to another parent's child.
- Message analysis endpoint.
- Gemini AI classifier for Hebrew message analysis.
- Rule-based fallback classifier.
- Message persistence.
- Prediction persistence.
- Message history endpoint.
- Filtering message history by child.
- Prevention of access to another parent's messages.
- Dashboard statistics API.
- Total children count.
- Total analyzed messages count.
- Message statistics by risk level.
- Message statistics by category.
- Automatic alert creation for high-risk messages.
- Alerts API.
- Unread alerts count.
- Mark alert as read.
- Parent can view only alerts that belong to their own children.
- Request and response validation using Pydantic.
- Batch message analysis API.
- CSV upload for multiple messages.
- Reports API.
- CSV report export.
- Automated unit and API tests.

Current automated test result:

```text
65 passed, 1 warning
```

---

## 9. Current Database Structure

### 9.1 Users Table

```text
users
├── id
├── full_name
├── email
├── password_hash
├── role
└── created_at
```

### 9.2 Children Table

```text
children
├── id
├── parent_id
├── full_name
├── age
└── created_at
```

Relationship:

```text
One User
    |
    └── Many Children
```

### 9.3 Messages Table

```text
messages
├── id
├── child_id
├── message_text
└── created_at
```

Relationship:

```text
One Child
    |
    └── Many Messages
```

### 9.4 Predictions Table

```text
predictions
├── id
├── message_id
├── category
├── risk_level
├── confidence
├── explanation
└── created_at
```

Relationship:

```text
One Message
    |
    └── One Prediction
```

### 9.5 Alerts Table

```text
alerts
├── id
├── child_id
├── message_id
├── prediction_id
├── title
├── category
├── risk_level
├── is_read
└── created_at
```

Relationship:

```text
One Child
    |
    └── Many Alerts
```

An alert is created automatically when a message receives a `High` risk level.

---

## 10. Current Authentication Flow

```text
User Registration
        ↓
Password is securely hashed
        ↓
User record is saved
        ↓
User Login
        ↓
Password is verified
        ↓
JWT access token is generated
        ↓
Client sends token with protected requests
        ↓
Backend identifies the current user
```

Protected requests use the following header:

```http
Authorization: Bearer ACCESS_TOKEN
```

The token currently expires after approximately 60 minutes according to the backend environment configuration.

---

## 11. Current Authorization Rules

The following authorization rules are implemented:

- A parent can create children only under their own account.
- The client does not send `parent_id` when creating a child.
- The backend obtains the parent ID from the JWT token.
- A parent can retrieve only their own children.
- A parent cannot retrieve another parent's child.
- A parent can analyze messages only for their own children.
- A parent can retrieve only messages belonging to their own children.
- A parent cannot view another parent's message history.
- A parent can view only dashboard statistics that belong to their own children and messages.
- A parent can view only alerts that belong to their own children.
- A parent cannot mark another parent's alert as read.
- Protected endpoints require a valid JWT token.
- Password hashes are never returned by the API.
- The real password is never stored directly in the database.

---

## 12. Currently Implemented Endpoints

| Method | Endpoint | Authentication | Description |
|---|---|---|---|
| GET | `/` | No | Return the backend status message |
| GET | `/api/health` | No | Check whether the backend is running |
| POST | `/api/auth/register` | No | Register a new parent |
| POST | `/api/auth/login` | No | Log in and receive a JWT token |
| GET | `/api/auth/me` | Yes | Return the logged-in user |
| POST | `/api/children` | Yes | Create a child for the logged-in parent |
| GET | `/api/children` | Yes | Return the current parent's children |
| GET | `/api/children/{child_id}` | Yes | Return one child owned by the current parent |
| POST | `/api/analyze` | Yes | Analyze and save a message |
| GET | `/api/messages` | Yes | Return the current parent's message history |
| GET | `/api/messages?child_id={id}` | Yes | Filter messages by child |
| GET | `/api/dashboard/stats` | Yes | Return dashboard statistics for the current parent |
| GET | `/api/alerts` | Yes | Return the current parent's alerts |
| GET | `/api/alerts?unread_only=true` | Yes | Return only unread alerts |
| GET | `/api/alerts/unread-count` | Yes | Return the number of unread alerts |
| PATCH | `/api/alerts/{alert_id}/read` | Yes | Mark an alert as read |

---

## 13. Current Message Analysis Flow

```text
Parent logs in
      ↓
Parent receives JWT token
      ↓
Parent creates a child profile
      ↓
Backend automatically stores the logged-in user as parent
      ↓
Parent submits a message with child_id
      ↓
Backend verifies that the child belongs to the parent
      ↓
Backend sends the text to the classifier
      ↓
Classifier returns category, risk, confidence, and explanation
      ↓
Backend saves the original message
      ↓
Backend saves the prediction
      ↓
If the prediction risk level is High
      ↓
Backend creates an alert
      ↓
Backend returns a JSON response
```

Example request:

```json
{
  "child_id": 1,
  "message": "אף אחד לא אוהב אותך"
}
```

Example response:

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

When the returned `risk_level` is `High`, the backend creates an alert automatically.

---

## 14. Current Dashboard Flow

```text
Parent logs in
      ↓
Parent receives JWT token
      ↓
Parent requests dashboard statistics
      ↓
Backend filters data by the current parent
      ↓
Backend counts children and messages
      ↓
Backend groups predictions by risk level and category
      ↓
Backend returns statistics
```

Example response:

```json
{
  "total_children": 1,
  "total_messages": 2,
  "risk_levels": {
    "Low": 1,
    "Medium": 0,
    "High": 1
  },
  "categories": {
    "Normal": 1,
    "Insult": 0,
    "Threat": 0,
    "Harassment": 0,
    "Bullying": 1
  }
}
```

---

## 15. Current Alerts Flow

```text
High-risk message is analyzed
      ↓
Backend creates an alert
      ↓
Parent requests alerts
      ↓
Backend returns only alerts that belong to the parent's children
      ↓
Parent can mark an alert as read
```

Example alert response:

```json
{
  "alert_id": 1,
  "child_id": 1,
  "message_id": 1,
  "title": "High risk message detected",
  "category": "Bullying",
  "risk_level": "High",
  "is_read": false,
  "created_at": "2026-07-08T14:50:00"
}
```

---

## 16. AI/NLP Integration Status

The current backend uses Gemini API as the main Hebrew message classifier.

The Gemini classifier and the local rule-based fallback help the team:

- Use Gemini API for real-time Hebrew message analysis.
- Keep the backend stable even if Gemini is unavailable.
- Test the API connection.
- Test the database.
- Test the Flutter integration.
- Define a stable contract between the backend and the AI module.

Current categories:

- Normal.
- Insult.
- Threat.
- Harassment.
- Bullying.

Current risk levels:

- Low.
- Medium.
- High.

The AI team member will later replace the internal implementation while keeping this function contract:

```python
analyze_message(text: str) -> dict
```

Expected output:

```python
{
    "category": "Bullying",
    "risk_level": "High",
    "confidence": 0.88,
    "explanation": "Explanation of the classification."
}
```

The FastAPI endpoint does not need major changes when switching between Gemini and the local fallback classifier, because the classifier returns the same response structure.

---

## 17. Current Testing Strategy

The backend includes automated tests for:

- Normal message classification.
- Insult classification.
- Threat classification.
- Harassment classification.
- Bullying classification.
- Health endpoint.
- Request validation.
- User registration.
- Duplicate email rejection.
- User login.
- Incorrect password rejection.
- JWT access token generation.
- Current-user endpoint.
- Child creation.
- Automatic child ownership.
- Child retrieval.
- Access-control rules.
- Message analysis.
- Message persistence.
- Message history.
- Message filtering.
- Dashboard statistics.
- Dashboard ownership and authorization.
- Alert creation for high-risk messages.
- Alert retrieval.
- Unread alerts count.
- Mark alert as read.
- Alert ownership and authorization.
- Protected endpoint behavior.

Tests are executed with:

```bash
python -m pytest -q
```

Current result:

```text
65 passed, 1 warning
```

---

## 18. MVP Features

The minimum working product should include:

1. User registration.
2. User login.
3. JWT authentication.
4. Parent account.
5. Child profile creation.
6. Message submission.
7. Message classification.
8. Risk-level calculation.
9. Message and prediction storage.
10. Message history.
11. Parent data isolation.
12. Dashboard statistics.
13. Alerts for high-risk messages.
14. Flutter connection to the backend.
15. Basic parent dashboard.
16. Automated backend tests.

---

## 19. Planned Features

The following features are planned for future development:

- Real Hebrew AI/NLP model.
- Batch message analysis.
- Admin role and admin panel.
- Audit log.
- Password-reset flow.
- Refresh tokens.
- PostgreSQL deployment.
- Docker support.
- Flutter integration.
- Notifications.
- Privacy and data-retention controls.

---

## 20. Suggested Team Responsibilities

### Student 1 - Flutter Frontend

Responsibilities:

- Flutter project.
- Registration page.
- Login page.
- JWT token storage.
- Parent dashboard.
- Child management screens.
- Message submission form.
- Message history page.
- Alerts and reports UI.
- Dashboard statistics UI.
- API communication.

### Student 2 - Backend and Database

Responsibilities:

- FastAPI server.
- Authentication.
- Authorization.
- JWT.
- API endpoints.
- SQLAlchemy models.
- Database operations.
- Child ownership.
- Message storage.
- Prediction storage.
- Message history.
- Dashboard statistics.
- Alerts API.
- Automated backend tests.

### Student 3 - AI/NLP

Responsibilities:

- Hebrew dataset.
- Text preprocessing.
- Model training.
- Model evaluation.
- Message classification.
- Confidence calculation.
- Risk-level logic.
- Integration with the backend function contract.

---

## 21. Recommended Technologies

### Client

- Flutter.
- Dart.

### Backend

- Python.
- FastAPI.
- Uvicorn.
- Pydantic.
- SQLAlchemy.
- JWT.
- Passlib.
- python-dotenv.

### AI/NLP

- Python.
- Gemini API.
- google-genai SDK.
- Prompt-based Hebrew text classification.
- Local rule-based fallback classifier.

### Database

- SQLite for development.
- PostgreSQL for deployment.

### Testing

- pytest.
- FastAPI TestClient.

### Development Tools

- Git.
- GitHub.
- Postman.
- Swagger UI.
- VS Code or PyCharm.
- Docker in a later phase.

---

## 22. Security and Privacy Notes

The project processes potentially sensitive messages involving children.

During development:

- Use only simulated or anonymous data.
- Do not upload real private conversations.
- Do not commit secret keys.
- Do not commit access tokens.
- Do not commit the local database.
- Do not store plain-text passwords.
- Keep the `.env` file outside Git.
- Limit every parent to their own data.
- Make sure alerts and dashboard statistics are filtered by the authenticated parent.

A production version would require additional security, privacy, legal, encryption, and data-retention controls.

---

## 23. Git Workflow

The team uses one shared GitHub repository.

Recommended workflow:

```text
main
├── frontend feature branches
├── backend feature branches
├── AI/NLP feature branches
└── documentation branches
```

Each task should be developed on a separate branch.

After testing:

1. Commit the changes.
2. Push the branch.
3. Open a Pull Request.
4. Let another team member review the changes.
5. Merge the Pull Request into `main`.
6. Update all local branches from `main`.