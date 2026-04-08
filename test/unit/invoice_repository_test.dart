import 'package:flutter_test/flutter_test.dart';

import 'package:snappcar/features/invoices/data/models/invoice_model.dart';

void main() {
  group('Invoice', () {
    test('fromJson maps fields including null ai_parsed_at', () {
      final json = {
        'id': 'inv1',
        'vehicle_id': 'v1',
        'photo_url': 'user1/v1/abc.jpg',
        'ai_parsed_at': null,
        'raw_text': null,
        'total_brl': null,
        'issued_at': null,
        'created_at': '2024-03-01T12:00:00.000Z',
        'updated_at': '2024-03-01T12:00:00.000Z',
      };

      final invoice = Invoice.fromJson(json);

      expect(invoice.id, equals('inv1'));
      expect(invoice.aiParsedAt, isNull);
      expect(invoice.totalBrl, isNull);
    });

    test('fromJson maps fields after AI parsing', () {
      final json = {
        'id': 'inv2',
        'vehicle_id': 'v1',
        'photo_url': 'user1/v1/def.jpg',
        'ai_parsed_at': '2024-03-01T12:05:00.000Z',
        'raw_text': null,
        'total_brl': 350.00,
        'issued_at': '2024-02-28',
        'created_at': '2024-03-01T12:00:00.000Z',
        'updated_at': '2024-03-01T12:05:00.000Z',
      };

      final invoice = Invoice.fromJson(json);

      expect(invoice.aiParsedAt, isNotNull);
      expect(invoice.totalBrl, equals(350.00));
      expect(invoice.issuedAt, isNotNull);
    });
  });

  group('InvoiceItem', () {
    test('item_type validation: only part/labor/other accepted', () {
      for (final type in ['part', 'labor', 'other']) {
        final json = {
          'id': 'ii1',
          'invoice_id': 'inv1',
          'description': 'Filtro de óleo',
          'quantity': 1.0,
          'unit_price': 45.00,
          'item_type': type,
          'created_at': '2024-03-01T12:00:00.000Z',
          'updated_at': '2024-03-01T12:00:00.000Z',
        };

        final item = InvoiceItem.fromJson(json);
        expect(item.itemType, equals(type));
      }
    });

    test('total calculation: quantity * unit_price', () {
      final item = InvoiceItem(
        id: 'ii2',
        invoiceId: 'inv1',
        description: 'Pastilha de freio',
        quantity: 4,
        unitPrice: 55.00,
        itemType: 'part',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      expect(item.quantity * item.unitPrice, equals(220.00));
    });
  });
}
