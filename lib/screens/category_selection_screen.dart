import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/categories.dart';
import '../services/auth_service.dart';
import '../widgets/category_art.dart';

class CategorySelectionScreen extends StatefulWidget {
  final VoidCallback onSelectionComplete;

  const CategorySelectionScreen({
    super.key,
    required this.onSelectionComplete,
  });

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  final Set<String> _selectedCategories = {};
  final _authService = AuthService();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Profile fields
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _usernameFormKey = GlobalKey<FormState>();
  
  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(),
                    
                    // Profile Section (Username & Bio)
                    _buildProfileSection(),
                    
                    // Categories Grid
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: _buildCategoriesGrid(),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Section
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Complete Your Profile',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Form(
            key: _usernameFormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: 'Username',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.person, color: AppColors.textSecondary),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username is required';
                    }
                    if (value.trim().length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    hintText: 'Bio (optional)',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.info_outline, color: AppColors.textSecondary),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 2,
                  maxLength: 150,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            AppStrings.selectCategories,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.selectCategoriesSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          // Selection counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedCategories.length >= 3
                    ? AppColors.success
                    : AppColors.border,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _selectedCategories.length >= 3
                      ? Icons.check_circle
                      : Icons.info_outline,
                  color: _selectedCategories.length >= 3
                      ? AppColors.success
                      : AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_selectedCategories.length} ${AppStrings.categoriesSelected}',
                  style: TextStyle(
                    color: _selectedCategories.length >= 3
                        ? AppColors.success
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: AppCategories.all.length,
        itemBuilder: (context, index) {
          final category = AppCategories.all[index];
          final isSelected = _selectedCategories.contains(category);

          return _buildCategoryCard(category, isSelected);
        },
      ),
    );
  }

  Widget _buildCategoryCard(String category, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedCategories.remove(category);
          } else {
            _selectedCategories.add(category);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTint : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The fandom's illustration rather than an emoji glyph.
            CategoryArtView(category: category, size: 48, selected: isSelected),
            const SizedBox(height: 10),
            Text(
              AppCategories.label(category),
              style: TextStyle(
                color: isSelected ? AppColors.primaryLight : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              const SizedBox(height: 6),
              const Icon(Icons.check_circle, color: AppColors.primary, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          ElevatedButton(
            onPressed: _isLoading ? null : _handleContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedCategories.length >= 3
                  ? AppColors.primary
                  : AppColors.surface,
              foregroundColor: _selectedCategories.length >= 3
                  ? Colors.white
                  : AppColors.textTertiary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              side: BorderSide(
                color: _selectedCategories.length >= 3
                    ? Colors.transparent
                    : AppColors.border,
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    AppStrings.continueText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedCategories.length >= 3
                          ? Colors.white
                          : AppColors.textTertiary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleContinue() async {
    // Clear previous error
    setState(() => _errorMessage = null);

    // Validate username
    if (!_usernameFormKey.currentState!.validate()) {
      return;
    }

    // Validate selection
    if (_selectedCategories.length < 3) {
      setState(() => _errorMessage = AppStrings.selectMinimum);
      _showErrorSnackBar(AppStrings.selectMinimum);
      return;
    }

    setState(() => _isLoading = true);

    // Update profile (username and bio)
    final profileResult = await _authService.updateUserProfile(
      username: _usernameController.text,
      bio: _bioController.text,
    );

    if (!profileResult.isSuccess) {
      setState(() => _isLoading = false);
      setState(() => _errorMessage = profileResult.error);
      _showErrorSnackBar(profileResult.error ?? AppStrings.errorOccurred);
      return;
    }

    // Update categories. Normalise to the canonical lowercase vocabulary so
    // arrayContains queries match seeded data.
    final result = await _authService.updateUserCategories(
      _selectedCategories.map(AppCategories.normalize).toList(),
    );

    setState(() => _isLoading = false);

    if (result.isSuccess && mounted) {
      widget.onSelectionComplete();
    } else if (mounted) {
      setState(() => _errorMessage = result.error);
      _showErrorSnackBar(result.error ?? AppStrings.errorOccurred);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}