import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/buyer.dart';
import '../models/expo.dart';
import '../models/product_price.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _buyersCol => _db.collection('buyers');
  CollectionReference<Map<String, dynamic>> get _exposCol => _db.collection('expos');
  CollectionReference<Map<String, dynamic>> get _pricesCol => _db.collection('prices');
  CollectionReference<Map<String, dynamic>> get _historyCol => _db.collection('price_history');

  // ===========================================================================
  // 1. BUYERS CRUD & REALTIME STREAMS
  // ===========================================================================

  Stream<List<Buyer>> streamBuyers() {
    return _buyersCol.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return Buyer.fromJson(doc.data());
      }).toList();
      list.sort((a, b) => a.srNo.compareTo(b.srNo));
      return list;
    });
  }

  Future<List<Buyer>> fetchBuyers() async {
    try {
      final snapshot = await _buyersCol.get();
      final list = snapshot.docs.map((doc) => Buyer.fromJson(doc.data())).toList();
      list.sort((a, b) => a.srNo.compareTo(b.srNo));
      return list;
    } catch (e) {
      debugPrint('FirestoreService: fetchBuyers error: $e');
      return [];
    }
  }

  Future<bool> saveBuyer(Buyer buyer) async {
    try {
      final docId = buyer.id.isNotEmpty ? buyer.id : Buyer.formatBuyerId(buyer.srNo);
      await _buyersCol.doc(docId).set(buyer.toJson(), SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('FirestoreService: saveBuyer error: $e');
      return false;
    }
  }

  Future<bool> deleteBuyer(String id) async {
    try {
      await _buyersCol.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('FirestoreService: deleteBuyer error: $e');
      return false;
    }
  }

  Future<int> batchSaveBuyers(List<Buyer> buyers) async {
    int count = 0;
    try {
      // Firestore batch limit is 500 writes
      const int batchSize = 400;
      for (int i = 0; i < buyers.length; i += batchSize) {
        final batch = _db.batch();
        final end = (i + batchSize < buyers.length) ? i + batchSize : buyers.length;
        for (int j = i; j < end; j++) {
          final b = buyers[j];
          final docId = b.id.isNotEmpty ? b.id : Buyer.formatBuyerId(b.srNo);
          batch.set(_buyersCol.doc(docId), b.toJson(), SetOptions(merge: true));
          count++;
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('FirestoreService: batchSaveBuyers error: $e');
    }
    return count;
  }

  // ===========================================================================
  // 2. EXPOS CRUD & REALTIME STREAMS
  // ===========================================================================

  Stream<List<ExpoItem>> streamExpos() {
    return _exposCol.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ExpoItem.fromJson(doc.data())).toList();
    });
  }

  Future<List<ExpoItem>> fetchExpos() async {
    try {
      final snapshot = await _exposCol.get();
      return snapshot.docs.map((doc) => ExpoItem.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('FirestoreService: fetchExpos error: $e');
      return [];
    }
  }

  Future<bool> saveExpo(ExpoItem expo) async {
    try {
      await _exposCol.doc(expo.id).set(expo.toJson(), SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('FirestoreService: saveExpo error: $e');
      return false;
    }
  }

  Future<bool> deleteExpo(String id) async {
    try {
      await _exposCol.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('FirestoreService: deleteExpo error: $e');
      return false;
    }
  }

  Future<int> batchSaveExpos(List<ExpoItem> expos) async {
    int count = 0;
    try {
      final batch = _db.batch();
      for (final e in expos) {
        batch.set(_exposCol.doc(e.id), e.toJson(), SetOptions(merge: true));
        count++;
      }
      await batch.commit();
    } catch (e) {
      debugPrint('FirestoreService: batchSaveExpos error: $e');
    }
    return count;
  }

  // ===========================================================================
  // 3. PRODUCT PRICES & HISTORY
  // ===========================================================================

  Stream<List<ProductPrice>> streamPrices() {
    return _pricesCol.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ProductPrice.fromJson(doc.data())).toList();
    });
  }

  Future<List<ProductPrice>> fetchPrices() async {
    try {
      final snapshot = await _pricesCol.get();
      return snapshot.docs.map((doc) => ProductPrice.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('FirestoreService: fetchPrices error: $e');
      return [];
    }
  }

  Future<bool> savePrice(ProductPrice price) async {
    try {
      await _pricesCol.doc(price.id).set(price.toJson(), SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('FirestoreService: savePrice error: $e');
      return false;
    }
  }

  Future<bool> deletePrice(String productId) async {
    try {
      await _pricesCol.doc(productId).delete();
      return true;
    } catch (e) {
      debugPrint('FirestoreService: deletePrice error: $e');
      return false;
    }
  }

  Future<int> batchSavePrices(List<ProductPrice> prices) async {
    int count = 0;
    try {
      final batch = _db.batch();
      for (final p in prices) {
        batch.set(_pricesCol.doc(p.id), p.toJson(), SetOptions(merge: true));
        count++;
      }
      await batch.commit();
    } catch (e) {
      debugPrint('FirestoreService: batchSavePrices error: $e');
    }
    return count;
  }

  Future<List<PriceHistoryItem>> fetchPriceHistory() async {
    try {
      final snapshot = await _historyCol.orderBy('recordedAt', descending: true).get();
      return snapshot.docs.map((doc) => PriceHistoryItem.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('FirestoreService: fetchPriceHistory error: $e');
      return [];
    }
  }

  Future<bool> savePriceHistory(PriceHistoryItem item) async {
    try {
      final docId = item.historyId.isNotEmpty ? item.historyId : '${item.productId}_${item.recordedAt}';
      await _historyCol.doc(docId).set(item.toJson(), SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('FirestoreService: savePriceHistory error: $e');
      return false;
    }
  }

  Future<int> batchSavePriceHistory(List<PriceHistoryItem> items) async {
    int count = 0;
    try {
      const int batchSize = 400;
      for (int i = 0; i < items.length; i += batchSize) {
        final batch = _db.batch();
        final end = (i + batchSize < items.length) ? i + batchSize : items.length;
        for (int j = i; j < end; j++) {
          final item = items[j];
          final docId = item.historyId.isNotEmpty ? item.historyId : '${item.productId}_${item.recordedAt}';
          batch.set(_historyCol.doc(docId), item.toJson(), SetOptions(merge: true));
          count++;
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('FirestoreService: batchSavePriceHistory error: $e');
    }
    return count;
  }
}
