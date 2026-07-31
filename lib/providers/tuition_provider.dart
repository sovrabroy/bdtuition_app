import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TuitionProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  List<dynamic> _tuitions = [];
  // Tuition IDs the teacher has applied to during this session. Lets the UI
  // show "Already Applied" instantly even if the backend hasn't refreshed the
  // has_applied flag yet.
  final Set<int> _appliedIds = {};
  Map<String, dynamic>? _selectedTuition;
  List<String> _cities = [];
  List<String> _areas = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;

  // Filters
  String? _selectedCity;
  List<String> _selectedAreas = [];
  String? _selectedGender;
  String? _searchCode;

  /// Tuition list with a locally-tracked `has_applied` flag merged in, so cards
  /// reflect an application immediately without waiting on the backend.
  List<dynamic> get tuitions => _tuitions.map((t) {
        if (t is Map<String, dynamic> && _appliedIds.contains(t['id'])) {
          return {...t, 'has_applied': true};
        }
        return t;
      }).toList();

  Map<String, dynamic>? get selectedTuition {
    final t = _selectedTuition;
    if (t != null && _appliedIds.contains(t['id'])) {
      return {...t, 'has_applied': true};
    }
    return t;
  }

  bool hasApplied(int id) => _appliedIds.contains(id);
  List<String> get cities => _cities;
  List<String> get areas => _areas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get total => _total;
  String? get selectedCity => _selectedCity;
  List<String> get selectedAreas => _selectedAreas;
  String? get selectedGender => _selectedGender;

  Future<void> loadTuitions({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _tuitions = [];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.getTuitions(
        page: _currentPage,
        city: _selectedCity,
        area: _selectedAreas.isNotEmpty ? _selectedAreas : null,
        gender: _selectedGender,
        tuitionCode: _searchCode,
      );

      final data = response.data;
      if (data['success'] == true) {
        if (refresh) {
          _tuitions = List.from(data['data']);
        } else {
          _tuitions.addAll(List.from(data['data']));
        }
        _currentPage = data['pagination']['current_page'];
        _lastPage = data['pagination']['last_page'];
        _total = data['pagination']['total'];
      }
    } catch (e) {
      _error = 'Failed to load tuitions';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadNextPage() async {
    if (_currentPage < _lastPage) {
      _currentPage++;
      await loadTuitions();
    }
  }

  Future<void> loadTuitionDetails(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.getTuitionDetails(id);
      if (response.data['success'] == true) {
        _selectedTuition = response.data['data'];
      }
    } catch (e) {
      _error = 'Failed to load details';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> applyForTuition(int tuitionId, String reference) async {
    try {
      final response = await _api.applyForTuition(tuitionId, reference);
      final data = response.data;
      if (data['success'] == true) {
        // Remember locally so the UI shows "Already Applied" right away.
        _appliedIds.add(tuitionId);
        notifyListeners();
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Failed to apply'};
    }
  }

  Future<void> loadCities() async {
    try {
      final response = await _api.getCities();
      if (response.data['success'] == true) {
        _cities = List<String>.from(response.data['data'])..sort();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> loadAreas(String city) async {
    try {
      final response = await _api.getAreas(city);
      if (response.data['success'] == true) {
        _areas = List<String>.from(response.data['data'])..sort();
        notifyListeners();
      }
    } catch (_) {}
  }

  void setFilters({String? city, List<String>? areas, String? gender, String? code}) {
    _selectedCity = city;
    _selectedAreas = areas ?? [];
    _selectedGender = gender;
    _searchCode = code;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCity = null;
    _selectedAreas = [];
    _selectedGender = null;
    _searchCode = null;
    _areas = [];
    notifyListeners();
  }
}
