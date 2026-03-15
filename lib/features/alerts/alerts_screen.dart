/// ESUN Alerts Screen
/// 
/// Notifications and alerts center.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../shared/widgets/widgets.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            TextButton(
              onPressed: () {},
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
            _buildNotificationList(_allNotifications),
            _buildNotificationList(_paymentNotifications),
            _buildNotificationList(_offerNotifications),
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
              padding: const EdgeInsets.all(10),
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
  
  static final List<_NotificationItem> _allNotifications = [
    _NotificationItem(
      icon: Icons.check_circle,
      title: 'Payment Successful',
      body: '₹5,000 sent to Rahul Sharma via UPI',
      time: '2 min ago',
      color: ESUNColors.success,
      isRead: false,
    ),
    _NotificationItem(
      icon: Icons.local_offer,
      title: 'Special Offer',
      body: 'Get 5% cashback on your next investment! Valid till Jan 31',
      time: '1 hour ago',
      color: Colors.purple,
      isRead: false,
    ),
    _NotificationItem(
      icon: Icons.warning,
      title: 'Bill Reminder',
      body: 'Electricity bill of ₹2,340 due in 3 days',
      time: '3 hours ago',
      color: ESUNColors.warning,
      isRead: true,
    ),
    _NotificationItem(
      icon: Icons.account_balance,
      title: 'Salary Credited',
      body: '₹75,000 credited to your HDFC account',
      time: 'Yesterday',
      color: ESUNColors.success,
      isRead: true,
    ),
    _NotificationItem(
      icon: Icons.trending_up,
      title: 'Investment Update',
      body: 'Your portfolio is up 2.5% this week. Great progress!',
      time: 'Yesterday',
      color: Colors.blue,
      isRead: true,
    ),
  ];
  
  static final List<_NotificationItem> _paymentNotifications = [
    _NotificationItem(
      icon: Icons.check_circle,
      title: 'Payment Successful',
      body: '₹5,000 sent to Rahul Sharma via UPI',
      time: '2 min ago',
      color: ESUNColors.success,
      isRead: false,
    ),
    _NotificationItem(
      icon: Icons.account_balance,
      title: 'Salary Credited',
      body: '₹75,000 credited to your HDFC account',
      time: 'Yesterday',
      color: ESUNColors.success,
      isRead: true,
    ),
  ];
  
  static final List<_NotificationItem> _offerNotifications = [
    _NotificationItem(
      icon: Icons.local_offer,
      title: 'Special Offer',
      body: 'Get 5% cashback on your next investment! Valid till Jan 31',
      time: '1 hour ago',
      color: Colors.purple,
      isRead: false,
    ),
  ];
}

class _NotificationItem {
  final IconData icon;
  final String title;
  final String body;
  final String time;
  final Color color;
  final bool isRead;
  
  _NotificationItem({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    required this.color,
    required this.isRead,
  });
}



