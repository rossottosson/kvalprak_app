// lib/models/clinic_model.dart
// NEW FILE

/// Represents a clinic with a name and its specific subdomain.
class Clinic {
  final String name; // Name to display in search results
  final String subdomain; // The 'customclinicname' part of the URL

  Clinic({required this.name, required this.subdomain});

  @override
  String toString() {
    return 'Clinic(name: $name, subdomain: $subdomain)';
  }
}