/// ESUN Remind Me Later Dialog
///
/// A bottom sheet dialog for users to schedule a reminder
/// when they choose to skip data linking.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../services/reminder_service.dart';
import '../../core/analytics/analytics_service.dart';

/// Shows the "Remind Me Later" bottom sheet
Future<bool?> showRemindMeLaterDialog(
  BuildContext context, {
  required ReminderType reminderType,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _RemindMeLaterSheet(
      reminderType: reminderType,
    ),
  );
}

class _RemindMeLaterSheet extends ConsumerStatefulWidget {
  final ReminderType reminderType;

  const _RemindMeLaterSheet({
    required this.reminderType,
  });

  @override
  ConsumerState<_RemindMeLaterSheet> createState() =>
      _RemindMeLaterSheetState();
}

class _RemindMeLaterSheetState extends ConsumerState<_RemindMeLaterSheet> {
  ReminderHours _selectedHours = ReminderHours.hours24;
  ReminderChannel _selectedChannel = ReminderChannel.push;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.xl),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ESUNColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: ESUNSpacing.xl),

          // Icon & Title
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: ESUNColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              size: 32,
              color: ESUNColors.primary,
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),

          Text(
            'When should we remind you?',
            style: ESUNTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ESUNSpacing.sm),

          Text(
            'We\'ll send you a friendly reminder to complete your data linking.',
            style: ESUNTypography.bodyMedium.copyWith(
              color: ESUNColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ESUNSpacing.xl),

          // Reminder time options
          ...ReminderHours.values.map((hours) => _buildTimeOption(hours)),
          const SizedBox(height: ESUNSpacing.lg),

          // Channel selection
          Text(
            'How should we notify you?',
            style: ESUNTypography.bodyMedium.copyWith(
              color: ESUNColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.sm),

          Row(
            children: [
              _buildChannelChip(ReminderChannel.push, Icons.notifications_outlined, 'Push'),
              const SizedBox(width: ESUNSpacing.sm),
              _buildChannelChip(ReminderChannel.email, Icons.email_outlined, 'Email'),
              const SizedBox(width: ESUNSpacing.sm),
              _buildChannelChip(ReminderChannel.both, Icons.all_inbox_outlined, 'Both'),
            ],
          ),
          const SizedBox(height: ESUNSpacing.xl),

          // Set Reminder button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _setReminder,
              style: ElevatedButton.styleFrom(
                backgroundColor: ESUNColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.alarm_add_rounded),
                        const SizedBox(width: 8),
                        Text(
                          'Remind me in ${_selectedHours.label}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),

          // Skip without reminder
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Skip without reminder',
              style: TextStyle(
                color: ESUNColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
        ],
      ),
    );
  }

  Widget _buildTimeOption(ReminderHours hours) {
    final isSelected = _selectedHours == hours;
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.sm),
      child: InkWell(
        onTap: () => setState(() => _selectedHours = hours),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ESUNSpacing.lg,
            vertical: ESUNSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? ESUNColors.primary.withOpacity(0.1)
                : ESUNColors.neutral100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? ESUNColors.primary : ESUNColors.neutral200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getTimeIcon(hours),
                color: isSelected ? ESUNColors.primary : ESUNColors.textSecondary,
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: Text(
                  hours.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? ESUNColors.primary : ESUNColors.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: ESUNColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelChip(ReminderChannel channel, IconData icon, String label) {
    final isSelected = _selectedChannel == channel;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedChannel = channel),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: ESUNSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? ESUNColors.primary.withOpacity(0.1)
                : ESUNColors.neutral100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? ESUNColors.primary : ESUNColors.neutral200,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? ESUNColors.primary : ESUNColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? ESUNColors.primary : ESUNColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTimeIcon(ReminderHours hours) {
    switch (hours) {
      case ReminderHours.hours24:
        return Icons.timer_outlined;
      case ReminderHours.hours72:
        return Icons.calendar_today_outlined;
      case ReminderHours.hours168:
        return Icons.date_range_outlined;
    }
  }

  Future<void> _setReminder() async {
    setState(() => _isLoading = true);

    try {
      // Track analytics
      ref.read(analyticsServiceProvider).logEvent(
        name: AnalyticsEvents.remindMeLaterClicked,
        parameters: {
          'reminder_type': widget.reminderType.value,
          'reminder_hours': _selectedHours.hours,
          'channel': _selectedChannel.value,
        },
      );

      // Call API
      final service = ref.read(reminderServiceProvider);
      final success = await service.setReminder(
        type: widget.reminderType,
        hours: _selectedHours,
        channel: _selectedChannel,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Reminder set for ${_selectedHours.label}'),
                ],
              ),
              backgroundColor: ESUNColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to set reminder. Try again.'),
              backgroundColor: ESUNColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: ESUNColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
