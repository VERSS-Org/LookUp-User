import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/services/auth_service.dart';
import 'package:lookup_user/src/services/data_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/theme.dart';
import 'package:lookup_user/src/utils/formatters.dart';
import 'package:lookup_user/src/widgets/common.dart';

/// Mensajes del postulante.
///
/// En pantallas anchas: dos paneles (lista de chats + conversación), como un
/// cliente de mensajería de escritorio. En móvil: lista y chat apilados.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({
    super.key,
    this.embedded = false,
    this.initialPostulacionId,
  });

  /// true cuando vive dentro del shell web (sin flecha de volver).
  final bool embedded;

  /// Hilo que debe quedar abierto al llegar desde Procesos. La seleccion se
  /// resuelve despues de cargar la bandeja, por lo que tambien funciona si el
  /// inbox aun no estaba disponible.
  final String? initialPostulacionId;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  Map<String, dynamic>? _selected;
  final TextEditingController _filterController = TextEditingController();
  String _filter = '';
  String? _loadError;
  bool _isLoading = true;
  bool _didApplyInitialThread = false;

  void _selectInitialThread(List<Map<String, dynamic>> inbox) {
    if (_didApplyInitialThread) return;
    final requestedId = widget.initialPostulacionId;
    if (requestedId == null || requestedId.isEmpty) return;
    for (final thread in inbox) {
      if (thread['postulacion_id']?.toString() == requestedId) {
        _selected = thread;
        _didApplyInitialThread = true;
        return;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInbox());
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _loadInbox() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      await context.read<LookUpDataService>().fetchInbox();
      if (!mounted) return;
      final inbox = context.read<LookUpDataService>().inbox;
      _selectInitialThread(inbox);
      final selectedId = _selected?['postulacion_id']?.toString();
      if (selectedId != null &&
          !inbox.any(
            (thread) => thread['postulacion_id']?.toString() == selectedId,
          )) {
        _selected = null;
      }
    } catch (error) {
      if (mounted) _loadError = error.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _open(Map<String, dynamic> hilo) {
    _didApplyInitialThread = true;
    setState(() => _selected = hilo);
  }

  void _closeMobileThread() => setState(() => _selected = null);

  @override
  Widget build(BuildContext context) {
    final data = context.watch<LookUpDataService>();
    final c = context.colors;
    final inbox = data.inbox;
    final isWide = MediaQuery.sizeOf(context).width >= 960;
    final normalizedFilter = normalizeSearchText(_filter);
    final filteredInbox = inbox.where((thread) {
      final counterpart = asMap(thread['contraparte']);
      final searchable = normalizeSearchText(
        '${counterpart['nombre'] ?? ''} ${thread['puesto_titulo'] ?? ''}',
      );
      return searchable.contains(normalizedFilter);
    }).toList();

    final Widget lista;
    if (_isLoading && inbox.isEmpty) {
      lista = ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(44),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    } else if (_loadError != null && inbox.isEmpty) {
      lista = ListView(
        padding: const EdgeInsets.all(22),
        children: [
          ErrorBanner(message: _loadError!),
          EmptyState(
            icon: Icons.cloud_off_outlined,
            title: context.t('common.error.connection'),
            message: context.t('chat.retry.msg'),
            actionLabel: context.t('common.retry'),
            onAction: _loadInbox,
          ),
        ],
      );
    } else if (filteredInbox.isEmpty) {
      lista = ListView(
        padding: const EdgeInsets.all(22),
        children: [
          EmptyState(
            icon: _filter.isEmpty
                ? Icons.chat_outlined
                : Icons.search_off_outlined,
            title: _filter.isEmpty
                ? context.t('chat.empty.title')
                : context.t('chat.search.empty.title'),
            message: _filter.isEmpty
                ? context.t('chat.empty.msg')
                : context.t('chat.search.empty.msg'),
          ),
        ],
      );
    } else {
      lista = ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: filteredInbox.length,
        separatorBuilder: (_, index) =>
            Divider(color: c.border, height: 1, indent: 78),
        itemBuilder: (context, index) => _ThreadTile(
          hilo: filteredInbox[index],
          selected:
              isWide &&
              _selected?['postulacion_id'] ==
                  filteredInbox[index]['postulacion_id'],
          onTap: () => _open(filteredInbox[index]),
        ),
      );
    }

    final listPanel = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: _ThreadSearchField(
            controller: _filterController,
            onChanged: (value) => setState(() => _filter = value),
          ),
        ),
        Divider(color: c.border, height: 1),
        Expanded(
          child: RefreshIndicator(onRefresh: _loadInbox, child: lista),
        ),
      ],
    );

    if (isWide) {
      return Scaffold(
        appBar: widget.embedded
            ? null
            : AppBar(centerTitle: true, title: const BrandMark(size: 32)),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              key: const Key('messages-list-panel'),
              width: 360,
              child: listPanel,
            ),
            VerticalDivider(width: 1, color: c.border),
            Expanded(
              child: _selected == null
                  ? Container(
                      key: const Key('messages-empty-pane'),
                      color: c.background,
                      child: const Center(child: BrandMark(size: 46)),
                    )
                  : ChatView(
                      key: Key(
                        'selected-thread-${_selected!['postulacion_id']}',
                      ),
                      hilo: _selected!,
                    ),
            ),
          ],
        ),
      );
    }

    if (_selected != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _closeMobileThread();
        },
        child: Scaffold(
          key: const Key('mobile-chat-screen'),
          body: SafeArea(
            child: ChatView(
              key: Key('selected-thread-${_selected!['postulacion_id']}'),
              hilo: _selected!,
              showBack: true,
              onBack: _closeMobileThread,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      key: const Key('mobile-messages-list'),
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          tooltip: context.t('common.back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const BrandMark(size: 32),
      ),
      body: SafeArea(top: false, child: listPanel),
    );
  }
}

class _ThreadSearchField extends StatelessWidget {
  const _ThreadSearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.t('chat.search.hint'),
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: context.t('search.clear'),
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        fillColor: c.surfaceAlt,
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({
    required this.hilo,
    required this.onTap,
    this.selected = false,
  });

  final Map<String, dynamic> hilo;
  final VoidCallback onTap;
  final bool selected;

  String _hora(String? raw) {
    if (raw == null) return '';
    final date = DateTime.tryParse(raw);
    if (date == null) return '';
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final contraparte = asMap(hilo['contraparte']);
    final ultimo = asMap(hilo['ultimo_mensaje']);
    final unread = asInt(hilo['no_leidos']);
    final esMio = ultimo['remitente_rol']?.toString() == 'postulante';

    return Material(
      color: selected ? c.surfaceAlt : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              CompanyAvatar(
                fotoUrl: contraparte['foto_url']?.toString(),
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            contraparte['nombre']?.toString() ??
                                context.t('common.company'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                              color: c.ink,
                            ),
                          ),
                        ),
                        Text(
                          _hora(ultimo['fecha']?.toString()),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: unread > 0 ? c.accent : c.inkFaint,
                            fontWeight: unread > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      hilo['puesto_titulo']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: c.inkFaint),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${esMio ? '${context.t('chat.you')}: ' : ''}${ultimo['texto'] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: unread > 0 ? c.ink : c.inkMuted,
                              fontWeight: unread > 0
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: c.accent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Conversación: cabecera, burbujas y campo de envío. Se usa como página
/// (móvil) o como panel derecho (web).
class ChatView extends StatefulWidget {
  const ChatView({
    super.key,
    required this.hilo,
    this.showBack = false,
    this.onBack,
  });

  final Map<String, dynamic> hilo;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;
  bool _isSending = false;
  bool _isLoadingThread = true;
  bool _isPolling = false;

  String get _postulacionId => widget.hilo['postulacion_id']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeThread());
  }

  Future<void> _initializeThread() async {
    final data = context.read<LookUpDataService>();
    await data.fetchThread(_postulacionId);
    if (!mounted) return;
    await data.markThreadRead(_postulacionId);
    if (!mounted) return;
    setState(() => _isLoadingThread = false);
    _scrollToBottom(animated: false);
    _pollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _pollThread(),
    );
  }

  Future<void> _pollThread() async {
    if (!mounted || _isPolling) return;
    _isPolling = true;
    try {
      final data = context.read<LookUpDataService>();
      final before = data.threadFor(_postulacionId).length;
      await data.fetchThread(_postulacionId);
      if (!mounted) return;
      if (data.threadFor(_postulacionId).length != before) {
        await data.markThreadRead(_postulacionId);
        _scrollToBottom();
      }
    } finally {
      _isPolling = false;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  Future<void> _send() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    _controller.clear();
    try {
      await context.read<LookUpDataService>().sendChatMessage(
        _postulacionId,
        texto,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        _controller.value = TextEditingValue(
          text: texto,
          selection: TextSelection.collapsed(offset: texto.length),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final data = context.watch<LookUpDataService>();
    final mensajes = data.threadFor(_postulacionId);
    final contraparte = asMap(widget.hilo['contraparte']);
    final auth = context.watch<AuthService>();
    final compact = MediaQuery.sizeOf(context).width < 430;

    return Container(
      color: c.background,
      child: Column(
        children: [
          // Cabecera de la conversación
          Container(
            height: 56,
            padding: EdgeInsets.only(left: widget.showBack ? 4 : 16, right: 12),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Row(
              children: [
                if (widget.showBack)
                  IconButton(
                    tooltip: context.t('common.back'),
                    icon: const Icon(Icons.arrow_back),
                    onPressed:
                        widget.onBack ?? () => Navigator.maybePop(context),
                  ),
                CompanyAvatar(
                  fotoUrl: contraparte['foto_url']?.toString(),
                  size: 36,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contraparte['nombre']?.toString() ??
                            context.t('common.company'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                      Text(
                        widget.hilo['puesto_titulo']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: c.inkFaint),
                      ),
                    ],
                  ),
                ),
                if (!compact && widget.hilo['estado_postulacion'] != null)
                  StatusChip(
                    label: widget.hilo['estado_postulacion'].toString(),
                    compact: true,
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingThread && mensajes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                    itemCount: mensajes.length,
                    itemBuilder: (context, index) => ChatBubble(
                      contacto: mensajes[index],
                      myRole: auth.role ?? 'postulante',
                    ),
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                compact ? 10 : 12,
                8,
                compact ? 10 : 12,
                8,
              ),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('chat-message-field'),
                      controller: _controller,
                      minLines: 1,
                      maxLines: compact ? 3 : 4,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: context.t('chat.reply'),
                        fillColor: c.surfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: c.brand),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: c.brand,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _isSending ? null : _send,
                      child: Padding(
                        padding: const EdgeInsets.all(11),
                        child: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
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

/// Burbuja de chat: mensajes propios a la derecha con tinte de marca.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.contacto, required this.myRole});

  final Map<String, dynamic> contacto;
  final String myRole;

  String _hora(String? raw) {
    if (raw == null) return '';
    final date = DateTime.tryParse(raw);
    if (date == null) return '';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final feedback = asMap(contacto['ultimo_feedback']);
    final tipo = feedback['tipo']?.toString() ?? 'otro';
    final mensaje = feedback['mensaje']?.toString() ?? '';
    final motivo = feedback['motivo_rechazo']?.toString();
    final isMine = contacto['remitente_rol']?.toString() == myRole;
    final esEvento = tipo == 'aprobacion' || tipo == 'rechazo';
    final compact = MediaQuery.sizeOf(context).width < 430;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        margin: EdgeInsets.only(
          bottom: 7,
          left: isMine ? (compact ? 34 : 56) : 0,
          right: isMine ? 0 : (compact ? 34 : 56),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: isMine
              ? (context.isDark
                    ? const Color(0xFF31405F)
                    : const Color(0xFFDCE5FA))
              : c.surface,
          border: Border.all(
            color: isMine ? c.brand.withValues(alpha: 0.16) : c.border,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMine ? 14 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (esEvento)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: StatusChip(
                  label: tipo == 'aprobacion' ? 'aceptado' : 'rechazado',
                  compact: true,
                ),
              ),
            Text(
              mensaje,
              style: TextStyle(color: c.ink, fontSize: 14, height: 1.4),
            ),
            if (motivo != null && motivo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  '${context.t('chat.reason')}: $motivo',
                  style: TextStyle(
                    color: c.inkMuted,
                    fontStyle: FontStyle.italic,
                    fontSize: 12.5,
                  ),
                ),
              ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _hora(contacto['fecha_hora']?.toString()),
                style: TextStyle(fontSize: 10.5, color: c.inkFaint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
