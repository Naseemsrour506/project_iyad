# SafeChat AI - Project Plan

## Project Name
SafeChat AI

## Project Description
SafeChat AI is a Hebrew cyberbullying detection system.
The system analyzes text messages, detects harmful or threatening content, classifies the message type, calculates a risk level, and displays alerts and reports for parents or administrators.

The project is designed as a smart web/mobile system with a Flutter client, backend server, database, and AI/NLP module.

## Main Goal
The main goal of the system is to help parents or school staff identify cyberbullying risks early by analyzing messages and showing clear warnings.

## System Type
The system will be built as a Flutter application that can support mobile and web platforms.

## Main Components

### 1. Client / Frontend
Technology: Flutter

Responsibilities:
- Login and register screens
- Parent dashboard
- Add child profile
- Upload or enter messages
- Display message analysis results
- Display alerts
- Display reports and statistics

### 2. Backend
Technology: Python FastAPI

Responsibilities:
- User authentication
- User roles
- Manage children profiles
- Manage messages
- Connect to the AI/NLP module
- Store analysis results
- Provide APIs for the client
- Generate reports

### 3. Database
Technology: PostgreSQL or SQLite for development

Main tables:
- Users
- Children
- Messages
- Predictions
- Alerts
- Audit Logs

### 4. AI / NLP Module
Technology: Python, scikit-learn

Responsibilities:
- Clean Hebrew text
- Detect offensive words
- Classify messages
- Calculate risk score
- Return category, risk level, confidence, and explanation

## User Roles

### Parent
- Add child profile
- Upload or enter messages
- View dangerous messages
- View alerts
- View reports

### Admin
- Manage users
- View system statistics
- Review flagged messages

### Child
- Optional role for simulation purposes

## Main Features

### MVP Features
1. User login and registration
2. Add child profile
3. Enter a message manually
4. Analyze message using AI/NLP
5. Show category and risk level
6. Save message and result in database
7. Show alerts dashboard
8. Show basic reports

### Advanced Features
1. Upload CSV file with messages
2. Batch message analysis
3. Charts and statistics
4. Export report to PDF
5. Email notification simulation
6. Admin panel
7. Audit log

## Suggested Team Responsibilities

### Student 1 - Frontend
- Flutter application
- Screens and UI
- Dashboard
- Alerts page
- Reports page

### Student 2 - Backend
- FastAPI server
- Authentication
- Database models
- API endpoints
- Integration with AI module

### Student 3 - AI / NLP
- Text cleaning
- Offensive words dictionary
- Machine learning model
- Risk score logic
- Prediction function

## Recommended Technologies

### Frontend
- Flutter
- Dart

### Backend
- Python
- FastAPI
- SQLAlchemy
- Pydantic
- JWT Authentication

### AI / NLP
- Python
- pandas
- numpy
- scikit-learn
- TF-IDF
- Logistic Regression or Naive Bayes

### Database
- PostgreSQL
- SQLite for early development

### Tools
- Git
- GitHub
- Postman
- Docker
- VS Code / PyCharm
