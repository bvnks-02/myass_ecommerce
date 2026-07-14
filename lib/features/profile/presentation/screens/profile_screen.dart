// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/security/input_sanitizer.dart';
import '../../../../core/security/input_validator.dart';
import '../../../../core/security/rate_limiter.dart';
import '../../../../core/services/dialog_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalController = TextEditingController();
  final TextEditingController _billingAddressController =
      TextEditingController();
  final TextEditingController _billingAddress2Controller =
      TextEditingController();
  final TextEditingController _billingCityController = TextEditingController();
  final TextEditingController _billingPostalController = TextEditingController();

  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  bool _billingSameAsShipping = true;
  Uint8List? _avatarPreview;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshRole();
      await authProvider.loadProfile();
      authProvider.clearError();
      _initData();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _addressController.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _postalController.dispose();
    _billingAddressController.dispose();
    _billingAddress2Controller.dispose();
    _billingCityController.dispose();
    _billingPostalController.dispose();
    super.dispose();
  }

  void _initData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    _nameController.text = user.userMetadata?['full_name'] ?? '';
    _emailController.text = user.email ?? '';
    _phoneController.text = user.userMetadata?['phone'] ?? '';

    _heightController.text = authProvider.height?.toString() ?? '';
    _weightController.text = authProvider.weight?.toString() ?? '';
    _addressController.text = authProvider.addressLine1 ?? '';
    _address2Controller.text = authProvider.addressLine2 ?? '';
    _cityController.text = authProvider.city ?? '';
    _postalController.text = authProvider.postalCode ?? '';
    _billingSameAsShipping = authProvider.billingSameAsShipping;
    _billingAddressController.text = authProvider.billingAddressLine1 ?? '';
    _billingAddress2Controller.text = authProvider.billingAddressLine2 ?? '';
    _billingCityController.text = authProvider.billingCity ?? '';
    _billingPostalController.text = authProvider.billingPostalCode ?? '';
  }

  Future<void> _pickAvatar() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';

      setState(() {
        _avatarPreview = bytes;
        _isUploadingAvatar = true;
      });

      final url = await authProvider.updateAvatar(bytes, ext);
      if (!mounted) return;
      if (url != null) {
        AppSnackBar.success(context, 'Photo de profil mise à jour.');
      } else {
        AppSnackBar.error(context, 'Le téléversement de la photo a échoué.');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Impossible de sélectionner l\'image.');
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _saveProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Rate limiting check
    if (!RateLimiters.api.isAllowed('profile_update')) {
      AppSnackBar.warning(
          context, 'Trop de tentatives. Veuillez réessayer plus tard.');
      return;
    }

    // --- Sanitize ---
    final name =
        InputSanitizer.sanitizeString(_nameController.text.trim(), maxLength: 100);
    final phone = InputSanitizer.sanitizeNumeric(_phoneController.text.trim());
    final address =
        InputSanitizer.sanitizeString(_addressController.text.trim(), maxLength: 200);
    final address2 = InputSanitizer.sanitizeString(
        _address2Controller.text.trim(),
        maxLength: 200);
    final city =
        InputSanitizer.sanitizeString(_cityController.text.trim(), maxLength: 100);
    final postal = InputSanitizer.sanitizeString(_postalController.text.trim(),
        maxLength: 20);
    final billingAddress = InputSanitizer.sanitizeString(
        _billingAddressController.text.trim(),
        maxLength: 200);
    final billingAddress2 = InputSanitizer.sanitizeString(
        _billingAddress2Controller.text.trim(),
        maxLength: 200);
    final billingCity = InputSanitizer.sanitizeString(
        _billingCityController.text.trim(),
        maxLength: 100);
    final billingPostal = InputSanitizer.sanitizeString(
        _billingPostalController.text.trim(),
        maxLength: 20);
    final heightRaw = _heightController.text.trim();
    final weightRaw = _weightController.text.trim();

    // --- Validate ---
    final nameError = InputValidator.validateFullName(name);
    if (nameError != null) {
      AppSnackBar.warning(context, 'Nom : $nameError');
      return;
    }
    if (phone.isNotEmpty) {
      final phoneError = InputValidator.validatePhoneNumber(phone);
      if (phoneError != null) {
        AppSnackBar.warning(context, 'Téléphone : $phoneError');
        return;
      }
    }

    double? height;
    if (heightRaw.isNotEmpty) {
      final err = InputValidator.validateNumeric(heightRaw, min: 30, max: 300);
      if (err != null) {
        AppSnackBar.warning(context, 'Taille (cm) : $err');
        return;
      }
      height = double.parse(heightRaw);
    }

    double? weight;
    if (weightRaw.isNotEmpty) {
      final err = InputValidator.validateNumeric(weightRaw, min: 20, max: 500);
      if (err != null) {
        AppSnackBar.warning(context, 'Poids (kg) : $err');
        return;
      }
      weight = double.parse(weightRaw);
    }

    setState(() => _isSaving = true);
    try {
      // 1. Name / phone live in auth user metadata (unchanged convention).
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'full_name': name, 'phone': phone}),
      );

      // 2. Extended fields go to public.user_profiles via the provider.
      final ok = await authProvider.saveProfileDetails(
        height: height,
        weight: weight,
        addressLine1: address.isEmpty ? null : address,
        addressLine2: address2.isEmpty ? null : address2,
        city: city.isEmpty ? null : city,
        postalCode: postal.isEmpty ? null : postal,
        billingSameAsShipping: _billingSameAsShipping,
        billingAddressLine1: billingAddress.isEmpty ? null : billingAddress,
        billingAddressLine2: billingAddress2.isEmpty ? null : billingAddress2,
        billingCity: billingCity.isEmpty ? null : billingCity,
        billingPostalCode: billingPostal.isEmpty ? null : billingPostal,
      );

      if (!mounted) return;
      if (ok) {
        await authProvider.refreshRole();
        AppSnackBar.success(context, 'Profil mis à jour avec succès !');
      } else {
        AppSnackBar.error(
            context, authProvider.errorMessage ?? 'Échec de la mise à jour.');
      }
    } catch (e) {
      if (mounted) {
        final message = e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('AuthException: ', '');
        AppSnackBar.error(context, 'Mise à jour impossible : $message');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Scaffold(
          backgroundColor: AppTheme.blackColor,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, authProvider),
                Expanded(
                  child: authProvider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : SingleChildScrollView(
                          padding: EdgeInsets.only(
                            left: ResponsiveUtils.padding(context),
                            right: ResponsiveUtils.padding(context),
                            top: ResponsiveUtils.sh(context, 20),
                            bottom: ResponsiveUtils.sh(context, 100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProfileHeader(authProvider),
                              const SizedBox(height: 30),
                              _buildUserInfo(),
                              const SizedBox(height: 20),
                              _buildBodyMetrics(),
                              const SizedBox(height: 20),
                              _buildShippingAddress(),
                              const SizedBox(height: 20),
                              _buildBillingAddress(),
                              const SizedBox(height: 25),
                              _buildSaveButton(),
                              const SizedBox(height: 30),
                              _buildSettings(authProvider),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider authProvider) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveUtils.padding(context)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false),
            child: Container(
              padding: EdgeInsets.all(ResponsiveUtils.sw(context, 12)),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: ResponsiveUtils.sf(context, 20),
              ),
            ),
          ),
          Text(
            'Profil',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveUtils.sf(context, 20),
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () async {
              await authProvider.refreshRole();
              await authProvider.loadProfile();
              if (mounted) {
                _initData();
                setState(() {});
              }
            },
            child: Container(
              padding: EdgeInsets.all(ResponsiveUtils.sw(context, 12)),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Icon(
                Icons.refresh,
                color: Colors.white70,
                size: ResponsiveUtils.sf(context, 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(AuthProvider authProvider) {
    final name = authProvider.user?.userMetadata?['full_name'] ?? 'Utilisateur Myazz';
    final role = authProvider.isAdmin ? 'Admin' : 'Client';
    final avatarUrl = authProvider.avatarUrl;

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: ResponsiveUtils.sw(context, 90),
                height: ResponsiveUtils.sw(context, 90),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                  image: _avatarPreview != null
                      ? DecorationImage(
                          image: MemoryImage(_avatarPreview!), fit: BoxFit.cover)
                      : (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                          : null,
                ),
                child: (_avatarPreview == null &&
                        (avatarUrl == null || avatarUrl.isEmpty))
                    ? Icon(
                        Icons.person,
                        size: ResponsiveUtils.sf(context, 44),
                        color: Colors.white,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploadingAvatar ? null : _pickAvatar,
                  child: Container(
                    padding: EdgeInsets.all(ResponsiveUtils.sw(context, 8)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppTheme.blackColor, width: 2),
                    ),
                    child: _isUploadingAvatar
                        ? SizedBox(
                            width: ResponsiveUtils.sf(context, 14),
                            height: ResponsiveUtils.sf(context, 14),
                            child: const CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2),
                          )
                        : Icon(Icons.camera_alt,
                            color: Colors.black,
                            size: ResponsiveUtils.sf(context, 14)),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.sh(context, 12)),
          Text(
            name,
            style: TextStyle(
              fontSize: ResponsiveUtils.sf(context, 20),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: ResponsiveUtils.sh(context, 5)),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.sw(context, 12),
                vertical: ResponsiveUtils.sh(context, 4)),
            decoration: BoxDecoration(
              color: authProvider.isAdmin
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role,
              style: TextStyle(
                fontSize: ResponsiveUtils.sf(context, 12),
                color: authProvider.isAdmin ? Colors.blue : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.padding(context)),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveUtils.sf(context, 18),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: ResponsiveUtils.sh(context, 20)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return _buildCard(
      title: 'Informations personnelles',
      children: [
        _buildInfoField(Icons.person, 'Nom complet', _nameController),
        SizedBox(height: ResponsiveUtils.sh(context, 15)),
        _buildInfoField(Icons.email, 'E-mail', _emailController,
            readOnly: true),
        SizedBox(height: ResponsiveUtils.sh(context, 15)),
        _buildInfoField(Icons.phone, 'Téléphone', _phoneController,
            keyboardType: TextInputType.phone),
      ],
    );
  }

  Widget _buildBodyMetrics() {
    return _buildCard(
      title: 'Mensurations',
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoField(
                Icons.height,
                'Taille (cm)',
                _heightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
              ),
            ),
            SizedBox(width: ResponsiveUtils.sw(context, 15)),
            Expanded(
              child: _buildInfoField(
                Icons.monitor_weight_outlined,
                'Poids (kg)',
                _weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShippingAddress() {
    return _buildCard(
      title: 'Adresse de livraison',
      children: [
        _buildInfoField(
            Icons.home_outlined, 'Adresse (ligne 1)', _addressController),
        SizedBox(height: ResponsiveUtils.sh(context, 15)),
        _buildInfoField(Icons.home_work_outlined, 'Adresse (ligne 2)',
            _address2Controller),
        SizedBox(height: ResponsiveUtils.sh(context, 15)),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildInfoField(
                  Icons.location_city, 'Ville', _cityController),
            ),
            SizedBox(width: ResponsiveUtils.sw(context, 15)),
            Expanded(
              child: _buildInfoField(
                Icons.markunread_mailbox_outlined,
                'Code postal',
                _postalController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBillingAddress() {
    return _buildCard(
      title: 'Adresse de facturation',
      children: [
        Row(
          children: [
            SizedBox(
              height: ResponsiveUtils.sh(context, 24),
              width: ResponsiveUtils.sw(context, 24),
              child: Checkbox(
                value: _billingSameAsShipping,
                activeColor: Colors.white,
                checkColor: Colors.black,
                side: const BorderSide(color: Colors.white54),
                onChanged: (v) =>
                    setState(() => _billingSameAsShipping = v ?? true),
              ),
            ),
            SizedBox(width: ResponsiveUtils.sw(context, 12)),
            Expanded(
              child: Text(
                'Identique à l\'adresse de livraison',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: ResponsiveUtils.sf(context, 14),
                ),
              ),
            ),
          ],
        ),
        if (!_billingSameAsShipping) ...[
          SizedBox(height: ResponsiveUtils.sh(context, 20)),
          _buildInfoField(Icons.receipt_long_outlined, 'Adresse (ligne 1)',
              _billingAddressController),
          SizedBox(height: ResponsiveUtils.sh(context, 15)),
          _buildInfoField(Icons.receipt_long_outlined, 'Adresse (ligne 2)',
              _billingAddress2Controller),
          SizedBox(height: ResponsiveUtils.sh(context, 15)),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildInfoField(
                    Icons.location_city, 'Ville', _billingCityController),
              ),
              SizedBox(width: ResponsiveUtils.sw(context, 15)),
              Expanded(
                child: _buildInfoField(
                  Icons.markunread_mailbox_outlined,
                  'Code postal',
                  _billingPostalController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding:
              EdgeInsets.symmetric(vertical: ResponsiveUtils.sh(context, 16)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _isSaving
            ? SizedBox(
                height: ResponsiveUtils.sh(context, 20),
                width: ResponsiveUtils.sw(context, 20),
                child: const CircularProgressIndicator(
                    color: Colors.black, strokeWidth: 2),
              )
            : Text(
                'Enregistrer',
                style: TextStyle(
                  fontSize: ResponsiveUtils.sf(context, 15),
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildInfoField(
    IconData icon,
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white),
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildSettings(AuthProvider authProvider) {
    return _buildCard(
      title: 'Paramètres',
      children: [
        if (authProvider.isAdmin)
          _buildSettingItem(
            Icons.admin_panel_settings,
            'Tableau de bord admin',
            'Gérer les produits et les commandes',
            () async {
              final isAdmin = await authProvider.checkIsAdmin();
              if (isAdmin && mounted) {
                Navigator.pushNamed(context, '/admin');
              }
            },
          ),
        _buildSettingItem(
          Icons.receipt_long,
          'Mes commandes',
          'Consulter l\'historique de vos commandes',
          () => Navigator.pushNamed(context, '/my_orders'),
        ),
        _buildSettingItem(
          Icons.notifications,
          'Notifications',
          'Gérer vos notifications',
          () => Navigator.pushNamed(context, '/notifications'),
        ),
        _buildSettingItem(
          Icons.security,
          'Confidentialité et sécurité',
          'Gérer vos paramètres de confidentialité',
          () => Navigator.pushNamed(context, '/privacy_security'),
        ),
        _buildSettingItem(
          Icons.help,
          'Aide et support',
          'Obtenir de l\'aide et du support',
          () => Navigator.pushNamed(context, '/help_support'),
        ),
        _buildSettingItem(
          Icons.info,
          'À propos',
          'Version de l\'application 1.0.0',
          () => Navigator.pushNamed(context, '/about'),
        ),
        _buildSettingItem(
          Icons.logout,
          'Déconnexion',
          'Se déconnecter de votre compte',
          () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[400]),
      ),
      trailing: Icon(Icons.arrow_forward_ios,
          color: Colors.grey, size: ResponsiveUtils.sf(context, 16)),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    context.dialogs.showLogoutConfirmation(
      onConfirm: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.signOut();
        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
    );
  }
}
