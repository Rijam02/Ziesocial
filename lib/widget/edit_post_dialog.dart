import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ziesocial/core/app_theme.dart';

class EditPostDialog extends StatefulWidget {
  final String initialCaption;
  final Function(String newCaption) onSave;

  const EditPostDialog({
    super.key,
    required this.initialCaption,
    required this.onSave,
  });

  @override
  State<EditPostDialog> createState() => _EditPostDialogState();
}

class _EditPostDialogState extends State<EditPostDialog> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialCaption);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    await widget.onSave(_controller.text.trim());
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      backgroundColor: AppColors.pureWhite,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Keterangan Postingan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.secondaryText,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Gap(14),
              TextField(
                controller: _controller,
                maxLines: 4,
                style: const TextStyle(fontSize: 14, height: 1.45),
                decoration: const InputDecoration(
                  hintText: 'Tulis keterangan baru untuk postingan ini...',
                ),
              ),
              const Gap(18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: AppColors.pureWhite,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
