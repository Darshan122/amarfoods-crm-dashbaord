import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:js' as js;
import '../models/buyer.dart';

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
      String phone = row.length > offset + 4 ? row[offset + 4].replaceAll('"', '').trim() : '';
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
  /// The Apps Script searches Column A for this numeric value.
  Future<bool> deleteBuyerBySrNo(int srNo, {String? customScriptUrl}) async {
    final targetScriptUrl = (customScriptUrl != null && customScriptUrl.trim().isNotEmpty)
        ? customScriptUrl.trim()
        : _scriptUrl;

    // Pass the numeric srNo as the id parameter
    final String getUrl = '$targetScriptUrl?action=deleteBuyer&id=${Uri.encodeComponent(srNo.toString())}';

    _cachedBuyers = null; // Always clear cache so next fetch is fresh

    if (kIsWeb) {
      try {
        js.context.callMethod('fetch', [
          getUrl,
          js.JsObject.jsify({'method': 'GET', 'mode': 'no-cors'})
        ]);
        final img = js.context['document'].callMethod('createElement', ['img']);
        img['src'] = getUrl;
        debugPrint('ApiService: deleteBuyerBySrNo($srNo) sent via Web fetch + img beacon');
        return true;
      } catch (e) {
        debugPrint('ApiService: Web deleteBuyerBySrNo error: $e');
      }
    }

    try {
      final response = await http.get(Uri.parse(getUrl)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 || response.statusCode == 302) {
        return true;
      }
    } catch (e) {
      debugPrint('ApiService: HTTP deleteBuyerBySrNo error: $e');
    }
    return true; // Optimistic: local state already updated
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

    if (kIsWeb) {
      try {
        js.context.callMethod('fetch', [
          getUrl,
          js.JsObject.jsify({'method': 'GET', 'mode': 'no-cors'})
        ]);
        final img = js.context['document'].callMethod('createElement', ['img']);
        img['src'] = getUrl;
        debugPrint('ApiService: Sent buyer update to Google Sheet via Web fetch + img beacon');
        _cachedBuyers = null;
        return true;
      } catch (e) {
        debugPrint('ApiService: Web no-cors fetch error: $e');
      }
    }

    try {
      final response = await http.get(Uri.parse(getUrl)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 || response.statusCode == 302) {
        _cachedBuyers = null;
        return true;
      }
    } catch (e) {
      debugPrint('ApiService: HTTP GET update failed: $e');
    }

    try {
      final jsonPayload = json.encode({
        'action': 'updateBuyer',
        'buyer': buyer.toJson(),
      });
      final response = await http.post(
        Uri.parse(targetScriptUrl),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: jsonPayload,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 302) {
        _cachedBuyers = null;
        return true;
      }
    } catch (e) {
      debugPrint('ApiService: HTTP POST update failed: $e');
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
}
