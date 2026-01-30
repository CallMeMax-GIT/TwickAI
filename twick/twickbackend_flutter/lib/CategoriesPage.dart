import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:twickbackend_flutter/TaskListPage.dart';
import 'package:twickbackend_flutter/models/Category.dart';
import 'package:twickbackend_flutter/models/CategoryList.dart';
import 'package:twickbackend_flutter/models/TaskList.dart';

// ───────────────── DELAYED ANIMATION WIDGET ─────────────────
class DelayedWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Object? resetTrigger; // Trigger to reset animation

  const DelayedWidget({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 0),
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeOut,
    this.resetTrigger,
  });

  @override
  State<DelayedWidget> createState() => _DelayedWidgetState();
}

class _DelayedWidgetState extends State<DelayedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Object? _lastResetTrigger;

  @override
  void initState() {
    super.initState();
    _lastResetTrigger = widget.resetTrigger;
    _initializeAnimation();
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(DelayedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset animation if resetTrigger changed
    if (widget.resetTrigger != null && 
        widget.resetTrigger != _lastResetTrigger) {
      _lastResetTrigger = widget.resetTrigger;
      _controller.reset();
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DelayedWidget(
                delay: const Duration(milliseconds: 0),
                resetTrigger: widget.key,
                child: _header(),
              ),
              const SizedBox(height: 24),
              DelayedWidget(
                delay: const Duration(milliseconds: 150),
                resetTrigger: widget.key,
                child: _categoryGrid(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────── HEADER ─────────────────
  Widget _header() {
    return Obx(
      () => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
          'Categories',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
          const SizedBox(height: 6),
        Text(
            'Managing ${allCategories.length} active categories',
            style: TextStyle(
            color: Colors.grey[600],
            fontSize: 15,
          ),
        ),
      ],
      ),
    );
  }

  // ───────────────── GRID ─────────────────
  Widget _categoryGrid(BuildContext context) {
    return Obx(
      () {
        final List<Widget> categoryWidgets = <Widget>[];
        
        // Add all category cards
        for (final category in allCategories) {
          final taskCount = TaskFilters.getTaskCountByCategoryId(category.id);
          final completedCount = TaskFilters.getCompletedCountByCategoryId(category.id);
          final progress = taskCount > 0 ? completedCount / taskCount : 0.0;

          categoryWidgets.add(
            _CategoryCard(
              key: ValueKey(category.id),
              category: category,
              taskCount: taskCount,
              progress: progress,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskListPage(
                      filterType: TaskFilterType.all,
                      categoryId: category.id,
                    ),
                  ),
                );
              },
            ),
          );
        }

        // Add create category card as the last item
        categoryWidgets.add(
          _CreateCategoryGridCard(
            key: const ValueKey('create_category'),
            onTap: () => _showCreateCategoryBottomSheet(context),
          ),
        );

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.95,
          children: categoryWidgets,
        );
      },
    );
  }


  void _showCreateCategoryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => const _CreateCategoryBottomSheet(),
    );
  }
}

// ───────────────── CATEGORY CARD ─────────────────
class _CategoryCard extends StatelessWidget {
  final TaskCategory category;
  final int taskCount;
  final double progress;
  final VoidCallback onTap;

  const _CategoryCard({
    super.key,
    required this.category,
    required this.taskCount,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: category.color.withOpacity(0.15),
              ),
              child: Icon(category.icon, color: category.color, size: 24),
            ),
            const Spacer(),
            Text(
              category.name,
              style: TextStyle(
                color: Colors.grey[900],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$taskCount ${taskCount == 1 ? 'task' : 'tasks'}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(category.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────── CREATE CATEGORY GRID CARD ─────────────────
class _CreateCategoryGridCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateCategoryGridCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.add,
                color: Colors.grey[600],
                size: 24,
              ),
            ),
            const Spacer(),
            Text(
              'Create Category',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────── EDIT CATEGORY BOTTOM SHEET ─────────────────
class _EditCategoryBottomSheet extends StatefulWidget {
  final TaskCategory category;

  const _EditCategoryBottomSheet({required this.category});

  @override
  State<_EditCategoryBottomSheet> createState() => _EditCategoryBottomSheetState();
}

class _EditCategoryBottomSheetState extends State<_EditCategoryBottomSheet> {
  late TextEditingController _nameController;
  late IconData _selectedIcon;
  late Color _selectedColor;
  final _formKey = GlobalKey<FormState>();

  final List<IconData> _availableIcons = [
    Icons.folder,
    Icons.work,
    Icons.person,
    Icons.fitness_center,
    Icons.account_balance_wallet,
    Icons.school,
    Icons.home,
    Icons.shopping_cart,
    Icons.restaurant,
    Icons.music_note,
    Icons.movie,
    Icons.sports_soccer,
    Icons.book,
    Icons.car_repair,
    Icons.pets,
    Icons.favorite,
  ];

  final List<Color> _availableColors = [
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.redAccent,
    Colors.pinkAccent,
    Colors.tealAccent,
    Colors.cyanAccent,
    Colors.amberAccent,
    Colors.indigoAccent,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _selectedIcon = widget.category.icon;
    _selectedColor = widget.category.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateCategory() {
    if (_formKey.currentState!.validate()) {
      final index = allCategories.indexWhere((cat) => cat.id == widget.category.id);
      if (index != -1) {
        allCategories[index] = TaskCategory(
          id: widget.category.id,
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          color: _selectedColor,
        );
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Category',
                        style: TextStyle(
                          color: Colors.grey[900],
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Name Input
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: Colors.grey[900], fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Category Name',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.blue[600]!,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a category name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  // Icon Selection
                  Text(
                    'SELECT ICON',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _availableIcons.length,
                        itemBuilder: (context, index) {
                          final icon = _availableIcons[index];
                          final isSelected = icon == _selectedIcon;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIcon = icon;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color.fromARGB(255, 19, 38, 61)
                                      : Colors.grey[300]!,
                                  width: isSelected ? 2.5 : 1.5,
                                ),
                              ),
                              child: Icon(
                                icon,
                                color: isSelected 
                                    ? const Color.fromARGB(255, 19, 38, 61)
                                    : Colors.grey[600],
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 32),
                  // Color Selection
                  Text(
                    'SELECT COLOR',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _availableColors.length,
                        itemBuilder: (context, index) {
                          final color = _availableColors[index];
                          final isSelected = color == _selectedColor;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColor = color;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 32),
                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF3B82F6), // Blue
                                    Color(0xFF1E40AF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: _updateCategory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Update Category',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }
}

// ───────────────── CREATE CATEGORY BOTTOM SHEET ─────────────────
class _CreateCategoryBottomSheet extends StatefulWidget {
  const _CreateCategoryBottomSheet();

  @override
  State<_CreateCategoryBottomSheet> createState() => _CreateCategoryBottomSheetState();
}

class _CreateCategoryBottomSheetState extends State<_CreateCategoryBottomSheet> {
  final _nameController = TextEditingController();
  IconData _selectedIcon = Icons.folder;
  Color _selectedColor = Colors.blueAccent;
  final _formKey = GlobalKey<FormState>();

  final List<IconData> _availableIcons = [
    Icons.folder,
    Icons.work,
    Icons.person,
    Icons.fitness_center,
    Icons.account_balance_wallet,
    Icons.school,
    Icons.home,
    Icons.shopping_cart,
    Icons.restaurant,
    Icons.music_note,
    Icons.movie,
    Icons.sports_soccer,
    Icons.book,
    Icons.car_repair,
    Icons.pets,
    Icons.favorite,
  ];

  final List<Color> _availableColors = [
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.redAccent,
    Colors.pinkAccent,
    Colors.tealAccent,
    Colors.cyanAccent,
    Colors.amberAccent,
    Colors.indigoAccent,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createCategory() {
    if (_formKey.currentState!.validate()) {
      final category = TaskCategory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
      );

      allCategories.add(category);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create Category',
                        style: TextStyle(
                          color: Colors.grey[900],
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Name Input
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: Colors.grey[900]),
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                      hintText: 'Enter category name',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blue[600]!,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a category name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  // Icon Selection
                  Text(
                    'SELECT ICON',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableIcons.length,
                      itemBuilder: (context, index) {
                        final icon = _availableIcons[index];
                        final isSelected = icon == _selectedIcon;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIcon = icon;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color.fromARGB(255, 19, 38, 61)
                                    : Colors.grey[300]!,
                                width: isSelected ? 2.5 : 1.5,
                              ),
                            ),
                            child: Icon(
                              icon,
                              color: isSelected 
                                  ? const Color.fromARGB(255, 19, 38, 61)
                                  : Colors.grey[600],
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Color Selection
                  Text(
                    'SELECT COLOR',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableColors.length,
                      itemBuilder: (context, index) {
                        final color = _availableColors[index];
                        final isSelected = color == _selectedColor;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF3B82F6), // Blue
                                    Color(0xFF1E40AF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: _createCategory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Create Category',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
