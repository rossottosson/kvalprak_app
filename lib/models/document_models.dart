// lib/models/document_models.dart
// SLUTGILTIG KORRIGERING 2: Hanterar nu även "main_attachment" som en bilaga.

class MainMenu {
  final String id;
  final String name;
  final String type;

  MainMenu({required this.id, required this.name, required this.type});

  factory MainMenu.fromJson(Map<String, dynamic> json) {
    return MainMenu(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Okänd Meny',
      type: json['type'] ?? 'menu',
    );
  }
}

class MenuItem {
  final String id;
  final String name;
  final String type;
  final String parentId;
  final int level;

  MenuItem({
    required this.id,
    required this.name,
    required this.type,
    required this.parentId,
    required this.level,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Okänt Objekt',
      type: json['type'] ?? 'unknown',
      parentId: json['parent_id'] ?? '',
      level: json['level'] ?? 0,
    );
  }
}

class Attachment {
  final String id;
  final String fileName;
  final String fileExt;

  Attachment({required this.id, required this.fileName, required this.fileExt});

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['attachment_id'] ?? '',
      fileName: json['file_name'] ?? 'Okänd fil',
      fileExt: json['file_ext'] ?? '',
    );
  }
}

class DocumentDetail {
  final String id;
  final String name;
  final String status;
  final String createdDate;
  final String createdBy;
  final List<Attachment> attachments;
  final String baseUrl;
  final String? mainAttachment;

  DocumentDetail({
    required this.id,
    required this.name,
    required this.status,
    required this.createdDate,
    required this.createdBy,
    required this.attachments,
    required this.baseUrl,
    this.mainAttachment,
  });

  factory DocumentDetail.fromJson(Map<String, dynamic> json) {
    final docData = json['document'] as Map<String, dynamic>? ?? {};
    
    // Börja med listan över extra bilagor
    final attachmentsListJson = docData['attachments'] as List<dynamic>? ?? [];
    final List<Attachment> finalAttachments = attachmentsListJson.map((attJson) => Attachment.fromJson(attJson)).toList();

    // ===================================
    // === HÄR ÄR DEN NYA LOGIKEN ===
    // ===================================
    // Titta efter en "main_attachment"
    final mainAttachmentString = docData['main_attachment'] as String?;
    if (mainAttachmentString != null && mainAttachmentString.isNotEmpty) {
      // Skapa ett Attachment-objekt från huvudfilen
      final mainAttachmentFileExt = mainAttachmentString.contains('.') ? '.${mainAttachmentString.split('.').last}' : '';
      final mainAttachmentId = mainAttachmentString.replaceAll(mainAttachmentFileExt, '');
      
      final mainAttachmentObject = Attachment(
        id: mainAttachmentId,
        fileName: docData['name'] ?? mainAttachmentString, // Använd dokumentets namn för huvudfilen
        fileExt: mainAttachmentFileExt,
      );
      // Lägg till den FÖRST i listan
      finalAttachments.insert(0, mainAttachmentObject);
    }

    return DocumentDetail(
      id: docData['id'] ?? '',
      name: docData['name'] ?? 'Okänt dokument',
      status: docData['status'] ?? 'okänd',
      createdDate: docData['created_date'] ?? '',
      createdBy: docData['created_by'] ?? '',
      attachments: finalAttachments, // Använd den nya, kompletta listan
      baseUrl: docData['base_url'] ?? '',
      mainAttachment: docData['main_attachment'],
    );
  }
}