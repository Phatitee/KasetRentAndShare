import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../config/theme.dart';
import '../../config/locale_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/chat_message_model.dart';
import '../../models/rental_item_model.dart';
import '../../models/rental_request_model.dart';
import '../rentals/item_detail_screen.dart';
import '../rentals/request_details_screen.dart';
import '../contracts/contract_details_screen.dart';
import 'create_contract_screen.dart';
import '../../widgets/user_avatar.dart';
import '../../models/user_model.dart';

import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/cloudinary_service.dart';
import 'location_picker_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? rentalItemName;
  final String? rentalItemId;
  final String? rentalRequestId;
  final String? rentalRequestName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.rentalItemName,
    this.rentalItemId,
    this.rentalRequestId,
    this.rentalRequestName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  UserModel? _otherUser;

  @override
  void initState() {
    super.initState();
    _loadOtherUserData();
    _markAsRead();
  }

  Future<void> _loadOtherUserData() async {
    final userData = await FirestoreService().getUserData(widget.otherUserId);
    if (mounted) {
      setState(() {
        _otherUser = userData;
      });
    }
  }

  void _markAsRead() {
    final currentUserId = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    if (currentUserId != null) {
      FirestoreService().markChatAsRead(widget.chatId, currentUserId);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = FirestoreService();

      final message = ChatMessageModel(
        id: '',
        chatId: widget.chatId,
        senderId: authService.currentUser!.uid,
        message: _messageController.text.trim(),
        timestamp: DateTime.now(),
      );

      await firestoreService.sendMessage(message);
      
      _messageController.clear();
      
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isSending = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = FirestoreService();

      // Upload image to Cloudinary
      final cloudinaryService = CloudinaryService();
      final imageUrl = await cloudinaryService.uploadImage(
        File(image.path),
        'chat_images',
      );

      // Send message with image
      final message = ChatMessageModel(
        id: '',
        chatId: widget.chatId,
        senderId: authService.currentUser!.uid,
        message: '',
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
      );

      await firestoreService.sendMessage(message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName),
            if (widget.rentalItemName != null)
              Text(
                'Renting: ${widget.rentalItemName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show chat options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: FirestoreService().getChatMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AppTheme.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textHint,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    final showDate = index == messages.length - 1 ||
                        !_isSameDay(
                          message.timestamp,
                          messages[index + 1].timestamp,
                        );

                    return Column(
                      children: [
                        if (showDate) _buildDateDivider(message.timestamp),
                        _buildMessageBubble(message, isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
          
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: AppTheme.primaryTeal,
                  ),
                  onPressed: _isSending ? null : () => _showAttachmentMenu(context),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
          ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context) async {
    final l = AppLocalizations.of(context);
    RentalItemModel? currentItem;
    RentalRequestModel? currentRequest;

    if (widget.rentalItemId != null) {
      currentItem = await FirestoreService().getRentalItem(widget.rentalItemId!);
    } else if (widget.rentalRequestId != null) {
      currentRequest = await FirestoreService().getRentalRequest(widget.rentalRequestId!);
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                  child: Icon(Icons.image, color: AppTheme.primaryTeal),
                ),
                title: Text(l.tr('send_image')),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                  child: Icon(Icons.location_on, color: AppTheme.primaryTeal),
                ),
                title: const Text('แชร์ตำแหน่งนัดหมาย'),
                onTap: () {
                  Navigator.pop(context);
                  _sendLocation();
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                  child: Icon(Icons.description, color: AppTheme.primaryTeal),
                ),
                title: Text(l.tr('create_contract')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateContractScreen(
                        chatId: widget.chatId,
                        rentalItem: currentItem,
                        rentalRequest: currentRequest,
                        otherUserId: widget.otherUserId,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, bool isMe) {
    // Status message (system)
    if (message.messageType == 'status') {
      return _buildStatusMessage(message);
    }

    // Item card message — rendered differently
    if (message.messageType == 'item_card') {
      return _buildItemCardMessage(message, isMe);
    }

    // Request card message
    if (message.messageType == 'request_card') {
      return _buildRequestCardMessage(message, isMe);
    }

    // Contract message
    if (message.messageType == 'contract') {
      return _buildContractMessage(message, isMe);
    }

    // Location message
    if (message.messageType == 'location') {
      return _buildLocationMessage(message, isMe);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            UserAvatar(
              photoUrl: _otherUser?.photoUrl,
              name: widget.otherUserName,
              radius: 16,
              fontSize: 12,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? AppTheme.primaryTeal : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: isMe
                        ? null
                        : Border.all(color: AppTheme.divider, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image (if exists)
                      if (message.imageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            message.imageUrl!,
                            width: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 150,
                                color: AppTheme.backgroundColor,
                                child: Icon(
                                  Icons.broken_image,
                                  color: AppTheme.textHint,
                                ),
                              );
                            },
                          ),
                        ),
                        if (message.message.isNotEmpty) const SizedBox(height: 8),
                      ],
                      
                      // Text message
                      if (message.message.isNotEmpty)
                        Text(
                          message.message,
                          style: TextStyle(
                            color: isMe ? Colors.white : AppTheme.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textHint,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToContractDetails(String contractId) async {
    try {
      final contract = await FirestoreService().getContract(contractId);
      if (contract != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContractDetailsScreen(contract: contract),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบข้อมูลสัญญา')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildStatusMessage(ChatMessageModel message) {
    final bool isClickable = message.contractId != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
      child: Center(
        child: GestureDetector(
          onTap: isClickable
              ? () => _navigateToContractDetails(message.contractId!)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isClickable ? AppTheme.primaryTeal.withAlpha(20) : AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isClickable ? AppTheme.primaryTeal.withAlpha(100) : AppTheme.divider,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isClickable ? Icons.description_outlined : Icons.info_outline,
                  size: 14,
                  color: isClickable ? AppTheme.primaryTeal : AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: isClickable ? AppTheme.primaryTeal : AppTheme.textSecondary,
                      fontWeight: isClickable ? FontWeight.bold : FontWeight.w500,
                      decoration: isClickable ? TextDecoration.underline : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Renders a tappable listing card bubble
  Widget _buildItemCardMessage(ChatMessageModel message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            UserAvatar(
              photoUrl: _otherUser?.photoUrl,
              name: widget.otherUserName,
              radius: 16,
              fontSize: 12,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Label above card
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    isMe ? 'คุณแชร์สิ่งนี้' : 'ได้รับคำขอเช่าสิ่งนี้',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textHint,
                    ),
                  ),
                ),

                // Tappable card
                GestureDetector(
                  onTap: () => _openItemDetail(message),
                  child: Container(
                    width: 240,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                          color: AppTheme.primaryTeal.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item image
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: message.itemImageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: message.itemImageUrl!,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    height: 140,
                                    color: AppTheme.backgroundColor,
                                    child: Icon(Icons.image_outlined,
                                        color: AppTheme.textHint, size: 40),
                                  ),
                                )
                              : Container(
                                  height: 140,
                                  color: AppTheme.backgroundColor,
                                  child: Center(
                                    child: Icon(Icons.inventory_2_outlined,
                                        color: AppTheme.textHint, size: 40),
                                  ),
                                ),
                        ),
                        // Item info
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.itemName ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              if (message.itemPrice != null)
                                Text(
                                  '฿${message.itemPrice!.toStringAsFixed(0)} / วัน',
                                  style: TextStyle(
                                    color: AppTheme.primaryTeal,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'ดูรายละเอียด ›',
                                    style: TextStyle(
                                      color: AppTheme.primaryTeal,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textHint,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openItemDetail(ChatMessageModel message) async {
    if (message.itemId == null) return;
    final firestoreService = FirestoreService();
    try {
      final item = await firestoreService.getRentalItem(message.itemId!);
      if (item != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ItemDetailScreen(item: item),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถโหลดรายละเอียดได้: $e')),
        );
      }
    }
  }

  /// Renders a request card bubble (from rental request posts)
  Widget _buildRequestCardMessage(ChatMessageModel message, bool isMe) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            UserAvatar(
              photoUrl: _otherUser?.photoUrl,
              name: widget.otherUserName,
              radius: 16,
              fontSize: 12,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    isMe ? l.tr('from_request') : l.tr('looking_for_rent'),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textHint,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _openRequestDetail(message),
                  child: Container(
                    width: 240,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                          color: AppTheme.accentMint, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header badge
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentMint.withOpacity(0.3),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(14)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search,
                                  size: 16, color: AppTheme.primaryTeal),
                              const SizedBox(width: 6),
                              Text(
                                l.tr('looking_to_rent'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryTeal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Request info
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.requestDescription ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              if (message.requestBudget != null)
                                Row(
                                  children: [
                                    Icon(Icons.payments_outlined,
                                        size: 16, color: AppTheme.primaryTeal),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${l.tr('budget_label')}: ฿${message.requestBudget!.toStringAsFixed(0)}${l.tr('per_day')}',
                                      style: TextStyle(
                                        color: AppTheme.primaryTeal,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    l.tr('view_details'),
                                    style: TextStyle(
                                      color: AppTheme.primaryTeal,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textHint,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRequestDetail(ChatMessageModel message) async {
    if (message.requestId == null) return;
    final firestoreService = FirestoreService();
    try {
      final request = await firestoreService.getRentalRequest(message.requestId!);
      if (request != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RequestDetailsScreen(request: request),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถโหลดรายละเอียดได้: $e')),
        );
      }
    }
  }

  /// Renders the contract message bubble
  Widget _buildContractMessage(ChatMessageModel message, bool isMe) {
    final contractData = message.contractData ?? {};
    final status = message.contractStatus ?? 'pending';

    // Format dates safely
    String dateRange = 'ไม่ระบุวันที่';
    if (contractData['startDate'] != null && contractData['endDate'] != null) {
      try {
        final start = DateTime.parse(contractData['startDate']);
        final end = DateTime.parse(contractData['endDate']);
        dateRange = '${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}';
      } catch (_) {}
    }

    final price = contractData['totalPrice']?.toString() ?? '0';
    final deposit = contractData['deposit']?.toString() ?? '0';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            UserAvatar(
              photoUrl: _otherUser?.photoUrl,
              name: widget.otherUserName,
              radius: 16,
              fontSize: 12,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    isMe ? 'คุณส่งสัญญาเช่า' : 'ส่งสัญญาเช่ามาให้คุณ',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textHint,
                    ),
                  ),
                ),
                Container(
                  width: 260,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryTeal, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryTeal.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.description_outlined, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'สัญญาเช่า',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (status != 'pending')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status == 'accepted' ? 'ยอมรับแล้ว' : 'ปฏิเสธแล้ว',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: status == 'accepted' ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Details
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contractData['rentalItemName'] ?? 'ไม่ระบุชื่อสิ่งของ',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 12),
                            _buildContractRow('ระยะเวลา', dateRange),
                            const SizedBox(height: 8),
                            _buildContractRow('ค่าเช่ารวม', '฿$price'),
                            const SizedBox(height: 8),
                            _buildContractRow('ค่ามัดจำ', '฿$deposit'),
                            
                            if (contractData['rules'] != null && contractData['rules'].toString().isNotEmpty) ...[
                              const Divider(height: 24),
                              Text('เงื่อนไขเพิ่มเติม:', style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
                              const SizedBox(height: 4),
                              Text(
                                contractData['rules'],
                                style: const TextStyle(fontSize: 13),
                              ),
                            ]
                          ],
                        ),
                      ),
                      
                      // Action Buttons (Only if pending AND is NOT me/the owner)
                      if (status == 'pending' && !isMe)
                        Container(
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => _updateContractStatus(message, 'declined'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('ปฏิเสธ', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              Container(width: 1, height: 40, color: Colors.grey.shade200),
                              Expanded(
                                child: TextButton(
                                  onPressed: () => _updateContractStatus(message, 'accepted'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    foregroundColor: AppTheme.primaryTeal,
                                  ),
                                  child: const Text('ยอมรับ', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textHint,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ),
      ],
    );
  }

  Future<void> _updateContractStatus(ChatMessageModel message, String newStatus) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;
    if (currentUserId == null) return;

    if (newStatus == 'accepted') {
      _showRenterSignatureDialog(message);
    } else {
      try {
        await FirestoreService().updateMessageContractStatus(
          widget.chatId,
          message.id,
          newStatus,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  void _showRenterSignatureDialog(ChatMessageModel message) {
    final SignatureController signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เซ็นชื่อเพื่อยอมรับสัญญา (Renter Signature)'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Signature(
                    controller: signatureController,
                    height: 200,
                    backgroundColor: Colors.grey[50]!,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => signatureController.clear(),
                    child: const Text('ล้างลายเซ็น'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              signatureController.dispose();
              Navigator.pop(context);
            },
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (signatureController.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กรุณาเซ็นชื่อก่อนยอมรับ')),
                );
                return;
              }

              final sigBytes = await signatureController.toPngBytes();
              if (mounted) Navigator.pop(context); // Close dialog

              if (sigBytes != null && mounted) {
                _handleAcceptContract(message, sigBytes);
              }
              signatureController.dispose();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
            child: const Text('ยอมรับและเซ็นสัญญา'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAcceptContract(ChatMessageModel message, List<int> sigBytes) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;
    if (currentUserId == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Upload signature to Cloudinary
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/renter_sig_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(sigBytes);

      final cloudinary = CloudinaryService();
      final signatureUrl = await cloudinary.uploadImage(file, 'contract_signatures');

      // 2. Confirm Contract
      await FirestoreService().confirmContract(
        widget.chatId,
        message,
        currentUserId,
        signatureUrl,
      );

      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context); // Remove loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สัญญาได้รับการยืนยันแล้ว! คุณสามารถดูได้ที่เมนูสัญญา'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context); // Remove loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _sendLocation() async {
    final LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPickerScreen(),
      ),
    );

    if (pickedLocation != null) {
      setState(() => _isSending = true);

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final firestoreService = FirestoreService();

        final message = ChatMessageModel(
          id: '',
          chatId: widget.chatId,
          senderId: authService.currentUser!.uid,
          message: '📍 นัดรับ/คืนของ: ดูตำแหน่งในแผนที่',
          timestamp: DateTime.now(),
          messageType: 'location',
          latitude: pickedLocation.latitude,
          longitude: pickedLocation.longitude,
        );

        await firestoreService.sendMessage(message);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSending = false);
        }
      }
    }
  }

  Widget _buildLocationMessage(ChatMessageModel message, bool isMe) {
    if (message.latitude == null || message.longitude == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            UserAvatar(
              photoUrl: _otherUser?.photoUrl,
              name: widget.otherUserName,
              radius: 16,
              fontSize: 12,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () async {
                    final url = 'https://www.google.com/maps/search/?api=1&query=${message.latitude},${message.longitude}';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url));
                    }
                  },
                  child: Container(
                    width: 240,
                    decoration: BoxDecoration(
                      color: isMe ? AppTheme.primaryTeal : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: isMe ? null : Border.all(color: AppTheme.divider),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Placeholder image or mini map
                                Icon(Icons.map_outlined, size: 48, color: AppTheme.primaryTeal.withOpacity(0.5)),
                                const Positioned(
                                  child: Icon(Icons.location_on, color: Colors.red, size: 32),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'นัดรับ/คืนของ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isMe ? Colors.white : AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'แตะเพื่อเปิดในแผนที่',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isMe ? Colors.white.withOpacity(0.8) : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textHint,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppTheme.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDate(date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(child: Divider(color: AppTheme.divider)),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('d MMM yyyy').format(date);
    }
  }
}
