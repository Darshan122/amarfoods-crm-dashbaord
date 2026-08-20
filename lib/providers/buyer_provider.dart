import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/buyer.dart';
import '../services/api_service.dart';

enum MainTab { dailyWorkArea, allImporters, analytics, emailTemplates }

class BuyerProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Buyer> _buyers = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _statusFilter = 'All Statuses';
  String _replyFilter = 'All Replies';
  MainTab _activeTab = MainTab.allImporters;

  final Set<String> _selectedBuyerIds = {};
  String? _errorMessage;

  Timer? _searchDebounce;

  List<Buyer> _filteredCache = [];
  List<Buyer> _overdueCache = [];
  List<Buyer> _followupTodayCache = [];
  List<Buyer> _firstEmailCache = [];
  List<Buyer> _allFollowupQueueCache = [];

  // Category-specific pagination limits (20 records per batch)
  static const int pageSize = 20;
  int _displayedCount = 20;
  int _overdueDisplayedCount = 20;
  int _followupDisplayedCount = 20;
  int _firstEmailDisplayedCount = 20;
  int _allFollowupQueueDisplayedCount = 20;
  int _filteredDisplayedCount = 20;

  DateTime? _lastLoadMoreTime;

  BuyerProvider() {
    loadBuyers();
  }

  // Getters
  List<Buyer> get buyers => _buyers;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String get replyFilter => _replyFilter;
  MainTab get activeTab => _activeTab;
  int get displayedCount => _displayedCount;
  Set<String> get selectedBuyerIds => _selectedBuyerIds;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _apiService.isConnected;
  String? get scriptUrl => _apiService.scriptUrl;

  // Tabs & Settings
  void setActiveTab(MainTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    // Clear search when switching tabs — each tab has an independent search state
    _searchDebounce?.cancel();
    _searchQuery = '';
    _rebuildCaches();
    resetPagination();
  }

  void resetPagination() {
    _displayedCount = pageSize;
    _overdueDisplayedCount = pageSize;
    _followupDisplayedCount = pageSize;
    _firstEmailDisplayedCount = pageSize;
    _allFollowupQueueDisplayedCount = pageSize;
    _filteredDisplayedCount = pageSize;
    notifyListeners();
  }

  void setScriptUrl(String? url) {
    _apiService.updateUrl(url ?? '');
    loadBuyers(forceRefresh: true);
  }

  static const String _localBuyersKey = 'amar_crm_local_buyers_v6';

  Future<void> _saveLocalBuyers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = jsonEncode(_buyers.map((b) => b.toJson()).toList());
      await prefs.setString(_localBuyersKey, jsonStr);
    } catch (e) {
      debugPrint('BuyerProvider: Error saving local buyers: $e');
    }
  }

  Future<List<Buyer>> _loadLocalBuyers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_localBuyersKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        return decoded.map((e) => Buyer.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('BuyerProvider: Error loading local buyers: $e');
    }
    return [];
  }

  Future<void> loadBuyers({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final remote = await _apiService.fetchBuyers(forceRefresh: forceRefresh);

      if (remote.isNotEmpty) {
        // Remote (Google Sheet) is the single source of truth.
        // Always trust remote data. Sort by Sr. No. so display order matches sheet.
        _buyers = remote;
        _buyers.sort((a, b) => a.srNo.compareTo(b.srNo));
      } else {
        // No remote data — fall back to local cache.
        final local = await _loadLocalBuyers();
        _buyers = local;
        _buyers.sort((a, b) => a.srNo.compareTo(b.srNo));
      }

      await _saveLocalBuyers();
      _rebuildCaches();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _rebuildCaches({bool preservePage = false}) {
    int savedPage = _currentPage;
    final query = _searchQuery.trim().toLowerCase();
    final cleanQuery = query
        .replaceAll('https://', '')
        .replaceAll('http://', '')
        .replaceAll('www.', '')
        .replaceAll(RegExp(r'/+$'), '')
        .trim();
    
    _filteredCache = [];
    _overdueCache = [];
    _followupTodayCache = [];
    _firstEmailCache = [];
    _allFollowupQueueCache = [];

    for (var b in _buyers) {
      final cleanWeb = b.website
          .toLowerCase()
          .replaceAll('https://', '')
          .replaceAll('http://', '')
          .replaceAll('www.', '')
          .replaceAll(RegExp(r'/+$'), '')
          .trim();
      final cleanCompany = b.company.toLowerCase();
      final cleanEmail = b.email.toLowerCase();
      final cleanId = b.id.toLowerCase();
      final cleanPhone = b.phone.toLowerCase();
      final cleanNotes = b.notes.toLowerCase();
      final srNoStr = b.srNo.toString();

      bool matchesSearch = query.isEmpty ||
          cleanCompany.contains(query) ||
          (cleanQuery.isNotEmpty && cleanCompany.contains(cleanQuery)) ||
          cleanEmail.contains(query) ||
          b.website.toLowerCase().contains(query) ||
          (cleanQuery.isNotEmpty && cleanWeb.contains(cleanQuery)) ||
          (cleanQuery.isNotEmpty && cleanWeb.isNotEmpty && cleanQuery.contains(cleanWeb)) ||
          cleanId.contains(query) ||
          srNoStr == query ||
          cleanPhone.contains(query) ||
          cleanNotes.contains(query);

      if (!matchesSearch) continue;

      if (_statusFilter != 'All Statuses' && _statusFilter != 'All') {
        if (b.status != _statusFilter) continue;
      }
      if (_replyFilter != 'All Replies' && _replyFilter != 'All') {
        if (b.clientReply != _replyFilter) continue;
      }

      // Use actual srNo from Google Sheet — do NOT re-number
      _filteredCache.add(b);

      // Category logic for Daily Work Area
      bool isConverted = b.clientReply.toLowerCase() == 'yes' ||
          b.status.toLowerCase() == 'converted';

      bool isFollowupCandidate = b.followupCount > 0 ||
          b.firstEmailDate.trim().isNotEmpty ||
          b.status.contains('Follow-Up') ||
          b.status == 'First Email Sent';

      if (!isConverted) {
        if (isFollowupCandidate) {
          // 1. Overdue Follow-ups (strictly past due)
          if (b.isOverdue()) {
            _overdueCache.add(b);
          } else if (b.isDueToday()) {
            // 2. Follow-ups Today (scheduled for today)
            _followupTodayCache.add(b);
          }
        } else {
          // 3. First Emails (Initial outreach only)
          _firstEmailCache.add(b);
        }
      }

      // 4. All Follow-up Queue
      if (isFollowupCandidate) {
        _allFollowupQueueCache.add(b);
      }
    }

    _displayedCount = pageSize;
    _overdueDisplayedCount = pageSize;
    _followupDisplayedCount = pageSize;
    _firstEmailDisplayedCount = pageSize;
    _allFollowupQueueDisplayedCount = pageSize;
    _filteredDisplayedCount = pageSize;

    if (preservePage && totalPages > 0) {
      _currentPage = savedPage.clamp(1, totalPages);
    } else {
      _currentPage = 1;
    }
  }

  // ── Page-based Pagination for All Importers Table ──
  int _rowsPerPage = 25; // Default 25 for fast 60fps scrolling
  int _currentPage = 1;

  int get rowsPerPage => _rowsPerPage;
  int get currentPage => _currentPage;

  int get totalPages {
    if (_filteredCache.isEmpty || _rowsPerPage <= 0) return 1;
    return (_filteredCache.length / _rowsPerPage).ceil();
  }

  int get startItemIndex {
    if (_filteredCache.isEmpty) return 0;
    if (_rowsPerPage <= 0) return 1;
    return (_currentPage - 1) * _rowsPerPage + 1;
  }

  int get endItemIndex {
    if (_filteredCache.isEmpty) return 0;
    if (_rowsPerPage <= 0) return _filteredCache.length;
    int end = _currentPage * _rowsPerPage;
    return end > _filteredCache.length ? _filteredCache.length : end;
  }

  List<Buyer> get pagedFilteredBuyers {
    if (_filteredCache.isEmpty) return [];
    if (_rowsPerPage <= 0) return _filteredCache;
    int start = (_currentPage - 1) * _rowsPerPage;
    if (start >= _filteredCache.length) {
      start = 0;
      _currentPage = 1;
    }
    int end = (start + _rowsPerPage).clamp(0, _filteredCache.length);
    return _filteredCache.sublist(start, end);
  }

  void setRowsPerPage(int count) {
    _rowsPerPage = count;
    _currentPage = 1;
    notifyListeners();
  }

  void setPage(int page) {
    int target = page.clamp(1, totalPages);
    if (_currentPage != target) {
      _currentPage = target;
      notifyListeners();
    }
  }

  void nextPage() {
    if (_currentPage < totalPages) {
      _currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      notifyListeners();
    }
  }

  // Paginated getters
  List<Buyer> get paginatedFilteredBuyers => pagedFilteredBuyers;
  List<Buyer> get paginatedOverdueBuyers => _take(_overdueCache, _overdueDisplayedCount);
  List<Buyer> get paginatedFollowupTodayBuyers => _take(_followupTodayCache, _followupDisplayedCount);
  List<Buyer> get paginatedFirstEmailBuyers => _take(_firstEmailCache, _firstEmailDisplayedCount);
  List<Buyer> get paginatedAllFollowupQueueBuyers => _take(_allFollowupQueueCache, _allFollowupQueueDisplayedCount);

  List<Buyer> _take(List<Buyer> list, int count) {
    int limit = count.clamp(0, list.length);
    return list.sublist(0, limit);
  }

  bool hasMore(List<Buyer> fullList) => _displayedCount < fullList.length;

  bool hasMoreCategory(String category) {
    switch (category) {
      case 'overdue':
        return _overdueDisplayedCount < _overdueCache.length;
      case 'followups':
        return _followupDisplayedCount < _followupTodayCache.length;
      case 'first_emails':
        return _firstEmailDisplayedCount < _firstEmailCache.length;
      case 'all_followup_queue':
        return _allFollowupQueueDisplayedCount < _allFollowupQueueCache.length;
      case 'filtered':
      default:
        return _filteredDisplayedCount < _filteredCache.length;
    }
  }

  void loadMoreCategory(String category) {
    final now = DateTime.now();
    if (_lastLoadMoreTime != null && now.difference(_lastLoadMoreTime!).inMilliseconds < 200) {
      return;
    }
    _lastLoadMoreTime = now;

    bool updated = false;
    switch (category) {
      case 'overdue':
        if (_overdueDisplayedCount < _overdueCache.length) {
          _overdueDisplayedCount += pageSize;
          updated = true;
        }
        break;
      case 'followups':
        if (_followupDisplayedCount < _followupTodayCache.length) {
          _followupDisplayedCount += pageSize;
          updated = true;
        }
        break;
      case 'first_emails':
        if (_firstEmailDisplayedCount < _firstEmailCache.length) {
          _firstEmailDisplayedCount += pageSize;
          updated = true;
        }
        break;
      case 'all_followup_queue':
        if (_allFollowupQueueDisplayedCount < _allFollowupQueueCache.length) {
          _allFollowupQueueDisplayedCount += pageSize;
          updated = true;
        }
        break;
      case 'filtered':
      default:
        if (_filteredDisplayedCount < _filteredCache.length) {
          _filteredDisplayedCount += pageSize;
          _displayedCount = _filteredDisplayedCount;
          updated = true;
        }
        break;
    }

    if (updated) {
      notifyListeners();
    }
  }

  void loadMore() {
    loadMoreCategory('filtered');
    loadMoreCategory('overdue');
    loadMoreCategory('followups');
    loadMoreCategory('first_emails');
    loadMoreCategory('all_followup_queue');
  }

  // Raw Filtered Lists
  List<Buyer> get overdueBuyers => _overdueCache;
  List<Buyer> get followupTodayBuyers => _followupTodayCache;
  List<Buyer> get firstEmailBuyers => _firstEmailCache;
  List<Buyer> get allFollowupQueueBuyers => _allFollowupQueueCache;
  List<Buyer> get filteredBuyers => _filteredCache;

  // Specialized Getters for Kanban
  List<Buyer> get followup1Buyers => _filteredCache.where((b) => b.status == 'Follow-up 1 Pending').toList();
  List<Buyer> get followupMultiBuyers => _filteredCache.where((b) => b.status.contains('Follow-up') && b.status != 'Follow-up 1 Pending').toList();
  List<Buyer> get convertedBuyers => _filteredCache.where((b) => b.clientReply.toLowerCase() == 'yes' || b.status == 'Converted').toList();

  // Metrics
  int get totalBuyersCount => _buyers.length;
  int get maxSrNo => _buyers.isEmpty ? 0 : _buyers.map((b) => b.srNo).reduce((a, b) => a > b ? a : b);
  int get dueTodayCount => _buyers.where((b) => b.isDueToday() && b.clientReply.toLowerCase() != 'yes').length;
  int get firstEmailCount => _buyers.where((b) => (b.followupCount == 0 && b.firstEmailDate.trim().isEmpty) || b.status == 'New' || b.status == 'First Email Pending').length;
  int get todayFollowupCount => _buyers.where((b) {
    bool isConverted = b.clientReply.toLowerCase() == 'yes' || b.status.toLowerCase() == 'converted';
    return !isConverted && b.isDueToday();
  }).length;
  int get activeFollowupCount => _buyers.where((b) => b.followupCount > 0 || b.firstEmailDate.trim().isNotEmpty || b.status.contains('Follow-Up')).length;
  int get convertedCount => _buyers.where((b) => b.clientReply.toLowerCase() == 'yes' || b.status == 'Converted').length;

  void setSearchQuery(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 150), () {
      _searchQuery = query;
      _rebuildCaches();
      notifyListeners();
    });
  }

  void setStatusFilter(String filter) {
    if (_statusFilter == filter) return;
    _statusFilter = filter;
    _rebuildCaches();
    notifyListeners();
  }

  void setReplyFilter(String filter) {
    if (_replyFilter == filter) return;
    _replyFilter = filter;
    _rebuildCaches();
    notifyListeners();
  }

  void toggleSelectBuyer(String id) {
    if (_selectedBuyerIds.contains(id)) {
      _selectedBuyerIds.remove(id);
    } else {
      _selectedBuyerIds.add(id);
    }
    notifyListeners();
  }

  void selectAllDueToday() {
    _selectedBuyerIds.clear();
    for (var b in _overdueCache) {
      _selectedBuyerIds.add(b.id);
    }
    for (var b in _followupTodayCache) {
      _selectedBuyerIds.add(b.id);
    }
    for (var b in _firstEmailCache) {
      _selectedBuyerIds.add(b.id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedBuyerIds.clear();
    notifyListeners();
  }

  Future<bool> markEmailSent(String buyerId, {Buyer? targetBuyer}) async {
    int index = _buyers.indexWhere((b) => b.id == buyerId);
    if (index < 0 && targetBuyer != null) {
      if (targetBuyer.srNo > 0) {
        index = _buyers.indexWhere((b) => b.srNo == targetBuyer.srNo);
      }
      if (index < 0 && targetBuyer.company.trim().isNotEmpty) {
        index = _buyers.indexWhere((b) => b.company.trim().toLowerCase() == targetBuyer.company.trim().toLowerCase());
      }
      if (index < 0 && targetBuyer.email.trim().isNotEmpty && targetBuyer.email.contains('@')) {
        index = _buyers.indexWhere((b) => b.email.trim().toLowerCase() == targetBuyer.email.trim().toLowerCase());
      }
    }
    if (index < 0) return false;

    final existing = _buyers[index];
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final nextDueStr = Buyer.calculateNextDueDate(DateTime.now());

    final bool isInitialEmail = existing.firstEmailDate.trim().isEmpty;
    final int updatedCount = isInitialEmail ? 0 : existing.followupCount + 1;

    final updated = existing.copyWith(
      firstEmailDate: isInitialEmail ? todayStr : existing.firstEmailDate,
      lastEmailDate: todayStr,
      nextDueDate: nextDueStr,
      followupCount: updatedCount,
      status: isInitialEmail ? 'First Email Sent' : 'Follow-Up $updatedCount Sent',
    );

    _buyers[index] = updated;
    _rebuildCaches(preservePage: true);
    await _saveLocalBuyers();
    notifyListeners();

    await _apiService.saveBuyer(updated);
    return true;
  }

  Future<bool> revertBuyer(Buyer oldBuyer) async {
    final index = _buyers.indexWhere((b) => b.srNo == oldBuyer.srNo || b.id == oldBuyer.id);
    if (index >= 0) {
      _buyers[index] = oldBuyer;
    } else {
      _buyers.add(oldBuyer);
    }
    _buyers.sort((a, b) => a.srNo.compareTo(b.srNo));
    _rebuildCaches(preservePage: true);
    await _saveLocalBuyers();
    notifyListeners();

    bool res = await _apiService.saveBuyer(oldBuyer);
    return res;
  }

  Future<bool> batchProcessSelected({bool sendGmail = false}) async {
    if (_selectedBuyerIds.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    for (var id in _selectedBuyerIds.toList()) {
      await markEmailSent(id);
    }
    _selectedBuyerIds.clear();
    _isLoading = false;
    _rebuildCaches(preservePage: true);
    notifyListeners();
    return true;
  }

  Future<bool> batchProcessSelectedCustom(List<String> ids, {bool sendGmail = false}) async {
    if (ids.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    for (var id in ids) {
      await markEmailSent(id);
    }
    _isLoading = false;
    _rebuildCaches(preservePage: true);
    notifyListeners();
    return true;
  }

  Future<bool> saveBuyer(Buyer buyer) async {
    // PRIMARY KEY = srNo. Match by srNo first (most reliable).
    int index = -1;
    if (buyer.srNo > 0) {
      index = _buyers.indexWhere((b) => b.srNo == buyer.srNo);
    }
    // Fallback: match by formatted id (e.g. AF-00150)
    if (index < 0 && buyer.id.isNotEmpty) {
      index = _buyers.indexWhere((b) => b.id == buyer.id);
    }
    // NOTE: Do NOT fallback to company name — name can change during edit
    // and would cause a brand-new row to be created.

    bool isEditing = index >= 0;
    Buyer targetBuyer = buyer;

    if (isEditing) {
      // Preserve the original srNo and id — they must never change on edit.
      targetBuyer = buyer.copyWith(
        id: _buyers[index].id,
        srNo: _buyers[index].srNo,
      );
      _buyers[index] = targetBuyer;
      _buyers.sort((a, b) => a.srNo.compareTo(b.srNo));
      _rebuildCaches(preservePage: true);
    } else {
      // New buyer — assign next sequential srNo.
      final maxSrNo = _buyers.isEmpty
          ? 0
          : _buyers.map((b) => b.srNo).reduce((a, b) => a > b ? a : b);
      final nextSrNo = maxSrNo + 1;
      targetBuyer = buyer.copyWith(
        id: Buyer.formatBuyerId(nextSrNo),
        srNo: nextSrNo,
      );
      _buyers.add(targetBuyer);
      _buyers.sort((a, b) => a.srNo.compareTo(b.srNo));
      _rebuildCaches(preservePage: false);
      _currentPage = totalPages;
    }
    await _saveLocalBuyers();
    notifyListeners();

    bool res = await _apiService.saveBuyer(targetBuyer);
    return res;
  }

  Future<bool> deleteBuyer(String id) async {
    // Find the buyer by id to get its srNo (our true primary key).
    final match = _buyers.where((b) => b.id == id).toList();
    if (match.isEmpty) return false;
    final srNoToDelete = match.first.srNo;

    _buyers.removeWhere((b) => b.srNo == srNoToDelete);
    _selectedBuyerIds.remove(id);
    _rebuildCaches(preservePage: true);
    await _saveLocalBuyers();
    notifyListeners();

    // Send srNo to Apps Script so it can find the exact row in Column A.
    bool res = await _apiService.deleteBuyerBySrNo(srNoToDelete);
    return res;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
