class Project {
  final String id;
  final String name;
  final String rootPath;
  final String keyPath;
  final bool active;

  Project({
    required this.id, 
    required this.name, 
    required this.rootPath, 
    required this.keyPath, 
    this.active = true
  });

  bool get isGovMode => name.toUpperCase().contains('GOV') || name.toUpperCase().contains('GOBERNANZA');

  Map<String, dynamic> toJson() => {
    'id': id, 
    'name': name, 
    'rootPath': rootPath, 
    'keyPath': keyPath,
    'active': active,
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] ?? (json['name'] ?? 'project').toLowerCase(),
        name: json['name'] ?? 'UNNAMED',
        rootPath: json['rootPath'] ?? (json['path'] ?? ''),
        keyPath: json['keyPath'] ?? 'root',
        active: json['active'] ?? true,
      );
}
