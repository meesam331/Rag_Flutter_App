import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'document_api.dart';

class ProjectPage extends StatefulWidget {
  const ProjectPage({super.key});

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  final _api = DocumentApi();
  final _questionController = TextEditingController();
  String? _fileName;
  String? _answer;
  bool _isUploading = false;
  bool _isAsking = false;

  @override
  void dispose() {
    _api.close();
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _uploadFile() async {
    if (_isUploading || _isAsking) return;

    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (!mounted || files.isEmpty) return;

      setState(() {
        _isUploading = true;
        _answer = null;
      });

      final name = await _api.upload(files.first);
      if (!mounted) return;
      setState(() => _fileName = name);
    } on PlatformException catch (error) {
      if (mounted) {
        _showError(error.message ?? 'Could not open the file picker.');
      }
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _fileName == null || _isAsking || _isUploading) {
      return;
    }

    setState(() {
      _isAsking = true;
      _answer = null;
    });
    try {
      final result = await _api.ask(question);
      if (mounted) setState(() => _answer = result);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _isAsking = false);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error.toString())));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Pagewise')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              Text(
                'Ask your document',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload one PDF, then ask a question.',
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isUploading || _isAsking ? null : _uploadFile,
                icon: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(
                  _isUploading ? 'Uploading...' : _fileName ?? 'Upload a PDF',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _questionController,
                enabled: _fileName != null && !_isAsking && !_isUploading,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _askQuestion(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Your question',
                  hintText: 'Ask something about your file',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _fileName == null || _isAsking || _isUploading
                    ? null
                    : _askQuestion,
                child: Text(
                  _isAsking ? 'Finding answer...' : 'Answer question',
                ),
              ),
              if (_answer != null) ...[
                const SizedBox(height: 24),
                Text('Answer', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                SelectableText(_answer!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
