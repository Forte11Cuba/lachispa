import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/invoice_service.dart';
import '../models/wallet_info.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/universal_screen_wrapper.dart';
import '../widgets/qr_scanner_widget.dart';

class VoucherScanScreen extends StatefulWidget {
  const VoucherScanScreen({super.key});

  @override
  State<VoucherScanScreen> createState() => _VoucherScanScreenState();
}

class _VoucherScanScreenState extends State<VoucherScanScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  
  bool _isProcessing = false;
  String? _lastScannedCode;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _invoiceService.dispose();
    super.dispose();
  }

  /// Converts voucher error types to user-friendly localized messages
  Map<String, String> _getVoucherErrorMessage(String errorType) {
    switch (errorType) {
      case 'already_claimed':
        return {
          'title': AppLocalizations.of(context)!.voucher_already_claimed,
          'description': AppLocalizations.of(context)!.voucher_already_claimed_desc,
        };
      case 'expired':
        return {
          'title': AppLocalizations.of(context)!.voucher_expired,
          'description': AppLocalizations.of(context)!.voucher_expired_desc,
        };
      case 'not_found':
        return {
          'title': AppLocalizations.of(context)!.voucher_not_found,
          'description': AppLocalizations.of(context)!.voucher_not_found_desc,
        };
      case 'server_error':
        return {
          'title': AppLocalizations.of(context)!.voucher_server_error,
          'description': AppLocalizations.of(context)!.voucher_server_error_desc,
        };
      case 'connection_error':
        return {
          'title': AppLocalizations.of(context)!.voucher_connection_error,
          'description': AppLocalizations.of(context)!.voucher_connection_error_desc,
        };
      case 'invalid_amount':
        return {
          'title': AppLocalizations.of(context)!.voucher_invalid_amount,
          'description': AppLocalizations.of(context)!.voucher_invalid_amount_desc,
        };
      case 'insufficient_funds':
        return {
          'title': AppLocalizations.of(context)!.voucher_insufficient_funds,
          'description': AppLocalizations.of(context)!.voucher_insufficient_funds_desc,
        };
      case 'invalid_code':
        return {
          'title': AppLocalizations.of(context)!.voucher_invalid_code,
          'description': AppLocalizations.of(context)!.voucher_not_valid_lnurl,
        };
      default:
        return {
          'title': AppLocalizations.of(context)!.voucher_generic_error,
          'description': AppLocalizations.of(context)!.voucher_generic_error_desc,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
          child: withBottomPadding(
            context,
            Column(
              children: [
                // Header
                _buildHeader(),
                
                // Main content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        
                        // Instructions
                        _buildInstructions(),
                        
                        const SizedBox(height: 24),
                        
                        // Scan QR Button
                        Expanded(
                          child: _buildScanButton(),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Action buttons
                        _buildActionButtons(),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            extraPadding: 24.0,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        children: [
          // Row with back button
          Row(
            children: [
              // Back button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  padding: EdgeInsets.zero,
                ),
              ),
              
              const Spacer(),
            ],
          ),
          
          SizedBox(height: isMobile ? 0 : 4),
          
          // Centered title
          Text(
            AppLocalizations.of(context)!.voucher_scan_title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isMobile ? 32 : 40,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.qr_code_2,
            color: const Color(0xFF4C63F7),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.voucher_scan_instructions,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.voucher_scan_subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large scan button
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2D3FE7),
                  const Color(0xFF4C63F7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D3FE7).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: _isProcessing ? null : _scanQR,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: _isProcessing
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                AppLocalizations.of(context)!.voucher_processing,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                color: Colors.white,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                AppLocalizations.of(context)!.voucher_scan_button,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Subtitle
          Text(
            AppLocalizations.of(context)!.voucher_tap_to_scan,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Manual input button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showManualInputDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.edit, size: 20),
            label: Text(
              AppLocalizations.of(context)!.voucher_manual_input,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _scanQR() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerWidget(
          onScanned: (String scannedData) {
            // Close the scanner
            Navigator.pop(context);
            
            // Avoid processing the same code multiple times
            if (scannedData == _lastScannedCode) return;
            _lastScannedCode = scannedData;
            
            // Process the scanned voucher
            _processScannedCode(scannedData);
          },
        ),
      ),
    );
  }

  /// Extracts LNURL from URLs that contain lightning parameter
  /// 
  /// Handles cases like: https://lachispa.me/?lightning=LNURL1DP68GURN8GHJ7...
  /// Returns the extracted LNURL or the original code if no lightning parameter found
  String _extractLNURLFromCode(String code) {
    try {
      // Check if it's a URL containing lightning parameter
      if (code.contains('lightning=')) {
        final uri = Uri.parse(code);
        
        // Try to get lightning parameter from query parameters
        final lightningParam = uri.queryParameters['lightning'];
        if (lightningParam != null && lightningParam.toLowerCase().startsWith('lnurl1')) {
          return lightningParam;
        }
        
        // Alternative: try to extract from the raw string (in case URI parsing fails)
        final lightningIndex = code.indexOf('lightning=');
        if (lightningIndex != -1) {
          String afterLightning = code.substring(lightningIndex + 'lightning='.length);
          
          // Find where the LNURL ends (at next & or end of string)
          int endIndex = afterLightning.indexOf('&');
          if (endIndex == -1) {
            endIndex = afterLightning.length;
          }
          
          final extractedLNURL = afterLightning.substring(0, endIndex);
          if (extractedLNURL.toLowerCase().startsWith('lnurl1')) {
            return extractedLNURL;
          }
        }
      }
      
      // If no lightning parameter found, return original code
      return code;
    } catch (e) {
      // If any parsing error occurs, return original code
      return code;
    }
  }

  void _processScannedCode(String code) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Extract LNURL from the scanned code (handles URLs with lightning= parameter)
      final extractedCode = _extractLNURLFromCode(code);
      
      // Check if it's an LNURL-withdraw voucher
      if (extractedCode.toLowerCase().startsWith('lnurl1')) {
        await _processVoucher(extractedCode);
      } else {
        _showErrorDialog(AppLocalizations.of(context)!.voucher_invalid_code, AppLocalizations.of(context)!.voucher_not_valid_lnurl);
      }
    } catch (e) {
      // Handle VoucherException with specific error types
      if (e.toString().startsWith('VoucherException:')) {
        final parts = e.toString().split(' - ');
        if (parts.length >= 2) {
          final errorType = parts[0].split(': ')[1];
          final errorMessage = _getVoucherErrorMessage(errorType);
          _showErrorDialog(errorMessage['title']!, errorMessage['description']!);
        } else {
          _showErrorDialog(AppLocalizations.of(context)!.voucher_processing_error, 'Error procesando el código: $e');
        }
      } else {
        _showErrorDialog(AppLocalizations.of(context)!.voucher_processing_error, 'Error procesando el código: $e');
      }
    } finally {
      setState(() {
        _isProcessing = false;
        _lastScannedCode = null;
      });
    }
  }

  Future<void> _processVoucher(String lnurl) async {
    try {
      // Step 1: Get voucher information first
      final voucherInfo = await _invoiceService.getVoucherInfo(lnurl: lnurl);
      
      // Step 2: Show confirmation dialog with voucher details
      _showVoucherConfirmationDialog(voucherInfo);
      
    } catch (e) {
      // Check if it's a VoucherException with specific error type
      if (e.toString().startsWith('VoucherException:')) {
        final parts = e.toString().split(' - ');
        if (parts.length >= 2) {
          final errorType = parts[0].split(': ')[1];
          rethrow; // Re-throw the VoucherException to be handled by _processScannedCode
        }
      }
      throw Exception('Error obteniendo información del voucher: $e');
    }
  }

  void _showManualInputDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D47),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          AppLocalizations.of(context)!.voucher_manual_input,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.voucher_manual_input_hint,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.voucher_manual_input_placeholder,
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
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel_button,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontFamily: 'Inter',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final code = controller.text.trim();
              Navigator.pop(context);
              if (code.isNotEmpty) {
                _processScannedCode(code);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C63F7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.process_button,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D47),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C63F7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'OK',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVoucherConfirmationDialog(Map<String, dynamic> voucherInfo) {
    final minSats = voucherInfo['minSats'] as int;
    final maxSats = voucherInfo['maxSats'] as int;
    final description = voucherInfo['description'] as String;
    final isFixedAmount = voucherInfo['isFixedAmount'] as bool;
    
    // For fixed amount vouchers, use max amount; for range vouchers, let user select
    final TextEditingController amountController = TextEditingController(
      text: isFixedAmount ? maxSats.toString() : maxSats.toString(),
    );
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D47),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.card_giftcard, color: const Color(0xFF4C63F7), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.voucher_detected_title,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description, color: Colors.white.withValues(alpha: 0.7), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontFamily: 'Inter',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Amount information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4C63F7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF4C63F7).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.monetization_on, color: const Color(0xFF4C63F7), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isFixedAmount ? AppLocalizations.of(context)!.voucher_fixed_amount : AppLocalizations.of(context)!.voucher_amount_range,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isFixedAmount 
                          ? '$maxSats sats'
                          : 'De $minSats a $maxSats sats',
                      style: TextStyle(
                        color: const Color(0xFF4C63F7),
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Amount input (only for range vouchers)
              if (!isFixedAmount) ...[
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.voucher_amount_to_claim,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Inter',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ej: ${maxSats}',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    suffixText: 'sats',
                    suffixStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.voucher_min_max_hint(minSats, maxSats),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isProcessing = false;
                _lastScannedCode = null;
              });
            },
            child: Text(
              AppLocalizations.of(context)!.cancel_button,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontFamily: 'Inter',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final amountText = amountController.text.trim();
              final amount = int.tryParse(amountText);
              
              if (amount == null || amount < minSats || amount > maxSats) {
                // Show error
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.voucher_amount_invalid(minSats, maxSats)),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              _claimVoucher(voucherInfo, amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C63F7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.voucher_claim_button,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _claimVoucher(Map<String, dynamic> voucherInfo, int amountSats) async {
    try {
      setState(() {
        _isProcessing = true;
      });
      
      final authProvider = context.read<AuthProvider>();
      final walletProvider = context.read<WalletProvider>();
      
      final wallet = walletProvider.primaryWallet;
      final serverUrl = authProvider.sessionData?.serverUrl;
      
      if (wallet == null || serverUrl == null) {
        throw Exception('No hay wallet configurado');
      }
      
      // Claim the voucher
      final result = await _invoiceService.claimVoucher(
        voucherInfo: voucherInfo,
        adminKey: wallet.adminKey,
        serverUrl: serverUrl,
        amountSats: amountSats,
      );
      
      // Show success dialog
      _showSuccessDialog(result);
      
    } catch (e) {
      // Handle VoucherException with specific error types
      if (e.toString().startsWith('VoucherException:')) {
        final parts = e.toString().split(' - ');
        if (parts.length >= 2) {
          final errorType = parts[0].split(': ')[1];
          final errorMessage = _getVoucherErrorMessage(errorType);
          _showErrorDialog(errorMessage['title']!, errorMessage['description']!);
        } else {
          _showErrorDialog(AppLocalizations.of(context)!.voucher_processing_error, e.toString());
        }
      } else {
        _showErrorDialog(AppLocalizations.of(context)!.voucher_processing_error, e.toString());
      }
    } finally {
      setState(() {
        _isProcessing = false;
        _lastScannedCode = null;
      });
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    final amount = result['amount'] as int;
    final description = result['description'] as String;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D47),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)!.voucher_claimed_title,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '$amount sats',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.voucher_claimed_subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to receive screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Continuar',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}