import 'package:freezed_annotation/freezed_annotation.dart';

part 'invoice_model.freezed.dart';
part 'invoice_model.g.dart';

@freezed
class Invoice with _$Invoice {
  const factory Invoice({
    required String id,
    required String vehicleId,
    required String photoUrl,
    DateTime? aiParsedAt,
    String? rawText,
    double? totalBrl,
    DateTime? issuedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Invoice;

  factory Invoice.fromJson(Map<String, dynamic> json) =>
      _$InvoiceFromJson(json);
}

@freezed
class InvoiceItem with _$InvoiceItem {
  const factory InvoiceItem({
    required String id,
    required String invoiceId,
    required String description,
    @Default(1) double quantity,
    required double unitPrice,
    required String itemType, // 'part' | 'labor' | 'other'
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _InvoiceItem;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) =>
      _$InvoiceItemFromJson(json);
}
