# PRIVACY POLICY AND END-USER DATA AGREEMENT FOR ADYAPAN ADMIN

**Effective Date:** June 08, 2026  
**Policy Reference ID:** ADYAPAN-ADMIN-PP-2026  

---

## 1. LEGAL FRAMEWORK AND DEFINITIONS
This Privacy Policy ("Policy") is a legally binding document that governs the data collection, processing, and protection practices of **Adyapan Admin** (hereinafter referred to as the "App", "Software", "we", "us", or "our").
The App is strictly classified as an **Internal Educational & School Management platform**. It is designed exclusively for authorized students, teachers, parents, and administrative staff ("Authorized Users") of our school.

*   **ENTERPRISE & SCHOOL USE ONLY:** This app is intended for registered members of the school only. There is no sign-up or registration mechanism within the App for the general public. Access is securely provisioned, created, and distributed solely by the School Administrator. Any unauthorized person cannot create an account or use this application.
*   **Centralized Admin Oversight:** All user accounts, access levels, class assignments, and data permissions are strictly controlled, audited, and revoked exclusively via the school's Centralized Admin Portal.
*   **Agreement to Terms:** By logging in, authenticating, or utilizing the App, you explicitly consent to the data processing modalities outlined in this document.

---

## 2. STRICT PURPOSE LIMITATION AND LAWFUL BASIS FOR PROCESSING
We process Personal Data based strictly on the legitimate educational and administrative tasks of the school, including managing student attendance, distributing homework/notes, tracking progress, and facilitating gamified learning. Data is collected exclusively to automate school workflows, eliminate manual entries, and provide a secure digital learning environment.

---

## 3. CATEGORICAL BREAKDOWN OF COLLECTED DATA

To fulfill its educational mandate, the App requires specific, explicit device-level permissions. We employ a principle of Data Minimization, collecting only what is absolutely critical.

### 3.1. Focus Shield Notification Policy (ACCESS_NOTIFICATION_POLICY)
*   **Core Functionality Declaration:** The App features a **Focus Shield** tool to help students minimize digital distractions while studying.
*   **DND Access:** To block notifications during active study hours, the App requests permission to manage the device's Do Not Disturb (DND) status (`ACCESS_NOTIFICATION_POLICY`).
*   **Data Protection Guarantee:** The Focus Shield operates entirely on-device. The App does **not** read, store, or transmit the contents of incoming notifications, message texts, or sender identities. No notification data ever leaves the device.

### 3.2. Media and Storage (READ_EXTERNAL_STORAGE / File Picker)
*   **Operational Necessity:** Students need to upload homework submissions, and teachers need to upload educational study notes and PDF documents.
*   **Processing Modality:** The App requests access to read device storage solely when the user triggers the attachment/upload flow. Only the specific documents, PDFs, or images manually selected by the user are read and uploaded. The App does **not** scan, read, or catalog any other personal files on the device.

### 3.3. Exact Data Fields Collected and Stored
To facilitate academic management, we store and sync the following educational details in our secure cloud database:

| Data Field | Purpose of Collection | Retention Period |
| :--- | :--- | :--- |
| **Account Credentials** | Email, Name, and password hash for secure login | Until account is deleted by Admin |
| **Attendance Logs** | Present/Absent/Excused timestamps for class records | Active academic year (purged after 180 days) |
| **Homework Files** | Submitted files, assignments, and notes for teacher grading | Active academic term |
| **Gamification Data** | Experience Points (XP), levels, and quiz progress for leaderboards | Duration of school enrollment |

---

## 4. GOOGLE PLAY CONSOLE DATA SAFETY DECLARATIONS

To ensure transparency, here is the exact mapping of data collected by Adyapan Admin as declared in the Google Play Console:

| Data Category | Data Type | Purpose of Collection | Sharing Status |
| :--- | :--- | :--- | :--- |
| **Personal Info** | Name, Email Address | Account Authentication & User Management | Not Shared |
| **Files & Docs** | Homework Uploads, PDF study notes | Academic Submissions & Material Distribution | Not Shared |
| **App Activity** | Interaction Logs (Attendance, Quizzes) | Academic Progress Reports & Leaderboard XP | Not Shared |
| **Diagnostics** | Crash Logs & Performance Stats | App Optimization & Bug Fixing | Not Shared |

*   **Encryption in Transit:** All data transmitted between the App and the server is encrypted using TLS 1.3 protocol.
*   **Data Deletion:** Users can request data deletion at any time, which will be processed within 30 days.

---

## 5. RIGOROUS COMPLIANCE WITH CHILDREN'S PRIVACY LAWS

Since the App is an educational platform used by children under the age of 13, we enforce strict compliance measures under **COPPA**, **FERPA**, and global student privacy frameworks:
*   **No Commercial Data Collection:** We do not collect student data for marketing, tracking, profiling, or behavioral advertising.
*   **No Ads or Trackers:** The App is 100% ad-free. No advertising SDKs, tracking pixels, or commercial analytical frameworks are integrated into this App.
*   **School Consent (COPPA compliant):** All student profiles are created directly by the school administration, which acts on behalf of parents to provide legal consent.
*   **FERPA Compliance:** Student educational records (grades, attendance, submissions) are held in strict confidence and are never disclosed to third parties without school authorization.

---

## 6. DEVICE SECURITY ARCHITECTURE AND ANTI-FRAUD MEASURES

Adyapan Admin implements the following security mechanisms to protect student and academic data:
*   **Root Detection:** The App performs an automated check at launch. If the device is rooted, access is denied to prevent data exploits.
*   **Single-Device Login Policy:** To prevent credential sharing, each student account is cryptographically bound to a single device using a unique pseudonymous identifier (`ANDROID_ID`). Logging in from a second device automatically terminates the previous session.
*   **Screenshot Prevention (FLAG_SECURE):** The App sets the `FLAG_SECURE` window flag on exam, grading, and dashboard screens. This programmatically prevents system screenshots, screen recording, and exposure in recent task switches to maintain academic integrity.
*   **Cleartext Traffic Prohibition:** All outbound communication is mandatorily routed over HTTPS/TLS. Plaintext HTTP connections are categorically blocked.

---

## 7. NO COOKIE, NO AD-TRACKING, AND NO BEHAVIORAL PROFILING

*   **Zero Cookies:** The App does not deploy or read HTTP cookies of any kind.
*   **Zero Cross-App Tracking:** The App does not employ cross-app tracking identifiers (like IDFA or GAID) for ads or profiling.
*   **Zero Ad SDKs:** The App does not contain any monetization SDKs.
*   **Analytics Scope:** The only analytics infrastructure present is Google Firebase Analytics, used exclusively for crash diagnostics and app stability monitoring.

---

## 8. DATA RETENTION AND DELETION PROTOCOLS

*   **Retention Lifecycle:** Data is retained strictly for the duration of the student's active enrollment.
*   **Right to Erasure:** Any Authorized User may request account and data purging by contacting the school administrator or by sending an email directly to **gulshankumarsps54@gmail.com**.
*   **Graduation Purge:** Upon student graduation or withdrawal from the school, their account data is automatically deactivated and permanently purged from databases within 180 days.

---

## 9. COMPLIANCE WITH INDIA'S DIGITAL PERSONAL DATA PROTECTION ACT, 2023 (DPDP ACT)

We comply with the provisions of India's **DPDP Act, 2023**:
*   **Data Fiduciary:** Adyapan Admin acts as the Data Fiduciary, determining the purpose of processing.
*   **Data Principal Rights:** Students and parents (Data Principals) have the right to access a summary of data, correct inaccuracies, request erasure, and nominate a representative in case of incapacity.
*   **Grievance Redressal:** Contact our Grievance Officer/DPO (listed in Section 11) for any concerns. We will acknowledge complaints within 24 hours and resolve them within 30 days.

---

## 10. GOVERNING LAW AND DISPUTE RESOLUTION

This Policy and any disputes arising hereunder shall be governed exclusively by and construed in accordance with the laws of **India**, including the Information Technology Act, 2000. Any legal action shall be instituted exclusively in the competent courts located in **Hyderabad, Telangana, India**.

---

## 11. LEGAL CONTACT, DPO, AND GRIEVANCE OFFICER

For matters pertaining to data protection, compliance audits, or privacy inquiries, contact our Grievance Officer:

*   **Data Protection & Grievance Officer:** Sai Charan
*   **Corporate Email:** niranjan@adyapan.com
*   **Website:** https://adyapanschool.com/
*   **Registered Address:** Sattva Magnus, behind Reliance Bazaar Shaikpet, Sabza Colony, Ambedkar Nagar, Toli Chowki, Hyderabad, Telangana 500008, India

---

## 12. INTELLECTUAL PROPERTY & COPYRIGHT DECLARATION
**© 2026 Adyapan Admin. All Rights Reserved.**  
Any unauthorized reproduction, redistribution, decompilation, reverse-engineering, or commercial cloning of this software, in whole or in part, is strictly prohibited. Any infringement will be met with immediate legal prosecution under the Indian Copyright Act, 1957.
