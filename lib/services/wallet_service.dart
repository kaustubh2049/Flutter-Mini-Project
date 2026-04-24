import 'package:supabase_flutter/supabase_flutter.dart';

class WalletTransaction {
  final String id;
  final String userId;
  final double amount;
  final String type; // 'credit' | 'debit'
  final String purpose; // 'boost' | 'verification' | 'subscription' | 'add_money'
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.purpose,
    required this.createdAt,
  });

  factory WalletTransaction.fromMap(Map<String, dynamic> map) {
    return WalletTransaction(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] ?? 'credit',
      purpose: map['purpose'] ?? 'add_money',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class WalletService {
  WalletService._();
  static final instance = WalletService._();

  final SupabaseClient _db = Supabase.instance.client;

  Future<double> getWalletBalance() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return 0.0;

    try {
      final row = await _db
          .from('wallets')
          .select('balance')
          .eq('user_id', uid)
          .maybeSingle();

      if (row == null) {
        // Initialize wallet if it doesn't exist
        await _db.from('wallets').insert({'user_id': uid, 'balance': 0.0});
        return 0.0;
      }

      return (row['balance'] as num).toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> addMoney(double amount) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('Please log in');

    // 1. Update balance
    final currentBalance = await getWalletBalance();
    final newBalance = currentBalance + amount;

    await _db
        .from('wallets')
        .update({'balance': newBalance})
        .eq('user_id', uid);

    // 2. Record transaction
    await _db.from('wallet_transactions').insert({
      'user_id': uid,
      'amount': amount,
      'type': 'credit',
      'purpose': 'add_money',
    });
  }

  Future<void> deductMoney(double amount, String purpose) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('Please log in');

    // 1. Check balance
    final currentBalance = await getWalletBalance();
    if (currentBalance < amount) {
      throw Exception('Insufficient wallet balance. Please add money.');
    }

    // 2. Update balance
    final newBalance = currentBalance - amount;
    await _db
        .from('wallets')
        .update({'balance': newBalance})
        .eq('user_id', uid);

    // 3. Record transaction
    await _db.from('wallet_transactions').insert({
      'user_id': uid,
      'amount': amount,
      'type': 'debit',
      'purpose': purpose,
    });
  }

  Future<List<WalletTransaction>> getTransactions() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];

    final response = await _db
        .from('wallet_transactions')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => WalletTransaction.fromMap(row))
        .toList();
  }
}
