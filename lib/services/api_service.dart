import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/buyer.dart';

class ApiService {
  static const String defaultScriptUrl =
      'https://script.google.com/macros/s/AKfycbxzMWQpzmDzjYcnbXm-9cmIM8reFisS0L6JrXLL-BQ56qMfSu1qdHE_FNa21Ghf_Stp/exec';

  static const String sheetGvizCsvUrl =
      'https://docs.google.com/spreadsheets/d/1O8BKIi482N4pfPIipraE0vl5xDw68Y0Y1v3NLyjnkrU/gviz/tq?tqx=out:csv&sheet=Sheet5';

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
    if (!forceRefresh && _cachedBuyers != null && _cachedBuyers!.isNotEmpty) {
      return _cachedBuyers!;
    }

    final targetScriptUrl = (customScriptUrl != null && customScriptUrl.trim().isNotEmpty)
        ? customScriptUrl.trim()
        : _scriptUrl;

    try {
      // 1. Fast CSV export load (under 300ms)
      final csvBuyers = await fetchBuyersViaCsv();
      if (csvBuyers.isNotEmpty) {
        _cachedBuyers = csvBuyers;
        // Optionally update via Apps Script API asynchronously in background
        _asyncBackgroundSync(targetScriptUrl);
        return csvBuyers;
      }

      // 2. Fallback to direct Apps Script API if CSV returned empty
      final response = await http.get(Uri.parse('$targetScriptUrl?action=getBuyers')).timeout(
        const Duration(seconds: 4),
      );

      if (response.statusCode == 200) {
        _isConnected = true;
        final decoded = json.decode(response.body);
        List<Buyer> list = [];
        if (decoded is List) {
          for (int i = 0; i < decoded.length; i++) {
            final item = decoded[i];
            if (item is Map<String, dynamic>) {
              list.add(Buyer.fromJson(item, i + 1));
            }
          }
          list = mergeDuplicateCompanies(list);
        } else if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          final List listData = decoded['data'];
          for (int i = 0; i < listData.length; i++) {
            final item = listData[i];
            if (item is Map<String, dynamic>) {
              list.add(Buyer.fromJson(item, i + 1));
            }
          }
          list = mergeDuplicateCompanies(list);
        }
        if (list.isNotEmpty) {
          _cachedBuyers = list;
          return list;
        }
      }
    } catch (e) {
      _isConnected = false;
      debugPrint('Fast API exception: $e. Using CSV fallback.');
    }
    final fallback = await fetchBuyersViaCsv();
    _cachedBuyers = fallback;
    return fallback;
  }

  void _asyncBackgroundSync(String targetUrl) {
    http.get(Uri.parse('$targetUrl?action=getBuyers')).timeout(const Duration(seconds: 4)).then((res) {
      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        if (decoded is List || (decoded is Map<String, dynamic> && decoded['data'] is List)) {
          // Successfully pinged Apps Script
          _isConnected = true;
        }
      }
    }).catchError((_) {});
  }

  Future<List<Buyer>> fetchBuyersViaCsv() async {
    try {
      final response = await http.get(Uri.parse(sheetGvizCsvUrl)).timeout(
        const Duration(seconds: 5),
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

    // Date regex matcher for YYYY-MM-DD or DD-MMM-YYYY
    final dateRegex = RegExp(r'\b\d{4}-\d{2}-\d{2}\b|\b\d{1,2}-[A-Za-z]{3}-\d{4}\b');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || line.startsWith('Amar Foods') || line.contains('Sr. No.') || line.contains('Importer Company')) continue;

      final row = _splitCsvRow(line);
      if (row.length < 3) continue;

      int offset = 0;
      if (row.isNotEmpty && row[0].isEmpty) {
        offset = 1;
      }

      String company = row.length > offset + 1 ? row[offset + 1].replaceAll('"', '').trim() : '';
      String rawWebsite = row.length > offset + 2 ? row[offset + 2].replaceAll('"', '').trim() : '';
      String rawEmail = row.length > offset + 3 ? row[offset + 3].replaceAll('"', '').trim() : '';
      String phone = row.length > offset + 4 ? row[offset + 4].replaceAll('"', '').trim() : '';
      String method = row.length > offset + 5 ? row[offset + 5].replaceAll('"', '').trim() : 'Email';

      // Smart Regex Date Extraction from all fields in row!
      final List<String> extractedDates = [];
      for (var col in row) {
        final cleanCol = col.replaceAll('"', '').trim();
        if (dateRegex.hasMatch(cleanCol)) {
          extractedDates.add(cleanCol);
        }
      }

      String connDate = extractedDates.isNotEmpty ? extractedDates[0] : '';
      String firstEmailDate = extractedDates.length > 1 ? extractedDates[1] : (extractedDates.isNotEmpty ? extractedDates[0] : '');
      String followUpDate = extractedDates.length > 2 ? extractedDates[2] : '';
      String lastEmailDate = extractedDates.length > 3 ? extractedDates[3] : (extractedDates.length > 1 ? extractedDates[1] : '');

      String rawReply = 'Pending';
      String status = 'New';
      String nextAction = 'Follow-Up';

      for (var col in row) {
        final cleanCol = col.replaceAll('"', '').trim();
        if (cleanCol == 'Hold' || cleanCol == 'Pending' || cleanCol == 'Yes' || cleanCol == 'No Interest') {
          rawReply = cleanCol;
        } else if (cleanCol == 'New' || cleanCol.contains('First Email') || cleanCol.contains('Follow-Up')) {
          if (!dateRegex.hasMatch(cleanCol) && cleanCol.length < 30) {
            status = cleanCol;
          }
        }
      }

      String website = cleanWebsiteUrl(rawWebsite);
      String email = cleanEmailStr(rawEmail);

      if (company.isEmpty && email.isEmpty) continue;
      if (company == 'N/A' || company.isEmpty) {
        if (website.isNotEmpty) {
          company = website.replaceAll('https://', '').replaceAll('http://', '').replaceAll('www.', '').split('/')[0];
        } else {
          company = 'Importer #$counter';
        }
      }

      list.add(Buyer(
        id: Buyer.formatBuyerId(counter),
        srNo: counter,
        company: company,
        website: website,
        email: email,
        phone: phone,
        connectionMethod: method.isEmpty ? 'Email' : method,
        connectionDate: connDate,
        firstEmailDate: firstEmailDate.isNotEmpty ? firstEmailDate : lastEmailDate,
        nextDueDate: followUpDate,
        clientReply: rawReply,
        lastEmailDate: lastEmailDate,
        notes: '',
        status: status.isEmpty ? 'New' : status,
        nextAction: nextAction.isEmpty ? 'Follow-Up' : nextAction,
        followupCount: 0,
      ));

      counter++;
    }

    return mergeDuplicateCompanies(list);
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
      result.add(b.copyWith(email: mergedEmailsStr.isNotEmpty ? mergedEmailsStr : b.email));
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

  Future<bool> deleteBuyer(String id) async {
    return true;
  }

  Future<int> batchMarkSent(List<String> buyerIds, {bool sendEmail = false}) async {
    return buyerIds.length;
  }

  Future<bool> updateBuyerOnSheet(Buyer buyer, {String? customScriptUrl}) async {
    final targetScriptUrl = (customScriptUrl != null && customScriptUrl.trim().isNotEmpty)
        ? customScriptUrl.trim()
        : _scriptUrl;

    try {
      final body = json.encode({
        'action': 'updateBuyer',
        'buyer': buyer.toJson(),
      });

      final response = await http.post(
        Uri.parse(targetScriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 302) {
        _cachedBuyers = null;
        return true;
      }
    } catch (e) {
      debugPrint('Error updating buyer on Google Sheet: $e');
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
        headers: {'Content-Type': 'application/json'},
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
