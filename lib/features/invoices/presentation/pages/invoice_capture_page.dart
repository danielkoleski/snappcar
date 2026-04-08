import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/extensions/build_context_extensions.dart';
import '../../providers/invoice_provider.dart';
import '../widgets/processing_indicator.dart';

class InvoiceCapturePage extends ConsumerStatefulWidget {
  const InvoiceCapturePage({required this.vehicleId, super.key});

  final String vehicleId;

  @override
  ConsumerState<InvoiceCapturePage> createState() =>
      _InvoiceCapturePageState();
}

class _InvoiceCapturePageState extends ConsumerState<InvoiceCapturePage> {
  File? _selectedImage;
  String? _processingInvoiceId;
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked == null) return;
    setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _upload() async {
    if (_selectedImage == null) return;

    final invoice = await ref
        .read(invoiceNotifierProvider.notifier)
        .capture(widget.vehicleId, _selectedImage!);

    if (!mounted) return;
    setState(() => _processingInvoiceId = invoice.id);
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = ref.watch(invoiceNotifierProvider).isLoading;

    if (_processingInvoiceId != null) {
      return ProcessingIndicatorPage(
        invoiceId: _processingInvoiceId!,
        vehicleId: widget.vehicleId,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Fotografar Nota Fiscal')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _selectedImage == null
                    ? _PlaceholderBox(
                        onCamera: () => _pickImage(ImageSource.camera),
                        onGallery: () => _pickImage(ImageSource.gallery),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              if (_selectedImage != null) ...[
                OutlinedButton.icon(
                  onPressed: isUploading
                      ? null
                      : () => setState(() => _selectedImage = null),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Usar outra foto'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: isUploading ? null : _upload,
                  icon: isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(isUploading ? 'Enviando...' : 'Enviar para análise'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  const _PlaceholderBox({
    required this.onCamera,
    required this.onGallery,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Fotografe a nota fiscal\ndo serviço ou peça',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Câmera'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Galeria'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
