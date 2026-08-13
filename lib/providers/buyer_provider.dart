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

  static const String _localBuyersKey = 'amar_crm_local_buyers_v4';

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
      final local = await _loadLocalBuyers();

      if (remote.isEmpty) {
        _buyers = local;
      } else if (local.isEmpty) {
        _buyers = remote;
      } else {
        // Smart Merge: Preserve all local user updates (emails, follow-up counts, replies, dates, statuses)
        final Map<String, Buyer> mapByCompany = {};

        for (var b in remote) {
          String key = b.company.trim().toLowerCase();
          if (key.isNotEmpty) {
            mapByCompany[key] = b;
          }
        }

        for (var b in local) {
          String key = b.company.trim().toLowerCase();
          if (key.isNotEmpty && mapByCompany.containsKey(key)) {
            final remoteB = mapByCompany[key]!;
            mapByCompany[key] = remoteB.copyWith(
              id: b.id.isNotEmpty ? b.id : remoteB.id,
              company: b.company.isNotEmpty ? b.company : remoteB.company,
              website: (b.website.isNotEmpty && b.website != 'N/A') ? b.website : remoteB.website,
              email: b.email.isNotEmpty ? b.email : remoteB.email,
              phone: b.phone.isNotEmpty ? b.phone : remoteB.phone,
              connectionMethod: b.connectionMethod.isNotEmpty ? b.connectionMethod : remoteB.connectionMethod,
              connectionDate: b.connectionDate.isNotEmpty ? b.connectionDate : remoteB.connectionDate,
              firstEmailDate: b.firstEmailDate.isNotEmpty ? b.firstEmailDate : remoteB.firstEmailDate,
              nextDueDate: b.nextDueDate.isNotEmpty ? b.nextDueDate : remoteB.nextDueDate,
              clientReply: b.clientReply != 'Pending' ? b.clientReply : remoteB.clientReply,
              lastEmailDate: b.lastEmailDate.isNotEmpty ? b.lastEmailDate : remoteB.lastEmailDate,
              followupCount: b.followupCount > remoteB.followupCount ? b.followupCount : remoteB.followupCount,
              status: b.status != 'New' ? b.status : remoteB.status,
              nextAction: b.nextAction.isNotEmpty ? b.nextAction : remoteB.nextAction,
              notes: b.notes.isNotEmpty ? b.notes : remoteB.notes,
            );
          } else if (key.isNotEmpty) {
            mapByCompany[key] = b;
          }
        }

        _buyers = mapByCompany.values.toList();
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
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    
    _filteredCache = [];
    _overdueCache = [];
    _followupTodayCache = [];
    _firstEmailCache = [];
    _allFollowupQueueCache = [];

    int counter = 1;

    for (var b in _buyers) {
      bool matchesSearch = query.isEmpty ||
          b.company.toLowerCase().contains(query) ||
          b.email.toLowerCase().contains(query) ||
          b.id.toLowerCase().contains(query);

      if (!matchesSearch) continue;

      if (_statusFilter != 'All Statuses' && _statusFilter != 'All') {
        if (b.status != _statusFilter) continue;
      }
      if (_replyFilter != 'All Replies' && _replyFilter != 'All') {
        if (b.clientReply != _replyFilter) continue;
      }

      final buyer = b.copyWith(srNo: counter++);
      _filteredCache.add(buyer);

      // Category logic for Daily Work Area
      bool isConverted = b.clientReply.toLowerCase() == 'yes' || b.clientReply.toLowerCase() == 'hold';
      
      if (!isConverted) {
        // 1. Overdue
        if (b.nextDueDate.isNotEmpty && b.nextDueDate.compareTo(todayStr) < 0) {
          _overdueCache.add(buyer);
        }
        // 2. Follow-ups Today
        if (b.isDueToday() && b.followupCount > 0 && (b.nextDueDate.isEmpty || b.nextDueDate.compareTo(todayStr) <= 0)) {
           _followupTodayCache.add(buyer);
        }
        // 3. First Emails (Any buyer with 0 follow-ups or no first email date yet)
        if (b.followupCount == 0 || b.firstEmailDate.isEmpty || b.status == 'New' || b.status == 'First Email Pending' || b.status == 'Contacted') {
          _firstEmailCache.add(buyer);
        }
      }

      // 4. All Follow-up Queue
      if (b.followupCount > 0 || b.status.contains('Follow-Up')) {
        _allFollowupQueueCache.add(buyer);
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
  int get dueTodayCount => _buyers.where((b) => b.isDueToday() && b.clientReply != 'Yes' && b.clientReply != 'Hold').length;
  int get firstEmailCount => _buyers.where((b) => b.firstEmailDate.isEmpty || b.status == 'New' || b.status == 'First Email Pending').length;
  int get todayFollowupCount => _buyers.where((b) => b.isDueToday() && b.followupCount > 0 && b.clientReply != 'Yes' && b.clientReply != 'Hold').length;
  int get activeFollowupCount => _buyers.where((b) => b.followupCount > 0).length;
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

  Future<bool> markEmailSent(String buyerId) async {
    final index = _buyers.indexWhere((b) => b.id == buyerId);
    if (index < 0) return false;

    final existing = _buyers[index];
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final nextDueStr = Buyer.calculateNextDueDate(DateTime.now());

    final updatedCount = existing.followupCount + 1;
    final updated = existing.copyWith(
      firstEmailDate: existing.firstEmailDate.isEmpty ? todayStr : existing.firstEmailDate,
      lastEmailDate: todayStr,
      nextDueDate: nextDueStr,
      followupCount: updatedCount,
      status: 'Follow-Up $updatedCount Sent',
    );

    _buyers[index] = updated;
    _rebuildCaches(preservePage: true);
    await _saveLocalBuyers();
    notifyListeners();

    await _apiService.saveBuyer(updated);
    return true;
  }

  Future<bool> batchProcessSelected({bool sendGmail = false}) async {
    if (_selectedBuyerIds.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    int updatedCount = await _apiService.batchMarkSent(_selectedBuyerIds.toList(), sendEmail: sendGmail);
    _selectedBuyerIds.clear();
    await loadBuyers();
    return updatedCount > 0;
  }

  Future<bool> batchProcessSelectedCustom(List<String> ids, {bool sendGmail = false}) async {
    if (ids.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    int updatedCount = await _apiService.batchMarkSent(ids, sendEmail: sendGmail);
    await loadBuyers();
    return updatedCount > 0;
  }

  Future<bool> saveBuyer(Buyer buyer) async {
    int index = _buyers.indexWhere((b) => b.id == buyer.id);
    if (index < 0 && buyer.company.trim().isNotEmpty) {
      index = _buyers.indexWhere((b) => b.company.trim().toLowerCase() == buyer.company.trim().toLowerCase());
    }

    bool isEditing = index >= 0;
    if (isEditing) {
      _buyers[index] = buyer;
      _rebuildCaches(preservePage: true);
    } else {
      final newSrNo = _buyers.length + 1;
      _buyers.add(buyer.copyWith(srNo: newSrNo));
      _rebuildCaches(preservePage: false);
      _currentPage = totalPages;
      _firstEmailDisplayedCount = _firstEmailCache.length;
    }
    await _saveLocalBuyers();
    notifyListeners();

    bool res = await _apiService.saveBuyer(buyer);
    return res;
  }

  Future<bool> deleteBuyer(String id) async {
    _buyers.removeWhere((b) => b.id == id);
    _selectedBuyerIds.remove(id);
    _rebuildCaches(preservePage: true);
    await _saveLocalBuyers();
    notifyListeners();

    bool res = await _apiService.deleteBuyer(id);
    return res;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
