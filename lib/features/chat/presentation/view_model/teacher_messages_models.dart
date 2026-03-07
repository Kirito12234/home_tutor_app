class TeacherThreadItem {
  const TeacherThreadItem({
    required this.id,
    required this.participantId,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.isOnline,
  });

  final String id;
  final String? participantId;
  final String name;
  final String lastMessage;
  final String time;
  final bool isOnline;

  TeacherThreadItem copyWith({
    String? id,
    String? participantId,
    String? name,
    String? lastMessage,
    String? time,
    bool? isOnline,
  }) {
    return TeacherThreadItem(
      id: id ?? this.id,
      participantId: participantId ?? this.participantId,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      time: time ?? this.time,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class TeacherStudentItem {
  const TeacherStudentItem({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  static TeacherStudentItem fromTutorStudentJson(Map<String, dynamic> json) {
    final student = json['student'];
    final studentMap =
        student is Map<String, dynamic> ? student : <String, dynamic>{};
    return TeacherStudentItem(
      id: studentMap['_id']?.toString() ?? studentMap['id']?.toString() ?? '',
      name: studentMap['name']?.toString() ?? 'Student',
    );
  }
}

class TeacherRequestItem {
  const TeacherRequestItem({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseTitle,
    required this.status,
    required this.isDeleted,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String courseTitle;
  final String status;
  final bool isDeleted;

  static TeacherRequestItem fromJson(Map<String, dynamic> json) {
    final student = json['student'];
    final studentMap =
        student is Map<String, dynamic> ? student : <String, dynamic>{};
    final course = json['course'];
    final courseMap = course is Map<String, dynamic> ? course : <String, dynamic>{};

    return TeacherRequestItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      studentId:
          studentMap['_id']?.toString() ?? studentMap['id']?.toString() ?? '',
      studentName: studentMap['name']?.toString() ?? 'Student',
      courseTitle: courseMap['title']?.toString() ?? 'Course',
      status: json['status']?.toString() ?? 'pending',
      isDeleted: json['isDeleted'] == true ||
          json['deleted'] == true ||
          (json['status']?.toString().toLowerCase() == 'deleted'),
    );
  }
}

