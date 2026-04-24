import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/wallet_service.dart';

final walletServiceProvider = Provider((ref) => WalletService.instance);

final walletBalanceProvider = FutureProvider<double>((ref) async {
  // Watching the service instance is fine, but we need to ensure this refreshes
  // if the auth state changes. 
  return ref.watch(walletServiceProvider).getWalletBalance();
});

final walletTransactionsProvider = FutureProvider<List<WalletTransaction>>((ref) async {
  return ref.watch(walletServiceProvider).getTransactions();
});
