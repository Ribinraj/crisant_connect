import 'package:crisant_connect/core/colors.dart';
import 'package:crisant_connect/core/constants.dart';
import 'package:crisant_connect/core/responsiveutils.dart';
import 'package:crisant_connect/core/urls.dart';
import 'package:crisant_connect/features/gallery/blocs/media_library_bloc/media_library_bloc.dart';
import 'package:crisant_connect/features/gallery/models/uploads_response.dart';
import 'package:crisant_connect/features/posts/blocs/clients_bloc/clients_bloc.dart';
import 'package:crisant_connect/features/posts/blocs/create_post_bloc/create_post_bloc.dart';
import 'package:crisant_connect/features/posts/blocs/post_mutation_bloc/post_mutation_bloc.dart';
import 'package:crisant_connect/features/posts/models/clients_response.dart';
import 'package:crisant_connect/features/posts/models/create_post_models.dart';
import 'package:crisant_connect/features/posts/models/posts_list_response.dart';
import 'package:crisant_connect/widgets/app_background.dart';
import 'package:crisant_connect/widgets/crisant_app_bar.dart';
import 'package:crisant_connect/widgets/custom_snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class ScreenCreatePost extends StatefulWidget {
  final bool isActive;
  final PostListItem? initialPost;

  const ScreenCreatePost({super.key, this.isActive = false, this.initialPost});

  @override
  State<ScreenCreatePost> createState() => _ScreenCreatePostState();
}

class _ScreenCreatePostState extends State<ScreenCreatePost> {
  static String _initialDateText() {
    final nextHour = DateTime.now().add(const Duration(hours: 1));
    return '${nextHour.month.toString().padLeft(2, '0')}/'
        '${nextHour.day.toString().padLeft(2, '0')}/${nextHour.year}';
  }

  static String _initialTimeText() {
    final nextHour = DateTime.now().add(const Duration(hours: 1));
    final hourOfPeriod = nextHour.hour % 12 == 0 ? 12 : nextHour.hour % 12;
    final minute = nextHour.minute.toString().padLeft(2, '0');
    final period = nextHour.hour >= 12 ? 'PM' : 'AM';
    return '$hourOfPeriod:$minute $period';
  }

  int? _selectedClientId;
  int _selectedContentType = 0; // 0=Post, 1=Story, 2=Reel
  bool _clientsRequested = false;

  final List<String> _contentTypes = ['Post', 'Story', 'Reel'];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(
    text: _initialDateText(),
  );
  final TextEditingController _timeController = TextEditingController(
    text: _initialTimeText(),
  );
  final ImagePicker _imagePicker = ImagePicker();
  final List<_SelectedCreative> _selectedCreatives = [];

  bool get _isEditing => widget.initialPost != null;

  @override
  void dispose() {
    _titleController.removeListener(_handleFormChanged);
    _captionController.removeListener(_handleFormChanged);
    _dateController.removeListener(_handleFormChanged);
    _timeController.removeListener(_handleFormChanged);
    _titleController.dispose();
    _captionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_handleFormChanged);
    _captionController.addListener(_handleFormChanged);
    _dateController.addListener(_handleFormChanged);
    _timeController.addListener(_handleFormChanged);
    _applyInitialPost(widget.initialPost);
    _requestClientsIfActive();
  }

  @override
  void didUpdateWidget(covariant ScreenCreatePost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPost?.id != widget.initialPost?.id) {
      _applyInitialPost(widget.initialPost);
    }
    _requestClientsIfActive();
  }

  void _applyInitialPost(PostListItem? post) {
    if (post == null) return;

    _selectedClientId = post.clientId > 0 ? post.clientId : null;
    final contentTypeIndex = _contentTypes.indexWhere(
      (type) => type.toLowerCase() == post.contentType.toLowerCase(),
    );
    _selectedContentType = contentTypeIndex == -1 ? 0 : contentTypeIndex;
    _titleController.text = post.title;
    _captionController.text = post.caption;

    final scheduledAt = post.scheduledFor ?? post.createdAt;
    if (scheduledAt != null) {
      _dateController.text = _formatUiDate(scheduledAt.toLocal());
      _timeController.text = _formatUiTime(scheduledAt.toLocal());
    }

    _selectedCreatives
      ..clear()
      ..addAll(_creativesFromPost(post));

    if (mounted) setState(() {});
  }

  void _requestClientsIfActive() {
    if (!widget.isActive || _clientsRequested) return;
    _clientsRequested = true;
    context.read<ClientsBloc>().add(FetchClientsRequested());
  }

  void _handleFormChanged() {
    if (mounted) setState(() {});
  }

  void _resetForm() {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedClientId = null;
      _selectedContentType = 0;
      _selectedCreatives.clear();
      _titleController.text = '';
      _captionController.text = '';
      _dateController.text = _initialDateText();
      _timeController.text = _initialTimeText();
    });
  }

  List<_SelectedCreative> _creativesFromPost(PostListItem post) {
    if (post.mediaItems.isNotEmpty) {
      return post.mediaItems.map(_SelectedCreative.fromPostMediaItem).toList();
    }

    if (post.mediaUrl.trim().isEmpty) return const [];

    return [
      _SelectedCreative.fromPostValues(
        name: post.mediaUrl.trim().split('/').last,
        mediaKind: post.mediaKind,
        mediaSource: post.mediaSource,
        mediaUrl: post.mediaUrl,
        driveFileUrl: '',
        driveFileName: '',
      ),
    ];
  }

  ClientModel? _selectedClientFromState(ClientsState state) {
    if (state is! ClientsSuccess || _selectedClientId == null) return null;
    for (final client in state.clients) {
      if (client.id == _selectedClientId) return client;
    }
    return null;
  }

  String get _selectedContentTypeValue =>
      _contentTypes[_selectedContentType].toLowerCase();

  String get _selectedContentTypeLabel => _contentTypes[_selectedContentType];

  void _submitPost() {
    final clientsState = context.read<ClientsBloc>().state;
    final selectedClient = _selectedClientFromState(clientsState);
    final initialPost = widget.initialPost;
    final title = _titleController.text.trim();
    final caption = _captionController.text.trim();
    final scheduledAt = _parseScheduledDateTime();
    final clientId =
        selectedClient?.id ?? (_isEditing ? initialPost?.clientId : null);

    if (clientId == null || clientId <= 0) {
      _showSnack('Please select a client', type: SnackbarType.warning);
      return;
    }
    if (title.isEmpty) {
      _showSnack('Please enter a title', type: SnackbarType.warning);
      return;
    }
    if (caption.isEmpty) {
      _showSnack('Please enter a caption', type: SnackbarType.warning);
      return;
    }
    if (scheduledAt == null) {
      _showSnack(
        'Please select a valid schedule date and time',
        type: SnackbarType.warning,
      );
      return;
    }
    if (_selectedCreatives.isEmpty) {
      _showSnack(
        'Please choose at least one creative',
        type: SnackbarType.warning,
      );
      return;
    }

    final selectedClientSocialAccountIds = selectedClient == null
        ? const <int>[]
        : <int>[
            selectedClient.facebookSocialAccountId,
            selectedClient.instagramSocialAccountId,
          ].where((id) => id > 0).toList();
    final socialAccountIds = selectedClientSocialAccountIds.isEmpty
        ? _socialAccountIdsFromPost(initialPost)
        : selectedClientSocialAccountIds;

    if (socialAccountIds.isEmpty) {
      _showSnack(
        'Selected client has no connected social accounts',
        type: SnackbarType.warning,
      );
      return;
    }

    final firstCreative = _selectedCreatives.first;
    final mediaItems = _selectedCreatives.map(_mediaItemFromCreative).toList();
    final request = CreatePostRequest(
      clientId: clientId,
      title: title,
      caption: caption,
      scheduledFor: _formatApiDateTime(scheduledAt),
      contentType: _selectedContentTypeValue,
      mediaKind: _mediaKindForCreative(firstCreative),
      mediaSource: _mediaSourceForCreative(firstCreative),
      mediaUrl: _mediaUrlForCreative(firstCreative),
      driveFileUrl: _driveFileUrlForCreative(firstCreative),
      driveFileName: _driveFileNameForCreative(firstCreative),
      reelThumbnailMode: 'upload',
      reelThumbnailUrl: '',
      reelThumbnailOffsetMs: 0,
      mediaItems: mediaItems,
      socialAccountIds: socialAccountIds,
    );

    if (_isEditing) {
      context.read<PostMutationBloc>().add(
        EditPostSubmitted(postId: widget.initialPost!.id, request: request),
      );
      return;
    }

    context.read<CreatePostBloc>().add(CreatePostSubmitted(request: request));
  }

  List<int> _socialAccountIdsFromPost(PostListItem? post) {
    if (post == null) return const [];

    return post.targets
        .map((target) => target.socialAccountId)
        .where((id) => id > 0)
        .toSet()
        .toList();
  }

  CreatePostMediaItem _mediaItemFromCreative(_SelectedCreative creative) {
    return CreatePostMediaItem(
      mediaKind: _mediaKindForCreative(creative),
      mediaSource: _mediaSourceForCreative(creative),
      mediaUrl: _mediaUrlForCreative(creative),
      driveFileUrl: _driveFileUrlForCreative(creative),
      driveFileName: _driveFileNameForCreative(creative),
    );
  }

  String _mediaKindForCreative(_SelectedCreative creative) {
    if (creative.apiMediaKind.trim().isNotEmpty) return creative.apiMediaKind;
    return creative.isVideo ? 'video' : 'image';
  }

  String _mediaSourceForCreative(_SelectedCreative creative) {
    if (creative.apiMediaSource.trim().isNotEmpty) {
      return creative.apiMediaSource;
    }
    return creative.sourceLabel == 'Google Drive' ? 'drive' : 'upload';
  }

  String _mediaUrlForCreative(_SelectedCreative creative) {
    if (creative.apiMediaUrl.trim().isNotEmpty) return creative.apiMediaUrl;
    return creative.mediaAsset?.url ?? creative.path;
  }

  String _driveFileUrlForCreative(_SelectedCreative creative) {
    if (creative.apiDriveFileUrl.trim().isNotEmpty) {
      return creative.apiDriveFileUrl;
    }
    return creative.sourceLabel == 'Google Drive' ? creative.path : '';
  }

  String _driveFileNameForCreative(_SelectedCreative creative) {
    if (creative.apiDriveFileName.trim().isNotEmpty) {
      return creative.apiDriveFileName;
    }
    return creative.sourceLabel == 'Google Drive' ? creative.name : '';
  }

  DateTime? _parseScheduledDateTime() {
    final dateParts = _dateController.text.trim().split('/');
    final timeMatch = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(_timeController.text.trim());

    if (dateParts.length != 3 || timeMatch == null) return null;

    final month = int.tryParse(dateParts[0]);
    final day = int.tryParse(dateParts[1]);
    final year = int.tryParse(dateParts[2]);
    final minute = int.tryParse(timeMatch.group(2)!);
    var hour = int.tryParse(timeMatch.group(1)!);
    final period = timeMatch.group(3)!.toUpperCase();

    if (month == null ||
        day == null ||
        year == null ||
        hour == null ||
        minute == null ||
        hour < 1 ||
        hour > 12 ||
        minute > 59) {
      return null;
    }

    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    final scheduledAt = DateTime(year, month, day, hour, minute);
    if (scheduledAt.year != year ||
        scheduledAt.month != month ||
        scheduledAt.day != day) {
      return null;
    }

    return scheduledAt;
  }

  String _formatApiDateTime(DateTime dateTime) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${dateTime.year}-${two(dateTime.month)}-${two(dateTime.day)} '
        '${two(dateTime.hour)}:${two(dateTime.minute)}:${two(dateTime.second)}';
  }

  String _formatUiDate(DateTime dateTime) {
    return '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  String _formatUiTime(DateTime dateTime) {
    final hourOfPeriod = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hourOfPeriod:$minute $period';
  }

  Future<void> _openCreativeSourceSheet() async {
    final source = await showModalBottomSheet<_CreativeSourceAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreativeSourceSheet(
        options: [
          _CreativeSourceOption(
            action: _CreativeSourceAction.uploadCreative,
            icon: Icons.cloud_upload_rounded,
            title: 'Upload creative',
            subtitle: 'Select from mobile gallery',
          ),
          _CreativeSourceOption(
            action: _CreativeSourceAction.pickFromGallery,
            icon: Icons.photo_library_rounded,
            title: 'Pick from gallery',
            subtitle: 'Use uploaded assets from media library',
          ),
          _CreativeSourceOption(
            action: _CreativeSourceAction.pickFromGoogleDrive,
            icon: Icons.add_to_drive_rounded,
            title: 'Pick from Google Drive',
            subtitle: 'Choose Drive files from the file picker',
          ),
        ],
      ),
    );

    if (!mounted || source == null) return;

    switch (source) {
      case _CreativeSourceAction.uploadCreative:
        await _pickFromMobileGallery();
      case _CreativeSourceAction.pickFromGallery:
        await _openGalleryPicker();
      case _CreativeSourceAction.pickFromGoogleDrive:
        await _pickFromDrive();
    }
  }

  Future<void> _pickFromMobileGallery() async {
    final files = await _imagePicker.pickMultipleMedia();
    if (!mounted || files.isEmpty) return;

    setState(() {
      _selectedCreatives.addAll(
        files.map(
          (file) => _SelectedCreative.local(
            name: file.name,
            sourceLabel: 'Mobile gallery',
            path: file.path,
          ),
        ),
      );
    });
    _showSnack(
      '${files.length} creative file(s) selected',
      type: SnackbarType.success,
    );
  }

  Future<void> _pickFromDrive() async {
    final result = await FilePicker.pickFiles(
      type: FileType.media,
      allowMultiple: true,
      withData: false,
    );
    if (!mounted || result == null || result.files.isEmpty) return;

    setState(() {
      _selectedCreatives.addAll(
        result.files.map(
          (file) => _SelectedCreative.local(
            name: file.name,
            sourceLabel: 'Google Drive',
            path: file.path ?? '',
          ),
        ),
      );
    });
    _showSnack(
      '${result.files.length} Drive file(s) selected',
      type: SnackbarType.success,
    );
  }

  Future<void> _openGalleryPicker() async {
    context.read<MediaLibraryBloc>().add(FetchMediaLibraryRequested());
    final selected = await showModalBottomSheet<List<MediaAsset>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<MediaLibraryBloc>(),
        child: _GalleryPickerSheet(
          initiallySelectedIds: _selectedCreatives
              .map((creative) => creative.mediaAsset?.id)
              .whereType<int>()
              .toSet(),
        ),
      ),
    );

    if (!mounted || selected == null || selected.isEmpty) return;

    setState(() {
      final existingIds = _selectedCreatives
          .map((creative) => creative.mediaAsset?.id)
          .whereType<int>()
          .toSet();
      _selectedCreatives.addAll(
        selected
            .where((asset) => !existingIds.contains(asset.id))
            .map(_SelectedCreative.fromMediaAsset),
      );
    });
    _showSnack(
      '${selected.length} gallery asset(s) selected',
      type: SnackbarType.success,
    );
  }

  void _removeCreative(_SelectedCreative creative) {
    setState(() => _selectedCreatives.remove(creative));
  }

  void _showSnack(String message, {SnackbarType type = SnackbarType.error}) {
    CustomSnackbar.show(context, message: message, type: type);
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils().init(context);
    final selectedClient = _selectedClientFromState(
      context.watch<ClientsBloc>().state,
    );

    return MultiBlocListener(
      listeners: [
        BlocListener<CreatePostBloc, CreatePostState>(
          listener: (context, state) {
            if (state is CreatePostSuccess) {
              _resetForm();
              _showSnack(
                state.post.id > 0
                    ? '${state.message} (#${state.post.id})'
                    : state.message,
                type: SnackbarType.success,
              );
            } else if (state is CreatePostFailure) {
              _showSnack(state.message, type: SnackbarType.error);
            }
          },
        ),
        BlocListener<PostMutationBloc, PostMutationState>(
          listener: (context, state) {
            if (!_isEditing) return;

            if (state is EditPostSuccess) {
              _showSnack(state.message, type: SnackbarType.success);
              Navigator.of(context).pop(true);
            } else if (state is PostMutationFailure &&
                state.action == PostMutationAction.edit &&
                state.postId == widget.initialPost?.id) {
              _showSnack(state.message, type: SnackbarType.error);
            }
          },
        ),
      ],
      child: Material(
        color: Colors.transparent,
        child: AppBackground(
          opacity: 0.35,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const CrisantAppBar(),
                if (_isEditing) const _EditPostBackHeader(),
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          ResponsiveUtils.wp(4.6),
                          ResponsiveUtils.hp(2.2),
                          ResponsiveUtils.wp(4.6),
                          ResponsiveUtils.hp(15),
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PostIntroCard(isEditing: _isEditing),
                              SizedBox(height: ResponsiveUtils.hp(2.4)),

                              // ── Section label
                              _FieldLabel('SELECT CLIENT'),
                              ResponsiveSizedBox.height5,
                              BlocBuilder<ClientsBloc, ClientsState>(
                                builder: (context, state) {
                                  final clients = state is ClientsSuccess
                                      ? state.clients
                                      : const <ClientModel>[];
                                  final selectedValue =
                                      clients.any(
                                        (client) =>
                                            client.id == _selectedClientId,
                                      )
                                      ? _selectedClientId
                                      : null;

                                  return _ClientDropdown(
                                    value: selectedValue,
                                    clients: clients,
                                    isLoading: state is ClientsLoading,
                                    errorMessage: state is ClientsFailure
                                        ? state.message
                                        : null,
                                    onRetry: () => context
                                        .read<ClientsBloc>()
                                        .add(FetchClientsRequested()),
                                    onChanged: (val) {
                                      setState(() => _selectedClientId = val);
                                    },
                                  );
                                },
                              ),
                              SizedBox(height: ResponsiveUtils.hp(2.4)),

                              // ── Scheduled Time
                              _FieldLabel('SCHEDULED TIME'),
                              ResponsiveSizedBox.height5,
                              Row(
                                children: [
                                  Expanded(
                                    child: _DatePickerField(
                                      controller: _dateController,
                                      hint: 'MM/DD/YYYY',
                                      icon: Icons.calendar_today_rounded,
                                    ),
                                  ),
                                  SizedBox(width: ResponsiveUtils.wp(3)),
                                  Expanded(
                                    child: _TimePickerField(
                                      controller: _timeController,
                                      hint: 'HH:MM AM',
                                      icon: Icons.access_time_rounded,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: ResponsiveUtils.hp(2.4)),

                              // ── Title
                              _FieldLabel('TITLE'),
                              ResponsiveSizedBox.height5,
                              _StyledTextField(
                                controller: _titleController,
                                hint: 'Craft your title here...',
                              ),
                              SizedBox(height: ResponsiveUtils.hp(2.4)),

                              // ── Caption
                              _FieldLabel('CAPTION'),
                              ResponsiveSizedBox.height5,
                              _StyledTextField(
                                controller: _captionController,
                                hint: 'Craft your message here...',
                                maxLines: 4,
                              ),
                              SizedBox(height: ResponsiveUtils.hp(2.8)),

                              // ── Content Type & Creative Source Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _FieldLabel('CONTENT TYPE'),
                                        ResponsiveSizedBox.height5,
                                        Wrap(
                                          spacing: ResponsiveUtils.wp(2),
                                          runSpacing: ResponsiveUtils.hp(0.8),
                                          children: List.generate(
                                            _contentTypes.length,
                                            (i) => _ContentTypeChip(
                                              label: _contentTypes[i],
                                              isSelected:
                                                  _selectedContentType == i,
                                              onTap: () => setState(
                                                () => _selectedContentType = i,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: ResponsiveUtils.wp(4)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _FieldLabel('CREATIVE SOURCE'),
                                        ResponsiveSizedBox.height5,
                                        _UploadButton(
                                          selectedCount:
                                              _selectedCreatives.length,
                                          onTap: _openCreativeSourceSheet,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (_selectedCreatives.isNotEmpty) ...[
                                SizedBox(height: ResponsiveUtils.hp(1.6)),
                                _SelectedCreativesWrap(
                                  creatives: _selectedCreatives,
                                  onRemove: _removeCreative,
                                ),
                              ],
                              SizedBox(height: ResponsiveUtils.hp(2.8)),

                              // ── Social Preview
                              _FieldLabel('SOCIAL PREVIEW'),
                              ResponsiveSizedBox.height10,
                              _SocialPreviewCard(
                                creatives: _selectedCreatives,
                                title: _titleController.text.trim(),
                                caption: _captionController.text.trim(),
                                client: selectedClient,
                                contentType: _selectedContentTypeLabel,
                                scheduledFor:
                                    '${_dateController.text.trim()} ${_timeController.text.trim()}',
                              ),
                              SizedBox(height: ResponsiveUtils.hp(3.2)),

                              // ── Review & Submit Button
                              BlocBuilder<CreatePostBloc, CreatePostState>(
                                builder: (context, createState) {
                                  return BlocBuilder<
                                    PostMutationBloc,
                                    PostMutationState
                                  >(
                                    builder: (context, mutationState) {
                                      final isCreating =
                                          createState is CreatePostLoading;
                                      final isEditing =
                                          mutationState is EditPostLoading &&
                                          mutationState.postId ==
                                              widget.initialPost?.id;
                                      final isLoading = isCreating || isEditing;
                                      return _ReviewSubmitButton(
                                        label: _isEditing
                                            ? 'Update Post'
                                            : 'Review & Submit',
                                        isLoading: isLoading,
                                        onTap: isLoading ? null : _submitPost,
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
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
    );
  }
}

class _EditPostBackHeader extends StatelessWidget {
  const _EditPostBackHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.wp(3.2),
        ResponsiveUtils.hp(0.8),
        ResponsiveUtils.wp(4.6),
        ResponsiveUtils.hp(0.8),
      ),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.9),
        border: const Border(top: BorderSide(color: Color(0xFFF0E6E2))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Back',
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF071426),
            ),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Update Post',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF071426),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Intro Card ──────────────────────────────────────────────────────────────

class _PostIntroCard extends StatelessWidget {
  final bool isEditing;

  const _PostIntroCard({required this.isEditing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.wp(5),
        ResponsiveUtils.hp(2.2),
        ResponsiveUtils.wp(5),
        ResponsiveUtils.hp(2.4),
      ),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Appcolors.kblackcolor.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditing
                ? 'Edit scheduled\nclient content'
                : 'Create content for\nassigned clients',
            style: TextStyle(
              color: const Color(0xFF0C1116),
              fontSize: ResponsiveUtils.sp(6.2).clamp(22, 26).toDouble(),
              fontWeight: FontWeight.w800,
              height: 1.22,
            ),
          ),
          SizedBox(height: ResponsiveUtils.hp(0.6)),
          Text(
            isEditing
                ? 'Update copy, timing, and creative assets\nbefore this post goes live.'
                : 'Draft, schedule, and preview your creative\nassets across multiple platforms.',
            style: TextStyle(
              color: const Color(0xFF7A6C66),
              fontSize: ResponsiveUtils.sp(3.8).clamp(13, 15).toDouble(),
              fontWeight: FontWeight.w400,
              height: 1.48,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Field Label ─────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: const Color(0xFF7A6C66),
        fontSize: ResponsiveUtils.sp(3.2).clamp(10, 12).toDouble(),
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
      ),
    );
  }
}

// ─── Client Dropdown ─────────────────────────────────────────────────────────

class _ClientDropdown extends StatelessWidget {
  final int? value;
  final List<ClientModel> clients;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final ValueChanged<int?> onChanged;

  const _ClientDropdown({
    required this.value,
    required this.clients,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.wp(4).clamp(14, 18).toDouble(),
          vertical: ResponsiveUtils.hp(1.4).clamp(10, 14).toDouble(),
        ),
        decoration: _dropdownDecoration,
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Appcolors.kredcolor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                errorMessage!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF1A2028),
                  fontSize: ResponsiveUtils.sp(3.7).clamp(13, 15).toDouble(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Container(
      decoration: _dropdownDecoration,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          hint: Text(
            isLoading
                ? 'Loading clients...'
                : clients.isEmpty
                ? 'No clients found'
                : 'Select client',
          ),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.wp(4).clamp(14, 18).toDouble(),
            vertical: ResponsiveUtils.hp(1.6).clamp(12, 16).toDouble(),
          ),
          borderRadius: BorderRadiusStyles.kradius10(),
          style: TextStyle(
            color: const Color(0xFF1A2028),
            fontSize: ResponsiveUtils.sp(4.2).clamp(14, 16).toDouble(),
            fontWeight: FontWeight.w600,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF7A6C66),
          ),
          items: clients
              .map(
                (client) => DropdownMenuItem<int>(
                  value: client.id,
                  child: Text(
                    client.name.isEmpty ? 'Client #${client.id}' : client.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: isLoading || clients.isEmpty ? null : onChanged,
        ),
      ),
    );
  }

  BoxDecoration get _dropdownDecoration {
    return BoxDecoration(
      color: Appcolors.kwhitecolor.withValues(alpha: 0.96),
      borderRadius: BorderRadiusStyles.kradius10(),
      border: Border.all(color: const Color(0xFFE8DDD9), width: 1),
      boxShadow: [
        BoxShadow(
          color: Appcolors.kblackcolor.withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

// ─── Date Picker Field ────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  const _DatePickerField({
    required this.controller,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (ctx, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Appcolors.kprimarycolor,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          controller.text =
              '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
        }
      },
      child: AbsorbPointer(
        child: _StyledTextField(
          controller: controller,
          hint: hint,
          suffixIcon: Icon(icon, size: 18, color: const Color(0xFF7A6C66)),
        ),
      ),
    );
  }
}

// ─── Time Picker Field ────────────────────────────────────────────────────────

class _TimePickerField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  const _TimePickerField({
    required this.controller,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
          builder: (ctx, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Appcolors.kprimarycolor,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
          final minute = picked.minute.toString().padLeft(2, '0');
          final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
          controller.text = '$hour:$minute $period';
        }
      },
      child: AbsorbPointer(
        child: _StyledTextField(
          controller: controller,
          hint: hint,
          suffixIcon: Icon(icon, size: 18, color: const Color(0xFF7A6C66)),
        ),
      ),
    );
  }
}

// ─── Styled Text Field ────────────────────────────────────────────────────────

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final Widget? suffixIcon;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.96),
        borderRadius: BorderRadiusStyles.kradius10(),
        border: Border.all(color: const Color(0xFFE8DDD9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Appcolors.kblackcolor.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(
          color: const Color(0xFF1A2028),
          fontSize: ResponsiveUtils.sp(4.2).clamp(14, 16).toDouble(),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xFFB0A09C),
            fontSize: ResponsiveUtils.sp(4.2).clamp(14, 16).toDouble(),
            fontWeight: FontWeight.w400,
          ),
          suffixIcon: suffixIcon,
          contentPadding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.wp(4).clamp(14, 18).toDouble(),
            vertical: ResponsiveUtils.hp(1.6).clamp(12, 16).toDouble(),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

// ─── Content Type Chip ────────────────────────────────────────────────────────

class _ContentTypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ContentTypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.wp(4).clamp(13, 18).toDouble(),
          vertical: ResponsiveUtils.hp(0.8).clamp(6, 9).toDouble(),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Appcolors.kprimarycolor
              : Appcolors.kwhitecolor.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Appcolors.kprimarycolor
                : const Color(0xFFE8DDD9),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Appcolors.kprimarycolor.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Appcolors.kwhitecolor : const Color(0xFF5A3A33),
            fontSize: ResponsiveUtils.sp(3.8).clamp(12, 14).toDouble(),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Upload Button ────────────────────────────────────────────────────────────

class _UploadButton extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onTap;

  const _UploadButton({required this.selectedCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.wp(4).clamp(14, 18).toDouble(),
          vertical: ResponsiveUtils.hp(1.2).clamp(9, 12).toDouble(),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6F3),
          borderRadius: BorderRadiusStyles.kradius10(),
          border: Border.all(
            color: Appcolors.kprimaryLightColor.withValues(alpha: 0.6),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_rounded,
              color: Appcolors.kprimarycolor,
              size: ResponsiveUtils.wp(5).clamp(18, 22).toDouble(),
            ),
            SizedBox(width: ResponsiveUtils.wp(2)),
            Flexible(
              child: Text(
                selectedCount == 0 ? 'CHOOSE' : '$selectedCount SELECTED',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Appcolors.kprimarycolor,
                  fontSize: ResponsiveUtils.sp(3.5).clamp(11, 13).toDouble(),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedCreativesWrap extends StatelessWidget {
  final List<_SelectedCreative> creatives;
  final ValueChanged<_SelectedCreative> onRemove;

  const _SelectedCreativesWrap({
    required this.creatives,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: creatives
          .map(
            (creative) => InputChip(
              avatar: Icon(
                creative.isVideo
                    ? Icons.movie_creation_rounded
                    : Icons.image_rounded,
                color: Appcolors.kprimarycolor,
                size: 18,
              ),
              label: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  creative.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              tooltip: '${creative.sourceLabel}: ${creative.name}',
              onDeleted: () => onRemove(creative),
              backgroundColor: Appcolors.kwhitecolor.withValues(alpha: 0.96),
              deleteIconColor: const Color(0xFF7A6C66),
              side: const BorderSide(color: Color(0xFFE8DDD9)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CreativeSourceSheet extends StatelessWidget {
  final List<_CreativeSourceOption> options;

  const _CreativeSourceSheet({required this.options});

  @override
  Widget build(BuildContext context) {
    return _BottomActionShell(
      title: 'Creative source',
      maxHeightFactor: 0.64,
      child: ListView(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: options
            .map(
              (option) => _SheetActionTile(
                icon: option.icon,
                title: option.title,
                subtitle: option.subtitle,
                onTap: () => Navigator.pop(context, option.action),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _GalleryPickerSheet extends StatefulWidget {
  final Set<int> initiallySelectedIds;

  const _GalleryPickerSheet({required this.initiallySelectedIds});

  @override
  State<_GalleryPickerSheet> createState() => _GalleryPickerSheetState();
}

class _GalleryPickerSheetState extends State<_GalleryPickerSheet> {
  late final Set<int> _selectedIds = {...widget.initiallySelectedIds};

  @override
  Widget build(BuildContext context) {
    return _BottomActionShell(
      title: 'Pick from gallery',
      maxHeightFactor: 0.86,
      scrollable: false,
      child: BlocBuilder<MediaLibraryBloc, MediaLibraryState>(
        builder: (context, state) {
          if (state is MediaLibraryLoading || state is MediaLibraryInitial) {
            return const SizedBox(
              height: 260,
              child: Center(
                child: CircularProgressIndicator(
                  color: Appcolors.kprimarycolor,
                ),
              ),
            );
          }

          if (state is MediaLibraryFailure) {
            return SizedBox(
              height: 260,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Appcolors.kredcolor,
                    size: 34,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF28313D),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.read<MediaLibraryBloc>().add(
                      FetchMediaLibraryRequested(),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final media = state is MediaLibrarySuccess
              ? state.media
              : const <MediaAsset>[];
          if (media.isEmpty) {
            return const SizedBox(
              height: 220,
              child: Center(
                child: Text(
                  'No media found',
                  style: TextStyle(
                    color: Color(0xFF28313D),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          }

          final selectedMedia = media
              .where((asset) => _selectedIds.contains(asset.id))
              .toList();

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: media.length,
                  itemBuilder: (context, index) {
                    final asset = media[index];
                    final selected = _selectedIds.contains(asset.id);
                    return _GalleryPickerTile(
                      asset: asset,
                      selected: selected,
                      onTap: () {
                        setState(() {
                          selected
                              ? _selectedIds.remove(asset.id)
                              : _selectedIds.add(asset.id);
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: selectedMedia.isEmpty
                    ? null
                    : () => Navigator.pop(context, selectedMedia),
                style: FilledButton.styleFrom(
                  backgroundColor: Appcolors.kprimarycolor,
                  foregroundColor: Appcolors.kwhitecolor,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  selectedMedia.isEmpty
                      ? 'Select assets'
                      : 'Use ${selectedMedia.length} asset(s)',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GalleryPickerTile extends StatelessWidget {
  final MediaAsset asset;
  final bool selected;
  final VoidCallback onTap;

  const _GalleryPickerTile({
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: Appcolors.kwhitecolor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Appcolors.kprimarycolor : const Color(0xFFE8DDD9),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (asset.isImage && asset.url.isNotEmpty)
                      Image.network(
                        asset.resolvedUrl(Endpoints.mediaBaseUrl),
                        fit: BoxFit.cover,
                        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                        errorBuilder: (_, _, _) =>
                            _PickerAssetFallback(asset: asset),
                      )
                    else
                      _PickerAssetFallback(asset: asset),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: selected
                            ? Appcolors.kprimarycolor
                            : Appcolors.kwhitecolor,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                asset.name.isEmpty ? asset.storedName : asset.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1A2028),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerAssetFallback extends StatelessWidget {
  final MediaAsset asset;

  const _PickerAssetFallback({required this.asset});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: asset.isVideo
              ? const [Color(0xFF102A43), Color(0xFF315C72)]
              : const [Color(0xFFFFEFEA), Color(0xFFF37A65)],
        ),
      ),
      child: Center(
        child: Icon(
          asset.isVideo ? Icons.play_circle_fill_rounded : Icons.image_rounded,
          color: Appcolors.kwhitecolor.withValues(alpha: 0.8),
          size: 42,
        ),
      ),
    );
  }
}

class _BottomActionShell extends StatelessWidget {
  final String title;
  final Widget child;
  final double maxHeightFactor;
  final bool scrollable;

  const _BottomActionShell({
    required this.title,
    required this.child,
    this.maxHeightFactor = 0.72,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: FractionallySizedBox(
          heightFactor: maxHeightFactor,
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: const BoxDecoration(
              color: Appcolors.kwhitecolor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8DDD9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1A2028),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: scrollable
                      ? SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: child,
                        )
                      : child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6F3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8DDD9)),
          ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Appcolors.kprimaryLightColor.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Appcolors.kprimarycolor, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF1A2028),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7A6C66),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF7A6C66)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreativeSourceOption {
  final _CreativeSourceAction action;
  final IconData icon;
  final String title;
  final String subtitle;

  const _CreativeSourceOption({
    required this.action,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _SelectedCreative {
  final String name;
  final String sourceLabel;
  final String path;
  final MediaAsset? mediaAsset;
  final String apiMediaKind;
  final String apiMediaSource;
  final String apiMediaUrl;
  final String apiDriveFileUrl;
  final String apiDriveFileName;

  const _SelectedCreative({
    required this.name,
    required this.sourceLabel,
    required this.path,
    this.mediaAsset,
    this.apiMediaKind = '',
    this.apiMediaSource = '',
    this.apiMediaUrl = '',
    this.apiDriveFileUrl = '',
    this.apiDriveFileName = '',
  });

  factory _SelectedCreative.local({
    required String name,
    required String sourceLabel,
    required String path,
  }) {
    return _SelectedCreative(
      name: name.isEmpty ? 'Selected creative' : name,
      sourceLabel: sourceLabel,
      path: path,
    );
  }

  factory _SelectedCreative.fromMediaAsset(MediaAsset asset) {
    return _SelectedCreative(
      name: asset.name.isEmpty ? asset.storedName : asset.name,
      sourceLabel: 'Gallery',
      path: asset.url,
      mediaAsset: asset,
    );
  }

  factory _SelectedCreative.fromPostMediaItem(PostMediaItem item) {
    return _SelectedCreative.fromPostValues(
      name: item.driveFileName.isNotEmpty
          ? item.driveFileName
          : item.mediaUrl.split('/').last,
      mediaKind: item.mediaKind,
      mediaSource: item.mediaSource,
      mediaUrl: item.mediaUrl,
      driveFileUrl: item.driveFileUrl,
      driveFileName: item.driveFileName,
    );
  }

  factory _SelectedCreative.fromPostValues({
    required String name,
    required String mediaKind,
    required String mediaSource,
    required String mediaUrl,
    required String driveFileUrl,
    required String driveFileName,
  }) {
    final normalizedSource = mediaSource.toLowerCase();
    return _SelectedCreative(
      name: name.trim().isEmpty ? 'Existing creative' : name.trim(),
      sourceLabel: normalizedSource == 'drive' ? 'Google Drive' : 'Gallery',
      path: normalizedSource == 'drive' && driveFileUrl.trim().isNotEmpty
          ? driveFileUrl
          : mediaUrl,
      apiMediaKind: mediaKind,
      apiMediaSource: mediaSource,
      apiMediaUrl: mediaUrl,
      apiDriveFileUrl: driveFileUrl,
      apiDriveFileName: driveFileName,
    );
  }

  bool get isVideo {
    if (apiMediaKind.toLowerCase() == 'video') return true;
    if (mediaAsset != null) return mediaAsset!.isVideo;
    final lowerName = name.toLowerCase();
    return lowerName.endsWith('.mp4') ||
        lowerName.endsWith('.mov') ||
        lowerName.endsWith('.m4v');
  }

  bool get isImage {
    if (apiMediaKind.toLowerCase() == 'image') return true;
    if (mediaAsset != null) return mediaAsset!.isImage;
    final lowerName = name.toLowerCase();
    return lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.gif') ||
        lowerName.endsWith('.webp') ||
        lowerName.endsWith('.heic');
  }

  String resolvedMediaUrl(String baseUrl) {
    final source = apiMediaUrl.trim().isNotEmpty ? apiMediaUrl : path;
    final trimmedUrl = source.trim();
    final parsedUrl = Uri.tryParse(trimmedUrl);
    if (parsedUrl == null || trimmedUrl.isEmpty) return trimmedUrl;
    if (parsedUrl.hasScheme) return trimmedUrl;

    final normalizedUrl = trimmedUrl.startsWith('/')
        ? trimmedUrl.substring(1)
        : trimmedUrl;
    final mediaBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';

    return Uri.parse(mediaBaseUrl).resolve(normalizedUrl).toString();
  }
}

enum _CreativeSourceAction {
  uploadCreative,
  pickFromGallery,
  pickFromGoogleDrive,
}

// ─── Social Preview Card ──────────────────────────────────────────────────────

class _SocialPreviewCard extends StatelessWidget {
  final List<_SelectedCreative> creatives;
  final String title;
  final String caption;
  final ClientModel? client;
  final String contentType;
  final String scheduledFor;

  const _SocialPreviewCard({
    required this.creatives,
    required this.title,
    required this.caption,
    required this.client,
    required this.contentType,
    required this.scheduledFor,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = _displayName;
    final titleText = title.isEmpty ? 'Post title' : title;
    final captionText = caption.isEmpty
        ? 'Your caption will appear here'
        : caption;

    return Container(
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.96),
        borderRadius: BorderRadiusStyles.kradius15(),
        border: Border.all(color: const Color(0xFFE8DDD9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Appcolors.kblackcolor.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Post header row
          Padding(
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtils.wp(3.6),
              ResponsiveUtils.hp(1.4),
              ResponsiveUtils.wp(2),
              ResponsiveUtils.hp(1),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  height: ResponsiveUtils.wp(9).clamp(34, 40).toDouble(),
                  width: ResponsiveUtils.wp(9).clamp(34, 40).toDouble(),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF17124B),
                    border: Border.all(
                      color: Appcolors.kprimaryLightColor.withValues(
                        alpha: 0.5,
                      ),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _avatarInitial,
                      style: TextStyle(
                        color: Appcolors.kwhitecolor,
                        fontWeight: FontWeight.w800,
                        fontSize: ResponsiveUtils.sp(
                          4.2,
                        ).clamp(14, 16).toDouble(),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.wp(2.4)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF1A2028),
                          fontSize: ResponsiveUtils.sp(
                            4,
                          ).clamp(13, 15).toDouble(),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$contentType • $scheduledFor',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF7A6C66),
                          fontSize: ResponsiveUtils.sp(
                            3,
                          ).clamp(10, 12).toDouble(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6F3),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE8DDD9)),
                  ),
                  child: Text(
                    contentType,
                    style: const TextStyle(
                      color: Appcolors.kprimarycolor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.wp(2)),
                const Icon(
                  Icons.more_horiz_rounded,
                  color: Color(0xFF7A6C66),
                  size: 22,
                ),
              ],
            ),
          ),

          Container(
            height: ResponsiveUtils.hp(22).clamp(160, 200).toDouble(),
            width: double.infinity,
            color: const Color(0xFF17124B),
            child: _PreviewCreativeCarousel(creatives: creatives),
          ),

          // ── Action icons row
          Padding(
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtils.wp(3.6),
              ResponsiveUtils.hp(1.2),
              ResponsiveUtils.wp(3.6),
              0,
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Color(0xFF1A2028), size: 22),
                SizedBox(width: ResponsiveUtils.wp(3.5)),
                const Icon(
                  Icons.bookmark_border_rounded,
                  color: Color(0xFF1A2028),
                  size: 22,
                ),
                SizedBox(width: ResponsiveUtils.wp(3.5)),
                const Icon(
                  Icons.send_rounded,
                  color: Color(0xFF1A2028),
                  size: 22,
                ),
                const Spacer(),
                const Icon(
                  Icons.bookmark_rounded,
                  color: Color(0xFF1A2028),
                  size: 22,
                ),
              ],
            ),
          ),

          // ── Caption text
          Padding(
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtils.wp(3.6),
              ResponsiveUtils.hp(0.8),
              ResponsiveUtils.wp(3.6),
              ResponsiveUtils.hp(1.4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF1A2028),
                    fontSize: ResponsiveUtils.sp(4.2).clamp(14, 16).toDouble(),
                    fontWeight: FontWeight.w900,
                    height: 1.24,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.hp(0.5)),
                RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(
                      color: const Color(0xFF1A2028),
                      fontSize: ResponsiveUtils.sp(
                        3.8,
                      ).clamp(12, 14).toDouble(),
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: '$displayName ',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: captionText,
                        style: const TextStyle(fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ResponsiveUtils.hp(0.5)),
                Text(
                  'JUST NOW',
                  style: TextStyle(
                    color: const Color(0xFFB0A09C),
                    fontSize: ResponsiveUtils.sp(3).clamp(9, 11).toDouble(),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _displayName {
    final instagramName = client?.instagramProfileName.trim() ?? '';
    final facebookName = client?.facebookProfileName.trim() ?? '';
    final clientName = client?.name.trim() ?? '';

    if (instagramName.isNotEmpty) return instagramName;
    if (facebookName.isNotEmpty) return facebookName;
    if (clientName.isNotEmpty) return clientName;
    return 'Select a client';
  }

  String get _avatarInitial {
    final source = (client?.name.trim().isNotEmpty ?? false)
        ? client!.name.trim()
        : _displayName;
    return source.substring(0, 1).toUpperCase();
  }
}

class _PreviewCreativeCarousel extends StatefulWidget {
  final List<_SelectedCreative> creatives;

  const _PreviewCreativeCarousel({required this.creatives});

  @override
  State<_PreviewCreativeCarousel> createState() =>
      _PreviewCreativeCarouselState();
}

class _PreviewCreativeCarouselState extends State<_PreviewCreativeCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void didUpdateWidget(covariant _PreviewCreativeCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentPage >= widget.creatives.length) {
      _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.creatives.length;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            physics: count > 1
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            itemCount: count == 0 ? 1 : count,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) {
              return _PreviewCreative(
                creative: count == 0 ? null : widget.creatives[index],
              );
            },
          ),
          if (count > 1)
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  count,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: _currentPage == index ? 18 : 6,
                    decoration: BoxDecoration(
                      color: Appcolors.kwhitecolor.withValues(
                        alpha: _currentPage == index ? 0.95 : 0.46,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          if (count > 1)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Appcolors.kblackcolor.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${_currentPage + 1}/$count',
                  style: const TextStyle(
                    color: Appcolors.kwhitecolor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviewCreative extends StatelessWidget {
  final _SelectedCreative? creative;

  const _PreviewCreative({required this.creative});

  @override
  Widget build(BuildContext context) {
    final mediaAsset = creative?.mediaAsset;
    if (mediaAsset != null && mediaAsset.isImage && mediaAsset.url.isNotEmpty) {
      return ClipRect(
        child: Image.network(
          mediaAsset.resolvedUrl(Endpoints.mediaBaseUrl),
          fit: BoxFit.cover,
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          errorBuilder: (_, _, _) => _PreviewPlaceholder(creative: creative),
        ),
      );
    }

    if (creative != null && creative!.isImage) {
      final imageUrl = creative!.resolvedMediaUrl(Endpoints.mediaBaseUrl);
      if (imageUrl.isNotEmpty) {
        return ClipRect(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
            errorBuilder: (_, _, _) => _PreviewPlaceholder(creative: creative),
          ),
        );
      }
    }

    return _PreviewPlaceholder(creative: creative);
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  final _SelectedCreative? creative;

  const _PreviewPlaceholder({required this.creative});

  @override
  Widget build(BuildContext context) {
    if (creative == null) {
      return ClipRect(
        child: SizedBox.expand(child: CustomPaint(painter: _BubblePainter())),
      );
    }

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: CustomPaint(painter: _BubblePainter())),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    creative!.isVideo
                        ? Icons.play_circle_fill_rounded
                        : Icons.image_rounded,
                    color: Appcolors.kwhitecolor.withValues(alpha: 0.86),
                    size: 42,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    creative!.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Appcolors.kwhitecolor,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    creative!.sourceLabel,
                    style: TextStyle(
                      color: Appcolors.kwhitecolor.withValues(alpha: 0.76),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Simple bubble painter for preview image placeholder ─────────────────────

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final bubbles = [
      (0.15, 0.3, 0.18),
      (0.45, 0.5, 0.25),
      (0.72, 0.25, 0.14),
      (0.28, 0.72, 0.15),
      (0.60, 0.68, 0.20),
      (0.85, 0.55, 0.12),
      (0.08, 0.62, 0.10),
    ];
    for (final (rx, ry, rf) in bubbles) {
      paint.color = const Color(0xFF263780).withValues(alpha: 0.55 + rf * 0.5);
      canvas.drawCircle(
        Offset(size.width * rx, size.height * ry),
        size.width * rf,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BubblePainter _) => false;
}

// ─── Review & Submit Button ───────────────────────────────────────────────────

class _ReviewSubmitButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ReviewSubmitButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: ResponsiveUtils.hp(6.8).clamp(52, 64).toDouble(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isLoading
                ? const [Color(0xFFE7A092), Color(0xFFD98B78)]
                : const [Color(0xFFF3633A), Color(0xFFD6521A)],
          ),
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: Appcolors.kprimarycolor.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Appcolors.kwhitecolor,
                    strokeWidth: 2.6,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: Appcolors.kwhitecolor,
                    fontSize: ResponsiveUtils.sp(4.8).clamp(16, 19).toDouble(),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
