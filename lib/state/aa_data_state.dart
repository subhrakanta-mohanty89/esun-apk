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
      branch: json['branch'],
      lastUpdated: json['last_updated'] != null 
          ? DateTime.tryParse(json['last_updated']) 
          : null,
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
  
  static final Map<String, String> _bankLogos = {
    'hdfc bank': 'https://www.hdfcbank.com/content/dam/HDFCbank/images/logo.png',
    'hdfc': 'https://www.hdfcbank.com/content/dam/HDFCbank/images/logo.png',
    'icici bank': 'https://www.icicibank.com/etc.clientlibs/icicibank/clientlibs/clientlib-base-web/resources/assets/images/logo.png',
    'icici': 'https://www.icicibank.com/etc.clientlibs/icicibank/clientlibs/clientlib-base-web/resources/assets/images/logo.png',
    'sbi': 'https://sbi.co.in/documents/16012/115064/sbi-logo.png',
    'state bank of india': 'https://sbi.co.in/documents/16012/115064/sbi-logo.png',
    'axis bank': 'https://www.axisbank.com/images/axis-bank-logo.png',
    'axis': 'https://www.axisbank.com/images/axis-bank-logo.png',
    'kotak': 'https://www.kotak.com/content/dam/Kotak/kotak-bank/images/kotak-logo.svg',
    'kotak mahindra bank': 'https://www.kotak.com/content/dam/Kotak/kotak-bank/images/kotak-logo.svg',
    'yes bank': 'https://www.yesbank.in/o/yes-bank-web-theme/images/yes_bank_logo.svg',
    'punjab national bank': 'https://www.pnbindia.in/images/logo.png',
    'pnb': 'https://www.pnbindia.in/images/logo.png',
    'bank of baroda': 'https://www.bankofbaroda.in/documents/d/guest/bob-logo-new.png',
    'canara bank': 'https://canarabank.com/assets/site/images/logo.png',
    'union bank': 'https://www.unionbankofindia.co.in/images/logo.png',
    'indian bank': 'https://www.indianbank.in/sites/all/themes/idfc_first_theme/images/logo.svg',
    'idfc first bank': 'https://www.idfcfirstbank.com/images/logo/idfc-first-bank-logo.svg',
    'federal bank': 'https://www.federalbank.co.in/documents/10180/21119/fb-logo.svg',
    'indusind bank': 'https://www.indusind.com/iblogs/wp-content/themes/Developer/assets/images/indusind-logo.svg',
  };
  
  // Mock data - matches seeded database values
  static List<BankAccountData> get mockList => [
    BankAccountData(bankName: 'HDFC Bank', accountNumber: 'XXXX8847', accountType: 'SAVINGS', balance: 542350.75,
      logoUrl: 'https://www.hdfcbank.com/content/dam/HDFCbank/images/logo.png'),
    BankAccountData(bankName: 'ICICI Bank', accountNumber: 'XXXX3392', accountType: 'SAVINGS', balance: 187500.00,
      logoUrl: 'https://www.icicibank.com/etc.clientlibs/icicibank/clientlibs/clientlib-base-web/resources/assets/images/logo.png'),
    BankAccountData(bankName: 'SBI', accountNumber: 'XXXX7156', accountType: 'SALARY', balance: 325000.00,
      logoUrl: 'https://sbi.co.in/documents/16012/115064/sbi-logo.png'),
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
    'hdfcbank': 'https://companieslogo.com/img/orig/HDB-bb6c1c30.png',
    'hdfc bank': 'https://companieslogo.com/img/orig/HDB-bb6c1c30.png',
    'icicibank': 'https://companieslogo.com/img/orig/IBN-189d6746.png',
    'icici bank': 'https://companieslogo.com/img/orig/IBN-189d6746.png',
    'sbin': 'https://companieslogo.com/img/orig/SBIN.NS-c0359dfd.png',
    'sbi': 'https://companieslogo.com/img/orig/SBIN.NS-c0359dfd.png',
    'axisbank': 'https://companieslogo.com/img/orig/AXISBANK.NS-c1c58d16.png',
    'axis bank': 'https://companieslogo.com/img/orig/AXISBANK.NS-c1c58d16.png',
    'kotakbank': 'https://companieslogo.com/img/orig/KOTAKBANK.NS-cfc1a0c6.png',
    
    // IT Companies
    'infy': 'https://companieslogo.com/img/orig/INFY-9d3f8f7e.png',
    'infosys': 'https://companieslogo.com/img/orig/INFY-9d3f8f7e.png',
    'tcs': 'https://companieslogo.com/img/orig/TCS.NS-7401f1bd.png',
    'wipro': 'https://companieslogo.com/img/orig/WIPRO.NS-d7027c3c.png',
    'hcltech': 'https://companieslogo.com/img/orig/HCLTECH.NS-6d56101b.png',
    'techm': 'https://companieslogo.com/img/orig/TECHM.NS-a80db389.png',
    
    // Major Conglomerates
    'reliance': 'https://companieslogo.com/img/orig/RELIANCE.NS-c0f19c7e.png',
    'reliance industries': 'https://companieslogo.com/img/orig/RELIANCE.NS-c0f19c7e.png',
    'tatamotors': 'https://companieslogo.com/img/orig/TATAMOTORS.NS-16f69c4e.png',
    'tata motors': 'https://companieslogo.com/img/orig/TATAMOTORS.NS-16f69c4e.png',
    'tatasteel': 'https://companieslogo.com/img/orig/TATASTEEL.NS-09b87bbb.png',
    'bhartiartl': 'https://companieslogo.com/img/orig/BHARTIARTL.NS-5d75aaed.png',
    'airtel': 'https://companieslogo.com/img/orig/BHARTIARTL.NS-5d75aaed.png',
    'itc': 'https://companieslogo.com/img/orig/ITC.NS-5c351c53.png',
    'hindunilvr': 'https://companieslogo.com/img/orig/HINDUNILVR.NS-41c8e7bb.png',
    'hul': 'https://companieslogo.com/img/orig/HINDUNILVR.NS-41c8e7bb.png',
    
    // Consumer/Tech
    'swiggy': 'https://companieslogo.com/img/orig/SWIGGY.NS-e13f0b4d.png',
    'zomato': 'https://companieslogo.com/img/orig/ZOMATO.NS-90ff4ea8.png',
    'ola': 'https://companieslogo.com/img/orig/OLECTRA-GREENTECH.NS-4e6b2e3c.png',
    'boat': 'https://upload.wikimedia.org/wikipedia/commons/1/1a/BoAt_Logo.svg',
    'nykaa': 'https://companieslogo.com/img/orig/NYKAA.NS-4e6d3f9c.png',
    'paytm': 'https://companieslogo.com/img/orig/PAYTM.NS-c8e94c40.png',
    
    // Auto
    'maruti': 'https://companieslogo.com/img/orig/MARUTI.NS-9c0bcf29.png',
    'bajaj-auto': 'https://companieslogo.com/img/orig/BAJAJ-AUTO.NS-f5cbe96c.png',
    'eichermot': 'https://companieslogo.com/img/orig/EICHERMOT.NS-acf47c5d.png',
    'm&m': 'https://companieslogo.com/img/orig/M%26M.NS-eb3f4af5.png',
    'mahindra': 'https://companieslogo.com/img/orig/M%26M.NS-eb3f4af5.png',
    
    // Financial
    'hdfclife': 'https://companieslogo.com/img/orig/HDFCLIFE.NS-2a7e55b4.png',
    'sbilife': 'https://companieslogo.com/img/orig/SBILIFE.NS-0fdd8e51.png',
    'bajfinance': 'https://companieslogo.com/img/orig/BAJFINANCE.NS-c39b4f91.png',
    
    // Mutual Fund AMCs
    'axis bluechip': 'https://www.axismf.com/images/Logo.svg',
    'groww': 'https://groww.in/images/groww-logo.svg',
    'hdfc mutual': 'https://www.hdfcfund.com/content/dam/abc/india/fund-assets/images/hdfcmf-logo.svg',
    'sbi mutual': 'https://www.sbimf.com/assets/images/sbi-mf-logo.svg',
    'icici pru': 'https://www.icicipruamc.com/content/dam/icicipruamc/images/logo/icici-pru-logo.svg',
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
    'lic of india': 'https://licindia.in/o/lic-theme/images/lic-of-india-logo.png',
    'lic': 'https://licindia.in/o/lic-theme/images/lic-of-india-logo.png',
    'hdfc life': 'https://www.hdfclife.com/content/dam/hdfclifeinsurancecompany/about-us/investor-corner/HDFC%20Life%20Logo.png',
    'hdfc ergo': 'https://www.hdfcergo.com/images/hdfc-ergo-logo.png',
    'icici prudential': 'https://www.iciciprulife.com/content/dam/icicipru/logos/icici-pru-life-logo.svg',
    'icici lombard': 'https://www.icicilombard.com/content/dam/icicilombard/images/logo/icici-lombard-logo.png',
    'sbi life': 'https://www.sbilife.co.in/sites/all/themes/bootstrapsbilife/images/logo.png',
    'max life': 'https://www.maxlifeinsurance.com/content/dam/maxlifeinsurance/images/Max_Life_Logo.png',
    'bajaj allianz': 'https://www.bajajallianzlife.com/etc/designs/bajajallianzlife/common-assets/images/logo.png',
    'tata aia': 'https://www.tataaia.com/content/dam/tataaialifeinsurancecompanylimited/navigations/tata-aia-logo.svg',
    'kotak life': 'https://insurance.kotak.com/content/dam/kli/images/kli-logo.svg',
    'reliance nippon': 'https://www.reliancenipponlife.com/ReactApp/images/rnli-logo.svg',
  };
  
  // Mock data - matches seeded database values
  static List<InsuranceData> get mockList => [
    InsuranceData(
      id: '1', provider: 'LIC of India', policyNumber: 'POL****5847',
      type: 'TERM', sumAssured: 10000000, premiumAmount: 15000,
      premiumFrequency: 'YEARLY', startDate: DateTime(2021, 6, 15),
      expiryDate: DateTime(2051, 6, 15), status: 'ACTIVE',
      logoUrl: 'https://licindia.in/o/lic-theme/images/lic-of-india-logo.png',
    ),
    InsuranceData(
      id: '2', provider: 'Max Life', policyNumber: 'POL****2938',
      type: 'ULIP', sumAssured: 2500000, premiumAmount: 50000,
      premiumFrequency: 'YEARLY', startDate: DateTime(2023, 3, 10),
      expiryDate: DateTime(2043, 3, 10), status: 'ACTIVE',
      logoUrl: 'https://www.maxlifeinsurance.com/content/dam/maxlifeinsurance/images/Max_Life_Logo.png',
    ),
    InsuranceData(
      id: '3', provider: 'HDFC ERGO', policyNumber: 'POL****8472',
      type: 'HEALTH', sumAssured: 500000, premiumAmount: 12000,
      premiumFrequency: 'YEARLY', startDate: DateTime(2024, 1, 1),
      expiryDate: DateTime(2025, 1, 1), status: 'ACTIVE',
      logoUrl: 'https://www.hdfcergo.com/images/hdfc-ergo-logo.png',
    ),
    InsuranceData(
      id: '4', provider: 'ICICI Lombard', policyNumber: 'POL****6183',
      type: 'VEHICLE', sumAssured: 1200000, premiumAmount: 8000,
      premiumFrequency: 'YEARLY', startDate: DateTime(2025, 9, 20),
      expiryDate: DateTime(2026, 9, 20), status: 'ACTIVE',
      logoUrl: 'https://www.icicilombard.com/content/dam/icicilombard/images/logo/icici-lombard-logo.png',
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
        final accounts = result.data['accounts'] as List?;
        return accounts?.map((a) => AALinkedAccount.fromJson(a)).toList() ?? [];
      }
    } catch (_) {}
    return [];
  }
  
  Future<List<BankAccountData>> _fetchBankAccounts() async {
    try {
      final result = await _api.get('/api/v1/aa/bank-accounts');
      if (result.isSuccess && result.data != null) {
        final accounts = result.data['accounts'] as List?;
        return accounts?.map((a) => BankAccountData.fromJson(a)).toList() ?? [];
      }
    } catch (_) {}
    return [];
  }
  
  Future<List<InvestmentHolding>> _fetchInvestments() async {
    try {
      final result = await _api.get('/api/v1/aa/investments');
      if (result.isSuccess && result.data != null) {
        final holdings = result.data['holdings'] as List?;
        return holdings?.map((h) => InvestmentHolding.fromJson(h)).toList() ?? [];
      }
    } catch (_) {}
    return [];
  }
  
  Future<List<LoanData>> _fetchLoans() async {
    try {
      final result = await _api.get('/api/v1/aa/loans');
      if (result.isSuccess && result.data != null) {
        final loans = result.data['loans'] as List?;
        return loans?.map((l) => LoanData.fromJson(l)).toList() ?? [];
      }
    } catch (_) {}
    return [];
  }
  
  Future<List<InsuranceData>> _fetchInsurances() async {
    try {
      final result = await _api.get('/api/v1/aa/insurances');
      if (result.isSuccess && result.data != null) {
        final insurances = result.data['insurances'] as List?;
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
  
  /// Load mock data for demo/testing
  void loadMockData() {
    state = state.copyWith(
      isLoading: false,
      isLoaded: true,
      lastUpdated: DateTime.now(),
      snapshot: FinancialSnapshot.mock,
      assetBreakdown: AssetBreakdown.mock,
      bankAccounts: [
        BankAccountData(
          bankName: 'HDFC Bank',
          accountNumber: 'XXXX1234',
          accountType: 'SAVINGS',
          balance: 85000,
          lastUpdated: DateTime.now(),
        ),
        BankAccountData(
          bankName: 'ICICI Bank',
          accountNumber: 'XXXX5678',
          accountType: 'SAVINGS',
          balance: 120889,
          lastUpdated: DateTime.now(),
        ),
      ],
      investments: [
        InvestmentHolding(
          id: '1',
          name: 'HDFC Mid-Cap Opportunities Fund',
          type: 'MUTUAL_FUND',
          symbol: 'HDFCMIDCAP',
          quantity: 156.34,
          avgBuyPrice: 892.45,
          currentValue: 162500,
          returns: 23000,
          returnsPercentage: 16.5,
          provider: 'CAMS',
        ),
        InvestmentHolding(
          id: '2',
          name: 'Reliance Industries Ltd',
          type: 'STOCK',
          symbol: 'RELIANCE',
          quantity: 50,
          avgBuyPrice: 2200,
          currentValue: 148500,
          returns: 38500,
          returnsPercentage: 35.0,
          provider: 'NSDL',
        ),
        InvestmentHolding(
          id: '3',
          name: 'Nippon India ETF Nifty BeES',
          type: 'ETF',
          symbol: 'NIFTYBEES',
          quantity: 200,
          avgBuyPrice: 230,
          currentValue: 52000,
          returns: 6000,
          returnsPercentage: 13.04,
          provider: 'CDSL',
        ),
      ],
      loans: [
        LoanData(
          id: '1',
          lenderName: 'SBI',
          loanType: 'HOME',
          accountNumber: 'XXXX9012',
          principalAmount: 5000000,
          outstandingAmount: 3200000,
          emiAmount: 42500,
          interestRate: 8.5,
          tenure: 240,
          remainingTenure: 168,
          nextEmiDate: DateTime.now().add(const Duration(days: 15)),
          status: 'ACTIVE',
        ),
        LoanData(
          id: '2',
          lenderName: 'HDFC Bank',
          loanType: 'PERSONAL',
          accountNumber: 'XXXX3456',
          principalAmount: 300000,
          outstandingAmount: 180000,
          emiAmount: 12500,
          interestRate: 12.5,
          tenure: 36,
          remainingTenure: 18,
          nextEmiDate: DateTime.now().add(const Duration(days: 10)),
          status: 'ACTIVE',
        ),
      ],
      insurances: [
        InsuranceData(
          id: '1',
          provider: 'LIC of India',
          policyNumber: 'XXXX7890',
          type: 'TERM',
          sumAssured: 10000000,
          premiumAmount: 12000,
          premiumFrequency: 'YEARLY',
          startDate: DateTime(2023, 1, 1),
          expiryDate: DateTime(2053, 1, 1),
          status: 'ACTIVE',
          nominees: ['Spouse'],
        ),
        InsuranceData(
          id: '2',
          provider: 'Star Health',
          policyNumber: 'XXXX4567',
          type: 'HEALTH',
          sumAssured: 1000000,
          premiumAmount: 18000,
          premiumFrequency: 'YEARLY',
          startDate: DateTime(2024, 1, 1),
          expiryDate: DateTime(2025, 1, 1),
          status: 'ACTIVE',
        ),
      ],
    );
  }
  
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
  return AADataNotifier(ref);
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
