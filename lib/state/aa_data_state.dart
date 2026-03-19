/// AA Data State
/// 
/// Manages Account Aggregator data from Finvu for display across the app.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_service.dart';

// ============================================================================
// Data Models
// ============================================================================

/// Linked bank account from AA
class AALinkedAccount {
  final String id;
  final String type;
  final String fipName;
  final String maskedNumber;
  final DateTime? lastSynced;
  final String? syncStatus;
  final double? balance;
  
  AALinkedAccount({
    required this.id,
    required this.type,
    required this.fipName,
    required this.maskedNumber,
    this.lastSynced,
    this.syncStatus,
    this.balance,
  });
  
  factory AALinkedAccount.fromJson(Map<String, dynamic> json) {
    return AALinkedAccount(
      id: json['id'] ?? '',
      type: json['type'] ?? 'SAVINGS',
      fipName: json['fip_name'] ?? json['fipName'] ?? '',
      maskedNumber: json['masked_number'] ?? json['maskedNumber'] ?? '',
      lastSynced: json['last_synced'] != null 
          ? DateTime.tryParse(json['last_synced']) 
          : null,
      syncStatus: json['sync_status'] ?? json['syncStatus'],
      balance: (json['balance'] as num?)?.toDouble(),
    );
  }
}

/// Bank account details
class BankAccountData {
  final String bankName;
  final String accountNumber;
  final String accountType;
  final double balance;
  final String? ifscCode;
  final String? branch;
  final DateTime? lastUpdated;
  final String? logoUrl;
  
  BankAccountData({
    required this.bankName,
    required this.accountNumber,
    required this.accountType,
    required this.balance,
    this.ifscCode,
    this.branch,
    this.lastUpdated,
    this.logoUrl,
  });
  
  factory BankAccountData.fromJson(Map<String, dynamic> json) {
    return BankAccountData(
      bankName: json['bank_name'] ?? json['bankName'] ?? json['fip_name'] ?? '',
      accountNumber: json['account_number'] ?? json['masked_number'] ?? '',
      accountType: json['account_type'] ?? json['type'] ?? 'SAVINGS',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      ifscCode: json['ifsc_code'] ?? json['ifscCode'],
      branch: json['branch_name'] ?? json['branch'],
      lastUpdated: json['last_synced_at'] != null 
          ? DateTime.tryParse(json['last_synced_at']) 
          : (json['last_updated'] != null 
              ? DateTime.tryParse(json['last_updated']) 
              : null),
      logoUrl: json['logo_url'] as String?,
    );
  }
  
  // Get logo URL based on bank name
  String? get effectiveLogoUrl {
    if (logoUrl != null) return logoUrl;
    final normalizedName = bankName.toLowerCase().trim();
    if (_bankLogos.containsKey(normalizedName)) {
      return _bankLogos[normalizedName];
    }
    final match = _bankLogos.entries.firstWhere(
      (e) => normalizedName.contains(e.key) || e.key.contains(normalizedName),
      orElse: () => const MapEntry('', ''),
    );
    return match.value.isNotEmpty ? match.value : null;
  }
  
  static String _faviconUrl(String domain) =>
      'https://www.google.com/s2/favicons?domain=$domain&sz=128';

  static final Map<String, String> _bankLogos = {
    'hdfc bank': _faviconUrl('hdfcbank.com'),
    'hdfc': _faviconUrl('hdfcbank.com'),
    'icici bank': _faviconUrl('icicibank.com'),
    'icici': _faviconUrl('icicibank.com'),
    'sbi': _faviconUrl('sbi.co.in'),
    'state bank of india': _faviconUrl('sbi.co.in'),
    'axis bank': _faviconUrl('axisbank.com'),
    'axis': _faviconUrl('axisbank.com'),
    'kotak': _faviconUrl('kotak.com'),
    'kotak mahindra bank': _faviconUrl('kotak.com'),
    'yes bank': _faviconUrl('yesbank.in'),
    'punjab national bank': _faviconUrl('pnbindia.in'),
    'pnb': _faviconUrl('pnbindia.in'),
    'bank of baroda': _faviconUrl('bankofbaroda.in'),
    'canara bank': _faviconUrl('canarabank.com'),
    'union bank': _faviconUrl('unionbankofindia.co.in'),
    'indian bank': _faviconUrl('indianbank.in'),
    'idfc first bank': _faviconUrl('idfcfirstbank.com'),
    'federal bank': _faviconUrl('federalbank.co.in'),
    'indusind bank': _faviconUrl('indusind.com'),
  };
  
  // Mock data - matches seeded database values
  static List<BankAccountData> get mockList => [
    BankAccountData(bankName: 'HDFC Bank', accountNumber: 'XXXX1234', accountType: 'SAVINGS', balance: 542350.75,
      logoUrl: _faviconUrl('hdfcbank.com')),
    BankAccountData(bankName: 'ICICI Bank', accountNumber: 'XXXX5678', accountType: 'SAVINGS', balance: 187500.00,
      logoUrl: _faviconUrl('icicibank.com')),
    BankAccountData(bankName: 'State Bank of India', accountNumber: 'XXXX9012', accountType: 'CURRENT', balance: 325000.00,
      logoUrl: _faviconUrl('sbi.co.in')),
  ];
}

/// Investment holding (stocks, mutual funds, ETFs)
class InvestmentHolding {
  final String id;
  final String name;
  final String type; // STOCK, MUTUAL_FUND, ETF
  final String? symbol;
  final String? exchange; // NSE, BSE
  final double quantity;
  final double avgBuyPrice;
  final double currentValue;
  final double returns;
  final double returnsPercentage;
  final String? dpId;
  final String? provider; // NSDL, CDSL, etc.
  final String? logoUrl;
  
  // Alias for avgBuyPrice
  double get avgCost => avgBuyPrice;
  
  // Get logo URL based on company name/symbol
  String? get effectiveLogoUrl {
    if (logoUrl != null) return logoUrl;
    final normalized = (symbol ?? name).toLowerCase().trim();
    if (_companyLogos.containsKey(normalized)) {
      return _companyLogos[normalized];
    }
    final match = _companyLogos.entries.firstWhere(
      (e) => normalized.contains(e.key) || e.key.contains(normalized),
      orElse: () => const MapEntry('', ''),
    );
    return match.value.isNotEmpty ? match.value : null;
  }
  
  static final Map<String, String> _companyLogos = {
    // Banks
    'hdfcbank': 'https://companieslogo.com/img/orig/HDB-bb6320df.png',
    'hdfc bank': 'https://companieslogo.com/img/orig/HDB-bb6320df.png',
    'icicibank': 'https://companieslogo.com/img/orig/IBN-83539eea.png',
    'icici bank': 'https://companieslogo.com/img/orig/IBN-83539eea.png',
    'sbin': 'https://companieslogo.com/img/orig/SBIN.NS-7d7e5a18.png',
    'sbi': 'https://companieslogo.com/img/orig/SBIN.NS-7d7e5a18.png',
    'axisbank': 'https://companieslogo.com/img/orig/AXISBANK.NS-27b1a785.png',
    'axis bank': 'https://companieslogo.com/img/orig/AXISBANK.NS-27b1a785.png',
    'kotakbank': 'https://companieslogo.com/img/orig/KOTAKBANK.NS-09b0cf3f.png',
    
    // IT Companies
    'infy': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://infosys.com&size=128',
    'infosys': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://infosys.com&size=128',
    'tcs': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://tcs.com&size=128',
    'wipro': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://wipro.com&size=128',
    'hcltech': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hcltech.com&size=128',
    'techm': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://techmahindra.com&size=128',
    
    // Major Conglomerates
    'reliance': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://ril.com&size=128',
    'reliance industries': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://ril.com&size=128',
    'tatamotors': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://tatamotors.com&size=128',
    'tata motors': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://tatamotors.com&size=128',
    'tatasteel': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://tatasteel.com&size=128',
    'bhartiartl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://airtel.in&size=128',
    'airtel': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://airtel.in&size=128',
    'itc': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://itcportal.com&size=128',
    'hindunilvr': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hul.co.in&size=128',
    'hul': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hul.co.in&size=128',
    
    // Consumer/Tech
    'swiggy': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://swiggy.com&size=128',
    'zomato': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://zomato.com&size=128',
    'ola': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://olaelectric.com&size=128',
    'boat': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://boat-lifestyle.com&size=128',
    'nykaa': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://nykaa.com&size=128',
    'paytm': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://paytm.com&size=128',
    
    // Auto
    'maruti': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://marutisuzuki.com&size=128',
    'bajaj-auto': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://bajajauto.com&size=128',
    'eichermot': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://eicher.in&size=128',
    'm&m': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://mahindra.com&size=128',
    'mahindra': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://mahindra.com&size=128',
    
    // Financial
    'hdfclife': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hdfclife.com&size=128',
    'sbilife': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://sbilife.co.in&size=128',
    'bajfinance': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://bajajfinserv.in&size=128',
    
    // Mutual Fund AMCs
    'axis bluechip': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://axismf.com&size=128',
    'groww': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://groww.in&size=128',
    'hdfc mutual': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hdfcfund.com&size=128',
    'sbi mutual': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://sbimf.com&size=128',
    'icici pru': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://icicipruamc.com&size=128',
  };
  
  InvestmentHolding({
    required this.id,
    required this.name,
    required this.type,
    this.symbol,
    this.exchange,
    required this.quantity,
    required this.avgBuyPrice,
    required this.currentValue,
    required this.returns,
    required this.returnsPercentage,
    this.dpId,
    this.provider,
    this.logoUrl,
  });
  
  static List<InvestmentHolding> get mockList => [
    InvestmentHolding(
      id: '1', name: 'HDFC Bank', type: 'stock', symbol: 'HDFCBANK',
      exchange: 'NSE', quantity: 50, avgBuyPrice: 1525, currentValue: 80000,
      returns: 3750, returnsPercentage: 4.92,
    ),
    InvestmentHolding(
      id: '2', name: 'Infosys', type: 'stock', symbol: 'INFY',
      exchange: 'NSE', quantity: 30, avgBuyPrice: 1380, currentValue: 43500,
      returns: 2100, returnsPercentage: 5.07,
    ),
    InvestmentHolding(
      id: '3', name: 'Axis Bluechip Fund', type: 'mutual_fund', symbol: 'AXISBLU',
      exchange: null, quantity: 100.5, avgBuyPrice: 45.50, currentValue: 5025,
      returns: 450, returnsPercentage: 9.84,
    ),
    InvestmentHolding(
      id: '4', name: 'Reliance Industries', type: 'stock', symbol: 'RELIANCE',
      exchange: 'NSE', quantity: 20, avgBuyPrice: 2720, currentValue: 57000,
      returns: 2600, returnsPercentage: 4.78,
    ),
  ];
  
  factory InvestmentHolding.fromJson(Map<String, dynamic> json) {
    final currentValue = (json['current_value'] as num?)?.toDouble() ?? 0.0;
    final invested = (json['invested_value'] as num?)?.toDouble() ?? 
                     (json['avg_buy_price'] as num?)?.toDouble() ?? 0.0 * 
                     ((json['quantity'] as num?)?.toDouble() ?? 0.0);
    final returns = currentValue - invested;
    final returnsPerc = invested > 0 ? (returns / invested) * 100 : 0.0;
    
    return InvestmentHolding(
      id: json['id'] ?? '',
      name: json['name'] ?? json['scheme_name'] ?? '',
      type: json['type'] ?? json['instrument_type'] ?? 'MUTUAL_FUND',
      symbol: json['symbol'] ?? json['isin'],
      exchange: json['exchange'],
      quantity: (json['quantity'] as num?)?.toDouble() ?? 
                (json['units'] as num?)?.toDouble() ?? 0.0,
      avgBuyPrice: (json['avg_buy_price'] as num?)?.toDouble() ?? 
                   (json['nav'] as num?)?.toDouble() ?? 0.0,
      currentValue: currentValue,
      returns: returns,
      returnsPercentage: returnsPerc,
      dpId: json['dp_id'] ?? json['dpId'],
      provider: json['provider'] ?? json['depository'],
      logoUrl: json['logo_url'] as String?,
    );
  }
}


/// Fixed deposit details
class FixedDepositData {
  final String id;
  final String bankName;
  final String accountNumber;
  final double principal;
  final double maturityAmount;
  final double interestRate;
  final DateTime startDate;
  final DateTime maturityDate;
  final String? tenure;
  
  FixedDepositData({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.principal,
    required this.maturityAmount,
    required this.interestRate,
    required this.startDate,
    required this.maturityDate,
    this.tenure,
  });
  
  factory FixedDepositData.fromJson(Map<String, dynamic> json) {
    return FixedDepositData(
      id: json['id'] ?? '',
      bankName: json['bank_name'] ?? json['fip_name'] ?? '',
      accountNumber: json['account_number'] ?? json['masked_number'] ?? '',
      principal: (json['principal'] as num?)?.toDouble() ?? 
                 (json['deposit_amount'] as num?)?.toDouble() ?? 0.0,
      maturityAmount: (json['maturity_amount'] as num?)?.toDouble() ?? 0.0,
      interestRate: (json['interest_rate'] as num?)?.toDouble() ?? 0.0,
      startDate: DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now(),
      maturityDate: DateTime.tryParse(json['maturity_date'] ?? '') ?? DateTime.now(),
      tenure: json['tenure'],
    );
  }
  
  // Alias for principal
  double get principalAmount => principal;
  
  static List<FixedDepositData> get mockList => [
    FixedDepositData(
      id: '1', bankName: 'HDFC Bank', accountNumber: 'FD001234',
      principal: 200000, maturityAmount: 225000, interestRate: 7.25,
      startDate: DateTime(2024, 1, 15), maturityDate: DateTime(2026, 1, 15),
    ),
    FixedDepositData(
      id: '2', bankName: 'SBI', accountNumber: 'FD005678',
      principal: 231614, maturityAmount: 255000, interestRate: 6.75,
      startDate: DateTime(2024, 3, 1), maturityDate: DateTime(2025, 9, 1),
    ),
  ];
}

/// Loan details
class LoanData {
  final String id;
  final String lenderName;
  final String loanType; // HOME, PERSONAL, VEHICLE, EDUCATION
  final String accountNumber;
  final double principalAmount;
  final double outstandingAmount;
  final double emiAmount;
  final double interestRate;
  final int tenure; // in months
  final int remainingTenure;
  final DateTime? nextEmiDate;
  final String status; // ACTIVE, CLOSED
  
  LoanData({
    required this.id,
    required this.lenderName,
    required this.loanType,
    required this.accountNumber,
    required this.principalAmount,
    required this.outstandingAmount,
    required this.emiAmount,
    required this.interestRate,
    required this.tenure,
    required this.remainingTenure,
    this.nextEmiDate,
    required this.status,
  });
  
  factory LoanData.fromJson(Map<String, dynamic> json) {
    return LoanData(
      id: json['id'] ?? '',
      lenderName: json['lender_name'] ?? json['fip_name'] ?? '',
      loanType: json['loan_type'] ?? json['type'] ?? 'PERSONAL',
      accountNumber: json['account_number'] ?? json['masked_number'] ?? '',
      principalAmount: (json['principal_amount'] as num?)?.toDouble() ?? 
                       (json['sanctioned_amount'] as num?)?.toDouble() ?? 0.0,
      outstandingAmount: (json['outstanding_amount'] as num?)?.toDouble() ?? 
                         (json['current_balance'] as num?)?.toDouble() ?? 0.0,
      emiAmount: (json['emi_amount'] as num?)?.toDouble() ?? 0.0,
      interestRate: (json['interest_rate'] as num?)?.toDouble() ?? 0.0,
      tenure: (json['tenure'] as int?) ?? 0,
      remainingTenure: (json['remaining_tenure'] as int?) ?? 0,
      nextEmiDate: json['next_emi_date'] != null 
          ? DateTime.tryParse(json['next_emi_date']) 
          : null,
      status: json['status'] ?? 'ACTIVE',
    );
  }
  
  // Alias getters for easier access
  String get lender => lenderName;
  String get type => loanType;
  double get outstanding => outstandingAmount;
  double get emi => emiAmount;
  DateTime? get nextDueDate => nextEmiDate;
  
  // Mock data - matches seeded database values
  static List<LoanData> get mockList => [
    LoanData(
      id: '1', lenderName: 'SBI', loanType: 'HOME', accountNumber: 'HL****3847',
      principalAmount: 2500000, outstandingAmount: 2500000, emiAmount: 25000,
      interestRate: 8.5, tenure: 240, remainingTenure: 220,
      nextEmiDate: DateTime(2026, 4, 5), status: 'ACTIVE',
    ),
    LoanData(
      id: '2', lenderName: 'ICICI Bank', loanType: 'CAR', accountNumber: 'CL****9281',
      principalAmount: 485000, outstandingAmount: 450000, emiAmount: 17000,
      interestRate: 9.2, tenure: 60, remainingTenure: 48,
      nextEmiDate: DateTime(2026, 4, 10), status: 'ACTIVE',
    ),
  ];
}

/// Insurance policy details
class InsuranceData {
  final String id;
  final String provider;
  final String policyNumber;
  final String type; // LIFE, HEALTH, TERM, VEHICLE
  final double sumAssured;
  final double premiumAmount;
  final String premiumFrequency; // MONTHLY, QUARTERLY, YEARLY
  final DateTime startDate;
  final DateTime? expiryDate;
  final String status;
  final List<String>? nominees;
  final String? logoUrl;
  
  InsuranceData({
    required this.id,
    required this.provider,
    required this.policyNumber,
    required this.type,
    required this.sumAssured,
    required this.premiumAmount,
    required this.premiumFrequency,
    required this.startDate,
    this.expiryDate,
    required this.status,
    this.nominees,
    this.logoUrl,
  });
  
  factory InsuranceData.fromJson(Map<String, dynamic> json) {
    return InsuranceData(
      id: json['id'] ?? '',
      provider: json['provider'] ?? json['insurer_name'] ?? '',
      policyNumber: json['policy_number'] ?? json['masked_number'] ?? '',
      type: json['type'] ?? json['policy_type'] ?? 'LIFE',
      sumAssured: (json['sum_assured'] as num?)?.toDouble() ?? 
                  (json['cover_amount'] as num?)?.toDouble() ?? 0.0,
      premiumAmount: (json['premium_amount'] as num?)?.toDouble() ?? 0.0,
      premiumFrequency: json['premium_frequency'] ?? 'YEARLY',
      startDate: DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now(),
      expiryDate: json['expiry_date'] != null 
          ? DateTime.tryParse(json['expiry_date']) 
          : null,
      status: json['status'] ?? 'ACTIVE',
      nominees: (json['nominees'] as List?)?.cast<String>(),
      logoUrl: json['logo_url'] as String?,
    );
  }
  
  // Alias getter
  String get providerName => provider;
  
  // Get logo URL based on provider name
  String? get effectiveLogoUrl {
    if (logoUrl != null) return logoUrl;
    return _insuranceProviderLogos[provider.toLowerCase()];
  }
  
  static final Map<String, String> _insuranceProviderLogos = {
    'lic of india': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://licindia.in&size=128',
    'lic': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://licindia.in&size=128',
    'hdfc life': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hdfclife.com&size=128',
    'hdfc ergo': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hdfcergo.com&size=128',
    'icici prudential': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://iciciprulife.com&size=128',
    'icici lombard': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://icicilombard.com&size=128',
    'sbi life': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://sbilife.co.in&size=128',
    'max life': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://maxlifeinsurance.com&size=128',
    'bajaj allianz': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://bajajallianz.com&size=128',
    'tata aia': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://tataaia.com&size=128',
    'kotak life': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://kotaklife.com&size=128',
    'reliance nippon': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://reliancenipponlife.com&size=128',
  };
  
  // Mock data - matches seeded database values
  static List<InsuranceData> get mockList => [
    InsuranceData(
      id: '1', provider: 'LIC of India', policyNumber: 'POL****5847',
      type: 'TERM', sumAssured: 10000000, premiumAmount: 15000,
      premiumFrequency: 'YEARLY', startDate: DateTime(2021, 6, 15),
      expiryDate: DateTime(2051, 6, 15), status: 'ACTIVE',
      logoUrl: 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://licindia.in&size=128',
    ),
    InsuranceData(
      id: '2', provider: 'Max Life', policyNumber: 'POL****2938',
      type: 'ULIP', sumAssured: 2500000, premiumAmount: 50000,
      premiumFrequency: 'YEARLY', startDate: DateTime(2023, 3, 10),
      expiryDate: DateTime(2043, 3, 10), status: 'ACTIVE',
      logoUrl: 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://maxlifeinsurance.com&size=128',
    ),
    InsuranceData(
      id: '3', provider: 'HDFC ERGO', policyNumber: 'POL****8472',
      type: 'HEALTH', sumAssured: 500000, premiumAmount: 12000,
      premiumFrequency: 'YEARLY', startDate: DateTime(2024, 1, 1),
      expiryDate: DateTime(2025, 1, 1), status: 'ACTIVE',
      logoUrl: 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hdfcergo.com&size=128',
    ),
    InsuranceData(
      id: '4', provider: 'ICICI Lombard', policyNumber: 'POL****6183',
      type: 'VEHICLE', sumAssured: 1200000, premiumAmount: 8000,
      premiumFrequency: 'YEARLY', startDate: DateTime(2025, 9, 20),
      expiryDate: DateTime(2026, 9, 20), status: 'ACTIVE',
      logoUrl: 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://icicilombard.com&size=128',
    ),
  ];
}

/// Financial snapshot from ETL
class FinancialSnapshot {
  final double netWorth;
  final double totalAssets;
  final double totalLiabilities;
  final double totalMonthlyIncome;
  final double totalMonthlyExpense;
  final double savingsRate;
  final double netWorthChange; // Year-over-year change percentage
  final DateTime snapshotDate;
  
  FinancialSnapshot({
    required this.netWorth,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.totalMonthlyIncome,
    required this.totalMonthlyExpense,
    required this.savingsRate,
    this.netWorthChange = 8.2,
    required this.snapshotDate,
  });
  
  factory FinancialSnapshot.fromJson(Map<String, dynamic> json) {
    // Handle both nested (backend) and flat (legacy) response formats
    final incomeData = json['income'] as Map<String, dynamic>?;
    final expenseData = json['expenses'] as Map<String, dynamic>?;
    final assetData = json['assets'] as Map<String, dynamic>?;
    final liabilityData = json['liabilities'] as Map<String, dynamic>?;
    
    // Parse income - check nested first, then flat
    final income = incomeData != null 
        ? (incomeData['total_monthly'] as num?)?.toDouble() ?? 0.0
        : (json['total_monthly_income'] as num?)?.toDouble() ?? 0.0;
    
    // Parse expense - check nested first, then flat
    final expense = expenseData != null
        ? (expenseData['total_monthly'] as num?)?.toDouble() ?? 0.0
        : (json['total_monthly_expense'] as num?)?.toDouble() ?? 0.0;
    
    // Parse assets - check nested first, then flat
    final totalAssets = assetData != null
        ? (assetData['total'] as num?)?.toDouble() ?? 0.0
        : (json['total_assets'] as num?)?.toDouble() ?? 0.0;
    
    // Parse liabilities - check nested first, then flat
    final totalLiabilities = liabilityData != null
        ? (liabilityData['total'] as num?)?.toDouble() ?? 0.0
        : (json['total_liabilities'] as num?)?.toDouble() ?? 0.0;
    
    final savingsRate = income > 0 ? ((income - expense) / income) * 100 : 0.0;
    
    return FinancialSnapshot(
      netWorth: (json['net_worth'] as num?)?.toDouble() ?? 0.0,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      totalMonthlyIncome: income,
      totalMonthlyExpense: expense,
      savingsRate: savingsRate,
      snapshotDate: DateTime.tryParse(json['snapshot_date'] ?? '') ?? DateTime.now(),
    );
  }
  
  // Default mock data when AA is not linked - matches seeded database values
  static FinancialSnapshot get mock => FinancialSnapshot(
    netWorth: 1549850.75,
    totalAssets: 4534850.75,
    totalLiabilities: 2985000.00,
    totalMonthlyIncome: 185000.00,
    totalMonthlyExpense: 95000.00,
    savingsRate: 48.65,
    netWorthChange: 8.2,
    snapshotDate: DateTime.now(),
  );
}

/// Asset breakdown by category
class AssetBreakdown {
  final double mutualFunds;
  final double stocks;
  final double etfs;
  final double bankBalance;
  final double fixedDeposits;
  final double realEstate;
  final double gold;
  final double others;
  
  AssetBreakdown({
    this.mutualFunds = 0,
    this.stocks = 0,
    this.etfs = 0,
    this.bankBalance = 0,
    this.fixedDeposits = 0,
    this.realEstate = 0,
    this.gold = 0,
    this.others = 0,
  });
  
  double get total => mutualFunds + stocks + etfs + bankBalance + 
                       fixedDeposits + realEstate + gold + others;
  
  factory AssetBreakdown.fromJson(Map<String, dynamic> json) {
    return AssetBreakdown(
      mutualFunds: (json['mutual_funds'] as num?)?.toDouble() ?? 0.0,
      stocks: (json['stocks'] as num?)?.toDouble() ?? 0.0,
      etfs: (json['etfs'] as num?)?.toDouble() ?? 0.0,
      bankBalance: (json['bank_balance'] as num?)?.toDouble() ?? 0.0,
      fixedDeposits: (json['fixed_deposits'] as num?)?.toDouble() ?? 0.0,
      realEstate: (json['real_estate'] as num?)?.toDouble() ?? 0.0,
      gold: (json['gold'] as num?)?.toDouble() ?? 0.0,
      others: (json['others'] as num?)?.toDouble() ?? 0.0,
    );
  }
  
  // Default mock data - matches seeded database values
  static AssetBreakdown get mock => AssetBreakdown(
    mutualFunds: 1250000,   // ₹12.5L in mutual funds
    stocks: 875000,          // ₹8.75L in stocks
    etfs: 225000,            // ₹2.25L in ETFs
    bankBalance: 1054850.75, // ₹10.55L in bank accounts
    fixedDeposits: 500000,   // ₹5L in FDs
    realEstate: 0,
    gold: 180000,            // ₹1.8L in gold
    others: 450000,          // ₹4.5L in PPF
  );
}

// ============================================================================
// AA Data State
// ============================================================================

class AADataState {
  final bool isLoading;
  final bool isLoaded;
  final String? error;
  final DateTime? lastUpdated;
  
  // Financial data
  final FinancialSnapshot? snapshot;
  final AssetBreakdown? assetBreakdown;
  
  // Linked accounts
  final List<AALinkedAccount> linkedAccounts;
  final List<BankAccountData> bankAccounts;
  
  // Investments (for Wealth Manager)
  final List<InvestmentHolding> investments;
  final List<FixedDepositData> fixedDeposits;
  
  // Loans (for Borrow Hub)
  final List<LoanData> loans;
  
  // Insurance (for Discover)
  final List<InsuranceData> insurances;
  
  const AADataState({
    this.isLoading = false,
    this.isLoaded = false,
    this.error,
    this.lastUpdated,
    this.snapshot,
    this.assetBreakdown,
    this.linkedAccounts = const [],
    this.bankAccounts = const [],
    this.investments = const [],
    this.fixedDeposits = const [],
    this.loans = const [],
    this.insurances = const [],
  });
  
  /// Factory constructor with default mock data for immediate display
  factory AADataState.withDefaults() {
    return AADataState(
      isLoaded: true,
      lastUpdated: DateTime.now(),
      snapshot: FinancialSnapshot.mock,
      assetBreakdown: AssetBreakdown.mock,
      bankAccounts: BankAccountData.mockList,
      investments: InvestmentHolding.mockList,
      fixedDeposits: FixedDepositData.mockList,
      loans: LoanData.mockList,
      insurances: InsuranceData.mockList,
    );
  }
  
  AADataState copyWith({
    bool? isLoading,
    bool? isLoaded,
    String? error,
    DateTime? lastUpdated,
    FinancialSnapshot? snapshot,
    AssetBreakdown? assetBreakdown,
    List<AALinkedAccount>? linkedAccounts,
    List<BankAccountData>? bankAccounts,
    List<InvestmentHolding>? investments,
    List<FixedDepositData>? fixedDeposits,
    List<LoanData>? loans,
    List<InsuranceData>? insurances,
  }) {
    return AADataState(
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      snapshot: snapshot ?? this.snapshot,
      assetBreakdown: assetBreakdown ?? this.assetBreakdown,
      linkedAccounts: linkedAccounts ?? this.linkedAccounts,
      bankAccounts: bankAccounts ?? this.bankAccounts,
      investments: investments ?? this.investments,
      fixedDeposits: fixedDeposits ?? this.fixedDeposits,
      loans: loans ?? this.loans,
      insurances: insurances ?? this.insurances,
    );
  }
  
  // Computed properties for dashboard
  double get totalBankBalance => bankAccounts.fold(0, (sum, a) => sum + a.balance);
  double get totalInvestmentValue => investments.fold(0, (sum, i) => sum + i.currentValue);
  double get totalFDValue => fixedDeposits.fold(0, (sum, fd) => sum + fd.principal);
  double get totalLoanOutstanding => loans.fold(0, (sum, l) => sum + l.outstandingAmount);
  double get totalInsuranceCover => insurances.fold(0, (sum, i) => sum + i.sumAssured);
  
  // Net worth calculation
  double get calculatedNetWorth => 
      totalBankBalance + totalInvestmentValue + totalFDValue - totalLoanOutstanding;

  // ---- Financial Health Score (computed from live data) ----
  double get _monthlyIncome => snapshot?.totalMonthlyIncome ?? 185000;
  double get _monthlyExpense => snapshot?.totalMonthlyExpense ?? 95000;
  double get _totalEmi => loans.fold<double>(0, (s, l) => s + l.emiAmount);
  int get creditScore => 780; // from snapshot / credit bureau

  String get creditLabel {
    if (creditScore >= 750) return 'Excellent';
    if (creditScore >= 700) return 'Good';
    if (creditScore >= 650) return 'Fair';
    return 'Poor';
  }

  /// Savings factor: (income - expense - emi) / income
  double get savingsFactor {
    if (_monthlyIncome <= 0) return 0;
    final rate = (_monthlyIncome - _monthlyExpense - _totalEmi) / _monthlyIncome;
    return rate.clamp(0.0, 1.0);
  }

  /// Spending factor: 1 - (expense / income) — lower spending = better
  double get spendingFactor {
    if (_monthlyIncome <= 0) return 0;
    return (1.0 - (_monthlyExpense / _monthlyIncome)).clamp(0.0, 1.0);
  }

  /// Investment factor: investmentValue / totalAssets
  double get investmentFactor {
    final total = totalBankBalance + totalInvestmentValue + totalFDValue;
    if (total <= 0) return 0;
    return (totalInvestmentValue / total).clamp(0.0, 1.0);
  }

  /// Debt factor: 1 - (outstanding / assets) — lower debt = better
  double get debtFactor {
    final total = totalBankBalance + totalInvestmentValue + totalFDValue;
    if (total <= 0) return totalLoanOutstanding > 0 ? 0.0 : 1.0;
    return (1.0 - (totalLoanOutstanding / (total + totalLoanOutstanding))).clamp(0.0, 1.0);
  }

  /// Overall health score 0–100
  int get healthScore {
    // Weighted: savings 25%, spending 20%, investments 20%, debt 20%, credit 15%
    final creditFactor = (creditScore - 300) / 600; // normalize 300-900 → 0-1
    final raw = (savingsFactor * 25 +
                 spendingFactor * 20 +
                 investmentFactor * 20 +
                 debtFactor * 20 +
                 creditFactor.clamp(0.0, 1.0) * 15);
    return raw.round().clamp(0, 100);
  }

  String get healthLabel {
    if (healthScore >= 80) return 'Excellent';
    if (healthScore >= 65) return 'Good';
    if (healthScore >= 50) return 'Fair';
    if (healthScore >= 35) return 'Poor';
    return 'Critical';
  }
}

// ============================================================================
// AA Data Notifier
// ============================================================================

class AADataNotifier extends StateNotifier<AADataState> {
  final Ref _ref;
  
  AADataNotifier(this._ref) : super(const AADataState());
  
  ApiService get _api => _ref.read(apiServiceProvider);
  
  /// Fetch all AA data from backend
  Future<void> fetchAllData() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        _fetchSnapshot(),
        _fetchLinkedAccounts(),
        _fetchBankAccounts(),
        _fetchInvestments(),
        _fetchLoans(),
        _fetchInsurances(),
      ]);
      
      state = state.copyWith(
        isLoading: false,
        isLoaded: true,
        lastUpdated: DateTime.now(),
        snapshot: results[0] as FinancialSnapshot?,
        linkedAccounts: results[1] as List<AALinkedAccount>,
        bankAccounts: results[2] as List<BankAccountData>,
        investments: results[3] as List<InvestmentHolding>,
        loans: results[4] as List<LoanData>,
        insurances: results[5] as List<InsuranceData>,
        assetBreakdown: _calculateAssetBreakdown(
          results[2] as List<BankAccountData>,
          results[3] as List<InvestmentHolding>,
          results[4] as List<LoanData>,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  Future<FinancialSnapshot?> _fetchSnapshot() async {
    try {
      final result = await _api.get('/api/v1/data/snapshot');
      if (result.isSuccess && result.data != null) {
        return FinancialSnapshot.fromJson(result.data);
      }
    } catch (_) {}
    return null;
  }
  
  Future<List<AALinkedAccount>> _fetchLinkedAccounts() async {
    try {
      final result = await _api.get('/api/v1/data/linked-accounts');
      if (result.isSuccess && result.data != null) {
        final body = result.data;
        final inner = body['data'] ?? body;
        final accounts = inner['accounts'] as List?;
        return accounts?.map((a) => AALinkedAccount.fromJson(a)).toList() ?? [];
      }
    } catch (_) {}
    return [];
  }
  
  Future<List<BankAccountData>> _fetchBankAccounts() async {
    try {
      final result = await _api.get('/api/v1/aa/bank-accounts');
      if (result.isSuccess && result.data != null) {
        final body = result.data;
        final inner = body['data'] ?? body;
        final accounts = inner['accounts'] as List?;
        return accounts?.map((a) => BankAccountData.fromJson(a)).toList() ?? [];
      }
    } catch (_) {}
    return [];
  }
  
  Future<List<InvestmentHolding>> _fetchInvestments() async {
    try {
      final result = await _api.get('/api/v1/aa/investments');
      if (result.isSuccess && result.data != null) {
        final body = result.data;
        final inner = body['data'] ?? body;
        final holdings = inner['holdings'] as List?;
        return holdings?.map((h) => InvestmentHolding.fromJson(h)).toList() ?? [];
      }
    } catch (_) {}
    return [];
  }
  
  Future<List<LoanData>> _fetchLoans() async {
    try {
      final result = await _api.get('/api/v1/aa/loans');
      if (result.isSuccess && result.data != null) {
        final body = result.data;
        final inner = body['data'] ?? body;
        final loans = inner['loans'] as List?;
        return loans?.map((l) => LoanData.fromJson(l)).toList() ?? [];
      }
    } catch (_) {}
    return [];
  }
  
  Future<List<InsuranceData>> _fetchInsurances() async {
    try {
      final result = await _api.get('/api/v1/aa/insurances');
      if (result.isSuccess && result.data != null) {
        final body = result.data;
        final inner = body['data'] ?? body;
        final insurances = inner['insurances'] as List?;
        return insurances?.map((i) => InsuranceData.fromJson(i)).toList() ?? [];
      }
    } catch (_) {}
    return [];
  }
  
  AssetBreakdown _calculateAssetBreakdown(
    List<BankAccountData> banks,
    List<InvestmentHolding> investments,
    List<LoanData> loans,
  ) {
    double mutualFunds = 0;
    double stocks = 0;
    double etfs = 0;
    
    for (final inv in investments) {
      switch (inv.type.toUpperCase()) {
        case 'MUTUAL_FUND':
        case 'MF':
          mutualFunds += inv.currentValue;
          break;
        case 'STOCK':
        case 'EQUITY':
          stocks += inv.currentValue;
          break;
        case 'ETF':
          etfs += inv.currentValue;
          break;
      }
    }
    
    return AssetBreakdown(
      mutualFunds: mutualFunds,
      stocks: stocks,
      etfs: etfs,
      bankBalance: banks.fold(0, (sum, b) => sum + b.balance),
      fixedDeposits: state.fixedDeposits.fold(0, (sum, fd) => sum + fd.principal),
    );
  }
  
  /// Load mock data for demo/testing — uses same 3 banks as mockList
  void loadMockData() {
    state = state.copyWith(
      isLoading: false,
      isLoaded: true,
      lastUpdated: DateTime.now(),
      snapshot: FinancialSnapshot.mock,
      assetBreakdown: AssetBreakdown.mock,
      bankAccounts: BankAccountData.mockList,
      investments: InvestmentHolding.mockList,
      fixedDeposits: FixedDepositData.mockList,
      loans: LoanData.mockList,
      insurances: InsuranceData.mockList,
    );
  }
  
  /// Deduct amount from a bank account balance (for payments/transfers)
  void deductFromBalance({
    required double amount,
    required String accountIdentifier,
    String? description,
    String? recipientName,
    String? category,
    String? mode,
  }) {
    String? matchedAccountId;
    final updatedAccounts = state.bankAccounts.map((account) {
      // Match by account number, last 4 digits, or bank name (bidirectional)
      final idLower = accountIdentifier.toLowerCase();
      final bankLower = account.bankName.toLowerCase();
      // Extract last 4 digits from identifier (e.g. "HDFC Bank savings •• 1234" → "1234")
      final digitMatches = RegExp(r'\d{4}').allMatches(accountIdentifier).toList();
      final last4 = digitMatches.isNotEmpty ? digitMatches.last.group(0)! : '';
      final matches = account.accountNumber.contains(accountIdentifier) ||
                      accountIdentifier.contains(account.accountNumber) ||
                      (last4.isNotEmpty && account.accountNumber.contains(last4)) ||
                      bankLower.contains(idLower) ||
                      idLower.contains(bankLower);
      if (matches && matchedAccountId == null) {
        matchedAccountId = account.accountNumber;
        return BankAccountData(
          bankName: account.bankName,
          accountNumber: account.accountNumber,
          accountType: account.accountType,
          balance: (account.balance - amount).clamp(0, double.infinity),
          ifscCode: account.ifscCode,
          branch: account.branch,
          lastUpdated: DateTime.now(),
          logoUrl: account.logoUrl,
        );
      }
      return account;
    }).toList();

    // Update snapshot with new net worth
    final newBankBalance = updatedAccounts.fold<double>(0, (sum, a) => sum + a.balance);
    final oldBankBalance = state.bankAccounts.fold<double>(0, (sum, a) => sum + a.balance);
    final balanceDiff = newBankBalance - oldBankBalance;
    
    final currentSnapshot = state.snapshot ?? FinancialSnapshot.mock;
    final updatedSnapshot = FinancialSnapshot(
      netWorth: currentSnapshot.netWorth + balanceDiff,
      totalAssets: currentSnapshot.totalAssets + balanceDiff,
      totalLiabilities: currentSnapshot.totalLiabilities,
      totalMonthlyIncome: currentSnapshot.totalMonthlyIncome,
      totalMonthlyExpense: currentSnapshot.totalMonthlyExpense + amount,
      savingsRate: currentSnapshot.savingsRate,
      netWorthChange: currentSnapshot.netWorthChange,
      snapshotDate: DateTime.now(),
    );

    // Update asset breakdown
    final currentAssets = state.assetBreakdown ?? AssetBreakdown.mock;
    final updatedAssets = AssetBreakdown(
      mutualFunds: currentAssets.mutualFunds,
      stocks: currentAssets.stocks,
      etfs: currentAssets.etfs,
      bankBalance: newBankBalance,
      fixedDeposits: currentAssets.fixedDeposits,
      realEstate: currentAssets.realEstate,
      gold: currentAssets.gold,
      others: currentAssets.others,
    );

    state = state.copyWith(
      bankAccounts: updatedAccounts,
      snapshot: updatedSnapshot,
      assetBreakdown: updatedAssets,
      lastUpdated: DateTime.now(),
    );

    // Persist to backend
    _syncBalanceToBackend(
      accountIdentifier: matchedAccountId ?? accountIdentifier,
      amount: -amount,
      description: description ?? 'Debit transaction',
      recipientName: recipientName,
      category: category,
      mode: mode,
    );
  }

  /// Add amount to a bank account balance (for income/refunds)
  void addToBalance({
    required double amount,
    required String accountIdentifier,
    String? description,
    String? recipientName,
    String? category,
    String? mode,
  }) {
    String? matchedAccountId;
    final updatedAccounts = state.bankAccounts.map((account) {
      final idLower = accountIdentifier.toLowerCase();
      final bankLower = account.bankName.toLowerCase();
      final digitMatches = RegExp(r'\d{4}').allMatches(accountIdentifier).toList();
      final last4 = digitMatches.isNotEmpty ? digitMatches.last.group(0)! : '';
      final matches = account.accountNumber.contains(accountIdentifier) ||
                      accountIdentifier.contains(account.accountNumber) ||
                      (last4.isNotEmpty && account.accountNumber.contains(last4)) ||
                      bankLower.contains(idLower) ||
                      idLower.contains(bankLower);
      if (matches && matchedAccountId == null) {
        matchedAccountId = account.accountNumber;
        return BankAccountData(
          bankName: account.bankName,
          accountNumber: account.accountNumber,
          accountType: account.accountType,
          balance: account.balance + amount,
          ifscCode: account.ifscCode,
          branch: account.branch,
          lastUpdated: DateTime.now(),
          logoUrl: account.logoUrl,
        );
      }
      return account;
    }).toList();

    // Update snapshot
    final newBankBalance = updatedAccounts.fold<double>(0, (sum, a) => sum + a.balance);
    final oldBankBalance = state.bankAccounts.fold<double>(0, (sum, a) => sum + a.balance);
    final balanceDiff = newBankBalance - oldBankBalance;
    
    final currentSnapshot = state.snapshot ?? FinancialSnapshot.mock;
    final updatedSnapshot = FinancialSnapshot(
      netWorth: currentSnapshot.netWorth + balanceDiff,
      totalAssets: currentSnapshot.totalAssets + balanceDiff,
      totalLiabilities: currentSnapshot.totalLiabilities,
      totalMonthlyIncome: currentSnapshot.totalMonthlyIncome + amount,
      totalMonthlyExpense: currentSnapshot.totalMonthlyExpense,
      savingsRate: currentSnapshot.savingsRate,
      netWorthChange: currentSnapshot.netWorthChange,
      snapshotDate: DateTime.now(),
    );

    // Update asset breakdown
    final currentAssets = state.assetBreakdown ?? AssetBreakdown.mock;
    final updatedAssets = AssetBreakdown(
      mutualFunds: currentAssets.mutualFunds,
      stocks: currentAssets.stocks,
      etfs: currentAssets.etfs,
      bankBalance: newBankBalance,
      fixedDeposits: currentAssets.fixedDeposits,
      realEstate: currentAssets.realEstate,
      gold: currentAssets.gold,
      others: currentAssets.others,
    );

    state = state.copyWith(
      bankAccounts: updatedAccounts,
      snapshot: updatedSnapshot,
      assetBreakdown: updatedAssets,
      lastUpdated: DateTime.now(),
    );

    // Persist to backend
    _syncBalanceToBackend(
      accountIdentifier: matchedAccountId ?? accountIdentifier,
      amount: amount,
      description: description ?? 'Credit transaction',
      recipientName: recipientName,
      category: category,
      mode: mode,
    );
  }

  /// Sync balance change to backend (fire-and-forget)
  Future<void> _syncBalanceToBackend({
    required String accountIdentifier,
    required double amount,
    required String description,
    String? recipientName,
    String? category,
    String? mode,
  }) async {
    try {
      await _api.post(
        '/api/v1/aa/update-balance',
        data: {
          'account_id': accountIdentifier,
          'amount': amount,
          'description': description,
          'recipient_name': recipientName ?? '',
          'category': category ?? 'transfer',
          'mode': mode ?? 'upi',
        },
      );
    } catch (_) {
      // Best-effort sync; local state is already updated
    }
  }

  /// Get total bank balance 
  double get totalBankBalance => state.totalBankBalance;
  
  /// Clear all AA data (on logout)
  void clear() {
    state = const AADataState();
  }
  
  /// Refresh data
  Future<void> refresh() => fetchAllData();
}

// ============================================================================
// Providers
// ============================================================================

final aaDataProvider = StateNotifierProvider<AADataNotifier, AADataState>((ref) {
  final notifier = AADataNotifier(ref);
  // Load default data immediately for fast UI rendering
  notifier.loadMockData();
  return notifier;
});

// Computed providers for specific screens
final bankAccountsProvider = Provider<List<BankAccountData>>((ref) {
  return ref.watch(aaDataProvider).bankAccounts;
});

final investmentsProvider = Provider<List<InvestmentHolding>>((ref) {
  return ref.watch(aaDataProvider).investments;
});

final loansProvider = Provider<List<LoanData>>((ref) {
  return ref.watch(aaDataProvider).loans;
});

final insurancesProvider = Provider<List<InsuranceData>>((ref) {
  return ref.watch(aaDataProvider).insurances;
});

final netWorthProvider = Provider<double>((ref) {
  final aaData = ref.watch(aaDataProvider);
  return aaData.snapshot?.netWorth ?? aaData.calculatedNetWorth;
});

final assetBreakdownProvider = Provider<AssetBreakdown>((ref) {
  return ref.watch(aaDataProvider).assetBreakdown ?? AssetBreakdown.mock;
});
