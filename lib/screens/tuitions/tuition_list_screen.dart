import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/tuition_provider.dart';
import 'tuition_detail_screen.dart';

class TuitionListScreen extends StatefulWidget {
  const TuitionListScreen({super.key});

  @override
  State<TuitionListScreen> createState() => _TuitionListScreenState();
}

class _TuitionListScreenState extends State<TuitionListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TuitionProvider>(context, listen: false);
      provider.loadTuitions(refresh: true);
      provider.loadCities();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    final provider = Provider.of<TuitionProvider>(context, listen: false);
    if (provider.currentPage >= provider.lastPage) return;

    setState(() => _isLoadingMore = true);
    await provider.loadNextPage();
    setState(() => _isLoadingMore = false);
  }

  void _showFilterSheet() {
    final provider = Provider.of<TuitionProvider>(context, listen: false);
    String? tempCity = provider.selectedCity;
    List<String> tempAreas = List.from(provider.selectedAreas);
    String? tempGender = provider.selectedGender;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.85,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filter Tuitions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempCity = null;
                                tempAreas = [];
                                tempGender = null;
                              });
                            },
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // City selection
                      const Text(
                        'City',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Consumer<TuitionProvider>(
                        builder: (_, tp, __) => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tp.cities.map((city) {
                            final selected = tempCity == city;
                            return FilterChip(
                              label: Text(city),
                              selected: selected,
                              selectedColor:
                                  AppTheme.primaryColor.withOpacity(0.2),
                              checkmarkColor: AppTheme.primaryColor,
                              onSelected: (val) {
                                setModalState(() {
                                  tempCity = val ? city : null;
                                  tempAreas = [];
                                });
                                if (val) {
                                  tp.loadAreas(city);
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Area selection
                      Consumer<TuitionProvider>(
                        builder: (_, tp, __) {
                          if (tempCity == null || tp.areas.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Area',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: tp.areas.map((area) {
                                  final selected = tempAreas.contains(area);
                                  return FilterChip(
                                    label: Text(area),
                                    selected: selected,
                                    selectedColor:
                                        AppTheme.primaryColor.withOpacity(0.2),
                                    checkmarkColor: AppTheme.primaryColor,
                                    onSelected: (val) {
                                      setModalState(() {
                                        if (val) {
                                          tempAreas.add(area);
                                        } else {
                                          tempAreas.remove(area);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),

                      // Gender filter
                      const Text(
                        'Preferred Gender',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['Male', 'Female', 'Any'].map((g) {
                          final selected = tempGender == g;
                          return ChoiceChip(
                            label: Text(g),
                            selected: selected,
                            selectedColor:
                                AppTheme.primaryColor.withOpacity(0.2),
                            onSelected: (val) {
                              setModalState(() {
                                tempGender = val ? g : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Apply button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            provider.setFilters(
                              city: tempCity,
                              areas: tempAreas,
                              gender: tempGender,
                            );
                            provider.loadTuitions(refresh: true);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _searchByCode(String code) {
    final provider = Provider.of<TuitionProvider>(context, listen: false);
    provider.setFilters(
      city: provider.selectedCity,
      areas: provider.selectedAreas,
      gender: provider.selectedGender,
      code: code.isNotEmpty ? code : null,
    );
    provider.loadTuitions(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar and filter
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by tuition code...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _searchByCode('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: _searchByCode,
                  onChanged: (val) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _showFilterSheet,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.filter_list, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Active filter chips
        Consumer<TuitionProvider>(
          builder: (_, provider, __) {
            final hasFilters = provider.selectedCity != null ||
                provider.selectedAreas.isNotEmpty ||
                provider.selectedGender != null;
            if (!hasFilters) return const SizedBox.shrink();
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: AppTheme.primaryColor.withOpacity(0.05),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (provider.selectedCity != null)
                    Chip(
                      label: Text(
                        provider.selectedCity!,
                        style: const TextStyle(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        provider.setFilters(
                          gender: provider.selectedGender,
                        );
                        provider.loadTuitions(refresh: true);
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ...provider.selectedAreas.map(
                    (a) => Chip(
                      label: Text(a, style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        final areas = List<String>.from(provider.selectedAreas)
                          ..remove(a);
                        provider.setFilters(
                          city: provider.selectedCity,
                          areas: areas,
                          gender: provider.selectedGender,
                        );
                        provider.loadTuitions(refresh: true);
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  if (provider.selectedGender != null)
                    Chip(
                      label: Text(
                        provider.selectedGender!,
                        style: const TextStyle(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        provider.setFilters(
                          city: provider.selectedCity,
                          areas: provider.selectedAreas,
                        );
                        provider.loadTuitions(refresh: true);
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            );
          },
        ),

        // Tuition list
        Expanded(
          child: Consumer<TuitionProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.tuitions.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.error != null && provider.tuitions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppTheme.errorColor),
                      const SizedBox(height: 12),
                      Text(provider.error!,
                          style:
                              const TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            provider.loadTuitions(refresh: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (provider.tuitions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      const Text(
                        'No tuitions found',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          provider.clearFilters();
                          provider.loadTuitions(refresh: true);
                        },
                        child: const Text('Clear filters'),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => provider.loadTuitions(refresh: true),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount:
                      provider.tuitions.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.tuitions.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final tuition = provider.tuitions[index];
                    return _TuitionCard(
                      tuition: tuition,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TuitionDetailScreen(
                              tuitionId: tuition['id'],
                            ),
                          ),
                        );
                      },
                      onApply: (tuition['can_apply'] == true &&
                              tuition['has_applied'] != true)
                          ? () => _showApplyDialog(tuition['id'])
                          : null,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showApplyDialog(int tuitionId) {
    final referenceController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apply for Tuition'),
        content: TextField(
          controller: referenceController,
          decoration: const InputDecoration(
            labelText: 'Authority Reference',
            hintText: 'Enter your reference (optional)',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider =
                  Provider.of<TuitionProvider>(context, listen: false);
              final result = await provider.applyForTuition(
                tuitionId,
                referenceController.text.trim(),
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result['message'] ?? (result['success'] == true
                        ? 'Applied successfully!'
                        : 'Failed to apply'),
                  ),
                  backgroundColor: result['success'] == true
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                ),
              );
              if (result['success'] == true) {
                provider.loadTuitions(refresh: true);
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _TuitionCard extends StatelessWidget {
  final Map<String, dynamic> tuition;
  final VoidCallback onTap;
  final VoidCallback? onApply;

  const _TuitionCard({
    required this.tuition,
    required this.onTap,
    this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tuition['tuition_code'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '৳${tuition['salary'] ?? '0'}/mo',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Location
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${tuition['area'] ?? ''}, ${tuition['city'] ?? ''}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Details row
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _DetailChip(
                    icon: Icons.class_,
                    text: tuition['class'] ?? '',
                  ),
                  _DetailChip(
                    icon: Icons.language,
                    text: tuition['medium'] ?? '',
                  ),
                  _DetailChip(
                    icon: Icons.person,
                    text: tuition['prefered_gender'] ?? '',
                  ),
                  _DetailChip(
                    icon: Icons.calendar_today,
                    text: '${tuition['day_per_week'] ?? ''} days/wk',
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Apply button
              if (tuition['has_applied'] == true)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Already Applied',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                )
              else if (onApply != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onApply,
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Apply Now'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
