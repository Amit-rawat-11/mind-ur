# Mindur Firestore Data Inconsistency Report

This report analyzes the core reasons why data is sometimes partially stored or missing in Firestore in the Mindur app, specifically addressing issues with new user signups, missing user information, and failing food log entries.

---

## 1. Missing User Profile Data (Name, Email, Goals missing, but Journal Entries exist)

**Why this is happening:**
The problem originates in how user creation and subsequent actions (like saving a journal) are handled. You are observing documents that only contain `journalStreak` and no base profile data like `email` or `name`.

1. **Interrupted Sign-Up Flow:** 
   In `signup_service.dart`, the `signUp` method performs two major network operations sequentially:
   - Creates the user in Firebase Auth (`createUserWithEmailAndPassword`).
   - Creates the profile in Firestore (`userDoc.set`).
   If the user's internet drops, or if the app crashes/is closed *after* Auth creation but *before* the Firestore `set()` operation completes, an account exists in Firebase Auth but has no corresponding Firestore document.

2. **The "Merge: True" Trap in Journaling:**
   When a user without a complete base profile (due to the interruption above) uses the app and writes a journal entry, `FirestoreService.addJournalEntry` runs this code:
   ```dart
   await userDoc.set({
     'journalStreak': { ... }
   }, SetOptions(merge: true));
   ```
   `SetOptions(merge: true)` will quietly create the user document if it does not exist. However, it will *only* populate the fields provided—in this case, just the `journalStreak`. This perfectly explains why you sometimes see user documents containing only journal streaks without names, emails, or signup goals.

**How to fix it:**
- **Atomic Operations:** Rely on Firebase Cloud Functions to create the Firestore user document triggered by Auth (`functions.auth.user().onCreate()`) to ensure absolute consistency.
- **Login Verification:** In `LoginScreen`, check if the user's Firestore document exists upon login. If it doesn't exist, prompt them to complete their profile setup or rebuild the document using their Auth token details (like email and display name).

---

## 2. Personalization Data Missing (Goals, Pet selection)

**Why this is happening:**
The personalization data is saved in `PersonalizationScreen` at the very end of the flow (`_completePersonalization`):
```dart
await FirestoreService().saveUserPersonalization(...);
if (mounted) context.go(AppRoutes.journalNew);
```
- **Navigation/Lifecycle Race Condition:** 
  Users might navigate away or close the app while the Firestore operation is still in the pending queue.
- If the user bypasses or skips the personalization screens in any way (e.g., via a deep link, app restart, or Android back button behavior), the initialization never gets triggered, leaving these fields blank in Firestore.

**How to fix it:**
- Enforce check constraints at the app's root (or Splash/Auth wrapper). If a user document exists but `personalizedCompleted` is missing or false, permanently redirect them back to the Personalization screen until it is successfully written.

---

## 3. Specific Food Logging Failures

**Why this is happening:**
You noticed that `logFood` fails for specific food items without any visible crash.
This is heavily indicative of **unsupported numeric values** or **null reference errors** in the specific food object's data.

1. **NaN or Infinity:** If the food data comes from an external API or calculation where division by zero or a parsing error unexpectedly yields `NaN` (Not a Number) or `Infinity`, Firestore SDKs will fail to serialize and upload the document. It throws an exception.
2. **Silent Failure in Catch Block:** 
   In `FirestoreService.dart`, `logFood` uses a standard try-catch:
   ```dart
   } catch (e) {
     if (kDebugMode) {
       debugPrint("Error logging food: $e");
     }
   }
   ```
   In release mode (production), this `catch` block completely swallows the exception. The UI doesn't know it failed, the user doesn't see an error, and the data is lost. It just appears like "it doesn't respond the way it should".

**How to fix it:**
- **Data Validation Before Submission:** Validate the `FoodItem` before saving. Ensure `calories`, `quantity`, and `protein` are valid, finite numbers (`!value.isNaN && !value.isInfinite`). Use fallback values `0` if an API returns null.
- **Provide User Feedback:** Rethrow errors or return a status boolean from `logFood` so the UI can show a SnackBar telling the user, "Failed to log food item. Please try again."

---

## Summary
The issues stem from **network/lifecycle interruptions during signup**, **Firestore `merge: true` behavior** inadvertently masking missing base profiles, and **silent error suppression** hiding serialization exceptions (like `NaN`) when logging specific foods. 

Applying stricter app-load verification for user profiles and input validation on food logging will resolve these discrepancies without redesigning the database.
