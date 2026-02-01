import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Deletes all user data collected by the app from Firestore.
/// Does not delete the Firebase Auth account; caller should sign out after.
class DeleteAccountService {
  final FirebaseFirestore firestore;

  DeleteAccountService({required this.firestore});

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Deletes all documents in a collection (batch, max 500 per batch).
  Future<void> _deleteCollection(CollectionReference col) async {
    const int batchSize = 400;
    QuerySnapshot snapshot = await col.limit(batchSize).get();
    while (snapshot.docs.isNotEmpty) {
      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snapshot.docs.length < batchSize) break;
      snapshot = await col.limit(batchSize).get();
    }
  }

  /// Deletes all user data: profile, dailyGoals, dietPlan, foodItems,
  /// dailyFoodEntries (and nested entries), mealPlans. Then deletes the user document.
  /// Returns normally on success; throws on failure.
  Future<void> deleteAllUserData() async {
    if (_userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    final userRef = firestore.collection('users').doc(_userId);

    // 1. dailyGoals – subcollection (documents by date)
    final dailyGoalsRef = userRef.collection('dailyGoals');
    await _deleteCollection(dailyGoalsRef);

    // 2. dietPlan – subcollection
    final dietPlanRef = userRef.collection('dietPlan');
    await _deleteCollection(dietPlanRef);

    // 3. foodItems – nested: users/{userId}/foodItems/{manualFilledFood|barcodeScannedFood}/foodItems/{itemId}
    //    Must delete nested "foodItems" subcollection under each doc first, then delete the parent doc.
    final foodItemsRef = userRef.collection('foodItems');
    final categorySnap = await foodItemsRef.get();
    for (final categoryDoc in categorySnap.docs) {
      await _deleteCollection(categoryDoc.reference.collection('foodItems'));
      await categoryDoc.reference.delete();
    }

    // 4. dailyFoodEntries – each doc is a date; each has nested "entries" subcollection
    final dailyFoodEntriesRef = userRef.collection('dailyFoodEntries');
    final dateSnap = await dailyFoodEntriesRef.get();
    for (final dateDoc in dateSnap.docs) {
      await _deleteCollection(dateDoc.reference.collection('entries'));
      await dateDoc.reference.delete();
    }

    // 5. mealPlans – subcollection
    final mealPlansRef = userRef.collection('mealPlans');
    await _deleteCollection(mealPlansRef);

    // 6. User document (profile, etc.)
    await userRef.delete();
  }
}
