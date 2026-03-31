/// ESUN Alerts Screen
/// 
/// Notifications and alerts center - derives from transaction history.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import '../../state/transaction_state.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});
  
  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  bool _allRead = false;
  
  List<_NotificationItem> _buildNotificationsFromTransactions() {
    final txns = ref.watch(transactionStateProvider).transactions;
    final notifications = <_NotificationItem>[];
    
    for (int i = 0; i < txns.length && i < 20; i++) {
      final t = txns[i];
      final ago = DateTime.now().difference(t.timestamp);
      String timeText;
      if (ago.inMinutes < 60) {
        timeText = '${ago.inMinutes} min ago';
      } else if (ago.inHours < 24) {
        timeText = '${ago.inHours} hours ago';
      } else if (ago.inDays < 2) {
        timeText = 'Yesterday';
      } else {
        timeText = '${ago.inDays} days ago';
      }
      
      IconData icon;
      Color color;
      String title;
      String category = 'payment';
      
      if (t.isDebit) {
        if (t.type == TransactionType.billPayment) {
          icon = Icons.receipt_long;
          color = ESUNColors.warning;
          title = 'Bill Payment';
          category = 'payment';
        } else {
          icon = Icons.check_circle;
          color = ESUNColors.success;
          title = 'Payment Successful';
          category = 'payment';
        }
      } else {
        icon = Icons.account_balance;
        color = ESUNColors.success;
        title = 'Credit Received';
        category = 'payment';
      }
      
      notifications.add(_NotificationItem(
        icon: icon,
        title: title,
        body: '${t.isDebit ? "₹${t.amount.toStringAsFixed(0)} - " : "₹${t.amount.toStringAsFixed(0)} + "}${t.title}',
        time: timeText,
        color: color,
        isRead: _allRead || i > 2,
        category: category,
      ));
    }
    
    // Add static offers
    notifications.add(_NotificationItem(
      icon: Icons.local_offer,
      title: 'Special Offer',
      body: 'Get 5% cashback on your next investment!',
      time: 'Today',
      color: Colors.purple,
      isRead: _allRead,
      category: 'offer',
    ));
    notifications.add(_NotificationItem(
      icon: Icons.trending_up,
      title: 'Investment Update',
      body: 'Your portfolio performance is looking good. Check Wealth Manager.',
      time: 'Today',
      color: Colors.blue,
      isRead: _allRead,
      category: 'offer',
    ));
    
    return notifications;
  }
  
  @override
  Widget build(BuildContext context) {
    final all = _buildNotificationsFromTransactions();
    final payments = all.where((n) => n.category == 'payment').toList();
    final offers = all.where((n) => n.category == 'offer').toList();
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _allRead = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read')),
                );
              },
              child: const Text('Mark all read'),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Payments'),
              Tab(text: 'Offers'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNotificationList(all),
            _buildNotificationList(payments),
            _buildNotificationList(offers),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotificationList(List<_NotificationItem> notifications) {
    if (notifications.isEmpty) {
      return const FPEmptyState(
        icon: Icons.notifications_off_outlined,
        title: 'No notifications',
        description: 'You\'re all caught up!',
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }
  
  Widget _buildNotificationCard(_NotificationItem notification) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(ESUNSpacing.md),
        decoration: BoxDecoration(
          color: notification.isRead 
              ? ESUNColors.surface 
              : ESUNColors.primary.withOpacity(0.05),
          borderRadius: ESUNRadius.mdRadius,
          border: Border.all(
            color: notification.isRead 
                ? ESUNColors.border 
                : ESUNColors.primary.withOpacity(0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(ESUNSpacing.md),
              decoration: BoxDecoration(
                color: notification.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification.icon,
                color: notification.color,
                size: 20,
              ),
            ),
            const SizedBox(width: ESUNSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: ESUNTypography.bodyLarge.copyWith(
                      fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: ESUNTypography.bodySmall.copyWith(
                      color: ESUNColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.time,
                    style: ESUNTypography.labelSmall.copyWith(
                      color: ESUNColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ESUNColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem {
  final IconData icon;
  final String title;
  final String body;
  final String time;
  final Color color;
  final bool isRead;
  final String category;
  
  _NotificationItem({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    required this.color,
    required this.isRead,
    this.category = 'all',
  });
}



