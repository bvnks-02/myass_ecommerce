import 'package:flutter/material.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../theme/app_theme.dart';

/// Text field + send button used at the bottom of a chat thread.
/// `onSend` receives the raw text; sanitization happens in the repository.
class ChatComposer extends StatefulWidget {
  const ChatComposer({super.key, required this.onSend});

  final Future<bool> Function(String content) onSend;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    var ok = false;
    try {
      ok = await widget.onSend(text);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    if (!mounted) return;
    if (ok) {
      // Keep the input focused so the user can chain messages.
      _controller.clear();
    } else {
      AppSnackBar.error(
          context, 'Message non envoyé. Vérifiez votre connexion et réessayez.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.sw(context, 12),
        ResponsiveUtils.sh(context, 8),
        ResponsiveUtils.sw(context, 12),
        ResponsiveUtils.sh(context, 12),
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Écrivez un message…',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: AppTheme.cardColorSecondary,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.sw(context, 16),
                    vertical: ResponsiveUtils.sh(context, 12),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: ResponsiveUtils.sw(context, 10)),
            GestureDetector(
              onTap: _handleSend,
              child: Container(
                width: ResponsiveUtils.sw(context, 46),
                height: ResponsiveUtils.sw(context, 46),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            color: Colors.black, strokeWidth: 2),
                      )
                    : Icon(Icons.send_rounded,
                        color: Colors.black,
                        size: ResponsiveUtils.sf(context, 22)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
