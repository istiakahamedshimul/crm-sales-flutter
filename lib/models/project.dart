class ProjectSubGroup {
  const ProjectSubGroup({required this.id, required this.name, required this.companyName});
  final int id;
  final String name;
  final String companyName;

  factory ProjectSubGroup.fromJson(Map<String, dynamic> json) => ProjectSubGroup(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        companyName: json['companyName'] as String? ?? 'Real Capital Group',
      );
}

class CrmProject {
  const CrmProject({required this.id, required this.name, required this.subGroupId, required this.type});
  final int id;
  final String name;
  final int subGroupId;
  final int type;

  factory CrmProject.fromJson(Map<String, dynamic> json) => CrmProject(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        subGroupId: json['subGroupId'] as int,
        type: json['type'] as int,
      );
}
