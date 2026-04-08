import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/invoice_repository.dart';
import '../data/models/invoice_model.dart';

part 'invoice_provider.g.dart';

@riverpod
Future<List<Invoice>> invoicesList(
  InvoicesListRef ref,
  String vehicleId,
) {
  return ref.watch(invoiceRepositoryProvider).fetchByVehicle(vehicleId);
}

@riverpod
Future<List<InvoiceItem>> invoiceItems(
  InvoiceItemsRef ref,
  String invoiceId,
) {
  return ref.watch(invoiceRepositoryProvider).fetchItems(invoiceId);
}

@riverpod
Stream<Invoice> invoiceStream(
  InvoiceStreamRef ref,
  String invoiceId,
) {
  return ref.watch(invoiceRepositoryProvider).subscribeToInvoice(invoiceId);
}

@riverpod
class InvoiceNotifier extends _$InvoiceNotifier {
  @override
  AsyncValue<Invoice?> build() => const AsyncData(null);

  Future<Invoice> capture(String vehicleId, File imageFile) async {
    state = const AsyncLoading();
    late Invoice invoice;
    state = await AsyncValue.guard(() async {
      invoice = await ref
          .read(invoiceRepositoryProvider)
          .create(vehicleId, imageFile);
      return invoice;
    });
    ref.invalidate(invoicesListProvider(vehicleId));
    return invoice;
  }
}
