/// ESUN Data Connections Screen
///
/// Manage Account Aggregator and Credit Bureau connections.
/// Shows connection status and provides actions to link/re-link/disconnect.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/widgets.dart';
import '../../state/app_state.dart';
import '../../core/network/api_service.dart';
import '../../core/analytics/analytics_service.dart';
import '../../services/aggregator_service.dart';

/// Connection status enum
enum ConnectionStatus {
  notLinked,
  pending,
  linked,
  error,
}

/// Data connection info
class DataConnection {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final ConnectionStatus status;
  final DateTime? lastSyncAt;
  final String? provider;
  final String? errorMessage;

  const DataConnection({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.status,
    this.lastSyncAt,
    this.provider,
    this.errorMessage,
  });
}

/// Provider for data connections status
final dataConnectionsProvider = FutureProvider<List<DataConnection>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final result = await api.get<Map<String, dynamic>>(
    '${ApiConfig.apiPrefix}/users/me/data-linking',
  );

  if (result.isError || result.data == null) {
    // Return default state from auth state
    final authState = ref.read(authStateProvider);
    return [
      DataConnection(
        id: 'aa',
        name: 'Account Aggregator',
        description: 'Connect your bank accounts securely via RBI-regulated AA framework',
        icon: Icons.account_balance_outlined,
        status: authState.aaConnected ? ConnectionStatus.linked : ConnectionStatus.notLinked,
      ),
      DataConnection(
        id: 'credit_bureau',
        name: 'Credit Bureau',
        description: 'Get your credit score and detailed credit report',
        icon: Icons.credit_score_outlined,
        status: authState.creditBureauConnected ? ConnectionStatus.linked : ConnectionStatus.notLinked,
      ),
    ];
  }

  final data = result.data!['data'] as Map<String, dynamic>? ?? {};
  
  return [
    DataConnection(
      id: 'aa',
      name: 'Account Aggregator',
      description: 'Connect your bank accounts securely via RBI-regulated AA framework',
      icon: Icons.account_balance_outlined,
      status: _parseStatus(data['aa_connected'], data['aa_consent_status']),
      provider: 'Setu AA',
    ),
    DataConnection(
      id: 'credit_bureau',
      name: 'Credit Bureau',
      description: 'Get your credit score and detailed credit report',
      icon: Icons.credit_score_outlined,
      status: data['credit_bureau_connected'] == true 
          ? ConnectionStatus.linked 
          : ConnectionStatus.notLinked,
      provider: data['credit_bureau_provider'] as String?,
    ),
  ];
});

ConnectionStatus _parseStatus(dynamic connected, dynamic consentStatus) {
  if (connected == true) return ConnectionStatus.linked;
  if (consentStatus == 'pending') return ConnectionStatus.pending;
  if (consentStatus == 'error' || consentStatus == 'rejected') return ConnectionStatus.error;
  return ConnectionStatus.notLinked;
}

class DataConnectionsScreen extends ConsumerStatefulWidget {
  const DataConnectionsScreen({super.key});

  @override
  ConsumerState<DataConnectionsScreen> createState() => _DataConnectionsScreenState();
}

class _DataConnectionsScreenState extends ConsumerState<DataConnectionsScreen> {
  bool _notificationsEnabled = true;
  bool _remindersEnabled = true;

  @override
  void initState() {
    super.initState();
    // Load aggregator data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aggregatorStateProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectionsAsync = ref.watch(dataConnectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Connections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: connectionsAsync.when(
        data: (connections) => _buildContent(connections),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildErrorState(e.toString()),
      ),
    );
  }

  Widget _buildContent(List<DataConnection> connections) {
    return ListView(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      children: [
        // Info Card
        _buildInfoCard(),
        const SizedBox(height: ESUNSpacing.lg),

        // Connections Section
        _buildSectionHeader('Your Connections'),
        const SizedBox(height: ESUNSpacing.sm),
        ...connections.map((conn) => _buildConnectionCard(conn)),
        const SizedBox(height: ESUNSpacing.lg),

        // Linked Accounts Section (from Aggregator)
        _buildSectionHeader('Linked Accounts'),
        const SizedBox(height: ESUNSpacing.sm),
        _buildLinkedAccountsSection(),
        const SizedBox(height: ESUNSpacing.lg),

        // Reminders Section
        _buildSectionHeader('Notifications & Reminders'),
        const SizedBox(height: ESUNSpacing.sm),
        _buildRemindersCard(),
        const SizedBox(height: ESUNSpacing.lg),

        // Regulatory Protection Footer
        _buildRegulatoryFooter(),
        const SizedBox(height: ESUNSpacing.md),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ESUNColors.primary.withOpacity(0.1),
            ESUNColors.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: ESUNRadius.lgRadius,
        border: Border.all(color: ESUNColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.md),
            decoration: BoxDecoration(
              color: ESUNColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.security_outlined,
              color: ESUNColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure & Private',
                  style: ESUNTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your data is encrypted and you control access. Disconnect anytime.',
                  style: ESUNTypography.bodySmall.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: ESUNTypography.titleSmall.copyWith(
        color: ESUNColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildLinkedAccountsSection() {
    final aggregatorState = ref.watch(aggregatorStateProvider);
    
    if (aggregatorState.isLoading) {
      return const FPCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(ESUNSpacing.xl),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (aggregatorState.accounts.isEmpty) {
      return FPCard(
        child: Padding(
          padding: const EdgeInsets.all(ESUNSpacing.lg),
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: ESUNColors.textTertiary.withOpacity(0.5),
              ),
              const SizedBox(height: ESUNSpacing.md),
              Text(
                'No Linked Accounts',
                style: ESUNTypography.titleSmall.copyWith(
                  color: ESUNColors.textSecondary,
                ),
              ),
              const SizedBox(height: ESUNSpacing.sm),
              Text(
                'Link your bank accounts via Account Aggregator to see them here.',
                style: ESUNTypography.bodySmall.copyWith(
                  color: ESUNColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ESUNSpacing.lg),
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.aaVerifyPan),
                icon: const Icon(Icons.add),
                label: const Text('Link Accounts'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Summary Card
        FPCard(
          child: Padding(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${aggregatorState.accounts.length} Account${aggregatorState.accounts.length > 1 ? 's' : ''} Linked',
                      style: ESUNTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sync, size: 20),
                      onPressed: _handleSyncData,
                      tooltip: 'Sync Data',
                    ),
                  ],
                ),
                const SizedBox(height: ESUNSpacing.md),
                // List linked accounts
                ...aggregatorState.accounts.map((account) => _buildLinkedAccountTile(account)),
              ],
            ),
          ),
        ),
        // Financial Summary (if available)
        if (aggregatorState.summary != null) ...[
          const SizedBox(height: ESUNSpacing.md),
          _buildFinancialSummaryCard(aggregatorState.summary!),
        ],
      ],
    );
  }

  Widget _buildLinkedAccountTile(LinkedAccount account) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.sm),
            decoration: BoxDecoration(
              color: ESUNColors.primary.withOpacity(0.1),
              borderRadius: ESUNRadius.smRadius,
            ),
            child: Icon(
              _getAccountTypeIcon(account.accountType),
              color: ESUNColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.bankName ?? account.fipId,
                  style: ESUNTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (account.maskedNumber != null)
                  Text(
                    account.maskedNumber!,
                    style: ESUNTypography.labelSmall.copyWith(
                      color: ESUNColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: ESUNSpacing.badgeInsets,
            decoration: BoxDecoration(
              color: account.isActive 
                  ? ESUNColors.success.withOpacity(0.1)
                  : ESUNColors.textTertiary.withOpacity(0.1),
              borderRadius: ESUNRadius.fullRadius,
            ),
            child: Text(
              account.isActive ? 'Active' : 'Inactive',
              style: ESUNTypography.labelSmall.copyWith(
                color: account.isActive ? ESUNColors.success : ESUNColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryCard(FinancialSummary summary) {
    return FPCard(
      child: Padding(
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Summary',
              style: ESUNTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: ESUNSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Balance',
                    _formatCurrency(summary.totalBalance),
                    ESUNColors.primary,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Net Worth',
                    _formatCurrency(summary.netWorth),
                    ESUNColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ESUNSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Monthly Income',
                    _formatCurrency(summary.monthlyIncome),
                    ESUNColors.info,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Monthly Expenses',
                    _formatCurrency(summary.monthlyExpenses),
                    ESUNColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ESUNTypography.labelSmall.copyWith(
            color: ESUNColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: ESUNTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  IconData _getAccountTypeIcon(String accountType) {
    switch (accountType.toLowerCase()) {
      case 'savings':
      case 'savings_account':
        return Icons.savings_outlined;
      case 'current':
      case 'current_account':
        return Icons.account_balance_outlined;
      case 'credit_card':
        return Icons.credit_card_outlined;
      case 'loan':
        return Icons.account_balance_wallet_outlined;
      case 'deposit':
      case 'fixed_deposit':
        return Icons.lock_outline;
      case 'mutual_fund':
        return Icons.trending_up_outlined;
      case 'insurance':
        return Icons.shield_outlined;
      default:
        return Icons.account_balance_outlined;
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  Future<void> _handleSyncData() async {
    final aggregatorNotifier = ref.read(aggregatorStateProvider.notifier);
    final success = await aggregatorNotifier.syncData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Data synced successfully' : 'Sync failed. Please try again.',
          ),
          backgroundColor: success ? ESUNColors.success : ESUNColors.error,
        ),
      );
    }
  }

  Widget _buildConnectionCard(DataConnection connection) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.md),
      child: FPCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(ESUNSpacing.md),
                  decoration: BoxDecoration(
                    color: _getStatusColor(connection.status).withOpacity(0.1),
                    borderRadius: ESUNRadius.smRadius,
                  ),
                  child: Icon(
                    connection.icon,
                    color: _getStatusColor(connection.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: ESUNSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connection.name,
                        style: ESUNTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        connection.description,
                        style: ESUNTypography.bodySmall.copyWith(
                          color: ESUNColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: ESUNSpacing.lg),

            // Status Row
            Row(
              children: [
                _buildStatusChip(connection.status),
                const Spacer(),
                if (connection.provider != null)
                  Text(
                    connection.provider!,
                    style: ESUNTypography.labelSmall.copyWith(
                      color: ESUNColors.textTertiary,
                    ),
                  ),
              ],
            ),

            // Last Sync (if linked)
            if (connection.status == ConnectionStatus.linked && connection.lastSyncAt != null) ...[
              const SizedBox(height: ESUNSpacing.sm),
              Row(
                children: [
                  Icon(Icons.sync, size: 14, color: ESUNColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    'Last synced: ${_formatDate(connection.lastSyncAt!)}',
                    style: ESUNTypography.labelSmall.copyWith(
                      color: ESUNColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],

            // Error Message
            if (connection.status == ConnectionStatus.error && connection.errorMessage != null) ...[
              const SizedBox(height: ESUNSpacing.sm),
              Container(
                padding: const EdgeInsets.all(ESUNSpacing.sm),
                decoration: BoxDecoration(
                  color: ESUNColors.errorSurface,
                  borderRadius: ESUNRadius.smRadius,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, size: 16, color: ESUNColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        connection.errorMessage!,
                        style: ESUNTypography.labelSmall.copyWith(
                          color: ESUNColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: ESUNSpacing.md),

            // Action Buttons
            _buildActionButtons(connection),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ConnectionStatus status) {
    String label;
    Color color;
    IconData icon;

    switch (status) {
      case ConnectionStatus.linked:
        label = 'Linked';
        color = ESUNColors.success;
        icon = Icons.check_circle;
        break;
      case ConnectionStatus.pending:
        label = 'Pending';
        color = ESUNColors.warning;
        icon = Icons.hourglass_empty;
        break;
      case ConnectionStatus.error:
        label = 'Error';
        color = ESUNColors.error;
        icon = Icons.error_outline;
        break;
      case ConnectionStatus.notLinked:
        label = 'Not Linked';
        color = ESUNColors.textTertiary;
        icon = Icons.link_off;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: ESUNRadius.fullRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: ESUNTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(DataConnection connection) {
    switch (connection.status) {
      case ConnectionStatus.notLinked:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleLink(connection),
            icon: const Icon(Icons.link),
            label: const Text('Link Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ESUNColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        );

      case ConnectionStatus.pending:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _handleLink(connection),
            icon: const Icon(Icons.refresh),
            label: const Text('Check Status'),
          ),
        );

      case ConnectionStatus.linked:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleViewLastSync(connection),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('View Sync'),
              ),
            ),
            const SizedBox(width: ESUNSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleRelink(connection),
                icon: const Icon(Icons.sync, size: 18),
                label: const Text('Re-link'),
              ),
            ),
            const SizedBox(width: ESUNSpacing.sm),
            IconButton(
              onPressed: () => _handleDisconnect(connection),
              icon: const Icon(Icons.link_off),
              color: ESUNColors.error,
              tooltip: 'Disconnect',
            ),
          ],
        );

      case ConnectionStatus.error:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _handleRelink(connection),
                icon: const Icon(Icons.refresh),
                label: const Text('Re-link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ESUNColors.error,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: ESUNSpacing.sm),
            OutlinedButton(
              onPressed: () => _handleDisconnect(connection),
              child: const Text('Remove'),
            ),
          ],
        );
    }
  }

  Widget _buildRemindersCard() {
    return FPCard(
      child: Column(
        children: [
          _buildSwitchTile(
            'Sync Notifications',
            'Get notified when data is synced',
            Icons.notifications_active_outlined,
            _notificationsEnabled,
            (value) => setState(() => _notificationsEnabled = value),
            iconColor: ESUNColors.info,
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
            height: 1,
            color: ESUNColors.divider.withOpacity(0.5),
          ),
          _buildSwitchTile(
            'Link Reminders',
            'Remind me to complete pending connections',
            Icons.schedule_outlined,
            _remindersEnabled,
            (value) => setState(() => _remindersEnabled = value),
            iconColor: ESUNColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged, {
    Color? iconColor,
  }) {
    final effectiveIconColor = iconColor ?? ESUNColors.primary;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: ESUNRadius.smRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ESUNSpacing.lg,
          vertical: ESUNSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(ESUNSpacing.sm),
              decoration: BoxDecoration(
                color: effectiveIconColor.withOpacity(0.1),
                borderRadius: ESUNRadius.smRadius,
              ),
              child: Icon(
                icon,
                color: effectiveIconColor,
                size: ESUNIconSize.sm,
              ),
            ),
            const SizedBox(width: ESUNSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ESUNTypography.bodyLarge),
                  Text(
                    subtitle,
                    style: ESUNTypography.bodySmall.copyWith(
                      color: ESUNColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  Widget _buildRegulatoryFooter() {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        color: ESUNColors.success.withOpacity(0.08),
        borderRadius: ESUNRadius.lgRadius,
        border: Border.all(color: ESUNColors.success.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.md),
            decoration: BoxDecoration(
              color: ESUNColors.success.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: ESUNColors.success,
              size: 22,
            ),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Regulated & Protected',
                  style: ESUNTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ESUNColors.success,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your data is protected and regulated by RBI, SEBI, IRDAI, and PFRDA.',
                  style: ESUNTypography.bodySmall.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: ESUNColors.error),
          const SizedBox(height: ESUNSpacing.md),
          Text('Failed to load connections', style: ESUNTypography.titleMedium),
          const SizedBox(height: ESUNSpacing.sm),
          TextButton(
            onPressed: () => ref.refresh(dataConnectionsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.linked:
        return ESUNColors.success;
      case ConnectionStatus.pending:
        return ESUNColors.warning;
      case ConnectionStatus.error:
        return ESUNColors.error;
      case ConnectionStatus.notLinked:
        return ESUNColors.textTertiary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleLink(DataConnection connection) {
    ref.read(analyticsServiceProvider).logEvent(
      name: 'data_connection_link_started',
      parameters: {'connection_id': connection.id},
    );

    if (connection.id == 'aa') {
      context.push(AppRoutes.aaVerifyPan);
    } else if (connection.id == 'credit_bureau') {
      context.push(AppRoutes.installationDataLinking);
    }
  }

  void _handleRelink(DataConnection connection) {
    ref.read(analyticsServiceProvider).logEvent(
      name: 'data_connection_relink',
      parameters: {'connection_id': connection.id},
    );
    _handleLink(connection);
  }

  void _handleDisconnect(DataConnection connection) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Disconnect ${connection.name}?'),
        content: Text(
          'This will revoke access to your ${connection.name.toLowerCase()} data. '
          'You can reconnect anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _disconnectConnection(connection);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ESUNColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnectConnection(DataConnection connection) async {
    ref.read(analyticsServiceProvider).logEvent(
      name: 'data_connection_disconnect',
      parameters: {'connection_id': connection.id},
    );

    // Use aggregator service to revoke consent if AA
    if (connection.id == 'aa') {
      final aggregatorState = ref.read(aggregatorStateProvider);
      if (aggregatorState.activeConsent != null) {
        final success = await ref.read(aggregatorStateProvider.notifier)
            .revokeConsent(aggregatorState.activeConsent!.consentId, reason: 'User requested disconnect');
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to disconnect. Please try again.')),
          );
          return;
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${connection.name} disconnected')),
    );

    // Update auth state
    if (connection.id == 'aa') {
      ref.read(authStateProvider.notifier).updateLinkingStatus(aaConnected: false);
    } else if (connection.id == 'credit_bureau') {
      ref.read(authStateProvider.notifier).updateLinkingStatus(creditBureauConnected: false);
    }

    // Refresh connections
    ref.invalidate(dataConnectionsProvider);
  }

  void _handleViewLastSync(DataConnection connection) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: ESUNRadius.sheetRadius,
      ),
      builder: (ctx) => _LastSyncSheet(connection: connection),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About Data Connections'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(
              'Account Aggregator',
              'Securely share your bank account data using RBI-regulated Account Aggregator framework.',
            ),
            const SizedBox(height: ESUNSpacing.md),
            _buildHelpItem(
              'Credit Bureau',
              'Access your credit score and full credit report from bureaus like CIBIL, Experian.',
            ),
            const SizedBox(height: ESUNSpacing.md),
            _buildHelpItem(
              'Your Control',
              'You can disconnect anytime. We never store your credentials.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ESUNTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
        ),
      ],
    );
  }
}

/// Bottom sheet showing last sync details
class _LastSyncSheet extends StatelessWidget {
  final DataConnection connection;

  const _LastSyncSheet({required this.connection});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(connection.icon, color: ESUNColors.primary),
              const SizedBox(width: ESUNSpacing.sm),
              Text(
                '${connection.name} Sync Details',
                style: ESUNTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.xl),
          _buildDetailRow('Status', 'Connected'),
          _buildDetailRow('Provider', connection.provider ?? 'N/A'),
          _buildDetailRow(
            'Last Sync',
            connection.lastSyncAt != null
                ? '${connection.lastSyncAt!.day}/${connection.lastSyncAt!.month}/${connection.lastSyncAt!.year}'
                : 'Never',
          ),
          _buildDetailRow('Data Shared', 'Account balances, Transactions'),
          const SizedBox(height: ESUNSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.md),
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
}
