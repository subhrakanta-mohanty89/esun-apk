/// ESUN Borrow Hub Screen
/// 
/// Loan products, credit options, and AI-powered loan assistant.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import '../../core/utils/utils.dart';
import '../../state/aa_data_state.dart';

class BorrowScreen extends ConsumerStatefulWidget {
  const BorrowScreen({super.key});

  @override
  ConsumerState<BorrowScreen> createState() => _BorrowScreenState();
}

class _BorrowScreenState extends ConsumerState<BorrowScreen> {
  final TextEditingController _loanAmountController = TextEditingController(text: '500000');
  String _selectedLoanPurpose = 'Personal';
  int _selectedTenure = 24;

  @override
  void dispose() {
    _loanAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrow Hub'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Credit Score - Top Priority
            _buildCreditScore(context),
            
            // Quick Loan Finder
            _buildQuickLoanFinder(context),
            
            // Best Loan Recommendations
            _buildBestLoanRecommendations(context),
            
            // Loan Products
            _buildLoanProducts(context),
            
            // Active Loans
            _buildActiveLoans(context),
            
            // Pre-approved Offers
            _buildPreApprovedOffers(context),
            
            // EMI Calculator
            _buildEMICalculator(context),
            
            // Loan Comparison
            _buildLoanComparison(context),
            
            // Quick Apply Steps
            _buildQuickApplySteps(context),
            
            // Partner Banks
            _buildPartnerBanks(context),
            
            // Why Choose Us
            _buildWhyChooseUs(context),
            
            // FAQs
            _buildFAQs(context),
            
            // Customer Testimonials
            _buildTestimonials(context),
            
            const SizedBox(height: 72),
          ],
        ),
      ),
    );
  }

  // Quick Loan Finder
  Widget _buildQuickLoanFinder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: FPCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.search, color: ESUNColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Find Your Perfect Loan',
                  style: ESUNTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ESUNSpacing.lg),
            // Loan Amount Input
            Text(
              'How much do you need?',
              style: ESUNTypography.bodyMedium.copyWith(
                color: ESUNColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _loanAmountController,
              keyboardType: TextInputType.number,
              style: ESUNTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: ESUNColors.primary,
              ),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: ESUNTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ESUNColors.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: ESUNRadius.mdRadius,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: ESUNRadius.mdRadius,
                  borderSide: const BorderSide(color: ESUNColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: ESUNSpacing.lg),
            // Loan Purpose
            Text(
              'What\'s it for?',
              style: ESUNTypography.bodyMedium.copyWith(
                color: ESUNColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Personal', 'Home', 'Vehicle', 'Business', 'Education', 'Medical'].map((purpose) {
                final isSelected = _selectedLoanPurpose == purpose;
                return ChoiceChip(
                  label: Text(purpose),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedLoanPurpose = purpose);
                  },
                  selectedColor: ESUNColors.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? ESUNColors.primary : ESUNColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: ESUNSpacing.lg),
            // Tenure Selection
            Text(
              'Preferred tenure: $_selectedTenure months',
              style: ESUNTypography.bodyMedium.copyWith(
                color: ESUNColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _selectedTenure.toDouble(),
              min: 6,
              max: 84,
              divisions: 13,
              label: '$_selectedTenure months',
              onChanged: (value) {
                setState(() => _selectedTenure = value.toInt());
              },
            ),
            const SizedBox(height: ESUNSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _findBestLoans(context),
                icon: const Icon(Icons.search),
                label: const Text('Find Best Loans'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Best Loan Recommendations
  Widget _buildBestLoanRecommendations(BuildContext context) {
    final recommendations = [
      _LoanRecommendation(
        bankName: 'HDFC Bank',
        loanType: 'Personal Loan',
        interestRate: '10.50%',
        maxAmount: '₹40 Lakh',
        processingFee: '1%',
        features: ['Instant Approval', 'No Collateral', 'Flexible EMI'],
        rating: 4.8,
        color: Colors.blue,
        isTopPick: true,
      ),
      _LoanRecommendation(
        bankName: 'ICICI Bank',
        loanType: 'Personal Loan',
        interestRate: '10.75%',
        maxAmount: '₹50 Lakh',
        processingFee: '0.5%',
        features: ['Low Processing Fee', '24hr Disbursement'],
        rating: 4.6,
        color: Colors.orange,
        isTopPick: false,
      ),
      _LoanRecommendation(
        bankName: 'SBI',
        loanType: 'Personal Loan',
        interestRate: '11.00%',
        maxAmount: '₹35 Lakh',
        processingFee: '1.5%',
        features: ['Government Bank', 'Lower EMI Option'],
        rating: 4.5,
        color: Colors.indigo,
        isTopPick: false,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.stars, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Best Loans For You',
                    style: ESUNTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Compare All'),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          ...recommendations.map((rec) => _buildRecommendationCard(context, rec)),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, _LoanRecommendation rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: ESUNSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: ESUNRadius.lgRadius,
        border: rec.isTopPick 
            ? Border.all(color: ESUNColors.primary, width: 2)
            : Border.all(color: ESUNColors.border),
        boxShadow: [
          if (rec.isTopPick)
            BoxShadow(
              color: ESUNColors.primary.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          if (rec.isTopPick)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                color: ESUNColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.thumb_up, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'TOP PICK - Best Match for You',
                    style: ESUNTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: rec.color.withOpacity(0.1),
                        borderRadius: ESUNRadius.smRadius,
                      ),
                      child: Center(
                        child: Text(
                          rec.bankName.substring(0, 2).toUpperCase(),
                          style: ESUNTypography.titleMedium.copyWith(
                            color: rec.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: ESUNSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec.bankName,
                            style: ESUNTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            rec.loanType,
                            style: ESUNTypography.bodySmall.copyWith(
                              color: ESUNColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          rec.rating.toString(),
                          style: ESUNTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: ESUNSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLoanStat2('Interest', rec.interestRate, ESUNColors.success),
                    _buildLoanStat2('Max Amt', rec.maxAmount, ESUNColors.primary),
                    _buildLoanStat2('Fee', rec.processingFee, ESUNColors.warning),
                  ],
                ),
                const SizedBox(height: ESUNSpacing.md),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: rec.features.map((f) => Container(
                    padding: ESUNSpacing.badgeInsets,
                    decoration: BoxDecoration(
                      color: ESUNColors.surfaceVariant,
                      borderRadius: ESUNRadius.fullRadius,
                    ),
                    child: Text(
                      f,
                      style: ESUNTypography.labelSmall.copyWith(
                        color: ESUNColors.textSecondary,
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: ESUNSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showLoanDetails(context, rec),
                        child: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: ESUNSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _applyForLoan(context, rec),
                        child: const Text('Apply Now'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanStat2(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: ESUNTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: ESUNTypography.labelSmall.copyWith(
            color: ESUNColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // Loan Comparison Section
  Widget _buildLoanComparison(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: FPCard(
        onTap: () => _showComparisonSheet(context),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(ESUNSpacing.md),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: ESUNRadius.smRadius,
              ),
              child: const Icon(Icons.compare_arrows, color: Colors.teal, size: 28),
            ),
            const SizedBox(width: ESUNSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compare Loans',
                    style: ESUNTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Compare rates from 15+ banks side by side',
                    style: ESUNTypography.bodySmall.copyWith(
                      color: ESUNColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: ESUNColors.textTertiary),
          ],
        ),
      ),
    );
  }

  // Quick Apply Steps
  Widget _buildQuickApplySteps(BuildContext context) {
    final steps = [
      _ApplyStep(1, 'Choose Loan', 'Select loan type & amount', Icons.touch_app),
      _ApplyStep(2, 'KYC Verification', 'Quick Aadhaar-based eKYC', Icons.verified_user),
      _ApplyStep(3, 'Document Upload', 'Income proof & bank statement', Icons.upload_file),
      _ApplyStep(4, 'Get Approval', 'Instant approval in 2 mins', Icons.check_circle),
    ];

    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to Apply',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          ...steps.map((step) => _buildStepItem(step)),
        ],
      ),
    );
  }

  Widget _buildStepItem(_ApplyStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ESUNColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${step.number}',
                style: ESUNTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: ESUNTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  step.subtitle,
                  style: ESUNTypography.bodySmall.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(step.icon, color: ESUNColors.primary, size: 24),
        ],
      ),
    );
  }

  // Partner Banks
  Widget _buildPartnerBanks(BuildContext context) {
    final banks = [
      _BankPartner('HDFC Bank', 'hdfc', Colors.blue),
      _BankPartner('ICICI Bank', 'icici', Colors.orange),
      _BankPartner('SBI', 'sbi', Colors.indigo),
      _BankPartner('Axis Bank', 'axis', Colors.purple),
      _BankPartner('Kotak', 'kotak', Colors.red),
      _BankPartner('Yes Bank', 'yes', Colors.blue),
      _BankPartner('IDFC First', 'idfc', Colors.green),
      _BankPartner('IndusInd', 'indus', Colors.teal),
    ];

    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our Partner Banks',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Get the best rates from 15+ partner banks',
            style: ESUNTypography.bodySmall.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: banks.length,
              itemBuilder: (context, index) {
                final bank = banks[index];
                return _buildBankLogo(bank);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankLogo(_BankPartner bank) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: ESUNSpacing.sm),
      decoration: BoxDecoration(
        color: ESUNColors.surface,
        borderRadius: ESUNRadius.mdRadius,
        border: Border.all(color: ESUNColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bank.color.withOpacity(0.1),
              borderRadius: ESUNRadius.smRadius,
            ),
            child: Center(
              child: Text(
                bank.name.substring(0, 2).toUpperCase(),
                style: ESUNTypography.titleSmall.copyWith(
                  color: bank.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            bank.name.split(' ').first,
            style: ESUNTypography.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Why Choose Us
  Widget _buildWhyChooseUs(BuildContext context) {
    final benefits = [
      _Benefit(Icons.speed, 'Quick Approval', '2-minute instant approval'),
      _Benefit(Icons.percent, 'Best Rates', 'Lowest interest rates guaranteed'),
      _Benefit(Icons.lock, 'Secure', 'Bank-grade security for your data'),
      _Benefit(Icons.support_agent, '24/7 Support', 'Round-the-clock assistance'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Choose Us',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: ESUNSpacing.md,
              mainAxisSpacing: ESUNSpacing.md,
            ),
            itemCount: benefits.length,
            itemBuilder: (context, index) {
              final benefit = benefits[index];
              return _buildBenefitCard(benefit);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard(_Benefit benefit) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: ESUNColors.primary.withOpacity(0.05),
        borderRadius: ESUNRadius.mdRadius,
        border: Border.all(color: ESUNColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(benefit.icon, color: ESUNColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            benefit.title,
            style: ESUNTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            benefit.subtitle,
            style: ESUNTypography.labelSmall.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // FAQs
  Widget _buildFAQs(BuildContext context) {
    final faqs = [
      _FAQ('What documents are required?', 'You need PAN Card, Aadhaar Card, last 3 months salary slips, and 6 months bank statement.'),
      _FAQ('How long does approval take?', 'Most loans are approved within 2 minutes. Disbursement happens within 24 hours.'),
      _FAQ('What is the minimum credit score?', 'A credit score of 650+ is required. Higher scores get better interest rates.'),
      _FAQ('Can I prepay my loan?', 'Yes, you can prepay after 6 months with nominal prepayment charges.'),
      _FAQ('Are there any hidden charges?', 'No hidden charges. Processing fee is clearly mentioned upfront.'),
    ];

    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequently Asked Questions',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          ...faqs.map((faq) => _buildFAQItem(faq)),
        ],
      ),
    );
  }

  Widget _buildFAQItem(_FAQ faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: ESUNSpacing.sm),
      decoration: BoxDecoration(
        color: ESUNColors.surface,
        borderRadius: ESUNRadius.mdRadius,
        border: Border.all(color: ESUNColors.border),
      ),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: ESUNTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, 0, ESUNSpacing.lg, ESUNSpacing.lg),
            child: Text(
              faq.answer,
              style: ESUNTypography.bodySmall.copyWith(
                color: ESUNColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Customer Testimonials
  Widget _buildTestimonials(BuildContext context) {
    final testimonials = [
      _Testimonial(
        'Rahul Sharma',
        'Mumbai',
        'Got my personal loan approved in just 5 minutes! The AI assistant helped me find the best rate.',
        4.9,
        '₹5 Lakh Loan',
      ),
      _Testimonial(
        'Priya Patel',
        'Delhi',
        'Excellent service! Compared rates from multiple banks and saved ₹15,000 on interest.',
        4.8,
        '₹10 Lakh Loan',
      ),
      _Testimonial(
        'Amit Kumar',
        'Bangalore',
        'Smooth process from application to disbursement. Got the money within 24 hours.',
        5.0,
        '₹3 Lakh Loan',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'What Our Users Say',
                style: ESUNTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  Text(
                    ' 4.9 (12K+ reviews)',
                    style: ESUNTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: testimonials.length,
              itemBuilder: (context, index) {
                final testimonial = testimonials[index];
                return _buildTestimonialCard(testimonial);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard(_Testimonial testimonial) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: ESUNSpacing.md),
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: ESUNColors.surface,
        borderRadius: ESUNRadius.lgRadius,
        border: Border.all(color: ESUNColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: ESUNColors.primary.withOpacity(0.1),
                child: Text(
                  testimonial.name.split(' ').map((e) => e[0]).take(2).join(),
                  style: ESUNTypography.titleSmall.copyWith(
                    color: ESUNColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testimonial.name,
                      style: ESUNTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      testimonial.location,
                      style: ESUNTypography.labelSmall.copyWith(
                        color: ESUNColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: ESUNSpacing.badgeInsets,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: ESUNRadius.fullRadius,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '${testimonial.rating}',
                      style: ESUNTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.sm),
          Expanded(
            child: Text(
              '"${testimonial.review}"',
              style: ESUNTypography.bodySmall.copyWith(
                color: ESUNColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: ESUNSpacing.badgeInsets,
            decoration: BoxDecoration(
              color: ESUNColors.success.withOpacity(0.1),
              borderRadius: ESUNRadius.fullRadius,
            ),
            child: Text(
              testimonial.loanType,
              style: ESUNTypography.labelSmall.copyWith(
                color: ESUNColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _findBestLoans(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Finding best loans based on your requirements...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLoanDetails(BuildContext context, _LoanRecommendation rec) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(ESUNSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: ESUNSpacing.lg),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: rec.color.withOpacity(0.1),
                      borderRadius: ESUNRadius.mdRadius,
                    ),
                    child: Center(
                      child: Text(
                        rec.bankName.substring(0, 2).toUpperCase(),
                        style: ESUNTypography.titleLarge.copyWith(
                          color: rec.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: ESUNSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec.bankName,
                          style: ESUNTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(rec.loanType),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ESUNSpacing.xl),
              _buildDetailRow('Interest Rate', rec.interestRate),
              _buildDetailRow('Maximum Amount', rec.maxAmount),
              _buildDetailRow('Processing Fee', rec.processingFee),
              _buildDetailRow('Tenure', '6 - 84 months'),
              _buildDetailRow('Prepayment', 'Allowed after 6 months'),
              _buildDetailRow('Disbursement', 'Within 24 hours'),
              const SizedBox(height: ESUNSpacing.lg),
              Text(
                'Eligibility Criteria',
                style: ESUNTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildEligibilityItem('Age: 21 - 60 years'),
              _buildEligibilityItem('Min Income: ₹25,000/month'),
              _buildEligibilityItem('Credit Score: 650+'),
              _buildEligibilityItem('Employment: Salaried/Self-employed'),
              const SizedBox(height: ESUNSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyForLoan(context, rec);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                  ),
                  child: const Text('Apply Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: ESUNTypography.bodyMedium.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: ESUNTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEligibilityItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: ESUNColors.success, size: 18),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  void _applyForLoan(BuildContext context, _LoanRecommendation rec) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: ESUNColors.success),
            const SizedBox(width: 8),
            const Text('Apply for Loan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You\'re applying for:'),
            const SizedBox(height: 8),
            Text(
              '${rec.bankName} - ${rec.loanType}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Required documents:'),
            const SizedBox(height: 8),
            _buildDocItem('PAN Card'),
            _buildDocItem('Aadhaar Card'),
            _buildDocItem('Last 3 months salary slips'),
            _buildDocItem('Bank statement (6 months)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Application submitted! We\'ll contact you within 24 hours.'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: ESUNColors.success,
                ),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  void _showComparisonSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(ESUNSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: ESUNSpacing.lg),
              Text(
                'Compare Personal Loans',
                style: ESUNTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: ESUNSpacing.lg),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Bank')),
                    DataColumn(label: Text('Rate')),
                    DataColumn(label: Text('Max Amt')),
                    DataColumn(label: Text('Fee')),
                    DataColumn(label: Text('Tenure')),
                  ],
                  rows: [
                    _buildCompareRow('HDFC Bank', '10.50%', '₹40L', '1%', '84 mo'),
                    _buildCompareRow('ICICI Bank', '10.75%', '₹50L', '0.5%', '84 mo'),
                    _buildCompareRow('SBI', '11.00%', '₹35L', '1.5%', '72 mo'),
                    _buildCompareRow('Axis Bank', '10.99%', '₹40L', '1%', '60 mo'),
                    _buildCompareRow('Kotak', '11.25%', '₹30L', '2%', '72 mo'),
                    _buildCompareRow('Yes Bank', '11.50%', '₹25L', '1.5%', '60 mo'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DataRow _buildCompareRow(String bank, String rate, String maxAmt, String fee, String tenure) {
    return DataRow(
      cells: [
        DataCell(Text(bank, style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(rate, style: const TextStyle(color: ESUNColors.success))),
        DataCell(Text(maxAmt)),
        DataCell(Text(fee)),
        DataCell(Text(tenure)),
      ],
    );
  }
  
  Widget _buildCreditScore(BuildContext context) {
    final aaData = ref.watch(aaDataProvider);
    final score = aaData.creditScore;
    final label = aaData.creditLabel;
    final percentage = score / 900;
    final percentText = '${(percentage * 100).round()}%';

    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: FPGradientCard(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ESUNColors.primary200, ESUNColors.secondaryLight],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Credit Score',
                        style: ESUNTypography.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ESUNSpacing.sm),
                  Text(
                    '$score',
                    style: ESUNTypography.displaySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: ESUNSpacing.badgeInsets,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: ESUNRadius.fullRadius,
                    ),
                    child: Text(
                      label,
                      style: ESUNTypography.labelSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                  Text(
                    percentText,
                    style: ESUNTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoanProducts(BuildContext context) {
    final products = [
      _LoanProduct('Personal Loan', 'Up to ₹25L', '10.5%', Icons.person, ESUNColors.primary400),
      _LoanProduct('Home Loan', 'Up to ₹5Cr', '8.5%', Icons.home, ESUNColors.secondary),
      _LoanProduct('Secured Loan', 'Up to ₹50L', '7.5%', Icons.workspace_premium, ESUNColors.accent),
      _LoanProduct('Vehicle Loan', 'Up to ₹1Cr', '9.0%', Icons.directions_car, ESUNColors.info),
    ];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Loan Products',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: ESUNSpacing.md,
              mainAxisSpacing: ESUNSpacing.md,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(product);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductCard(_LoanProduct product) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: product.color.withOpacity(0.05),
        borderRadius: ESUNRadius.lgRadius,
        border: Border.all(color: product.color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(product.icon, color: product.color, size: 28),
          const Spacer(),
          Text(
            product.name,
            style: ESUNTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            product.maxAmount,
            style: ESUNTypography.bodySmall.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'From ${product.rate} p.a.',
            style: ESUNTypography.labelMedium.copyWith(
              color: product.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActiveLoans(BuildContext context) {
    final aaData = ref.watch(aaDataProvider);
    final loans = aaData.loans;
    
    if (loans.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Loans',
              style: ESUNTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: ESUNSpacing.md),
            FPCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(ESUNSpacing.xl),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 48, color: ESUNColors.success),
                      const SizedBox(height: ESUNSpacing.md),
                      Text(
                        'No Active Loans',
                        style: ESUNTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'You have no outstanding loans',
                        style: ESUNTypography.bodySmall.copyWith(
                          color: ESUNColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Loans (${loans.length})',
                style: ESUNTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: ESUNSpacing.badgeInsets,
                decoration: BoxDecoration(
                  color: ESUNColors.primary.withOpacity(0.1),
                  borderRadius: ESUNRadius.fullRadius,
                ),
                child: Text(
                  'Total: ${loans.fold(0.0, (sum, loan) => sum + loan.outstanding).toINR()}',
                  style: ESUNTypography.labelSmall.copyWith(
                    color: ESUNColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          ...loans.map((loan) => Padding(
            padding: const EdgeInsets.only(bottom: ESUNSpacing.md),
            child: _buildActiveLoanCard(loan),
          )),
        ],
      ),
    );
  }
  
  Widget _buildActiveLoanCard(LoanData loan) {
    final progress = (loan.principalAmount - loan.outstanding) / loan.principalAmount;
    final paidAmount = loan.principalAmount - loan.outstanding;
    
    IconData getLoanIcon(String type) {
      switch (type.toLowerCase()) {
        case 'personal': return Icons.person;
        case 'home': return Icons.home;
        case 'car': return Icons.directions_car;
        case 'education': return Icons.school;
        case 'business': return Icons.business;
        default: return Icons.account_balance;
      }
    }
    
    Color getLoanColor(String type) {
      switch (type.toLowerCase()) {
        case 'personal': return Colors.blue;
        case 'home': return Colors.green;
        case 'car': return Colors.orange;
        case 'education': return Colors.purple;
        case 'business': return Colors.teal;
        default: return Colors.grey;
      }
    }
    
    return FPCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(ESUNSpacing.md),
                decoration: BoxDecoration(
                  color: getLoanColor(loan.type).withOpacity(0.1),
                  borderRadius: ESUNRadius.smRadius,
                ),
                child: Icon(getLoanIcon(loan.type), color: getLoanColor(loan.type)),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${loan.type} Loan',
                      style: ESUNTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      loan.lender,
                      style: ESUNTypography.bodySmall.copyWith(
                        color: ESUNColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    loan.outstanding.toINR(),
                    style: ESUNTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Outstanding',
                    style: ESUNTypography.labelSmall.copyWith(
                      color: ESUNColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLoanStat('EMI', loan.emi.toINR()),
              _buildLoanStat('Interest', '${loan.interestRate}%'),
              _buildLoanStat('Tenure', '${loan.tenure} months'),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          ClipRRect(
            borderRadius: ESUNRadius.fullRadius,
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: ESUNColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(getLoanColor(loan.type)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${paidAmount.toINR()} paid',
                style: ESUNTypography.labelSmall.copyWith(
                  color: ESUNColors.success,
                ),
              ),
              if (loan.nextDueDate != null)
                Text(
                  'Next EMI: ${_formatDate(loan.nextDueDate!)}',
                  style: ESUNTypography.labelSmall.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
  
  Widget _buildLoanStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: ESUNTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: ESUNTypography.labelSmall.copyWith(
            color: ESUNColors.textSecondary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPreApprovedOffers(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Pre-approved Offers',
                style: ESUNTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ESUNColors.success.withOpacity(0.1),
                  borderRadius: ESUNRadius.fullRadius,
                ),
                child: Text(
                  'NEW',
                  style: ESUNTypography.labelSmall.copyWith(
                    color: ESUNColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ESUNColors.primary300, ESUNColors.primary500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: ESUNRadius.lgRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'You\'re pre-approved!',
                      style: ESUNTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ESUNSpacing.md),
                Text(
                  'Personal Loan up to',
                  style: ESUNTypography.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  '₹10,00,000',
                  style: ESUNTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'At 10.5% p.a. • Instant approval',
                  style: ESUNTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: ESUNSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green.shade700,
                    ),
                    child: const Text('Apply Now'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEMICalculator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: FPCard(
        onTap: () {},
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(ESUNSpacing.md),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: ESUNRadius.smRadius,
              ),
              child: const Icon(Icons.calculate, color: Colors.purple, size: 28),
            ),
            const SizedBox(width: ESUNSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EMI Calculator',
                    style: ESUNTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Calculate your monthly payments',
                    style: ESUNTypography.bodySmall.copyWith(
                      color: ESUNColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: ESUNColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _LoanProduct {
  final String name;
  final String maxAmount;
  final String rate;
  final IconData icon;
  final Color color;
  
  _LoanProduct(this.name, this.maxAmount, this.rate, this.icon, this.color);
}

class _LoanRecommendation {
  final String bankName;
  final String loanType;
  final String interestRate;
  final String maxAmount;
  final String processingFee;
  final List<String> features;
  final double rating;
  final Color color;
  final bool isTopPick;

  _LoanRecommendation({
    required this.bankName,
    required this.loanType,
    required this.interestRate,
    required this.maxAmount,
    required this.processingFee,
    required this.features,
    required this.rating,
    required this.color,
    required this.isTopPick,
  });
}

class _ApplyStep {
  final int number;
  final String title;
  final String subtitle;
  final IconData icon;

  _ApplyStep(this.number, this.title, this.subtitle, this.icon);
}

class _BankPartner {
  final String name;
  final String code;
  final Color color;

  _BankPartner(this.name, this.code, this.color);
}

class _Benefit {
  final IconData icon;
  final String title;
  final String subtitle;

  _Benefit(this.icon, this.title, this.subtitle);
}

class _FAQ {
  final String question;
  final String answer;

  _FAQ(this.question, this.answer);
}

class _Testimonial {
  final String name;
  final String location;
  final String review;
  final double rating;
  final String loanType;

  _Testimonial(this.name, this.location, this.review, this.rating, this.loanType);
}



