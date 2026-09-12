import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:js' as js;
import '../models/buyer.dart';
import '../models/expo.dart';
import '../models/product_price.dart';

class ApiService {
  static const String defaultScriptUrl =
      'https://script.google.com/macros/s/AKfycbyOFxeG3sZp7Ccs8jlhfJ2osgQuQA2dHQ2pRZvNel7fL9ol82clds3fpKkRr1aNmP6C/exec';

  static const String sheetGvizCsvUrl =
      'https://docs.google.com/spreadsheets/d/1jtqUJxkvQoyxTccC1gOUv1WejJigm7DMX9P66OyrhuA/gviz/tq?tqx=out:csv&sheet=Sheet1';

  String _scriptUrl = defaultScriptUrl;
  bool _isConnected = true;

  String get scriptUrl => _scriptUrl;
  bool get isConnected => _isConnected;

  void updateUrl(String url) {
    if (url.trim().isNotEmpty) {
      _scriptUrl = url.trim();
    }
  }

  static String cleanWebsiteUrl(String rawStr) {
    if (rawStr.isEmpty) return 'N/A';
    String s = rawStr.trim();
    if (s.contains('@')) return 'N/A';
    if (s.toLowerCase() == 'n/a' || s == '-' || s.length < 4) return 'N/A';

    final urlReg = RegExp(r'(https?://[^\s,]+|[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/[^\s,]*)?)');
    final match = urlReg.firstMatch(s);
    if (match != null) {
      String found = match.group(0)!;
      if (!found.startsWith('http://') && !found.startsWith('https://')) {
        found = 'https://$found';
      }
      return found;
    }
    return 'N/A';
  }

  static String cleanPhoneStr(String rawStr) {
    if (rawStr.isEmpty) return '';
    String s = rawStr.trim();
    if (s.startsWith("'")) s = s.substring(1).trim();
    final lower = s.toLowerCase();
    if (lower == '#error!' ||
        lower.contains('#error') ||
        lower == '#ref!' ||
        lower == '#value!' ||
        lower == '#n/a' ||
        lower == 'n/a' ||
        lower == '-' ||
        lower == 'null') {
      return '';
    }
    return s;
  }

  static String cleanEmailStr(String rawStr) {
    if (rawStr.isEmpty) return '';
    final split = rawStr.split(RegExp(r'[,;/]'));
    final List<String> valid = [];
    for (var s in split) {
      final clean = s.replaceAll('"', '').trim();
      if (clean.contains('@') && !valid.contains(clean)) {
        valid.add(clean);
      }
    }
    return valid.join(', ');
  }

  List<Buyer>? _cachedBuyers;

  Future<List<Buyer>> fetchBuyers({String? customScriptUrl, bool forceRefresh = false}) async {
    // On web: always fetch fresh data so deleted/edited rows never come back from stale cache
    if (kIsWeb) forceRefresh = true;

    if (!forceRefresh && _cachedBuyers != null && _cachedBuyers!.isNotEmpty) {
      return _cachedBuyers!;
    }

    final targetScriptUrl = (customScriptUrl != null && customScriptUrl.trim().isNotEmpty)
        ? customScriptUrl.trim()
        : _scriptUrl;

    // 1. Direct Apps Script API fetch with cache-busting timestamp (fetches LIVE data from Google Sheet!)
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final response = await http.get(
        Uri.parse('$targetScriptUrl?action=getBuyers&_t=$timestamp'),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        _isConnected = true;
        final decoded = json.decode(response.body);
        List<Buyer> list = [];
        List? buyerList;

        if (decoded is List) {
          buyerList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['buyers'] is List) {
            buyerList = decoded['buyers'];
          } else if (decoded['data'] is List) {
            buyerList = decoded['data'];
          }
        }

        if (buyerList != null) {
          for (int i = 0; i < buyerList.length; i++) {
            final item = buyerList[i];
            if (item is Map<String, dynamic>) {
              list.add(Buyer.fromJson(item, i + 1));
            }
          }
          // No deduplication — show every row as a separate buyer (Sr. No. = primary key)
          if (list.isNotEmpty) {
            _cachedBuyers = list;
            return list;
          }
        }
      }
    } catch (e) {
      debugPrint('ApiService: Direct Apps Script fetch exception: $e. Using CSV fallback.');
    }

    // 2. Fallback to Google Sheets GVIZ CSV if Apps Script GET failed
    final csvBuyers = await fetchBuyersViaCsv();
    if (csvBuyers.isNotEmpty) {
      _cachedBuyers = csvBuyers;
      return csvBuyers;
    }

    return [];
  }

  Future<List<Buyer>> fetchBuyersViaCsv() async {
    try {
      final response = await http.get(Uri.parse(sheetGvizCsvUrl)).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        _isConnected = true;
        return parseCsvData(response.body);
      }
    } catch (e) {
      _isConnected = false;
      debugPrint('Error fetching CSV: $e');
    }
    return [];
  }

  List<Buyer> parseCsvData(String csvText) {
    final List<Buyer> list = [];
    final lines = LineSplitter.split(csvText).toList();
    if (lines.isEmpty) return list;

    int counter = 1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || line.startsWith('Amar Foods') || line.contains('Sr. No.') || line.contains('Importer Company')) continue;

      final row = _splitCsvRow(line);
      if (row.length < 2) continue;

      int offset = 0;
      if (row.isNotEmpty && row[0].replaceAll('"', '').trim().isEmpty) {
        offset = 1;
      }

      String srNoStr = row.length > offset ? row[offset].replaceAll('"', '').trim() : '';
      int srNo = int.tryParse(srNoStr) ?? counter;

      String company = row.length > offset + 1 ? row[offset + 1].replaceAll('"', '').trim() : '';
      String rawWebsite = row.length > offset + 2 ? row[offset + 2].replaceAll('"', '').trim() : '';
      String rawEmail = row.length > offset + 3 ? row[offset + 3].replaceAll('"', '').trim() : '';
      String phone = cleanPhoneStr(row.length > offset + 4 ? row[offset + 4].replaceAll('"', '').trim() : '');
      String method = row.length > offset + 5 ? row[offset + 5].replaceAll('"', '').trim() : 'Email';
      String connDate = row.length > offset + 6 ? row[offset + 6].replaceAll('"', '').trim() : '';
      String firstEmailDate = row.length > offset + 7 ? row[offset + 7].replaceAll('"', '').trim() : '';
      String followUpDate = row.length > offset + 8 ? row[offset + 8].replaceAll('"', '').trim() : '';
      String clientReply = row.length > offset + 9 ? row[offset + 9].replaceAll('"', '').trim() : 'Pending';

      String website = cleanWebsiteUrl(rawWebsite);
      String email = cleanEmailStr(rawEmail);

      final cleanComp = company.trim().toLowerCase();
      final cleanEmail = email.trim().toLowerCase();
      final cleanWeb = website.trim().toLowerCase();

      bool isCompEmpty = cleanComp.isEmpty || cleanComp == 'n/a' || cleanComp == '-';
      bool isEmailEmpty = cleanEmail.isEmpty || cleanEmail == 'n/a' || cleanEmail == '-';
      bool isWebEmpty = cleanWeb.isEmpty || cleanWeb == 'n/a' || cleanWeb == '-';

      // Skip any completely blank or non-actionable rows
      if (isCompEmpty && isEmailEmpty && isWebEmpty) continue;

      if (isCompEmpty) {
        if (!isWebEmpty) {
          company = website.replaceAll('https://', '').replaceAll('http://', '').replaceAll('www.', '').split('/')[0];
        } else if (!isEmailEmpty) {
          company = email.split('@')[0];
        } else {
          company = 'Importer #$counter';
        }
      }

      if (clientReply.isEmpty || clientReply == '-') clientReply = 'Pending';

      String status = 'New';
      if (clientReply.toLowerCase() == 'yes') {
        status = 'Converted';
      } else if (clientReply.toLowerCase() == 'hold') {
        status = 'On Hold';
      } else if (firstEmailDate.isNotEmpty) {
        status = 'First Email Sent';
      }

      String marketType = 'International';
      if (row.length > offset + 10) {
        for (int c = offset + 10; c < row.length; c++) {
          final val = row[c].replaceAll('"', '').trim();
          if (val.toLowerCase() == 'domestic' || val.toLowerCase() == 'dom') {
            marketType = 'Domestic';
            break;
          }
        }
      }

      list.add(Buyer(
        id: Buyer.formatBuyerId(srNo > 0 ? srNo : counter),
        srNo: srNo > 0 ? srNo : counter,
        company: company,
        website: website,
        email: email,
        phone: phone,
        connectionMethod: method.isEmpty ? 'Email' : method,
        connectionDate: connDate,
        firstEmailDate: firstEmailDate,
        nextDueDate: followUpDate,
        clientReply: clientReply,
        lastEmailDate: firstEmailDate,
        notes: '',
        status: status,
        nextAction: 'Follow-Up',
        followupCount: 0,
        marketType: marketType,
      ));

      counter++;
    }

    // Return list as-is — no deduplication, each Sr. No. row is a separate buyer
    return list;
  }

  List<Buyer> mergeDuplicateCompanies(List<Buyer> rawList) {
    final Map<String, Buyer> map = {};
    final Map<String, Set<String>> emailsMap = {};

    for (var b in rawList) {
      String key = b.company.trim().toLowerCase();

      Set<String> emailSet = emailsMap.putIfAbsent(key, () => <String>{});
      if (b.email.isNotEmpty && b.email != 'no@no') {
        final split = b.email.split(RegExp(r'[,;/]'));
        for (var e in split) {
          final clean = e.trim();
          if (clean.contains('@')) {
            emailSet.add(clean);
          }
        }
      }

      if (!map.containsKey(key)) {
        map[key] = b;
      } else {
        final existing = map[key]!;
        String mergedWebsite = (existing.website.trim().isNotEmpty && existing.website != 'N/A' && existing.website != '-')
            ? existing.website
            : b.website;
        String mergedPhone = existing.phone.isNotEmpty ? existing.phone : b.phone;
        String mergedConnDate = existing.connectionDate.isNotEmpty ? existing.connectionDate : b.connectionDate;
        String mergedFirstEmail = existing.firstEmailDate.isNotEmpty ? existing.firstEmailDate : b.firstEmailDate;
        String mergedLastEmail = existing.lastEmailDate.isNotEmpty ? existing.lastEmailDate : b.lastEmailDate;
        String mergedNextDue = existing.nextDueDate.isNotEmpty ? existing.nextDueDate : b.nextDueDate;
        int maxCount = existing.followupCount > b.followupCount ? existing.followupCount : b.followupCount;

        String mergedNotes = existing.notes;
        if (b.notes.isNotEmpty && !mergedNotes.contains(b.notes)) {
          mergedNotes = mergedNotes.isEmpty ? b.notes : '$mergedNotes | ${b.notes}';
        }

        map[key] = existing.copyWith(
          website: mergedWebsite,
          phone: mergedPhone,
          connectionDate: mergedConnDate,
          firstEmailDate: mergedFirstEmail,
          lastEmailDate: mergedLastEmail,
          nextDueDate: mergedNextDue,
          followupCount: maxCount,
          notes: mergedNotes,
        );
      }
    }

    final List<Buyer> result = [];
    for (var entry in map.entries) {
      final b = entry.value;
      final emailSet = emailsMap[entry.key] ?? {};
      final mergedEmailsStr = emailSet.join(', ');
      result.add(b.copyWith(
        email: mergedEmailsStr.isNotEmpty ? mergedEmailsStr : b.email,
      ));
    }

    return result;
  }

  List<String> _splitCsvRow(String line) {
    final List<String> result = [];
    bool inQuotes = false;
    StringBuffer sb = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(sb.toString());
        sb.clear();
      } else {
        sb.write(char);
      }
    }
    result.add(sb.toString());
    return result;
  }

  Future<bool> saveBuyer(Buyer buyer) async {
    return updateBuyerOnSheet(buyer);
  }

  /// Delete a buyer row from Google Sheet by its Sr. No. (Column A).
  Future<bool> deleteBuyerBySrNo(int srNo, {String? customScriptUrl}) async {
    final targetScriptUrl = (customScriptUrl != null && customScriptUrl.trim().isNotEmpty)
        ? customScriptUrl.trim()
        : _scriptUrl;

    final String getUrl = '$targetScriptUrl?action=deleteBuyer&id=${Uri.encodeComponent(srNo.toString())}';
    final String postBody = json.encode({
      'action': 'deleteBuyer',
      'id': srNo.toString(),
      'srNo': srNo,
    });

    _cachedBuyers = null; // Always clear cache so next fetch is fresh

    if (kIsWeb) {
      try {
        // 1. Direct POST fetch with text/plain body (no-cors)
        js.context.callMethod('fetch', [
          targetScriptUrl,
          js.JsObject.jsify({
            'method': 'POST',
            'mode': 'no-cors',
            'headers': {'Content-Type': 'text/plain;charset=utf-8'},
            'body': postBody,
          }),
        ]);

        // 2. Secondary GET via XHR
        js.context.callMethod('eval', ['''
          (function() {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", "$getUrl", true);
            xhr.send();
          })();
        ''']);
        debugPrint('ApiService: deleteBuyerBySrNo($srNo) sent via POST & GET');
        return true;
      } catch (e) {
        debugPrint('ApiService: Web deleteBuyerBySrNo error: $e');
      }
    }

    try {
      final response = await http.post(
        Uri.parse(targetScriptUrl),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: postBody,
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 || response.statusCode == 302) {
        return true;
      }
    } catch (e) {
      debugPrint('ApiService: HTTP POST deleteBuyerBySrNo error: $e');
    }
    return true; // Optimistic: local state already updated
  }

  /// Calls Apps Script to sequentially renumber all buyers in Sheet1 Column A from 1 to N.
  Future<bool> renumberBuyersOnSheet({String? customScriptUrl}) async {
    final targetScriptUrl = (customScriptUrl != null && customScriptUrl.trim().isNotEmpty)
        ? customScriptUrl.trim()
        : _scriptUrl;

    final String getUrl = '$targetScriptUrl?action=renumberBuyers';
    final String postBody = json.encode({'action': 'renumberBuyers'});

    if (kIsWeb) {
      try {
        js.context.callMethod('fetch', [
          targetScriptUrl,
          js.JsObject.jsify({
            'method': 'POST',
            'mode': 'no-cors',
            'headers': {'Content-Type': 'text/plain;charset=utf-8'},
            'body': postBody,
          }),
        ]);
        js.context.callMethod('eval', ['''
          (function() {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", "$getUrl", true);
            xhr.send();
          })();
        ''']);
        return true;
      } catch (e) {
        debugPrint('ApiService: Web renumberBuyersOnSheet error: $e');
      }
    }

    try {
      final response = await http.post(
        Uri.parse(targetScriptUrl),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: postBody,
      ).timeout(const Duration(seconds: 8));
      return response.statusCode == 200 || response.statusCode == 302;
    } catch (e) {
      debugPrint('ApiService: HTTP POST renumberBuyersOnSheet error: $e');
    }
    return true;
  }

  Future<int> batchMarkSent(List<String> buyerIds, {bool sendEmail = false}) async {
    return buyerIds.length;
  }

  Future<bool> updateBuyerOnSheet(Buyer buyer, {String? customScriptUrl}) async {
    final targetScriptUrl = (customScriptUrl != null && customScriptUrl.trim().isNotEmpty)
        ? customScriptUrl.trim()
        : _scriptUrl;

    final String buyerJson = json.encode(buyer.toJson());
    final String base64Payload = base64Encode(utf8.encode(buyerJson));
    final String getUrl = '$targetScriptUrl?action=updateBuyer&payload=${Uri.encodeComponent(base64Payload)}';
    final String postBody = json.encode({
      'action': 'updateBuyer',
      'buyer': buyer.toJson(),
    });

    _cachedBuyers = null;

    if (kIsWeb) {
      try {
        // 1. Direct POST fetch with text/plain body (no-cors) - standard for web-to-Apps-Script
        js.context.callMethod('fetch', [
          targetScriptUrl,
          js.JsObject.jsify({
            'method': 'POST',
            'mode': 'no-cors',
            'headers': {'Content-Type': 'text/plain;charset=utf-8'},
            'body': postBody,
          }),
        ]);

        // 2. Secondary GET via XHR
        js.context.callMethod('eval', ['''
          (function() {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", "$getUrl", true);
            xhr.send();
          })();
        ''']);
        debugPrint('ApiService: updateBuyerOnSheet sent via POST & GET');
        return true;
      } catch (e) {
        debugPrint('ApiService: Web updateBuyer error: $e');
      }
    }

    try {
      final response = await http.post(
        Uri.parse(targetScriptUrl),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: postBody,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 || response.statusCode == 302) {
        _cachedBuyers = null;
        return true;
      }
    } catch (e) {
      debugPrint('ApiService: HTTP POST updateBuyer failed: $e');
    }
    return false;
  }

  Future<bool> batchUpdateBuyersOnSheet(List<Buyer> buyers, {String? customScriptUrl}) async {
    final targetScriptUrl = (customScriptUrl != null && customScriptUrl.trim().isNotEmpty)
        ? customScriptUrl.trim()
        : _scriptUrl;

    try {
      final body = json.encode({
        'action': 'batchUpdateBuyers',
        'buyers': buyers.map((b) => b.toJson()).toList(),
      });

      final response = await http.post(
        Uri.parse(targetScriptUrl),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: body,
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200 || response.statusCode == 302) {
        return true;
      }
    } catch (e) {
      debugPrint('Error batch updating buyers on Google Sheet: $e');
    }
    return false;
  }

  // ------------------------------------------------------------------
  // EXPOS GOOGLE SHEET API SYNC
  // ------------------------------------------------------------------

  Future<List<ExpoItem>> fetchExpos({String? customScriptUrl}) async {
    final targetScriptUrl = (customScriptUrl != null && customScriptUrl.trim().isNotEmpty)
        ? customScriptUrl.trim()
        : _scriptUrl;

    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final response = await http.get(
        Uri.parse('$targetScriptUrl?action=getExpos&_t=$timestamp'),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List? exposList;
        if (decoded is List) {
          exposList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['expos'] is List) {
            exposList = decoded['expos'];
          } else if (decoded['data'] is List) {
            exposList = decoded['data'];
          }
        }

        if (exposList != null) {
          return exposList.map((e) => ExpoItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
    } catch (e) {
      debugPrint('ApiService: fetchExpos exception: $e');
    }
    return [];
  }

  Future<bool> saveExpoOnSheet(ExpoItem expo, {String? customScriptUrl}) async {
    final targetScriptUrl = (customScriptUrl != null && customScriptUrl.trim().isNotEmpty)
        ? customScriptUrl.trim()
        : _scriptUrl;

    final String payloadJson = json.encode(expo.toJson());
    final String base64Payload = base64Encode(utf8.encode(payloadJson));
    final String getUrl = '$targetScriptUrl?action=updateExpo&payload=${Uri.encodeComponent(base64Payload)}';
    final String postBody = json.encode({
      'action': 'updateExpo',
      'expo': expo.toJson(),
    });

    if (kIsWeb) {
      try {
        // 1. Direct POST fetch with text/plain body (no-cors) - standard for web-to-Apps-Script
        js.context.callMethod('fetch', [
          targetScriptUrl,
          js.JsObject.jsify({
            'method': 'POST',
            'mode': 'no-cors',
            'headers': {'Content-Type': 'text/plain;charset=utf-8'},
            'body': postBody,
          }),
        ]);

        // 2. Secondary GET via XHR
        js.context.callMethod('eval', ['''
          (function() {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", "$getUrl", true);
            xhr.send();
          })();
        ''']);
        debugPrint('ApiService: saveExpoOnSheet sent via POST & GET');
        return true;
      } catch (e) {
        debugPrint('ApiService: Web saveExpoOnSheet error: $e');
      }
    }

    try {
      final response = await http.post(
        Uri.parse(targetScriptUrl),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: postBody,
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 || response.statusCode == 302) return true;
    } catch (e) {
      debugPrint('ApiService: HTTP POST updateExpo failed: $e');
    }
    return true;
  }

  Future<bool> deleteExpoFromSheet(String expoId, {String? customScriptUrl}) async {
    final targetScriptUrl = (customScriptUrl != null && customScriptUrl.trim().isNotEmpty)
        ? customScriptUrl.trim()
        : _scriptUrl;

    final String getUrl = '$targetScriptUrl?action=deleteExpo&id=${Uri.encodeComponent(expoId)}';
    final String postBody = json.encode({
      'action': 'deleteExpo',
      'id': expoId,
    });

    if (kIsWeb) {
      try {
        js.context.callMethod('fetch', [
          targetScriptUrl,
          js.JsObject.jsify({
            'method': 'POST',
            'mode': 'no-cors',
            'headers': {'Content-Type': 'text/plain;charset=utf-8'},
            'body': postBody,
          }),
        ]);
        js.context.callMethod('eval', ['''
          (function() {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", "$getUrl", true);
            xhr.send();
          })();
        ''']);
        debugPrint('ApiService: deleteExpoFromSheet sent via POST & GET');
        return true;
      } catch (e) {
        debugPrint('ApiService: Web deleteExpoFromSheet error: $e');
      }
    }

    try {
      final response = await http.post(
        Uri.parse(targetScriptUrl),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: postBody,
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 || response.statusCode == 302) return true;
    } catch (e) {
      debugPrint('ApiService: HTTP deleteExpo failed: $e');
    }
    return true;
  }

  // ------------------------------------------------------------------
  // 3. PRODUCT PRICE LIST & HISTORY API
  // ------------------------------------------------------------------

  Future<List<ProductPrice>> fetchPrices({String? customScriptUrl}) async {
    final targetScriptUrl = (customScriptUrl != null && customScriptUrl.trim().isNotEmpty)
        ? customScriptUrl.trim()
        : _scriptUrl;

    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final response = await http.get(
        Uri.parse('$targetScriptUrl?action=getPrices&_t=$timestamp'),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List? priceList;
        if (decoded is List) {
          priceList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['prices'] is List) {
            priceList = decoded['prices'];
          } else if (decoded['data'] is List) {
            priceList = decoded['data'];
          }
        }

        if (priceList != null && priceList.isNotEmpty) {
          return priceList
              .map((e) => ProductPrice.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('ApiService: fetchPrices exception: $e');
    }
    return getDefaultPrices();
  }

  /// Save or update a single product price in Google Sheets (PriceList tab + PriceHistory upsert)
  Future<bool> saveProductPrice(
    ProductPrice price, {
    String? weekLabel,
    String? customScriptUrl,
  }) async {
    final targetScriptUrl = (customScriptUrl != null && customScriptUrl.trim().isNotEmpty)
        ? customScriptUrl.trim()
        : _scriptUrl;

    final Map<String, dynamic> payload = {
      'action': 'saveProductPrice',
      'weekLabel': weekLabel ?? 'Daily Spot Rate',
      'price': price.toJson(),
    };

    final String payloadJson = json.encode(payload);
    final String base64Payload = base64Encode(utf8.encode(payloadJson));
    final String getUrl = '$targetScriptUrl?action=saveProductPrice&payload=${Uri.encodeComponent(base64Payload)}';

    if (kIsWeb) {
      try {
        js.context.callMethod('fetch', [
          targetScriptUrl,
          js.JsObject.jsify({
            'method': 'POST',
            'mode': 'no-cors',
            'headers': {'Content-Type': 'text/plain;charset=utf-8'},
            'body': payloadJson,
          }),
        ]);

        js.context.callMethod('eval', ['''
          (function() {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", "$getUrl", true);
            xhr.send();
          })();
        ''']);
        debugPrint('ApiService: saveProductPrice(${price.id}) sent via POST & GET');
        return true;
      } catch (e) {
        debugPrint('ApiService: Web saveProductPrice error: $e');
      }
    }

    try {
      final response = await http.post(
        Uri.parse(targetScriptUrl),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: payloadJson,
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 || response.statusCode == 302) return true;
    } catch (e) {
      debugPrint('ApiService: HTTP saveProductPrice failed: $e');
    }
    return true;
  }

  /// Delete a product from Google Sheet PriceList tab by ID
  Future<bool> deleteProductPrice(
    String productId, {
    String? customScriptUrl,
  }) async {
    final targetScriptUrl = (customScriptUrl != null && customScriptUrl.trim().isNotEmpty)
        ? customScriptUrl.trim()
        : _scriptUrl;

    final String getUrl = '$targetScriptUrl?action=deleteProductPrice&id=${Uri.encodeComponent(productId)}';
    final String postBody = json.encode({
      'action': 'deleteProductPrice',
      'id': productId,
    });

    if (kIsWeb) {
      try {
        js.context.callMethod('fetch', [
          targetScriptUrl,
          js.JsObject.jsify({
            'method': 'POST',
            'mode': 'no-cors',
            'headers': {'Content-Type': 'text/plain;charset=utf-8'},
            'body': postBody,
          }),
        ]);

        js.context.callMethod('eval', ['''
          (function() {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", "$getUrl", true);
            xhr.send();
          })();
        ''']);
        debugPrint('ApiService: deleteProductPrice($productId) sent via POST & GET');
        return true;
      } catch (e) {
        debugPrint('ApiService: Web deleteProductPrice error: $e');
      }
    }

    try {
      final response = await http.post(
        Uri.parse(targetScriptUrl),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: postBody,
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 || response.statusCode == 302) return true;
    } catch (e) {
      debugPrint('ApiService: HTTP deleteProductPrice failed: $e');
    }
    return true;
  }

  Future<bool> saveWeeklyPrices(
    List<ProductPrice> prices, {
    String? weekLabel,
    String? customScriptUrl,
  }) async {
    final targetScriptUrl = (customScriptUrl != null && customScriptUrl.trim().isNotEmpty)
        ? customScriptUrl.trim()
        : _scriptUrl;

    final Map<String, dynamic> payload = {
      'action': 'saveWeeklyPrices',
      'weekLabel': weekLabel ?? 'Week ${DateTime.now().toLocal().toString().split(' ')[0]}',
      'prices': prices.map((p) => p.toJson()).toList(),
    };

    final String payloadJson = json.encode(payload);
    final String base64Payload = base64Encode(utf8.encode(payloadJson));
    final String getUrl = '$targetScriptUrl?action=updatePrices&payload=${Uri.encodeComponent(base64Payload)}';

    if (kIsWeb) {
      try {
        js.context.callMethod('fetch', [
          targetScriptUrl,
          js.JsObject.jsify({
            'method': 'POST',
            'mode': 'no-cors',
            'headers': {'Content-Type': 'text/plain;charset=utf-8'},
            'body': payloadJson,
          }),
        ]);

        js.context.callMethod('eval', ['''
          (function() {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", "$getUrl", true);
            xhr.send();
          })();
        ''']);
        debugPrint('ApiService: saveWeeklyPrices sent via POST & GET');
        return true;
      } catch (e) {
        debugPrint('ApiService: Web saveWeeklyPrices error: $e');
      }
    }

    try {
      final response = await http.post(
        Uri.parse(targetScriptUrl),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: payloadJson,
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 || response.statusCode == 302) return true;
    } catch (e) {
      debugPrint('ApiService: HTTP saveWeeklyPrices failed: $e');
    }
    return true;
  }

  Future<List<PriceHistoryItem>> fetchPriceHistory({String? customScriptUrl}) async {
    final targetScriptUrl = (customScriptUrl != null && customScriptUrl.trim().isNotEmpty)
        ? customScriptUrl.trim()
        : _scriptUrl;

    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final response = await http.get(
        Uri.parse('$targetScriptUrl?action=getPriceHistory&_t=$timestamp'),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List? histList;
        if (decoded is List) {
          histList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['history'] is List) {
            histList = decoded['history'];
          } else if (decoded['data'] is List) {
            histList = decoded['data'];
          }
        }

        if (histList != null) {
          return histList
              .map((e) => PriceHistoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('ApiService: fetchPriceHistory exception: $e');
    }
    return [];
  }

  static List<ProductPrice> getDefaultPrices() {
    final today = DateTime.now().toLocal().toString().split(' ')[0];
    const defaultValidity = 'Daily Spot Rate';

    return [
      // ─── WHITE ONION ─────────────────────────────────────────
      ProductPrice(
        id: 'WO-01',
        category: 'White Onion',
        name: 'White Onion Flakes (Sorted)',
        grade: 'A-Grade (Optical Sorted)',
        packing: '14 kg Bag',
        currency: '₹ / kg',
        currentPrice: 197,
        prevPrice: 197,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: 'Export Quality, Optical Sorted',
        lastUpdated: today,
      ),
      ProductPrice(
        id: 'WO-02',
        category: 'White Onion',
        name: 'White Onion Flakes (Unsorted)',
        grade: 'Commercial / Domestic Grade',
        packing: '14 kg Bag',
        currency: '₹ / kg',
        currentPrice: 185,
        prevPrice: 185,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: 'Commercial / Domestic Grade',
        lastUpdated: today,
      ),
      ProductPrice(
        id: 'WO-03',
        category: 'White Onion',
        name: 'White Onion Chopped',
        grade: '3 - 5 mm (Export Quality)',
        packing: '20 kg Bag',
        currency: '₹ / kg',
        currentPrice: 197,
        prevPrice: 197,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: 'Clean & Even Cut',
        lastUpdated: today,
      ),
      ProductPrice(
        id: 'WO-04',
        category: 'White Onion',
        name: 'White Onion Minced',
        grade: '1 - 3 mm (Export Quality)',
        packing: '20 kg Bag',
        currency: '₹ / kg',
        currentPrice: 197,
        prevPrice: 197,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: 'Standard Size',
        lastUpdated: today,
      ),
      ProductPrice(
        id: 'WO-05',
        category: 'White Onion',
        name: 'White Onion Granules',
        grade: '40 - 60 Mesh (Export Quality)',
        packing: '25 kg Bag',
        currency: '₹ / kg',
        currentPrice: 187,
        prevPrice: 187,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: 'Free Flowing',
        lastUpdated: today,
      ),
      ProductPrice(
        id: 'WO-06',
        category: 'White Onion',
        name: 'White Onion Powder',
        grade: '80 - 100 Mesh (Export Quality)',
        packing: '25 kg Bag',
        currency: '₹ / kg',
        currentPrice: 172,
        prevPrice: 172,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: '100% Pure & Fine',
        lastUpdated: today,
      ),

      // ─── RED ONION ───────────────────────────────────────────
      ProductPrice(
        id: 'RO-01',
        category: 'Red Onion',
        name: 'Red Onion Flakes (Sorted)',
        grade: 'A-Grade (Optical Sorted)',
        packing: '14 kg Bag',
        currency: '₹ / kg',
        currentPrice: 137,
        prevPrice: 137,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: 'Export Quality, Optical Sorted',
        lastUpdated: today,
      ),
      ProductPrice(
        id: 'RO-02',
        category: 'Red Onion',
        name: 'Red Onion Flakes (Unsorted)',
        grade: 'Commercial / Domestic Grade',
        packing: '14 kg Bag',
        currency: '₹ / kg',
        currentPrice: 115,
        prevPrice: 115,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: 'Commercial / Domestic Grade',
        lastUpdated: today,
      ),
      ProductPrice(
        id: 'RO-03',
        category: 'Red Onion',
        name: 'Red Onion Chopped',
        grade: '3 - 5 mm (Export Quality)',
        packing: '20 kg Bag',
        currency: '₹ / kg',
        currentPrice: 140,
        prevPrice: 140,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: 'Clean & Even Cut',
        lastUpdated: today,
      ),
      ProductPrice(
        id: 'RO-04',
        category: 'Red Onion',
        name: 'Red Onion Minced',
        grade: '1 - 3 mm (Export Quality)',
        packing: '20 kg Bag',
        currency: '₹ / kg',
        currentPrice: 140,
        prevPrice: 140,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: 'Uniform Size',
        lastUpdated: today,
      ),
      ProductPrice(
        id: 'RO-05',
        category: 'Red Onion',
        name: 'Red Onion Granules',
        grade: '40 - 60 Mesh (Export Quality)',
        packing: '25 kg Bag',
        currency: '₹ / kg',
        currentPrice: 122,
        prevPrice: 122,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: 'Free Flowing',
        lastUpdated: today,
      ),
      ProductPrice(
        id: 'RO-06',
        category: 'Red Onion',
        name: 'Red Onion Powder',
        grade: '80 - 100 Mesh (Export Quality)',
        packing: '25 kg Bag',
        currency: '₹ / kg',
        currentPrice: 112,
        prevPrice: 112,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: 'Deep Red Pure Powder',
        lastUpdated: today,
      ),

      // ─── PINK ONION ──────────────────────────────────────────
      ProductPrice(
        id: 'PO-01',
        category: 'Pink Onion',
        name: 'Pink Onion Flakes (Sorted)',
        grade: 'A-Grade (Optical Sorted)',
        packing: '14 kg Bag',
        currency: '₹ / kg',
        currentPrice: 132,
        prevPrice: 132,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: 'Export Quality, Optical Sorted',
        lastUpdated: today,
      ),
      ProductPrice(
        id: 'PO-02',
        category: 'Pink Onion',
        name: 'Pink Onion Flakes (Unsorted)',
        grade: 'Commercial / Domestic Grade',
        packing: '14 kg Bag',
        currency: '₹ / kg',
        currentPrice: 122,
        prevPrice: 122,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: 'Commercial / Domestic Grade',
        lastUpdated: today,
      ),
      ProductPrice(
        id: 'PO-03',
        category: 'Pink Onion',
        name: 'Pink Onion Chopped',
        grade: '3 - 5 mm (Export Quality)',
        packing: '20 kg Bag',
        currency: '₹ / kg',
        currentPrice: 127,
        prevPrice: 127,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: 'Clean & Even Cut',
        lastUpdated: today,
      ),
      ProductPrice(
        id: 'PO-04',
        category: 'Pink Onion',
        name: 'Pink Onion Minced',
        grade: '1 - 3 mm (Export Quality)',
        packing: '20 kg Bag',
        currency: '₹ / kg',
        currentPrice: 127,
        prevPrice: 127,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: 'Uniform Cut',
        lastUpdated: today,
      ),
      ProductPrice(
        id: 'PO-05',
        category: 'Pink Onion',
        name: 'Pink Onion Granules',
        grade: '40 - 60 Mesh (Export Quality)',
        packing: '25 kg Bag',
        currency: '₹ / kg',
        currentPrice: 132,
        prevPrice: 132,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: 'Free Flowing',
        lastUpdated: today,
      ),
      ProductPrice(
        id: 'PO-06',
        category: 'Pink Onion',
        name: 'Pink Onion Powder',
        grade: '80 - 100 Mesh (Export Quality)',
        packing: '25 kg Bag',
        currency: '₹ / kg',
        currentPrice: 112,
        prevPrice: 112,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: '100% Pure Pink Onion',
        lastUpdated: today,
      ),

      // ─── GARLIC ──────────────────────────────────────────────
      ProductPrice(
        id: 'GA-01',
        category: 'Garlic',
        name: 'Garlic Flakes (Sorted)',
        grade: 'A-Grade (Machine Sorted)',
        packing: '25 kg Bag',
        currency: '₹ / kg',
        currentPrice: 217,
        prevPrice: 217,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: 'Export Quality, Machine Sorted',
        lastUpdated: today,
      ),
      ProductPrice(
        id: 'GA-02',
        category: 'Garlic',
        name: 'Garlic Flakes (Unsorted)',
        grade: 'Commercial / Domestic Grade',
        packing: '25 kg Bag',
        currency: '₹ / kg',
        currentPrice: 187,
        prevPrice: 187,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: 'Commercial / Domestic Grade',
        lastUpdated: today,
      ),
      ProductPrice(
        id: 'GA-03',
        category: 'Garlic',
        name: 'Garlic Chopped',
        grade: '3 - 5 mm (Export Quality)',
        packing: '25 kg Bag',
        currency: '₹ / kg',
        currentPrice: 237,
        prevPrice: 237,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: 'Even Granulation',
        lastUpdated: today,
      ),
      ProductPrice(
        id: 'GA-04',
        category: 'Garlic',
        name: 'Garlic Minced',
        grade: '1 - 3 mm (Export Quality)',
        packing: '25 kg Bag',
        currency: '₹ / kg',
        currentPrice: 237,
        prevPrice: 237,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: 'Clean & Aromatic',
        lastUpdated: today,
      ),
      ProductPrice(
        id: 'GA-05',
        category: 'Garlic',
        name: 'Garlic Granules',
        grade: '40 - 60 Mesh (Export Quality)',
        packing: '25 kg Bag',
        currency: '₹ / kg',
        currentPrice: 232,
        prevPrice: 232,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: 'Golden/White Free Flowing',
        lastUpdated: today,
      ),
      ProductPrice(
        id: 'GA-06',
        category: 'Garlic',
        name: 'Garlic Powder',
        grade: '100 Mesh (Export Quality)',
        packing: '25 kg Bag',
        currency: '₹ / kg',
        currentPrice: 110,
        prevPrice: 110,
        moq: '1000 kg',
        validity: defaultValidity,
        remarks: 'Pure Aromatic Flavor',
        lastUpdated: today,
      ),
    ];
  }
}
