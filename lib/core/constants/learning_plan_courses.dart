class LearningPlanCourse {
  final String id;
  final String title;
  final String description;
  final String level;
  final String mentor;
  final int completed;
  final int total;
  final int weeks;
  final List<String> modules;

  const LearningPlanCourse({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.mentor,
    required this.completed,
    required this.total,
    required this.weeks,
    required this.modules,
  });
}

List<LearningPlanCourse> buildLearningPlanCourses() {
  const seeds = [
    LearningPlanCourse(
      id: 'ethical-hacking',
      title: 'Ethical Hacking',
      description: 'Network security labs, threat modeling, and CTF practice.',
      level: 'Beginner',
      mentor: 'Sujan Karki',
      completed: 12,
      total: 32,
      weeks: 8,
      modules: [
        'Recon and scanning',
        'Vulnerability assessment',
        'Web security basics',
        'Exploit fundamentals',
        'Reporting and ethics',
      ],
    ),
    LearningPlanCourse(
      id: 'ai-data-science',
      title: 'AI with Data Science',
      description: 'Data pipelines, ML models, and applied analytics.',
      level: 'Intermediate',
      mentor: 'Anisha Rai',
      completed: 8,
      total: 40,
      weeks: 10,
      modules: [
        'Python foundations',
        'Data cleaning',
        'Model training',
        'Evaluation and tuning',
        'Deployment basics',
      ],
    ),
    LearningPlanCourse(
      id: 'product-design',
      title: 'Product Design',
      description: 'Problem framing, UX flows, and product storytelling.',
      level: 'Beginner',
      mentor: 'Prerna Thapa',
      completed: 6,
      total: 24,
      weeks: 6,
      modules: [
        'User research',
        'Wireframing',
        'UI systems',
        'Prototyping',
        'Design critique',
      ],
    ),
    LearningPlanCourse(
      id: 'ui-ux-design',
      title: 'UI/UX Design',
      description: 'Interaction design, accessibility, and UX audits.',
      level: 'Intermediate',
      mentor: 'Rojan Shrestha',
      completed: 9,
      total: 30,
      weeks: 7,
      modules: [
        'UX heuristics',
        'Interface patterns',
        'Accessibility',
        'Usability testing',
        'Portfolio polish',
      ],
    ),
    LearningPlanCourse(
      id: 'full-stack-dev',
      title: 'Full-Stack Development',
      description: 'APIs, databases, and modern frontend workflows.',
      level: 'Intermediate',
      mentor: 'Bikash Shrestha',
      completed: 14,
      total: 36,
      weeks: 9,
      modules: [
        'Frontend essentials',
        'REST APIs',
        'Database design',
        'Authentication',
        'Deployment',
      ],
    ),
    LearningPlanCourse(
      id: 'mobile-app-dev',
      title: 'Mobile App Development',
      description: 'Flutter UI, state management, and app release.',
      level: 'Beginner',
      mentor: 'Laxmi Adhikari',
      completed: 10,
      total: 28,
      weeks: 7,
      modules: [
        'Flutter UI',
        'State patterns',
        'Firebase basics',
        'Animations',
        'Store launch',
      ],
    ),
    LearningPlanCourse(
      id: 'cloud-devops',
      title: 'Cloud & DevOps',
      description: 'Containers, CI/CD, and cloud deployment.',
      level: 'Intermediate',
      mentor: 'Prerna Thapa',
      completed: 7,
      total: 26,
      weeks: 6,
      modules: [
        'Docker basics',
        'CI/CD pipelines',
        'Cloud services',
        'Monitoring',
        'Scaling',
      ],
    ),
    LearningPlanCourse(
      id: 'data-analytics',
      title: 'Data Analytics',
      description: 'Dashboards, insights, and business reporting.',
      level: 'Beginner',
      mentor: 'Anisha Rai',
      completed: 11,
      total: 34,
      weeks: 8,
      modules: [
        'Data prep',
        'SQL basics',
        'Dashboards',
        'Storytelling',
        'KPI tracking',
      ],
    ),
    LearningPlanCourse(
      id: 'cybersecurity-essentials',
      title: 'Cybersecurity Essentials',
      description: 'Core defense skills and security operations.',
      level: 'Beginner',
      mentor: 'Sujan Karki',
      completed: 5,
      total: 20,
      weeks: 5,
      modules: [
        'Security basics',
        'Endpoint protection',
        'Network defense',
        'Incident response',
        'Risk management',
      ],
    ),
    LearningPlanCourse(
      id: 'digital-marketing',
      title: 'Digital Marketing',
      description: 'SEO, campaigns, and analytics-driven growth.',
      level: 'Beginner',
      mentor: 'Aayush Rana',
      completed: 4,
      total: 18,
      weeks: 5,
      modules: [
        'SEO basics',
        'Content strategy',
        'Ads and targeting',
        'Analytics',
        'Optimization',
      ],
    ),
  ];

  final courses = <LearningPlanCourse>[];
  for (var i = 0; i < 100; i++) {
    final seed = seeds[i % seeds.length];
    final level = (i ~/ seeds.length) + 1;
    final title = level == 1 ? seed.title : '${seed.title} Level $level';
    final description = level == 1
        ? seed.description
        : '${seed.description} Advanced level $level.';
    final completed = (seed.completed + (i * 3)) % seed.total;
    courses.add(
      LearningPlanCourse(
        id: '${seed.id}-$i',
        title: title,
        description: description,
        level: seed.level,
        mentor: seed.mentor,
        completed: completed == 0 ? 1 : completed,
        total: seed.total,
        weeks: seed.weeks,
        modules: seed.modules,
      ),
    );
  }
  return courses;
}
