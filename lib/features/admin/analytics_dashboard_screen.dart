/// Analytics Dashboard Screen
///
/// Admin screen for viewing analytics KPIs, conversion funnels,
/// error metrics, and managing alerts.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_api_service.dart';

/// Dashboard data provider
final dashboardDataProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.watch(analyticsApiServiceProvider);
  final result = await api.getDashboard(days: 30);
  return result.when(
    success: (data) => data,
    error: (e) => throw e,
  );
});

/// AA Funnel data provider
final aaFunnelProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.watch(analyticsApiServiceProvider);
  final result = await api.getConversionFunnel('aa', days: 30);
  return result.when(
    success: (data) => data,
    error: (e) => throw e,
  );
});

/// Alerts provider
final alertsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(analyticsApiServiceProvider);
  final result = await api.getAlerts();
  return result.when(
    success: (data) => data,
    error: (e) => throw e,
  );
});

/// Analytics Dashboard Screen (Admin Only)
class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardDataProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text(
          'Analytics Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A62B8), Color(0xFF2E4A9A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(dashboardDataProvider);
              ref.invalidate(aaFunnelProvider);
              ref.invalidate(alertsProvider);
            },
          ),
        ],
      ),
      body: dashboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => _buildDashboard(context, ref, data),
      ),
    );
  }
  
  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> dashboard,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardDataProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // KPI Cards Row
          _buildKPISection(context, dashboard),
          const SizedBox(height: 16),
          
          // AA Conversion Funnel
          _buildFunnelSection(context, ref),
          const SizedBox(height: 16),
          
          // Active Alerts
          _buildAlertsSection(context, ref),
          const SizedBox(height: 16),
          
          // Error Metrics
          _buildErrorSection(context, dashboard),
        ],
      ),
    );
  }
  
  Widget _buildKPISection(BuildContext context, Map<String, dynamic> dashboard) {
    final kpis = dashboard['kpis'] as Map<String, dynamic>? ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics (Last 30 Days)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildKPICard(
              context,
              'Total Events',
              '${kpis['total_events'] ?? 0}',
              Icons.analytics,
              const [Color(0xFF4A62B8), Color(0xFF2E4A9A)], // Purple-Blue gradient
            ),
            _buildKPICard(
              context,
              'Active Users',
              '${kpis['active_users'] ?? 0}',
              Icons.people,
              const [Color(0xFF11998E), Color(0xFF38EF7D)], // Teal-Green gradient
            ),
            _buildKPICard(
              context,
              'AA Conversion',
              '${kpis['aa_conversion_rate'] ?? 0}%',
              Icons.link,
              const [Color(0xFFFF6B6B), Color(0xFFFFE66D)], // Red-Yellow gradient
            ),
            _buildKPICard(
              context,
              'Error Rate',
              '${kpis['error_rate'] ?? 0}%',
              Icons.error_outline,
              const [Color(0xFFED213A), Color(0xFF93291E)], // Deep Red gradient
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildKPICard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    List<Color> gradientColors,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.9), size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFunnelSection(BuildContext context, WidgetRef ref) {
    final funnel = ref.watch(aaFunnelProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A62B8).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A62B8), Color(0xFF2E4A9A)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.filter_alt, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'AA Conversion Funnel',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            funnel.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading funnel: $e'),
              data: (data) => _buildFunnelChart(context, data),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFunnelChart(BuildContext context, Map<String, dynamic> data) {
    final stages = data['stages'] as List<dynamic>? ?? [];
    
    if (stages.isEmpty) {
      return const Text('No funnel data available');
    }
    
    final colors = [
      const Color(0xFF4A62B8),
      const Color(0xFF2E4A9A),
      const Color(0xFF11998E),
      const Color(0xFF38EF7D),
      const Color(0xFFFF6B6B),
    ];
    
    return Column(
      children: stages.asMap().entries.map<Widget>((entry) {
        final index = entry.key;
        final Map<String, dynamic> stageData = entry.value as Map<String, dynamic>;
        final name = stageData['name'] as String? ?? '';
        final rate = stageData['conversion_rate'] as double? ?? 0;
        final color = colors[index % colors.length];
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: rate / 100,
                    backgroundColor: Colors.grey[200],
                    minHeight: 10,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${rate.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildAlertsSection(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFED213A).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFED213A), Color(0xFF93291E)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.notifications_active, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Active Alerts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                alerts.when(
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                  data: (data) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: data.isNotEmpty 
                        ? const LinearGradient(colors: [Color(0xFFED213A), Color(0xFF93291E)])
                        : const LinearGradient(colors: [Color(0xFF11998E), Color(0xFF38EF7D)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${data.length}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            alerts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading alerts: $e'),
              data: (data) => data.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38EF7D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF11998E)),
                        SizedBox(width: 8),
                        Text('All systems operating normally', 
                          style: TextStyle(color: Color(0xFF11998E), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                : Column(
                    children: data.map((alert) => _buildAlertTile(context, ref, alert)).toList(),
                  ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAlertTile(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> alert,
  ) {
    final severity = alert['severity'] as String? ?? 'info';
    final gradientColors = severity == 'critical'
        ? const [Color(0xFFED213A), Color(0xFF93291E)]
        : severity == 'warning'
            ? const [Color(0xFFFF6B6B), Color(0xFFFFE66D)]
            : const [Color(0xFF4A62B8), Color(0xFF2E4A9A)];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: gradientColors.first.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
        ),
        title: Text(
          alert['rule_name'] as String? ?? 'Alert',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            alert['message'] as String? ?? '',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () => _resolveAlert(context, ref, alert['id'] as String),
          style: ElevatedButton.styleFrom(
            backgroundColor: gradientColors.first,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Resolve'),
        ),
      ),
    );
  }
  
  Future<void> _resolveAlert(
    BuildContext context,
    WidgetRef ref,
    String alertId,
  ) async {
    final api = ref.read(analyticsApiServiceProvider);
    final result = await api.resolveAlert(alertId);
    
    result.when(
      success: (_) {
        ref.invalidate(alertsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alert resolved')),
        );
      },
      error: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resolve: ${e.message}')),
        );
      },
    );
  }
  
  Widget _buildErrorSection(BuildContext context, Map<String, dynamic> dashboard) {
    final errors = dashboard['error_metrics'] as Map<String, dynamic>? ?? {};
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A62B8).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bug_report, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Error Metrics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildErrorRow('AA API Errors', errors['aa_errors'] ?? 0, const Color(0xFFED213A)),
            _buildErrorRow('AA Timeouts', errors['aa_timeouts'] ?? 0, const Color(0xFFFF6B6B)),
            _buildErrorRow('CB Errors', errors['cb_errors'] ?? 0, const Color(0xFF2E4A9A)),
            _buildErrorRow('Export Failures', errors['export_failures'] ?? 0, const Color(0xFFFF8E53)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorRow(String label, int count, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: count > 0 
                ? LinearGradient(
                    colors: [accentColor.withOpacity(0.8), accentColor],
                  )
                : const LinearGradient(
                    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                  ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
