# SafeChat AI - Project Plan

## 1. Project Name

**SafeChat AI**

## 2. Project Description

SafeChat AI is a smart system for detecting cyberbullying and harmful messages in Hebrew.

The system allows a parent to register, log in, create child profiles, submit messages for analysis, and view the message classification and risk level.

The backend analyzes each message, stores the original message and its analysis result in a database, and returns a structured response to the client application.

The current classifier is a temporary rule-based implementation. It will later be replaced by a real AI/NLP model while keeping the same interface between the AI module and the backend.

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
- Allows each parent to access only their own children and messages.
- Provides a foundation for alerts, reports, and dashboard statistics.

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
      ├── Request validation
      └── Database operations
      |
      v
Temporary Rule-Based Hebrew Classifier
      |
      | Will later be replaced by an AI/NLP model
      v
SQLite Database
      |
      ├── Users
      ├── Children
      ├── Messages
      └── Predictions
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
- Display alerts and statistics in future versions.
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
- Return message history.
- Prevent users from accessing another user's data.

### 7.3 AI/NLP Module

Technology:

- Python.
- scikit-learn.
- pandas.
- NumPy.
- TF-IDF.
- Logistic Regression, Naive Bayes, or another classification model.

Responsibilities:

- Prepare and clean Hebrew text.
- Build or load a labeled dataset.
- Train a text classification model.
- Classify messages.
- Calculate confidence.
- Return a risk level.
- Return an explanation or classification reason.

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

Future tables may include:

- Alerts.
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
- Temporary Hebrew rule-based classifier.
- Message persistence.
- Prediction persistence.
- Message history endpoint.
- Filtering message history by child.
- Prevention of access to another parent's messages.
- Request and response validation using Pydantic.
- Automated unit and API tests.

Current automated test result:

```text
29 passed
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

---

## 14. AI/NLP Integration Status

The current backend uses a temporary rule-based Hebrew classifier.

The temporary classifier helps the team:

- Develop the backend before the final AI model is ready.
- Test the API connection.
- Test the database.
- Test the Flutter integration later.
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

The FastAPI endpoint should not need major changes when the final AI model is connected.

---

## 15. Current Testing Strategy

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
- Protected endpoint behavior.

Tests are executed with:

```bash
python -m pytest -q
```

Current result:

```text
29 passed
```

---

## 16. MVP Features

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
12. Flutter connection to the backend.
13. Basic parent dashboard.
14. Automated backend tests.

---

## 17. Planned Features

The following features are planned for future development:

- Real Hebrew AI/NLP model.
- Alerts for high-risk messages.
- Dashboard statistics.
- Message counts by risk level.
- Message counts by category.
- CSV file upload.
- Batch message analysis.
- Export reports.
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

## 18. Suggested Team Responsibilities

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

## 19. Recommended Technologies

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
- pandas.
- NumPy.
- scikit-learn.
- TF-IDF.
- Logistic Regression or Naive Bayes.

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

## 20. Security and Privacy Notes

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

A production version would require additional security, privacy, legal, encryption, and data-retention controls.

---

## 21. Git Workflow

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

