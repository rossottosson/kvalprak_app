// lib/models/document_models.dart

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
    
    final attachmentsListJson = docData['attachments'] as List<dynamic>? ?? [];
    final List<Attachment> finalAttachments = attachmentsListJson.map((attJson) => Attachment.fromJson(attJson)).toList();

    final mainAttachmentString = docData['main_attachment'] as String?;
    
    if (mainAttachmentString != null && mainAttachmentString.isNotEmpty) {
      int lastDotIndex = mainAttachmentString.lastIndexOf('.');
      String fileName = mainAttachmentString;
      String fileExt = "";
      String attachmentId = mainAttachmentString;

      if (lastDotIndex != -1) {
        fileExt = mainAttachmentString.substring(lastDotIndex);
        attachmentId = mainAttachmentString.substring(0, lastDotIndex);
      }
      
      final mainAttachmentObject = Attachment(
        id: attachmentId,
        fileName: docData['name'] ?? mainAttachmentString,
        fileExt: fileExt,
      );
      finalAttachments.insert(0, mainAttachmentObject);
    }

    return DocumentDetail(
      id: docData['id'] ?? '',
      name: docData['name'] ?? 'Okänt dokument',
      status: docData['status'] ?? 'okänd',
      createdDate: docData['created_date'] ?? '',
      createdBy: docData['created_by'] ?? '',
      attachments: finalAttachments,
      baseUrl: docData['base_url'] ?? '',
      mainAttachment: docData['main_attachment'],
    );
  }
}

class DocumentSearchResult {
  final String id;
  final String name;
  final String description;
  final String folderName;
  final String menuName;

  DocumentSearchResult({
    required this.id,
    required this.name,
    required this.description,
    required this.folderName,
    required this.menuName,
  });

  factory DocumentSearchResult.fromJson(Map<String, dynamic> json) {
    return DocumentSearchResult(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Okänt dokument',
      description: json['description'] ?? '',
      folderName: json['folder_name'] ?? '',
      menuName: json['menu_name'] ?? '',
    );
  }
}