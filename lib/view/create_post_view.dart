import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/model/user_model.dart';
import 'package:ziesocial/viewmodel/create_post_viewmodel.dart';
import 'package:ziesocial/viewmodel/login_viewmodel.dart';
import 'package:ziesocial/viewmodel/profile_viewmodel.dart';

class CreatePostView extends StatefulWidget {
  final bool initialHighlightMode;

  const CreatePostView({
    super.key,
    this.initialHighlightMode = false,
  });

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _PickedPhotoItem {
  final XFile file;
  final Uint8List bytes;

  const _PickedPhotoItem({
    required this.file,
    required this.bytes,
  });
}

class _CreatePostViewState extends State<CreatePostView> {
  final _captionController = TextEditingController();
  final _highlightTitleController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final List<_PickedPhotoItem> _pickedHistory = [];
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  late bool _isHighlight;
  String? _localError;

  // Source & Editor State (Rotate & Penyesuaian Ukuran / Rasio Foto)
  String _activeSourceTab = 'gallery'; // 'gallery' | 'camera'
  String _selectedRatioKey = '4:5'; // '1:1', '4:5', '16:9'
  int _rotationTurns = 0; // 0, 1, 2, 3 (90° per putaran searah jarum jam)
  bool _isCoverFit = true; // true = Isi Penuh (Cover), false = Tampil Utuh (Contain)
  bool _isProcessingImage = false;
  bool _showQuickSymbols = false;

  static const List<String> _suggestedTags = [
    '#lifestyle',
    '#coffeetime',
    '#jakarta',
    '#sudutkota',
  ];

  // Karakter BMP 3-byte yang aman untuk charset database MySQL utf8
  static const List<String> _quickSymbols = [
    '☺',
    '♥',
    '★',
    '✨',
    '☕',
    '♪',
  ];

  double get _selectedAspectRatio {
    switch (_selectedRatioKey) {
      case '1:1':
        return 1.0;
      case '16:9':
        return 16 / 9;
      case '4:5':
      default:
        return 4 / 5;
    }
  }

  @override
  void initState() {
    super.initState();
    _isHighlight = widget.initialHighlightMode;
    _captionController.addListener(() {
      if (mounted) setState(() {});
    });
    _highlightTitleController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    _highlightTitleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _activeSourceTab = source == ImageSource.camera ? 'camera' : 'gallery';
    });

    final image = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();
    final fileSize = bytes.lengthInBytes;

    if (fileSize > 5 * 1024 * 1024) {
      if (!mounted) return;
      setState(() {
        _localError = 'Ukuran gambar maksimal 5MB.';
      });
      return;
    }

    setState(() {
      _pickedHistory.insert(0, _PickedPhotoItem(file: image, bytes: bytes));
      _selectedImage = image;
      _selectedImageBytes = bytes;
      _rotationTurns = 0;
      _localError = null;
    });
  }

  void _selectFromHistory(_PickedPhotoItem item) {
    setState(() {
      _selectedImage = item.file;
      _selectedImageBytes = item.bytes;
      _rotationTurns = 0;
      _localError = null;
    });
  }

  void _rotatePhoto() {
    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih foto terlebih dahulu untuk memutar gambar.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _rotationTurns = (_rotationTurns + 1) % 4;
    });
  }

  void _toggleFitMode() {
    if (_selectedImageBytes == null) {
      _pickImage(ImageSource.gallery);
      return;
    }

    setState(() {
      _isCoverFit = !_isCoverFit;
    });
  }

  void _insertTextIntoCaption(String insertion) {
    final text = _captionController.text;
    final selection = _captionController.selection;
    final int start = selection.isValid ? selection.start : text.length;
    final int end = selection.isValid ? selection.end : text.length;

    final updated = text.replaceRange(start, end, insertion);
    if (updated.length > 500) return;

    _captionController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + insertion.length),
    );
  }

  void _insertSuggestedTag(String tag) {
    final current = _captionController.text;
    if (current.contains(tag)) return;
    final trimmed = current.trimRight();
    final next = trimmed.isEmpty ? tag : '$trimmed $tag';
    if (next.length > 500) return;

    _captionController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  /// Merender hasil rotasi (0°/90°/180°/270°) & penyesuaian rasio/ukuran foto (1:1, 4:5, 16:9)
  /// menjadi bytes gambar PNG baru sehingga foto yang terunggah persis dengan pratinjau.
  Future<Uint8List?> _renderEditedImageBytes(Uint8List sourceBytes) async {
    ui.Codec? codec;
    ui.Image? srcImage;
    try {
      codec = await ui.instantiateImageCodec(sourceBytes);
      final frame = await codec.getNextFrame();
      srcImage = frame.image;

      final double srcW = srcImage.width.toDouble();
      final double srcH = srcImage.height.toDouble();
      final int turns = _rotationTurns % 4;

      final double effW = (turns % 2 == 0) ? srcW : srcH;
      final double effH = (turns % 2 == 0) ? srcH : srcW;
      final double targetRatio = _selectedAspectRatio;

      const List<int> candidateWidths = [1080, 840, 640, 480];

      for (final maxW in candidateWidths) {
        final double clampedW = math.min(maxW.toDouble(), math.max(effW, 600.0));
        final int outW = clampedW.round().clamp(320, maxW);
        final int outH = (outW / targetRatio).round().clamp(180, 1920);

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        // Latar gelap agar tepi mode 'Tampil Utuh' menyatu dengan pratinjau
        canvas.drawRect(
          ui.Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
          ui.Paint()..color = AppColors.onSurface,
        );

        final double scaleX = outW / effW;
        final double scaleY = outH / effH;
        final double scale = _isCoverFit
            ? math.max(scaleX, scaleY)
            : math.min(scaleX, scaleY);

        canvas.save();
        canvas.translate(outW / 2.0, outH / 2.0);
        canvas.rotate(turns * math.pi / 2.0);
        canvas.scale(scale, scale);

        final paint = ui.Paint()..filterQuality = ui.FilterQuality.high;
        canvas.drawImage(
          srcImage,
          ui.Offset(-srcW / 2.0, -srcH / 2.0),
          paint,
        );
        canvas.restore();

        final picture = recorder.endRecording();
        final outImage = await picture.toImage(outW, outH);
        final byteData =
            await outImage.toByteData(format: ui.ImageByteFormat.png);
        outImage.dispose();
        picture.dispose();

        if (byteData != null) {
          final result = byteData.buffer.asUint8List();
          if (result.lengthInBytes <= 4500000 || maxW == candidateWidths.last) {
            return result;
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      srcImage?.dispose();
      codec?.dispose();
    }
  }

  Future<void> _handleShare() async {
    if (_selectedImage == null || _selectedImageBytes == null) {
      setState(() {
        _localError =
            'Pilih foto terlebih dahulu sebelum menerbitkan postingan.';
      });
      return;
    }

    final highlightTitle = _highlightTitleController.text.trim();
    if (_isHighlight && highlightTitle.isEmpty) {
      setState(() {
        _localError = 'Masukkan judul sorotan profil terlebih dahulu.';
      });
      return;
    }

    final currentUser = context.read<LoginViewModel>().user;
    if (currentUser == null) {
      setState(() {
        _localError = 'Sesi akun tidak ditemukan. Silakan masuk kembali.';
      });
      return;
    }

    setState(() {
      _localError = null;
      _isProcessingImage = true;
    });

    Uint8List uploadBytes = _selectedImageBytes!;
    String uploadFileName = _selectedImage!.name;

    final renderedBytes = await _renderEditedImageBytes(_selectedImageBytes!);
    if (renderedBytes != null && renderedBytes.isNotEmpty) {
      uploadBytes = renderedBytes;
      uploadFileName = 'post_${DateTime.now().millisecondsSinceEpoch}.png';
    }

    if (!mounted) return;
    setState(() => _isProcessingImage = false);

    final userId = int.tryParse(currentUser.id) ?? 0;
    final profileVm = context.read<ProfileViewModel>();

    final success = await context.read<CreatePostViewModel>().createPost(
          userId: userId,
          imagePath: _selectedImage!.path,
          imageBytes: uploadBytes,
          fileName: uploadFileName,
          caption: _captionController.text.trim(),
          isHighlight: _isHighlight,
          highlightTitle: highlightTitle,
        );

    if (!mounted) return;

    if (success) {
      if (userId > 0) {
        profileVm.fetchProfile(userId, viewerId: userId);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isHighlight
                ? 'Postingan & Sorotan "$highlightTitle" berhasil diposting.'
                : 'Postingan baru berhasil diposting.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } else {
      final error = context.read<CreatePostViewModel>().errorMessage;
      setState(() {
        _localError = error ?? 'Gagal menerbitkan postingan.';
      });
    }
  }

  String _getInitials(UserModel? user) {
    final source = (user?.name.trim().isNotEmpty == true)
        ? user!.name.trim()
        : (user?.username.trim() ?? '');
    if (source.isEmpty) return 'Z';
    final parts = source.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return source[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = context.watch<CreatePostViewModel>().isLoading;
    final isBusy = isUploading || _isProcessingImage;
    final currentUser = context.watch<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    final existingHighlights = context
            .watch<ProfileViewModel>()
            .getProfile(currentUserId)
            ?.highlights ??
        [];
    final avatarUrl = ApiConstants.getImageUrl(currentUser?.avatar);
    final username = currentUser?.username.isNotEmpty == true
        ? currentUser!.username
        : 'pengguna';
    final fullName = currentUser?.name.isNotEmpty == true
        ? currentUser!.name
        : 'Kreator ZieSocial';

    final String? selectedExistingHighlightCover = () {
      final title = _highlightTitleController.text.trim().toLowerCase();
      if (title.isEmpty) return null;
      for (final hl in existingHighlights) {
        if (hl.title.trim().toLowerCase() == title) {
          return ApiConstants.getImageUrl(hl.coverImage);
        }
      }
      return null;
    }();

    final bool isCreatingNewHighlight = !existingHighlights.any(
      (hl) =>
          hl.title.trim().toLowerCase() ==
          _highlightTitleController.text.trim().toLowerCase(),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.85),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap:
                                isBusy ? null : () => Navigator.pop(context),
                            customBorder: const CircleBorder(),
                            child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(
                                Icons.close_rounded,
                                size: 24,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Buat Postingan',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 16,
                              height: 24 / 16,
                              letterSpacing: -0.16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: isBusy ? null : _handleShare,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: Colors.white,
                              elevation: 1,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isBusy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Posting',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Segmented Source Mode Bar (Galeri | Kamera)
                  Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 320),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildSourceSegmentButton(
                                label: 'Galeri',
                                icon: Icons.photo_library_outlined,
                                activeIcon: Icons.photo_library,
                                isActive: _activeSourceTab == 'gallery',
                                onTap: () => _pickImage(ImageSource.gallery),
                              ),
                            ),
                            Expanded(
                              child: _buildSourceSegmentButton(
                                label: 'Kamera',
                                icon: Icons.photo_camera_outlined,
                                activeIcon: Icons.photo_camera,
                                isActive: _activeSourceTab == 'camera',
                                onTap: () => _pickImage(ImageSource.camera),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. Primary Media Stage (Interactive Preview + Ratio + Rotate)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: _selectedAspectRatio,
                      end: _selectedAspectRatio,
                    ),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    builder: (context, ratio, _) {
                      return AspectRatio(
                        aspectRatio: ratio,
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: AppColors.onSurface,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (_selectedImageBytes != null)
                                SizedBox.expand(
                                  child: RotatedBox(
                                    quarterTurns: _rotationTurns,
                                    child: Image.memory(
                                      _selectedImageBytes!,
                                      fit: _isCoverFit
                                          ? BoxFit.cover
                                          : BoxFit.contain,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                )
                              else
                                InkWell(
                                  onTap: () => _pickImage(ImageSource.gallery),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.10),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withValues(alpha: 0.18),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.add_photo_alternate_outlined,
                                              size: 30,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const Gap(14),
                                          const Text(
                                            'Pilih Foto Postingan',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const Gap(4),
                                          const Text(
                                            'Ketuk di sini atau pilih dari Galeri / Kamera (maks. 5MB)',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontSize: 12,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                              // Top-Right Mode Badge (jika gambar dipilih)
                              if (_selectedImageBytes != null)
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.50),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _isCoverFit
                                          ? 'Penuh ($_selectedRatioKey)'
                                          : 'Utuh ($_selectedRatioKey)',
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                              // Bottom Overlay Controls: Ratio Selector (kiri) + Rotate & Fit (kanan)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    28,
                                    16,
                                    16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.62),
                                        Colors.black.withValues(alpha: 0.20),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Aspect Ratio Pills (1:1 | 4:5 | 16:9)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.42),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildRatioPill('1:1'),
                                            const Gap(4),
                                            _buildRatioPill('4:5'),
                                            const Gap(4),
                                            _buildRatioPill('16:9'),
                                          ],
                                        ),
                                      ),

                                      // Rotate Photo & Adjust Fit/Crop Buttons
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildStageActionButton(
                                            icon: Icons.crop_rotate_rounded,
                                            tooltip: 'Putar Foto 90°',
                                            isHighlighted: _rotationTurns != 0,
                                            onTap: _rotatePhoto,
                                          ),
                                          const Gap(6),
                                          _buildStageActionButton(
                                            icon: Icons.layers_outlined,
                                            tooltip: _isCoverFit
                                                ? 'Mode Tampil Utuh (Tanpa Terpotong)'
                                                : 'Mode Isi Penuh Sesuai Rasio',
                                            isHighlighted: !_isCoverFit,
                                            onTap: _toggleFitMode,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // 3. Gallery Thumbnails Strip
                  Container(
                    color: AppColors.surfaceContainerLow,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      height: 64,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // Camera Quick Tile
                          InkWell(
                            onTap: () => _pickImage(ImageSource.camera),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.photo_camera_outlined,
                                    size: 22,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  Gap(3),
                                  Text(
                                    'Kamera',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Gap(8),

                          // Picked Thumbnails (or slot prompt if none yet)
                          if (_pickedHistory.isEmpty)
                            InkWell(
                              onTap: () => _pickImage(ImageSource.gallery),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 22,
                                      color: AppColors.primary,
                                    ),
                                    Gap(2),
                                    Text(
                                      'Pilih',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...List.generate(_pickedHistory.length, (index) {
                              final item = _pickedHistory[index];
                              final bool isSelected =
                                  identical(item.bytes, _selectedImageBytes);

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => _selectFromHistory(item),
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: isSelected
                                          ? Border.all(
                                              color: AppColors.primary,
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Opacity(
                                          opacity: isSelected ? 1.0 : 0.85,
                                          child: RotatedBox(
                                            quarterTurns:
                                                isSelected ? _rotationTurns : 0,
                                            child: Image.memory(
                                              item.bytes,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: Container(
                                              width: 16,
                                              height: 16,
                                              decoration: const BoxDecoration(
                                                color: AppColors.primary,
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                '${index + 1}',
                                                style: const TextStyle(
                                                  fontFamily:
                                                      'Plus Jakarta Sans',
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),

                        ],
                      ),
                    ),
                  ),

                  // 4. Content & Metadata Form Canvas
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_localError != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                const Gap(8),
                                Expanded(
                                  child: Text(
                                    _localError!,
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(18),
                        ],

                        // Caption & Author Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.onSurface.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Author Identity
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.secondary,
                                        ],
                                        begin: Alignment.bottomLeft,
                                        end: Alignment.topRight,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      backgroundColor:
                                          AppColors.surfaceContainerLowest,
                                      backgroundImage: avatarUrl.isNotEmpty
                                          ? NetworkImage(avatarUrl)
                                          : null,
                                      child: avatarUrl.isEmpty
                                          ? Text(
                                              _getInitials(currentUser),
                                              style: const TextStyle(
                                                fontFamily: 'Plus Jakarta Sans',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                  const Gap(10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          username,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                        Text(
                                          fullName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 12,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(10),

                              // Borderless Caption Input
                              TextField(
                                controller: _captionController,
                                minLines: 3,
                                maxLines: 6,
                                maxLength: 500,
                                buildCounter: (
                                  _, {
                                  required currentLength,
                                  required isFocused,
                                  required maxLength,
                                }) =>
                                    null,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                  height: 1.45,
                                  color: AppColors.onSurface,
                                ),
                                decoration: const InputDecoration(
                                  hintText:
                                      'Tulis caption untuk postingan Anda...',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 14,
                                    color: AppColors.outline,
                                  ),
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 6),
                                ),
                              ),
                              const Gap(6),

                              // Caption Utilities Toolbar + Counter
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      _buildCaptionToolButton(
                                        icon: Icons.sentiment_satisfied_outlined,
                                        isActive: _showQuickSymbols,
                                        onTap: () {
                                          setState(() {
                                            _showQuickSymbols =
                                                !_showQuickSymbols;
                                          });
                                        },
                                      ),
                                      const Gap(6),
                                      _buildCaptionToolButton(
                                        icon: Icons.alternate_email_rounded,
                                        onTap: () =>
                                            _insertTextIntoCaption('@'),
                                      ),
                                      const Gap(6),
                                      _buildCaptionToolButton(
                                        icon: Icons.tag_rounded,
                                        onTap: () =>
                                            _insertTextIntoCaption('#'),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${_captionController.text.length}/500',
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                      color: AppColors.outline,
                                    ),
                                  ),
                                ],
                              ),

                              if (_showQuickSymbols) ...[
                                const Gap(10),
                                Wrap(
                                  spacing: 8,
                                  children: _quickSymbols.map((sym) {
                                    return InkWell(
                                      onTap: () => _insertTextIntoCaption(sym),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 34,
                                        height: 32,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainerLow,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          sym,
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],

                              const Gap(10),

                              // Suggested Hashtags
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  const Text(
                                    'Saran:',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.outline,
                                    ),
                                  ),
                                  ..._suggestedTags.map((tag) {
                                    return InkWell(
                                      onTap: () => _insertSuggestedTag(tag),
                                      borderRadius: BorderRadius.circular(999),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainer,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          tag,
                                          style: const TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Gap(20),

                        // FITUR SOROTAN (HIGHLIGHTS SECTION)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.surfaceContainerLowest,
                                AppColors.surfaceContainerLow,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.onSurface.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Highlight Master Toggle Row
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.auto_awesome,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Gap(12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Flexible(
                                              child: Text(
                                                'Jadikan Sorotan',
                                                style: TextStyle(
                                                  fontFamily:
                                                      'Plus Jakarta Sans',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.onSurface,
                                                ),
                                              ),
                                            ),
                                            const Gap(6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    AppColors.secondaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: const Text(
                                                'POPULER',
                                                style: TextStyle(
                                                  fontFamily:
                                                      'Plus Jakarta Sans',
                                                  fontSize: 9,
                                                  letterSpacing: 0.6,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Gap(2),
                                        const Text(
                                          'Sematkan permanen di profil Anda',
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 12,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _isHighlight,
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: AppColors.primary,
                                    inactiveThumbColor: Colors.white,
                                    inactiveTrackColor:
                                        AppColors.surfaceContainerHighest,
                                    trackOutlineColor:
                                        const WidgetStatePropertyAll(
                                      Colors.transparent,
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        _isHighlight = val;
                                      });
                                    },
                                  ),
                                ],
                              ),

                              // Sorotan Interactive Sub-Menu Panel
                              if (_isHighlight) ...[
                                const Gap(16),

                                // Existing Highlight Selection Chips
                                const Text(
                                  'Pilih Album Sorotan:',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const Gap(8),
                                SizedBox(
                                  height: 36,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _highlightTitleController.clear();
                                            });
                                          },
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isCreatingNewHighlight
                                                  ? AppColors.onSurface
                                                  : AppColors
                                                      .surfaceContainerHigh,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.add_circle_outline,
                                                  size: 16,
                                                  color: isCreatingNewHighlight
                                                      ? AppColors
                                                          .surfaceContainerLowest
                                                      : AppColors.onSurface,
                                                ),
                                                const Gap(6),
                                                Text(
                                                  'Sorotan Baru',
                                                  style: TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: isCreatingNewHighlight
                                                        ? AppColors
                                                            .surfaceContainerLowest
                                                        : AppColors.onSurface,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      ...existingHighlights.map((hl) {
                                        final isSelected =
                                            _highlightTitleController.text
                                                    .trim()
                                                    .toLowerCase() ==
                                                hl.title.trim().toLowerCase();
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                _highlightTitleController.text =
                                                    hl.title;
                                              });
                                            },
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 14,
                                              ),
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppColors.onSurface
                                                    : AppColors
                                                        .surfaceContainerHigh,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                hl.title,
                                                style: TextStyle(
                                                  fontFamily:
                                                      'Plus Jakarta Sans',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected
                                                      ? AppColors
                                                          .surfaceContainerLowest
                                                      : AppColors.onSurface,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                                const Gap(16),

                                // Highlight Name Field with Cover Preview
                                const Text(
                                  'Nama Sorotan Baru',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const Gap(6),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.onSurface
                                            .withValues(alpha: 0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainerHigh,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            if (_selectedImageBytes != null)
                                              RotatedBox(
                                                quarterTurns: _rotationTurns,
                                                child: Image.memory(
                                                  _selectedImageBytes!,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            else if (selectedExistingHighlightCover !=
                                                    null &&
                                                selectedExistingHighlightCover
                                                    .isNotEmpty)
                                              Image.network(
                                                selectedExistingHighlightCover,
                                                fit: BoxFit.cover,
                                              )
                                            else
                                              const ColoredBox(
                                                color:
                                                    AppColors.primaryContainer,
                                              ),
                                            Container(
                                              color: Colors.black
                                                  .withValues(alpha: 0.35),
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.edit_outlined,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Gap(10),
                                      Expanded(
                                        child: TextField(
                                          controller: _highlightTitleController,
                                          style: const TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.onSurface,
                                          ),
                                          decoration: const InputDecoration(
                                            hintText:
                                                'Contoh: Liburan, Perjalanan, Jurnal...',
                                            hintStyle: TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.outline,
                                            ),
                                            filled: false,
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Gap(14),

                                // Microcopy Notice
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryFixed
                                        .withValues(alpha: 0.50),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      Gap(8),
                                      Expanded(
                                        child: Text(
                                          'Postingan ini akan langsung disematkan dalam lingkaran sorotan profil Anda dan dapat dilihat tanpa batas waktu 24 jam.',
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 12,
                                            height: 1.45,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Gap(20),

                        // 5. Primary CTA Anchor ("Publikasikan Postingan")
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isBusy ? null : _handleShare,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isBusy
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 17,
                                        height: 17,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Gap(10),
                                      Text(
                                        'Mengunggah Postingan...',
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send_rounded, size: 19),
                                      Gap(8),
                                      Text(
                                        'Publikasikan Postingan',
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const Gap(8),
                        const Text(
                          'Dengan membagikan, Anda menyetujui Ketentuan Komunitas Ziesocial.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            color: AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceSegmentButton({
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
        decoration: BoxDecoration(
          color:
              isActive ? AppColors.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.onSurface.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 18,
              color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            const Gap(6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? AppColors.onSurface
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatioPill(String label) {
    final bool isSelected = _selectedRatioKey == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRatioKey = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? AppColors.onSurface
                : Colors.white.withValues(alpha: 0.78),
          ),
        ),
      ),
    );
  }

  Widget _buildStageActionButton({
    required IconData icon,
    required String tooltip,
    required bool isHighlighted,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isHighlighted
            ? AppColors.primaryContainer
            : Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptionToolButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: isActive
          ? AppColors.surfaceContainer
          : AppColors.surfaceContainerLow,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 18,
            color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
