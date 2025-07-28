import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/ln_address_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../models/ln_address.dart';

class LNAddressScreen extends StatefulWidget {
  const LNAddressScreen({super.key});

  @override
  State<LNAddressScreen> createState() => _LNAddressScreenState();
}

class _LNAddressScreenState extends State<LNAddressScreen> {
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedWalletId;
  bool _showCreateForm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  void _initializeScreen() {
    final authProvider = context.read<AuthProvider>();
    final walletProvider = context.read<WalletProvider>();
    final lnAddressProvider = context.read<LNAddressProvider>();

    if (walletProvider.primaryWallet != null) {
      final wallet = walletProvider.primaryWallet!;
      _selectedWalletId = wallet.id;
      
      lnAddressProvider.setAuthHeaders(wallet.inKey, wallet.adminKey);
      lnAddressProvider.setCurrentWallet(_selectedWalletId!);
    }

    lnAddressProvider.loadAllAddresses();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isMobile = screenWidth < 768;
          
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F1419),
                  Color(0xFF1A1D47),
                  Color(0xFF2D3FE7),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  
                  _buildHeader(),
                  
                  
                  Expanded(
                    child: Consumer3<LNAddressProvider, WalletProvider, AuthProvider>(
                      builder: (context, lnAddressProvider, walletProvider, authProvider, child) {
                        return Column(
                          children: [
                            
                            _buildWalletInfo(walletProvider, authProvider),
                            
                            
                            Expanded(
                              child: _showCreateForm
                                  ? _buildCreateForm(lnAddressProvider, walletProvider)
                                  : _buildAddressList(lnAddressProvider),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Title
          const Expanded(
            child: Text(
              'Lightning Address',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _refreshAddresses,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletInfo(WalletProvider walletProvider, AuthProvider authProvider) {
    final serverDomain = authProvider.sessionData?.serverUrl
        .replaceAll('https://', '')
        .replaceAll('http://', '') ?? 'your-server.com';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    walletProvider.primaryWallet?.name ?? 'Sin billetera seleccionada',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Servidor: $serverDomain',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList(LNAddressProvider lnAddressProvider) {
    if (lnAddressProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (lnAddressProvider.error != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error cargando direcciones',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lnAddressProvider.error!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildPrimaryButton(
                  text: 'Reintentar',
                  onPressed: _refreshAddresses,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (!lnAddressProvider.hasAddresses)
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.alternate_email,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sin Lightning addresses',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crea tu primera Lightning Address',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: lnAddressProvider.currentWalletAddresses.length,
              itemBuilder: (context, index) {
                final address = lnAddressProvider.currentWalletAddresses[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _buildAddressItem(address, lnAddressProvider),
                );
              },
            ),
          ),
        
        if (!_showCreateForm)
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: _buildPrimaryButton(
                text: 'Agregar Nueva Dirección',
                onPressed: () {
                  setState(() {
                    _showCreateForm = true;
                  });
                },
                icon: Icons.add,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddressItem(LNAddress address, LNAddressProvider lnAddressProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.alternate_email,
                color: Color(0xFF4C63F7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            address.fullAddress,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Por defecto',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleAddressAction(value, address, lnAddressProvider),
                iconColor: Colors.white,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'copy',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 18),
                        SizedBox(width: 8),
                        Text('Copiar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'set_default',
                    child: Row(
                      children: [
                        Icon(
                          address.isDefault ? Icons.star : Icons.star_border,
                          size: 18,
                          color: address.isDefault ? Colors.amber : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address.isDefault ? 'Es por defecto' : 'Establecer como por defecto',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          if (address.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              address.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: address.isDefault 
                      ? Colors.amber.withValues(alpha: 0.2)
                      : (address.isActive 
                          ? Colors.green.withValues(alpha: 0.2) 
                          : Colors.grey.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: address.isDefault 
                        ? Colors.amber.withValues(alpha: 0.3)
                        : (address.isActive 
                            ? Colors.green.withValues(alpha: 0.3) 
                            : Colors.grey.withValues(alpha: 0.3)),
                  ),
                ),
                child: Text(
                  address.isDefault ? 'Por defecto' : (address.isActive ? 'Activa' : 'Inactiva'),
                  style: TextStyle(
                    color: address.isDefault ? Colors.amber : (address.isActive ? Colors.green : Colors.grey),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Created: ${_formatDate(address.createdAt)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreateForm(LNAddressProvider lnAddressProvider, WalletProvider walletProvider) {
    final serverDomain = context.read<AuthProvider>().sessionData?.serverUrl
        .replaceAll('https://', '')
        .replaceAll('http://', '') ?? 'your-server.com';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF4C63F7),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Nueva Lightning Address',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setState(() {
                            _showCreateForm = false;
                            _usernameController.clear();
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  const Text(
                    'Wallet:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedWalletId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1A1D47),
                        style: const TextStyle(color: Colors.white),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        items: walletProvider.wallets.map((wallet) {
                          return DropdownMenuItem<String>(
                            value: wallet.id,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet,
                                  color: Color(0xFF4C63F7),
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    wallet.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedWalletId = newValue;
                            });
                            
                            
                            final selectedWallet = walletProvider.wallets.firstWhere(
                              (w) => w.id == newValue,
                            );
                            lnAddressProvider.setAuthHeaders(selectedWallet.inKey, selectedWallet.adminKey);
                            lnAddressProvider.setCurrentWallet(newValue);
                          }
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Username input
                  const Text(
                    'Lightning Address:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'satoshi',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF4C63F7),
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final error = LNAddress.getUsernameError(value);
                            return error.isEmpty ? null : error;
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_-]')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '@$serverDomain',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  // Error message
                  if (lnAddressProvider.error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lnAddressProvider.error!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildSecondaryButton(
                          text: 'Cancel',
                          onPressed: () {
                            setState(() {
                              _showCreateForm = false;
                              _usernameController.clear();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPrimaryButton(
                          text: lnAddressProvider.isCreating ? 'Creating...' : 'Create',
                          onPressed: lnAddressProvider.isCreating ? null : _createAddress,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2D3FE7),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _handleAddressAction(String action, LNAddress address, LNAddressProvider lnAddressProvider) {
    switch (action) {
      case 'copy':
        Clipboard.setData(ClipboardData(text: address.fullAddress));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${address.fullAddress} copiada'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 'set_default':
        _setAsDefault(address, lnAddressProvider);
        break;
      case 'delete':
        _showDeleteConfirmation(address, lnAddressProvider);
        break;
    }
  }

  void _setAsDefault(LNAddress address, LNAddressProvider lnAddressProvider) async {
    if (address.isDefault) {
      // If already default, do nothing
      return;
    }
    
    final success = await lnAddressProvider.setAsDefault(address.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${address.fullAddress} establecida como por defecto'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDeleteConfirmation(LNAddress address, LNAddressProvider lnAddressProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D47),
        title: const Text(
          'Delete Lightning Address',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete ${address.fullAddress}?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await lnAddressProvider.deleteLNAddress(address.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lightning Address eliminada'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _createAddress() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWalletId == null) return;

    context.read<LNAddressProvider>().clearError();
    
    final walletProvider = context.read<WalletProvider>();
    final selectedWallet = walletProvider.wallets.firstWhere(
      (w) => w.id == _selectedWalletId!,
    );
    
    final success = await context.read<LNAddressProvider>().createLNAddress(
      username: _usernameController.text.trim().toLowerCase(),
      walletId: _selectedWalletId!,
      description: 'Lightning Address for ${selectedWallet.name}',
    );

    if (success && mounted) {
      setState(() {
        _showCreateForm = false;
        _usernameController.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lightning Address created successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _refreshAddresses() {
    context.read<LNAddressProvider>().refresh();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}