import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import 'models/invoice_model.dart';

part 'invoice_repository.g.dart';

@riverpod
InvoiceRepository invoiceRepository(InvoiceRepositoryRef ref) {
  return SupabaseInvoiceRepository(Supabase.instance.client);
}

abstract class InvoiceRepository {
  Future<List<Invoice>> fetchByVehicle(String vehicleId);
  Future<Invoice> create(String vehicleId, File imageFile);
  Future<List<InvoiceItem>> fetchItems(String invoiceId);
  Future<InvoiceItem> updateItem(InvoiceItem item);
  Stream<Invoice> subscribeToInvoice(String invoiceId);
}

class SupabaseInvoiceRepository implements InvoiceRepository {
  SupabaseInvoiceRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Invoice>> fetchByVehicle(String vehicleId) async {
    final response = await _client
        .from('invoices')
        .select()
        .eq('vehicle_id', vehicleId)
        .order('created_at', ascending: false);
    return (response as List<dynamic>)
        .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Invoice> create(String vehicleId, File imageFile) async {
    final uid = _client.auth.currentUser!.id;
    final fileName = '${const Uuid().v4()}.jpg';
    final storagePath = '$uid/$vehicleId/$fileName';

    // Upload to private Storage bucket
    await _client.storage
        .from(AppConstants.invoicesBucket)
        .upload(storagePath, imageFile);

    // Create invoice row with ai_parsed_at = null
    final response = await _client
        .from('invoices')
        .insert({
          'vehicle_id': vehicleId,
          'photo_url': storagePath,
        })
        .select()
        .single();

    return Invoice.fromJson(response);
  }

  @override
  Future<List<InvoiceItem>> fetchItems(String invoiceId) async {
    final response = await _client
        .from('invoice_items')
        .select()
        .eq('invoice_id', invoiceId)
        .order('created_at');
    return (response as List<dynamic>)
        .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<InvoiceItem> updateItem(InvoiceItem item) async {
    final data = item.toJson()
      ..remove('created_at')
      ..remove('updated_at');

    final response = await _client
        .from('invoice_items')
        .update(data)
        .eq('id', item.id)
        .select()
        .single();
    return InvoiceItem.fromJson(response);
  }

  @override
  Stream<Invoice> subscribeToInvoice(String invoiceId) {
    return _client
        .from('invoices')
        .stream(primaryKey: ['id'])
        .eq('id', invoiceId)
        .map((rows) => Invoice.fromJson(rows.first));
  }
}
