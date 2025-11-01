# Loan Manager App Architecture

## Overview
A comprehensive loan management system for small-scale loan managers with secure multi-user support, automated calculations, AI integration, and offline-first functionality.

## Tech Stack
- **Frontend**: Flutter/Dart with Material 3 design
- **Local Storage**: SharedPreferences for settings, JSON files for data
- **Backend**: Local storage with future cloud sync capability
- **AI Integration**: OpenAI GPT for natural language queries and insights
- **Design**: Modern, sophisticated monochrome with accent colors

## Core Features

### 1. Authentication & User Management
- Secure sign-in (email/password, phone OTP, biometrics)
- Multi-user support with isolated data
- User session management

### 2. Loan Management
- Add/edit/delete borrower records
- Automated interest calculations
- Processing fee handling
- Payment tracking and balance updates
- Loan status management (active, completed, overdue)

### 3. Financial Features
- Configurable interest rates and processing fees
- Monthly interest application
- Interest pause/resume functionality
- Payment recording (full, partial, custom)
- Balance and history tracking

### 4. Reporting & Analytics
- Generate PDF/Excel reports
- Daily, weekly, monthly, yearly views
- KPI dashboard
- Timeline view of transactions

### 5. Communication
- SMS reminder templates
- Dynamic message generation with placeholders
- Manual messaging capability
- Push notifications

### 6. AI Integration
- Natural language queries
- Repayment probability predictions
- Interest rate suggestions
- Risk assessment insights

## Data Models

### User
```dart
class User {
  String id;
  String name;
  String email;
  String phone;
  String passwordHash;
  DateTime createdAt;
  DateTime updatedAt;
}
```

### Borrower
```dart
class Borrower {
  String id;
  String userId; // Foreign key to User
  String name;
  String phone;
  String address;
  List<String> loanIds;
  DateTime createdAt;
  DateTime updatedAt;
}
```

### Loan
```dart
class Loan {
  String id;
  String userId; // Foreign key to User
  String borrowerId; // Foreign key to Borrower
  String loanCode;
  double capitalAmount;
  double processingFee;
  double currentBalance;
  double interestRate;
  DateTime startDate;
  DateTime dueDate;
  LoanStatus status;
  bool interestPaused;
  List<String> paymentIds;
  DateTime createdAt;
  DateTime updatedAt;
}
```

### Payment
```dart
class Payment {
  String id;
  String loanId; // Foreign key to Loan
  double amount;
  DateTime paymentDate;
  PaymentType type;
  String notes;
  DateTime createdAt;
}
```

### Settings
```dart
class Settings {
  String userId;
  double defaultInterestRate;
  double defaultProcessingFeePercentage;
  double defaultProcessingFeeFixed;
  String messageTemplate;
  String bankDetails;
  bool notificationsEnabled;
  ThemeMode themeMode;
  DateTime updatedAt;
}
```

## Service Classes

### AuthService
- User authentication and session management
- Secure credential storage
- Multi-user data isolation

### LoanService  
- CRUD operations for loans
- Interest calculation and application
- Balance updates and loan status management

### BorrowerService
- CRUD operations for borrowers
- Borrower search and filtering

### PaymentService
- Payment recording and tracking
- Payment history management

### SettingsService
- App configuration management
- Template and rate management

### ReportService
- Report generation (PDF/Excel)
- Data aggregation and analytics

### NotificationService
- SMS and push notification handling
- Message template processing

### AIService
- OpenAI integration for natural language processing
- Prediction and recommendation generation

## Screen Structure

### 1. Authentication Flow
- **LoginScreen**: Multi-option login (email/password, phone OTP, biometrics)
- **RegisterScreen**: New user registration

### 2. Main Navigation
- **DashboardScreen**: KPIs, active loans, overdue count, quick actions
- **LoansScreen**: List of all loans with search and filter
- **BorrowersScreen**: Borrower management and profiles  
- **PaymentsScreen**: Payment recording and history
- **ReportsScreen**: Report generation and analytics
- **AIAssistantScreen**: Natural language queries and insights
- **SettingsScreen**: App configuration and templates

### 3. Detail Screens
- **LoanDetailScreen**: Individual loan management
- **BorrowerDetailScreen**: Borrower profile and loan history
- **AddLoanScreen**: New loan creation with processing fee calculation
- **RecordPaymentScreen**: Payment entry form
- **ReportViewerScreen**: Generated report display

## Implementation Plan

### Phase 1: Core Foundation (Priority 1)
1. Set up project structure and dependencies
2. Implement theme and design system
3. Create data models and services
4. Build authentication system
5. Develop local storage infrastructure

### Phase 2: Loan Management (Priority 1)
1. Implement loan CRUD operations
2. Build borrower management system  
3. Create payment tracking functionality
4. Develop interest calculation engine
5. Add processing fee logic

### Phase 3: User Interface (Priority 1)
1. Build dashboard with KPIs
2. Create loan and borrower list screens
3. Implement add/edit loan forms
4. Develop payment recording interface
5. Add search and filter capabilities

### Phase 4: Advanced Features (Priority 2)
1. Implement report generation
2. Add messaging templates and notifications
3. Develop timeline and analytics views
4. Create settings management
5. Add data export functionality

### Phase 5: AI Integration (Priority 3)
1. Integrate OpenAI API
2. Implement natural language query processing
3. Add prediction and recommendation features
4. Develop AI insights dashboard

### Phase 6: Polish & Testing (Priority 3)
1. Comprehensive error handling
2. Performance optimization
3. UI/UX refinements
4. Testing and bug fixes
5. Documentation completion

## Design Principles
- **Sophisticated Monochrome**: Clean, professional appearance with minimal accent colors
- **Modern UI**: Generous spacing, rounded corners, card-based layouts
- **Accessibility**: High contrast, readable fonts, intuitive navigation
- **Responsive**: Adapts to different screen sizes and orientations
- **Performance**: Efficient data handling and smooth animations