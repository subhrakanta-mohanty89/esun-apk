/// ESUN Discover Screen
/// 
/// Explore financial products, offers, and features.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/widgets/smart_network_image.dart';
import '../../state/aa_data_state.dart';
import '../../core/utils/utils.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});
  
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? ESUNColors.darkBackground : ESUNColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? ESUNColors.darkSurface : ESUNColors.surface,
        elevation: 0,
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(AppRoutes.search),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Banner
            _buildFeaturedBanner(context),
            
            // My Insurance Policies (from AA)
            _buildMyInsurancePolicies(context),
            
            // Categories
            _buildCategories(context),
            
            // Investment Products
            _buildInvestmentProducts(context),
            
            // Lending Products
            _buildLendingProducts(context),
            
            // Education Products
            _buildEducationProducts(context),
            
            // Financial Tools
            _buildFinancialTools(context),
            
            // Offers
            _buildOffers(context),
            
            // Learn & Earn
            _buildLearnSection(context),
            
            // Rewards
            _buildRewards(context),
            
            const SizedBox(height: ESUNSpacing.xxxl),
          ],
        ),
      ),
    );
  }
  
  // Investment Products Section
  Widget _buildInvestmentProducts(BuildContext context) {
    final products = [
      _ProductItem(
        'Mutual Funds',
        'Start SIP from ₹100',
        Icons.pie_chart,
        Colors.purple,
        '15.2% avg returns',
        true,
      ),
      _ProductItem(
        'Stocks & ETFs',
        'Invest in top companies',
        Icons.candlestick_chart,
        Colors.blue,
        'Zero brokerage',
        true,
      ),
      _ProductItem(
        'Fixed Deposits',
        'Up to 8.5% p.a.',
        Icons.account_balance,
        Colors.orange,
        'Guaranteed returns',
        false,
      ),
      _ProductItem(
        'Digital Gold',
        '24K 99.9% pure gold',
        Icons.workspace_premium,
        Colors.amber,
        'From ₹1',
        false,
      ),
      _ProductItem(
        'Bonds',
        'Government & Corporate',
        Icons.receipt_long,
        Colors.teal,
        '7-9% returns',
        false,
      ),
      _ProductItem(
        'NPS',
        'National Pension Scheme',
        Icons.elderly,
        Colors.indigo,
        'Tax benefits',
        false,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg, vertical: ESUNSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.green, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Investment Products',
                    style: ESUNTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.35,
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

  Widget _buildProductCard(_ProductItem product) {
    return GestureDetector(
      onTap: () => _navigateToProduct(product.name),
      child: Container(
        padding: const EdgeInsets.all(ESUNSpacing.md),
        decoration: BoxDecoration(
          color: product.color.withOpacity(0.05),
          borderRadius: ESUNRadius.lgRadius,
          border: Border.all(color: product.color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(ESUNSpacing.sm),
                  decoration: BoxDecoration(
                    color: product.color.withOpacity(0.1),
                    borderRadius: ESUNRadius.smRadius,
                  ),
                  child: Icon(product.icon, color: product.color, size: 20),
                ),
                if (product.isPopular)
                  Container(
                    padding: ESUNSpacing.tagInsets,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      borderRadius: ESUNRadius.fullRadius,
                    ),
                    child: Text(
                      'POPULAR',
                      style: ESUNTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 8,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              product.name,
              style: ESUNTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              product.subtitle,
              style: ESUNTypography.labelSmall.copyWith(
                color: ESUNColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              product.highlight,
              style: ESUNTypography.labelSmall.copyWith(
                color: product.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // My Insurance Policies (from Account Aggregator)
  Widget _buildMyInsurancePolicies(BuildContext context) {
    final aaData = ref.watch(aaDataProvider);
    final insurances = aaData.insurances;
    
    if (insurances.isEmpty) {
      return const SizedBox.shrink();
    }
    
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
                  Container(
                    padding: const EdgeInsets.all(ESUNSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: ESUNRadius.smRadius,
                    ),
                    child: const Icon(Icons.shield_outlined, color: Colors.deepPurple, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'My Insurance',
                    style: ESUNTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: ESUNSpacing.badgeInsets,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: ESUNRadius.fullRadius,
                ),
                child: Text(
                  '${insurances.length} Policies',
                  style: ESUNTypography.labelSmall.copyWith(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          ...insurances.map((insurance) => Padding(
            padding: const EdgeInsets.only(bottom: ESUNSpacing.sm),
            child: _buildInsuranceCard(insurance),
          )),
        ],
      ),
    );
  }
  
  Widget _buildInsuranceCard(InsuranceData insurance) {
    IconData getInsuranceIcon(String type) {
      switch (type.toLowerCase()) {
        case 'life': return Icons.favorite;
        case 'health': return Icons.local_hospital;
        case 'motor': case 'car': return Icons.directions_car;
        case 'home': return Icons.home;
        case 'travel': return Icons.flight;
        case 'term': return Icons.security;
        default: return Icons.shield;
      }
    }
    
    Color getInsuranceColor(String type) {
      switch (type.toLowerCase()) {
        case 'life': return Colors.red;
        case 'health': return Colors.green;
        case 'motor': case 'car': return Colors.blue;
        case 'home': return Colors.orange;
        case 'travel': return Colors.purple;
        case 'term': return Colors.teal;
        default: return Colors.grey;
      }
    }
    
    final daysUntilExpiry = insurance.expiryDate != null 
        ? insurance.expiryDate!.difference(DateTime.now()).inDays 
        : 365; // Default to not expiring soon
    final isExpiringSoon = daysUntilExpiry <= 30 && daysUntilExpiry > 0;
    final isExpired = daysUntilExpiry <= 0;
    
    return FPCard(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Viewing ${insurance.providerName} policy...')),
        );
      },
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(ESUNSpacing.sm),
            decoration: BoxDecoration(
              color: getInsuranceColor(insurance.type).withOpacity(0.1),
              borderRadius: ESUNRadius.smRadius,
            ),
            child: insurance.effectiveLogoUrl != null
                ? ClipRRect(
                    borderRadius: ESUNRadius.xsRadius,
                    child: SmartNetworkImage(
                      imageUrl: insurance.effectiveLogoUrl!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      placeholderIcon: getInsuranceIcon(insurance.type),
                      placeholderColor: getInsuranceColor(insurance.type),
                      errorBuilder: (_, __, ___) => Icon(
                        getInsuranceIcon(insurance.type),
                        color: getInsuranceColor(insurance.type),
                        size: 24,
                      ),
                    ),
                  )
                : Icon(
                    getInsuranceIcon(insurance.type),
                    color: getInsuranceColor(insurance.type),
                    size: 24,
                  ),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${insurance.type} Insurance',
                      style: ESUNTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isExpiringSoon || isExpired)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: ESUNSpacing.tagInsets,
                        decoration: BoxDecoration(
                          color: isExpired ? ESUNColors.error : Colors.orange,
                          borderRadius: ESUNRadius.fullRadius,
                        ),
                        child: Text(
                          isExpired ? 'EXPIRED' : 'EXPIRING SOON',
                          style: ESUNTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  insurance.providerName,
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
                CurrencyFormatter.format(insurance.sumAssured),
                style: ESUNTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Cover',
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

  // Lending Products Section
  Widget _buildLendingProducts(BuildContext context) {
    final products = [
      _LendingProduct(
        'Personal Loan',
        'Up to ₹40 Lakh',
        'From 10.5% p.a.',
        Icons.person,
        Colors.blue,
        'Instant approval',
      ),
      _LendingProduct(
        'Home Loan',
        'Up to ₹5 Crore',
        'From 8.5% p.a.',
        Icons.home,
        Colors.green,
        'Lowest EMI',
      ),
      _LendingProduct(
        'Car Loan',
        'Up to ₹1 Crore',
        'From 9.0% p.a.',
        Icons.directions_car,
        Colors.purple,
        '100% financing',
      ),
      _LendingProduct(
        'Education Loan',
        'Up to ₹75 Lakh',
        'From 8.0% p.a.',
        Icons.school,
        Colors.orange,
        'No collateral',
      ),
      _LendingProduct(
        'Business Loan',
        'Up to ₹50 Lakh',
        'From 12% p.a.',
        Icons.business,
        Colors.teal,
        'Quick disbursal',
      ),
      _LendingProduct(
        'Gold Loan',
        'Up to ₹2 Crore',
        'From 7.5% p.a.',
        Icons.workspace_premium,
        Colors.amber,
        'Lowest rates',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg, vertical: ESUNSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance, color: Colors.blue, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Lending Products',
                    style: ESUNTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.sm),
          SizedBox(
            height: 170,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildLendingCard(product);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLendingCard(_LendingProduct product) {
    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.borrow);
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: ESUNSpacing.md),
        padding: const EdgeInsets.all(ESUNSpacing.md),
        decoration: BoxDecoration(
          color: product.color.withOpacity(0.05),
          borderRadius: ESUNRadius.lgRadius,
          border: Border.all(color: product.color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(ESUNSpacing.md),
              decoration: BoxDecoration(
                color: product.color.withOpacity(0.1),
                borderRadius: ESUNRadius.smRadius,
              ),
              child: Icon(product.icon, color: product.color, size: 24),
            ),
            const SizedBox(height: ESUNSpacing.sm),
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
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product.rate,
                  style: ESUNTypography.labelSmall.copyWith(
                    color: product.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: ESUNSpacing.tagInsets,
              decoration: BoxDecoration(
                color: ESUNColors.success.withOpacity(0.1),
                borderRadius: ESUNRadius.fullRadius,
              ),
              child: Text(
                product.badge,
                style: ESUNTypography.labelSmall.copyWith(
                  color: ESUNColors.success,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Education Products Section
  Widget _buildEducationProducts(BuildContext context) {
    final courses = [
      _EducationItem(
        'Stock Market Basics',
        'Learn investing fundamentals',
        '2.5 hours',
        'Beginner',
        4.8,
        1250,
        Colors.blue,
        'FREE',
      ),
      _EducationItem(
        'Mutual Funds Masterclass',
        'Build wealth with SIPs',
        '4 hours',
        'Intermediate',
        4.9,
        3420,
        Colors.purple,
        '₹299',
      ),
      _EducationItem(
        'Tax Planning Guide',
        'Save more, legally',
        '3 hours',
        'All Levels',
        4.7,
        2180,
        Colors.green,
        'FREE',
      ),
      _EducationItem(
        'Personal Finance 101',
        'Master your money',
        '5 hours',
        'Beginner',
        4.9,
        5630,
        Colors.orange,
        '₹199',
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
                  const Icon(Icons.school, color: Colors.orange, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Learn & Grow',
                    style: ESUNTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          ...courses.map((course) => _buildEducationCard(course)),
        ],
      ),
    );
  }

  Widget _buildEducationCard(_EducationItem course) {
    return GestureDetector(
      onTap: () => _showProductDetail(course.title, 'Learn about ${course.title.toLowerCase()} with expert content.', Colors.indigo, Icons.school),
      child: Container(
        margin: const EdgeInsets.only(bottom: ESUNSpacing.md),
        padding: const EdgeInsets.all(ESUNSpacing.md),
        decoration: BoxDecoration(
          color: ESUNColors.surface,
          borderRadius: ESUNRadius.lgRadius,
          border: Border.all(color: ESUNColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: course.color.withOpacity(0.1),
                borderRadius: ESUNRadius.mdRadius,
              ),
              child: Icon(Icons.play_circle_fill, color: course.color, size: 32),
            ),
            const SizedBox(width: ESUNSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: ESUNTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    course.subtitle,
                    style: ESUNTypography.bodySmall.copyWith(
                      color: ESUNColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: ESUNColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        course.duration,
                        style: ESUNTypography.labelSmall.copyWith(
                          color: ESUNColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: ESUNSpacing.tagInsets,
                        decoration: BoxDecoration(
                          color: course.color.withOpacity(0.1),
                          borderRadius: ESUNRadius.fullRadius,
                        ),
                        child: Text(
                          course.level,
                          style: ESUNTypography.labelSmall.copyWith(
                            color: course.color,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        '${course.rating}',
                        style: ESUNTypography.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  course.price,
                  style: ESUNTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: course.price == 'FREE' ? ESUNColors.success : ESUNColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${course.enrolled}+ enrolled',
                  style: ESUNTypography.labelSmall.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeaturedBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg, vertical: ESUNSpacing.md),
      child: Container(
        height: 180,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E4A9A), Color(0xFF1C2961)],
          ),
          borderRadius: ESUNRadius.lgRadius,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.card_giftcard,
                size: 150,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: ESUNSpacing.badgeInsets,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: ESUNRadius.fullRadius,
                    ),
                    child: Text(
                      'LIMITED TIME',
                      style: ESUNTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Get ₹500 Cashback',
                    style: ESUNTypography.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'On your first investment of ₹5,000 or more',
                    style: ESUNTypography.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: ESUNSpacing.md),
                  ElevatedButton(
                    onPressed: () => context.go(AppRoutes.invest),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2E4A9A),
                      padding: ESUNSpacing.buttonInsets,
                    ),
                    child: const Text('Invest Now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategories(BuildContext context) {
    final categories = [
      _DiscoverCategory(Icons.credit_card, 'Cards', Colors.blue),
      _DiscoverCategory(Icons.account_balance, 'Loans', Colors.green),
      _DiscoverCategory(Icons.shield, 'Insurance', Colors.orange),
      _DiscoverCategory(Icons.workspace_premium, 'Gold', Colors.amber),
      _DiscoverCategory(Icons.account_balance_wallet, 'FD/RD', Colors.purple),
      _DiscoverCategory(Icons.currency_bitcoin, 'Crypto', Colors.indigo),
      _DiscoverCategory(Icons.home_work, 'Real Estate', Colors.teal),
      _DiscoverCategory(Icons.more_horiz, 'More', Colors.grey),
    ];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg, vertical: ESUNSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: categories.sublist(0, 4).map((cat) {
              return Expanded(child: _buildCategoryItem(cat));
            }).toList(),
          ),
          Row(
            children: categories.sublist(4).map((cat) {
              return Expanded(child: _buildCategoryItem(cat));
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryItem(_DiscoverCategory category) {
    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.discoverCategoryPath(category.label.toLowerCase()));
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(category.icon, color: category.color, size: 24),
          ),
          const SizedBox(height: ESUNSpacing.xs),
          Text(
            category.label,
            style: ESUNTypography.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildFinancialTools(BuildContext context) {
    final tools = [
      _ToolItem('EMI Calculator', Icons.calculate, 'Plan your loans', Colors.blue),
      _ToolItem('Tax Planner', Icons.receipt_long, 'Save on taxes', Colors.green),
      _ToolItem('Net Worth', Icons.account_balance_wallet, 'Track wealth', Colors.purple),
      _ToolItem('SIP Calculator', Icons.trending_up, 'Plan investments', Colors.orange),
    ];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg, vertical: ESUNSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Tools',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.0,
              crossAxisSpacing: ESUNSpacing.md,
              mainAxisSpacing: ESUNSpacing.md,
            ),
            itemCount: tools.length,
            itemBuilder: (context, index) {
              final tool = tools[index];
              return _buildToolCard(tool, index);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildToolCard(_ToolItem tool, int index) {
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0:
            _showEMICalculator();
            break;
          case 1:
            _showTaxPlanner();
            break;
          case 2:
            _showNetWorth();
            break;
          case 3:
            _showSIPCalculator();
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.all(ESUNSpacing.md),
        decoration: BoxDecoration(
          color: tool.color.withOpacity(0.05),
          borderRadius: ESUNRadius.lgRadius,
          border: Border.all(color: tool.color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tool.icon, color: tool.color, size: 28),
            const SizedBox(height: ESUNSpacing.sm),
            Text(
              tool.name,
              style: ESUNTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              tool.description,
              style: ESUNTypography.labelSmall.copyWith(
                color: ESUNColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // EMI Calculator
  void _showEMICalculator() {
    double loanAmount = 1000000;
    double interestRate = 8.5;
    double tenure = 20;
    double emi = 0;
    double totalInterest = 0;
    double totalPayment = 0;
    
    void calculateEMI(StateSetter setStateSheet) {
      double r = interestRate / 12 / 100;
      double n = tenure * 12;
      emi = (loanAmount * r * (1 + r).toDouble()) / ((1 + r).toDouble() - 1);
      // Fix for power calculation
      double powerResult = 1;
      for (int i = 0; i < n; i++) {
        powerResult *= (1 + r);
      }
      emi = (loanAmount * r * powerResult) / (powerResult - 1);
      totalPayment = emi * n;
      totalInterest = totalPayment - loanAmount;
      setStateSheet(() {});
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) {
          // Initial calculation
          if (emi == 0) calculateEMI(setStateSheet);
          
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              child: Padding(
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
                          padding: const EdgeInsets.all(ESUNSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.calculate, color: Colors.blue),
                        ),
                        const SizedBox(width: ESUNSpacing.md),
                        Text('EMI Calculator', style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: ESUNSpacing.xl),
                    
                    // Loan Amount
                    Text('Loan Amount', style: ESUNTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: ESUNSpacing.sm),
                    Row(
                      children: [
                        Text('₹${(loanAmount / 100000).toStringAsFixed(1)}L', style: ESUNTypography.titleMedium.copyWith(color: Colors.blue)),
                        const Spacer(),
                        Text('₹50L', style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textTertiary)),
                      ],
                    ),
                    Slider(
                      value: loanAmount,
                      min: 100000,
                      max: 5000000,
                      divisions: 49,
                      activeColor: Colors.blue,
                      onChanged: (val) {
                        loanAmount = val;
                        calculateEMI(setStateSheet);
                      },
                    ),
                    const SizedBox(height: ESUNSpacing.md),
                    
                    // Interest Rate
                    Text('Interest Rate (p.a.)', style: ESUNTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: ESUNSpacing.sm),
                    Row(
                      children: [
                        Text('${interestRate.toStringAsFixed(1)}%', style: ESUNTypography.titleMedium.copyWith(color: Colors.blue)),
                        const Spacer(),
                        Text('20%', style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textTertiary)),
                      ],
                    ),
                    Slider(
                      value: interestRate,
                      min: 5,
                      max: 20,
                      divisions: 30,
                      activeColor: Colors.blue,
                      onChanged: (val) {
                        interestRate = val;
                        calculateEMI(setStateSheet);
                      },
                    ),
                    const SizedBox(height: ESUNSpacing.md),
                    
                    // Tenure
                    Text('Loan Tenure (Years)', style: ESUNTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: ESUNSpacing.sm),
                    Row(
                      children: [
                        Text('${tenure.toInt()} Years', style: ESUNTypography.titleMedium.copyWith(color: Colors.blue)),
                        const Spacer(),
                        Text('30 Years', style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textTertiary)),
                      ],
                    ),
                    Slider(
                      value: tenure,
                      min: 1,
                      max: 30,
                      divisions: 29,
                      activeColor: Colors.blue,
                      onChanged: (val) {
                        tenure = val;
                        calculateEMI(setStateSheet);
                      },
                    ),
                    const SizedBox(height: ESUNSpacing.xl),
                    
                    // Results
                    Container(
                      padding: const EdgeInsets.all(ESUNSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Monthly EMI'),
                              Text('₹${emi.toStringAsFixed(0)}', style: ESUNTypography.titleLarge.copyWith(color: Colors.blue, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Principal'),
                              Text('₹${(loanAmount / 100000).toStringAsFixed(2)}L', style: ESUNTypography.bodyLarge),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Interest'),
                              Text('₹${(totalInterest / 100000).toStringAsFixed(2)}L', style: ESUNTypography.bodyLarge.copyWith(color: Colors.orange)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Amount'),
                              Text('₹${(totalPayment / 100000).toStringAsFixed(2)}L', style: ESUNTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: ESUNSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Apply for loan with this EMI')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                        ),
                        child: const Text('Apply for Loan', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Tax Planner
  void _showTaxPlanner() {
    double income = 1200000;
    double section80C = 150000;
    double section80D = 25000;
    double hra = 200000;
    double otherDeductions = 50000;
    
    double taxableIncome = 0;
    double taxOldRegime = 0;
    double taxNewRegime = 0;
    
    void calculateTax(StateSetter setStateSheet) {
      double totalDeductions = section80C + section80D + hra + otherDeductions;
      taxableIncome = income - totalDeductions;
      if (taxableIncome < 0) taxableIncome = 0;
      
      // Old regime (with deductions)
      if (taxableIncome <= 250000) {
        taxOldRegime = 0;
      } else if (taxableIncome <= 500000) {
        taxOldRegime = (taxableIncome - 250000) * 0.05;
      } else if (taxableIncome <= 1000000) {
        taxOldRegime = 12500 + (taxableIncome - 500000) * 0.20;
      } else {
        taxOldRegime = 12500 + 100000 + (taxableIncome - 1000000) * 0.30;
      }
      
      // New regime (without deductions, on gross income)
      double newTaxableIncome = income;
      if (newTaxableIncome <= 300000) {
        taxNewRegime = 0;
      } else if (newTaxableIncome <= 600000) {
        taxNewRegime = (newTaxableIncome - 300000) * 0.05;
      } else if (newTaxableIncome <= 900000) {
        taxNewRegime = 15000 + (newTaxableIncome - 600000) * 0.10;
      } else if (newTaxableIncome <= 1200000) {
        taxNewRegime = 45000 + (newTaxableIncome - 900000) * 0.15;
      } else if (newTaxableIncome <= 1500000) {
        taxNewRegime = 90000 + (newTaxableIncome - 1200000) * 0.20;
      } else {
        taxNewRegime = 150000 + (newTaxableIncome - 1500000) * 0.30;
      }
      
      setStateSheet(() {});
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) {
          if (taxableIncome == 0) calculateTax(setStateSheet);
          
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              child: Padding(
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
                          padding: const EdgeInsets.all(ESUNSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.receipt_long, color: Colors.green),
                        ),
                        const SizedBox(width: ESUNSpacing.md),
                        Text('Tax Planner', style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: ESUNSpacing.md),
                    Text('FY 2024-25', style: ESUNTypography.labelMedium.copyWith(color: ESUNColors.textSecondary)),
                    const SizedBox(height: ESUNSpacing.xl),
                    
                    // Annual Income
                    Text('Annual Income', style: ESUNTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        Text('₹${(income / 100000).toStringAsFixed(1)}L', style: ESUNTypography.titleMedium.copyWith(color: Colors.green)),
                        const Spacer(),
                        Text('₹50L', style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textTertiary)),
                      ],
                    ),
                    Slider(
                      value: income,
                      min: 300000,
                      max: 5000000,
                      divisions: 47,
                      activeColor: Colors.green,
                      onChanged: (val) {
                        income = val;
                        calculateTax(setStateSheet);
                      },
                    ),
                    
                    // Section 80C
                    Text('Section 80C (PPF, ELSS, LIC)', style: ESUNTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        Text('₹${(section80C / 1000).toStringAsFixed(0)}K', style: ESUNTypography.titleMedium.copyWith(color: Colors.green)),
                        const Spacer(),
                        Text('Max ₹1.5L', style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textTertiary)),
                      ],
                    ),
                    Slider(
                      value: section80C,
                      min: 0,
                      max: 150000,
                      divisions: 15,
                      activeColor: Colors.green,
                      onChanged: (val) {
                        section80C = val;
                        calculateTax(setStateSheet);
                      },
                    ),
                    
                    // Section 80D
                    Text('Section 80D (Health Insurance)', style: ESUNTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        Text('₹${(section80D / 1000).toStringAsFixed(0)}K', style: ESUNTypography.titleMedium.copyWith(color: Colors.green)),
                        const Spacer(),
                        Text('Max ₹50K', style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textTertiary)),
                      ],
                    ),
                    Slider(
                      value: section80D,
                      min: 0,
                      max: 50000,
                      divisions: 10,
                      activeColor: Colors.green,
                      onChanged: (val) {
                        section80D = val;
                        calculateTax(setStateSheet);
                      },
                    ),
                    const SizedBox(height: ESUNSpacing.lg),
                    
                    // Results
                    Container(
                      padding: const EdgeInsets.all(ESUNSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Text('Regime Comparison', style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: ESUNSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(ESUNSpacing.md),
                                  decoration: BoxDecoration(
                                    color: taxOldRegime <= taxNewRegime ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: taxOldRegime <= taxNewRegime ? Border.all(color: Colors.green) : null,
                                  ),
                                  child: Column(
                                    children: [
                                      const Text('Old Regime'),
                                      const SizedBox(height: 4),
                                      Text('₹${(taxOldRegime / 1000).toStringAsFixed(0)}K', style: ESUNTypography.titleMedium.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                                      if (taxOldRegime <= taxNewRegime) const Text('Recommended', style: TextStyle(color: Colors.green, fontSize: 10)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(ESUNSpacing.md),
                                  decoration: BoxDecoration(
                                    color: taxNewRegime < taxOldRegime ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: taxNewRegime < taxOldRegime ? Border.all(color: Colors.green) : null,
                                  ),
                                  child: Column(
                                    children: [
                                      const Text('New Regime'),
                                      const SizedBox(height: 4),
                                      Text('₹${(taxNewRegime / 1000).toStringAsFixed(0)}K', style: ESUNTypography.titleMedium.copyWith(color: Colors.blue, fontWeight: FontWeight.bold)),
                                      if (taxNewRegime < taxOldRegime) const Text('Recommended', style: TextStyle(color: Colors.green, fontSize: 10)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: ESUNSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Potential Savings'),
                              Text('₹${((taxOldRegime - taxNewRegime).abs() / 1000).toStringAsFixed(0)}K', style: ESUNTypography.bodyLarge.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Net Worth Tracker
  void _showNetWorth() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
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
                      padding: const EdgeInsets.all(ESUNSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: Colors.purple),
                    ),
                    const SizedBox(width: ESUNSpacing.md),
                    Text('Net Worth', style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: ESUNSpacing.xl),
                
                // Net Worth Summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(ESUNSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E4A9A), Color(0xFF1C2961)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('Total Net Worth', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text('₹28,45,000', style: ESUNTypography.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: ESUNSpacing.badgeInsets,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('+12.5% this year', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ESUNSpacing.xl),
                
                // Assets
                Text('Assets', style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: ESUNSpacing.md),
                _buildNetWorthItem('Bank Accounts', '₹4,25,000', Colors.blue, Icons.account_balance),
                _buildNetWorthItem('Mutual Funds', '₹12,80,000', Colors.green, Icons.trending_up),
                _buildNetWorthItem('Stocks', '₹6,50,000', Colors.orange, Icons.show_chart),
                _buildNetWorthItem('Fixed Deposits', '₹3,00,000', Colors.teal, Icons.lock),
                _buildNetWorthItem('Gold', '₹2,50,000', Colors.amber, Icons.workspace_premium),
                _buildNetWorthItem('Real Estate', '₹0', Colors.brown, Icons.home),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Assets', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('₹29,05,000', style: ESUNTypography.titleMedium.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: ESUNSpacing.xl),
                
                // Liabilities
                Text('Liabilities', style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: ESUNSpacing.md),
                _buildNetWorthItem('Home Loan', '₹0', Colors.red, Icons.home_work),
                _buildNetWorthItem('Car Loan', '₹45,000', Colors.red, Icons.directions_car),
                _buildNetWorthItem('Credit Card', '₹15,000', Colors.red, Icons.credit_card),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Liabilities', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('₹60,000', style: ESUNTypography.titleMedium.copyWith(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNetWorthItem(String title, String value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(child: Text(title)),
          Text(value, style: ESUNTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
  
  // SIP Calculator
  void _showSIPCalculator() {
    double monthlyInvestment = 10000;
    double expectedReturn = 12;
    double timePeriod = 10;
    double futureValue = 0;
    double totalInvested = 0;
    double wealthGained = 0;
    
    void calculateSIP(StateSetter setStateSheet) {
      int n = (timePeriod * 12).toInt();
      double r = expectedReturn / 100 / 12;
      
      // FV = P × ((1 + r)^n – 1) / r × (1 + r)
      double powerResult = 1;
      for (int i = 0; i < n; i++) {
        powerResult *= (1 + r);
      }
      futureValue = monthlyInvestment * ((powerResult - 1) / r) * (1 + r);
      totalInvested = monthlyInvestment * n;
      wealthGained = futureValue - totalInvested;
      
      setStateSheet(() {});
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) {
          if (futureValue == 0) calculateSIP(setStateSheet);
          
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              child: Padding(
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
                          padding: const EdgeInsets.all(ESUNSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.trending_up, color: Colors.orange),
                        ),
                        const SizedBox(width: ESUNSpacing.md),
                        Text('SIP Calculator', style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: ESUNSpacing.xl),
                    
                    // Monthly Investment
                    Text('Monthly Investment', style: ESUNTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: ESUNSpacing.sm),
                    Row(
                      children: [
                        Text('₹${(monthlyInvestment / 1000).toStringAsFixed(0)}K', style: ESUNTypography.titleMedium.copyWith(color: Colors.orange)),
                        const Spacer(),
                        Text('₹1L', style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textTertiary)),
                      ],
                    ),
                    Slider(
                      value: monthlyInvestment,
                      min: 500,
                      max: 100000,
                      divisions: 199,
                      activeColor: Colors.orange,
                      onChanged: (val) {
                        monthlyInvestment = val;
                        calculateSIP(setStateSheet);
                      },
                    ),
                    const SizedBox(height: ESUNSpacing.md),
                    
                    // Expected Return
                    Text('Expected Return (p.a.)', style: ESUNTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: ESUNSpacing.sm),
                    Row(
                      children: [
                        Text('${expectedReturn.toStringAsFixed(0)}%', style: ESUNTypography.titleMedium.copyWith(color: Colors.orange)),
                        const Spacer(),
                        Text('30%', style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textTertiary)),
                      ],
                    ),
                    Slider(
                      value: expectedReturn,
                      min: 1,
                      max: 30,
                      divisions: 29,
                      activeColor: Colors.orange,
                      onChanged: (val) {
                        expectedReturn = val;
                        calculateSIP(setStateSheet);
                      },
                    ),
                    const SizedBox(height: ESUNSpacing.md),
                    
                    // Time Period
                    Text('Time Period (Years)', style: ESUNTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: ESUNSpacing.sm),
                    Row(
                      children: [
                        Text('${timePeriod.toInt()} Years', style: ESUNTypography.titleMedium.copyWith(color: Colors.orange)),
                        const Spacer(),
                        Text('30 Years', style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textTertiary)),
                      ],
                    ),
                    Slider(
                      value: timePeriod,
                      min: 1,
                      max: 30,
                      divisions: 29,
                      activeColor: Colors.orange,
                      onChanged: (val) {
                        timePeriod = val;
                        calculateSIP(setStateSheet);
                      },
                    ),
                    const SizedBox(height: ESUNSpacing.xl),
                    
                    // Results
                    Container(
                      padding: const EdgeInsets.all(ESUNSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Future Value'),
                              Text('₹${(futureValue / 100000).toStringAsFixed(2)}L', style: ESUNTypography.titleLarge.copyWith(color: Colors.orange, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Invested'),
                              Text('₹${(totalInvested / 100000).toStringAsFixed(2)}L', style: ESUNTypography.bodyLarge),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Wealth Gained'),
                              Text('₹${(wealthGained / 100000).toStringAsFixed(2)}L', style: ESUNTypography.bodyLarge.copyWith(color: Colors.green, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: ESUNSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Start SIP with these settings')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                        ),
                        child: const Text('Start SIP', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildOffers(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg, vertical: ESUNSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exclusive Offers',
                style: ESUNTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.sm),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildOfferCard(
                  'Credit Card',
                  '5% cashback on all spends',
                  Colors.blue,
                  Icons.credit_card,
                ),
                _buildOfferCard(
                  'Personal Loan',
                  'Rates from 10.5% p.a.',
                  Colors.green,
                  Icons.account_balance,
                ),
                _buildOfferCard(
                  'Premium Account',
                  'Zero balance + Free lounge',
                  Colors.purple,
                  Icons.star,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOfferCard(String title, String subtitle, Color color, IconData icon) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: ESUNSpacing.md),
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: ESUNRadius.lgRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const Spacer(),
              Container(
                padding: ESUNSpacing.badgeInsets,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: ESUNRadius.fullRadius,
                ),
                child: Text(
                  'NEW',
                  style: ESUNTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: ESUNTypography.titleSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: ESUNTypography.labelSmall.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLearnSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learn & Earn',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          _buildLearnCard(
            'Investing 101',
            'Learn the basics of investing and earn ₹50',
            '5 min • 3 modules',
            Colors.blue,
            0.7,
          ),
          const SizedBox(height: ESUNSpacing.sm),
          _buildLearnCard(
            'Budgeting Basics',
            'Master your money with simple budgeting tips',
            '3 min • 2 modules',
            Colors.green,
            0.4,
          ),
        ],
      ),
    );
  }
  
  Widget _buildLearnCard(
    String title,
    String description,
    String duration,
    Color color,
    double progress,
  ) {
    return FPCard(
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(ESUNSpacing.md),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: ESUNRadius.smRadius,
                ),
                child: Icon(Icons.school, color: color),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ESUNTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      duration,
                      style: ESUNTypography.labelSmall.copyWith(
                        color: ESUNColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: ESUNSpacing.chipInsets,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: ESUNRadius.fullRadius,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '₹50',
                      style: ESUNTypography.labelMedium.copyWith(
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          Text(
            description,
            style: ESUNTypography.bodySmall.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: ESUNRadius.fullRadius,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Text(
                '${(progress * 100).toInt()}%',
                style: ESUNTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildRewards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: FPGradientCard(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'ESUN Rewards',
                        style: ESUNTypography.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ESUNSpacing.sm),
                  Text(
                    '2,450 Points',
                    style: ESUNTypography.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Worth ₹245 • Redeem now',
                    style: ESUNTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(ESUNSpacing.md),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: ESUNRadius.mdRadius,
              ),
              child: const Icon(Icons.redeem, color: Color(0xFFF59E0B)),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProduct(String name) {
    switch (name) {
      case 'Mutual Funds':
        context.push(AppRoutes.mutualFunds);
      case 'Stocks & ETFs':
        context.push(AppRoutes.stocks);
      case 'Fixed Deposits':
        context.push(AppRoutes.discoverCategoryPath('fd/rd'));
      case 'Digital Gold':
        context.push(AppRoutes.digitalGold);
      case 'Bonds':
        context.push(AppRoutes.discoverCategoryPath('more'));
      case 'NPS':
        context.push(AppRoutes.discoverCategoryPath('more'));
      default:
        context.push(AppRoutes.invest);
    }
  }
  
  void _showProductDetail(String title, String description, Color color, IconData icon) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(ESUNSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(ESUNSpacing.md),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: ESUNRadius.mdRadius,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: ESUNSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ESUNSpacing.lg),
            Text(
              description,
              style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary),
            ),
            const SizedBox(height: ESUNSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: ESUNSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      // Navigate to invest screen for investment products
                      context.push(AppRoutes.invest);
                    },
                    child: const Text('Explore'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverCategory {
  final IconData icon;
  final String label;
  final Color color;
  
  _DiscoverCategory(this.icon, this.label, this.color);
}

class _ToolItem {
  final String name;
  final IconData icon;
  final String description;
  final Color color;
  
  _ToolItem(this.name, this.icon, this.description, this.color);
}

class _ProductItem {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String highlight;
  final bool isPopular;

  _ProductItem(this.name, this.subtitle, this.icon, this.color, this.highlight, this.isPopular);
}

class _LendingProduct {
  final String name;
  final String maxAmount;
  final String rate;
  final IconData icon;
  final Color color;
  final String badge;

  _LendingProduct(this.name, this.maxAmount, this.rate, this.icon, this.color, this.badge);
}

class _EducationItem {
  final String title;
  final String subtitle;
  final String duration;
  final String level;
  final double rating;
  final int enrolled;
  final Color color;
  final String price;

  _EducationItem(this.title, this.subtitle, this.duration, this.level, this.rating, this.enrolled, this.color, this.price);
}



