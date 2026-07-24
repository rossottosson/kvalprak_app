// lib/screens/document_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:kvalprak_app/providers/document_provider.dart';
import 'package:kvalprak_app/login_screen.dart';
import 'package:kvalprak_app/services/exceptions.dart';

class DocumentDetailScreen extends StatefulWidget {
  final String documentId;
  final String documentName;

  const DocumentDetailScreen({
    required this.documentId,
    required this.documentName,
    super.key,
  });

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  final ChromeSafariBrowser browser = ChromeSafariBrowser();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _handleSessionExpired() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Din session har gått ut. Vänligen logga in igen.'),
        backgroundColor: Colors.orange,
      ),
    );
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _fetchData() async {
    try {
      await context.read<DocumentProvider>().fetchDocumentDetails(widget.documentId);
    } on SessionExpiredException {
      _handleSessionExpired();
    } catch (e) {
      print("Ett annat fel uppstod: $e");
    }
  }

  void _openAttachment(String baseUrl, String attachmentId, String fileExt) async {
    late final String urlString;
    if (fileExt == '.docx' || fileExt == '.xlsx' || fileExt == '.pptx') {
      urlString = 'https://view.officeapps.live.com/op/view.aspx?src=$baseUrl/$attachmentId$fileExt';
    } else {
      urlString = '$baseUrl/$attachmentId$fileExt';
    }

    await browser.open(
        url: WebUri(urlString),
        options: ChromeSafariBrowserClassOptions(
            android: AndroidChromeCustomTabsOptions(shareState: CustomTabsShareState.SHARE_STATE_OFF),
            ios: IOSSafariOptions(
                barCollapsingEnabled: true,
                preferredBarTintColor: Theme.of(context).primaryColor,
                preferredControlTintColor: Colors.white,
                dismissButtonStyle: IOSSafariDismissButtonStyle.CLOSE
            ),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.documentName,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildBody(provider, textTheme),
    );
  }

  Widget _buildBody(DocumentProvider provider, TextTheme textTheme) {
    if (provider.isLoading && provider.documentDetail == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Kunde inte ladda dokument:\n${provider.error}',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(color: Colors.red),
          ),
        ),
      );
    }

    final doc = provider.documentDetail;
    if (doc == null) {
      return const Center(child: Text('Dokumentet kunde inte hittas.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(doc.name, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline),
            title: Text('Status: ${doc.status}'),
            dense: true,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline),
            title: Text('Skapad av: ${doc.createdBy}'),
            dense: true,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text('Skapad: ${doc.createdDate}'),
            dense: true,
          ),
          const Divider(height: 32),
          Text('Bilagor', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          if (doc.attachments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Inga bilagor hittades.'),
            )
          else
            ...doc.attachments.map((att) {
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: Text(att.fileName),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openAttachment(doc.baseUrl, att.id, att.fileExt),
                ),
              );
            }),
        ],
      ),
    );
  }
}