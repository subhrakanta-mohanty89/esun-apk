/// ESUN Contacts Service
///
/// Provides access to device contacts for payments and transfers.
/// Handles contact fetching, searching, and caching.

import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contact model for payments
class PaymentContact {
  final String id;
  final String displayName;
  final String? phoneNumber;
  final String? email;
  final String? photoUrl;
  final String initials;

  const PaymentContact({
    required this.id,
    required this.displayName,
    this.phoneNumber,
    this.email,
    this.photoUrl,
    required this.initials,
  });

  factory PaymentContact.fromFlutterContact(Contact contact) {
    final phone = contact.phones.isNotEmpty ? contact.phones.first.number : null;
    final email = contact.emails.isNotEmpty ? contact.emails.first.address : null;
    
    // Generate initials
    final nameParts = contact.displayName.split(' ');
    String initials;
    if (nameParts.length >= 2) {
      initials = '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
      initials = nameParts[0].substring(0, nameParts[0].length >= 2 ? 2 : 1).toUpperCase();
    } else {
      initials = '?';
    }

    return PaymentContact(
      id: contact.id,
      displayName: contact.displayName,
      phoneNumber: phone,
      email: email,
      initials: initials,
    );
  }

  /// Format phone number for display
  String get formattedPhone {
    if (phoneNumber == null) return '';
    // Remove all non-digit characters except +
    final cleaned = phoneNumber!.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.length >= 10) {
      // Format as Indian phone number
      if (cleaned.startsWith('+91')) {
        return '+91 ${cleaned.substring(3, 8)} ${cleaned.substring(8)}';
      } else if (cleaned.length == 10) {
        return '${cleaned.substring(0, 5)} ${cleaned.substring(5)}';
      }
    }
    return phoneNumber!;
  }

  /// Check if contact has a valid phone number for payment
  bool get hasValidPhone {
    if (phoneNumber == null) return false;
    final digitsOnly = phoneNumber!.replaceAll(RegExp(r'\D'), '');
    return digitsOnly.length >= 10;
  }
}

/// Contacts state
class ContactsState {
  final List<PaymentContact> contacts;
  final List<PaymentContact> frequentContacts;
  final bool isLoading;
  final bool hasPermission;
  final String? error;

  const ContactsState({
    this.contacts = const [],
    this.frequentContacts = const [],
    this.isLoading = false,
    this.hasPermission = false,
    this.error,
  });

  ContactsState copyWith({
    List<PaymentContact>? contacts,
    List<PaymentContact>? frequentContacts,
    bool? isLoading,
    bool? hasPermission,
    String? error,
  }) {
    return ContactsState(
      contacts: contacts ?? this.contacts,
      frequentContacts: frequentContacts ?? this.frequentContacts,
      isLoading: isLoading ?? this.isLoading,
      hasPermission: hasPermission ?? this.hasPermission,
      error: error,
    );
  }
}

/// Contacts provider
final contactsProvider = StateNotifierProvider<ContactsNotifier, ContactsState>((ref) {
  return ContactsNotifier();
});

/// Contacts notifier
class ContactsNotifier extends StateNotifier<ContactsState> {
  ContactsNotifier() : super(const ContactsState());

  /// Load contacts from device
  Future<void> loadContacts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check permission
      final hasPermission = await FlutterContacts.requestPermission();
      
      if (!hasPermission) {
        state = state.copyWith(
          isLoading: false,
          hasPermission: false,
          error: 'Contacts permission denied',
        );
        return;
      }

      // Get contacts with phones only
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      // Filter contacts with valid phone numbers
      final paymentContacts = contacts
          .where((c) => c.phones.isNotEmpty)
          .map((c) => PaymentContact.fromFlutterContact(c))
          .where((c) => c.hasValidPhone)
          .toList();

      // Sort alphabetically
      paymentContacts.sort((a, b) => a.displayName.compareTo(b.displayName));

      // Get frequent contacts (first 5 for now - could be based on transaction history)
      final frequent = paymentContacts.take(5).toList();

      state = state.copyWith(
        contacts: paymentContacts,
        frequentContacts: frequent,
        isLoading: false,
        hasPermission: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load contacts: $e',
      );
    }
  }

  /// Search contacts
  List<PaymentContact> searchContacts(String query) {
    if (query.isEmpty) return state.contacts;
    
    final lowerQuery = query.toLowerCase();
    return state.contacts.where((contact) {
      return contact.displayName.toLowerCase().contains(lowerQuery) ||
          (contact.phoneNumber?.contains(query) ?? false);
    }).toList();
  }

  /// Refresh contacts
  Future<void> refresh() async {
    await loadContacts();
  }
}

/// Contacts service singleton
class ContactsService {
  ContactsService._();
  static final instance = ContactsService._();

  List<PaymentContact>? _cachedContacts;

  /// Get all contacts with phone numbers
  Future<List<PaymentContact>> getContacts({bool forceRefresh = false}) async {
    if (_cachedContacts != null && !forceRefresh) {
      return _cachedContacts!;
    }

    final hasPermission = await FlutterContacts.requestPermission();
    if (!hasPermission) {
      return [];
    }

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    _cachedContacts = contacts
        .where((c) => c.phones.isNotEmpty)
        .map((c) => PaymentContact.fromFlutterContact(c))
        .where((c) => c.hasValidPhone)
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    return _cachedContacts!;
  }

  /// Search contacts by name or phone
  Future<List<PaymentContact>> searchContacts(String query) async {
    final contacts = await getContacts();
    if (query.isEmpty) return contacts;

    final lowerQuery = query.toLowerCase();
    return contacts.where((contact) {
      return contact.displayName.toLowerCase().contains(lowerQuery) ||
          (contact.phoneNumber?.contains(query) ?? false);
    }).toList();
  }

  /// Clear cache
  void clearCache() {
    _cachedContacts = null;
  }
}
