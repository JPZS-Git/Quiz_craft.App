import 'package:flutter/material.dart';
import '../../services/shared_preferences_services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;

class ProfilePage extends StatefulWidget {
  static const routeName = '/profile';
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _avatarUrl;

  bool _saving = false;
  bool _privacyAccepted = false;

  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _surfaceGray = Color(0xFF475569);

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = SharedPreferencesService();
    final name = await prefs.getUserName();
    final email = await prefs.getUserEmail();
    final avatar = await prefs.getUserAvatarUrl();

    if (mounted) {
      setState(() {
        _nameController.text = name ?? '';
        _emailController.text = email ?? '';
        _avatarUrl = avatar;
      });
    }
  }

  String _initialsFromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    final first = parts[0].characters.first;
    final second = parts[1].characters.first;
    return (first + second).toUpperCase();
  }

  Future<void> _editAvatar() async {
    final prefs = SharedPreferencesService();

    final choice = await showModalBottomSheet<String?>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('Remover foto'),
              onTap: () => Navigator.of(context).pop('remove'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.of(context).pop('camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Carregar foto'),
              onTap: () => Navigator.of(context).pop('gallery'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == null) return;

    if (choice == 'remove') {
      await prefs.setUserAvatarUrl(null);
      if (!mounted) return;
      setState(() => _avatarUrl = null);
      return;
    }

    final picker = ImagePicker();
    XFile? picked;
    try {
      if (choice == 'camera') {
        picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 1200, imageQuality: 85);
      } else if (choice == 'gallery') {
        picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
      }
    } catch (e) {
      // ignore errors from permissions or picker
      return;
    }

    if (picked == null) return;

    if (kIsWeb || picked.path.isEmpty) {
      try {
        final bytes = await picked.readAsBytes();
        final base64Data = base64Encode(bytes);
        final dataUrl = 'data:image/png;base64,$base64Data';
        await prefs.setUserAvatarUrl(dataUrl);
        if (!mounted) return;
        setState(() => _avatarUrl = dataUrl);
      } catch (e) {
        return;
      }
      return;
    }

    final path = picked.path;
    await prefs.setUserAvatarUrl(path);
    if (!mounted) return;
    setState(() => _avatarUrl = path);
  }

  String? _validateName(String? value) {
    if (value == null) return 'Nome é obrigatório.';
    final v = value.trim();
    if (v.isEmpty) return 'Nome é obrigatório.';
    if (v.length > 100) return 'Nome muito longo.';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null) return 'E-mail é obrigatório.';
    final v = value.trim();
    if (v.isEmpty) return 'E-mail é obrigatório.';
    final emailRegExp = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
    if (!emailRegExp.hasMatch(v)) return 'E-mail inválido.';
    return null;
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    if (!_privacyAccepted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Aviso de Privacidade'),
          content: const Text(
            'Ao salvar seu nome e e-mail, voc\u00ea concorda com a nossa Pol\u00edtica de Privacidade. Por favor, confirme que leu e aceita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _privacyAccepted = true);
                _save();
              },
              child: const Text('Aceito'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    final prefs = SharedPreferencesService();
    await prefs.setUserName(name);
    await prefs.setUserEmail(email);
    await prefs.setPrivacyPolicyAllRead(true);

    if (!mounted) return;

    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil salvo com sucesso.')),
    );

    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar header
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: _primaryBlue,
                        child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                            ? ClipOval(
                                child: _buildAvatarImage(_avatarUrl!),
                              )
                            : Text(
                                _initialsFromName(_nameController.text.isNotEmpty ? _nameController.text : 'U'),
                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _editAvatar,
                        child: const Text('Alterar foto'),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                // Campo Nome
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nome',
                    hintText: 'Seu nome completo',
                    filled: true,
                    fillColor: const Color.fromRGBO(71, 85, 105, 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _surfaceGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primaryBlue, width: 2),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: _validateName,
                ),
                const SizedBox(height: 16),

                // Campo Email
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    hintText: 'seu@exemplo.com',
                    filled: true,
                    fillColor: const Color.fromRGBO(71, 85, 105, 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _surfaceGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primaryBlue, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),

                // Checkbox alinhado
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _privacyAccepted,
                      onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
                      activeColor: _primaryBlue,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _privacyAccepted = !_privacyAccepted),
                        child: const Text(
                          'Li e aceito a Política de Privacidade.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.3,
                            color: _surfaceGray,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Botão Salvar
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Salvar'),
                ),
                const SizedBox(height: 12),

                // Botão Cancelar
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryBlue,
                    side: const BorderSide(color: _primaryBlue),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage(String avatar) {
    // data URL (web)
    if (avatar.startsWith('data:')) {
      try {
        final comma = avatar.indexOf(',');
        final base64Str = avatar.substring(comma + 1);
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, width: 96, height: 96, fit: BoxFit.cover);
      } catch (e) {
        return const SizedBox.shrink();
      }
    }

    // http(s) network
    if (avatar.startsWith('http')) {
      return Image.network(
        avatar,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }

    // otherwise treat as local file path (mobile/desktop)
    try {
      final file = File(avatar);
      if (file.existsSync()) {
        return Image.file(file, width: 96, height: 96, fit: BoxFit.cover);
      }
    } catch (e) {
      // ignore
    }

    return const SizedBox.shrink();
  }
}


