import '../../domain/entities/course.dart';
import '../../../dashboard/domain/entities/lesson.dart';

class DummyCourses {
  static List<Course> getCourses() {
    final seeds = [
      Course(
        id: '1',
        title: 'ProductDesign v1.0',
        instructor: 'sagar shrestha',
        price: 19000,
        durationHours: 6,
        lessonCount: 24,
        category: 'Visual identity',
        description: 'So that you can clearly understand where all this mistake comes from, the mistake that causes blame and pain, and so that you can clearly understand where all this mistake comes from.',
        isBestseller: true,
        isPopular: true,
        lessons: [
          Lesson(
            id: '1-1',
            title: 'Welcome to the Course',
            durationMinutes: 6,
            isCompleted: true,
            order: 1,
          ),
          Lesson(
            id: '1-2',
            title: 'Process overview',
            durationMinutes: 6,
            order: 2,
          ),
          Lesson(
            id: '1-3',
            title: 'Discovery',
            durationMinutes: 6,
            isLocked: true,
            order: 3,
          ),
          Lesson(
            id: '1-4',
            title: 'User Research',
            durationMinutes: 8,
            isLocked: true,
            order: 4,
          ),
          Lesson(
            id: '1-5',
            title: 'Wireframing',
            durationMinutes: 10,
            isLocked: true,
            order: 5,
          ),
        ],
      ),
      Course(
        id: '2',
        title: 'Java Development',
        instructor: 'Albert Maharjan',
        price: 50000,
        durationHours: 16,
        lessonCount: 32,
        category: 'Coding',
        description: 'Learn Java programming from scratch with hands-on projects and real-world examples.',
        isPopular: true,
        lessons: [
          Lesson(
            id: '2-1',
            title: 'Introduction to Java',
            durationMinutes: 10,
            order: 1,
          ),
          Lesson(
            id: '2-2',
            title: 'Variables and Data Types',
            durationMinutes: 12,
            order: 2,
          ),
        ],
      ),
      Course(
        id: '3',
        title: 'Visual Design',
        instructor: 'Bishikha Satgaiya',
        price: 20000,
        durationHours: 14,
        lessonCount: 20,
        category: 'Visual identity',
        description: 'Master the fundamentals of visual design and create stunning graphics.',
        isNew: true,
        lessons: [
          Lesson(
            id: '3-1',
            title: 'Design Principles',
            durationMinutes: 8,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '4',
        title: 'Product Design',
        instructor: 'santosh shrestha',
        price: 19000,
        durationHours: 16,
        lessonCount: 24,
        category: 'Visual identity',
        description: 'Complete product design course covering all aspects of design thinking.',
        lessons: [
          Lesson(
            id: '4-1',
            title: 'Introduction',
            durationMinutes: 5,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '5',
        title: 'Brand Identity',
        instructor: 'Sagar Shrestha',
        price: 25000,
        durationHours: 14,
        lessonCount: 18,
        category: 'Visual identity',
        description: 'Build strong brand systems and identity guidelines.',
        lessons: [
          Lesson(
            id: '5-1',
            title: 'Brand Strategy',
            durationMinutes: 7,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '6',
        title: 'UI Systems',
        instructor: 'Andesh Shahi',
        price: 30000,
        durationHours: 16,
        lessonCount: 22,
        category: 'Visual identity',
        description: 'Design consistent UI components and design systems.',
        lessons: [
          Lesson(
            id: '6-1',
            title: 'System Foundations',
            durationMinutes: 6,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '7',
        title: 'Watercolor Basics',
        instructor: 'Pratiksha Lama',
        price: 14000,
        durationHours: 10,
        lessonCount: 16,
        category: 'Painting',
        description: 'Learn watercolor techniques and color blending.',
        lessons: [
          Lesson(
            id: '7-1',
            title: 'Brush control',
            durationMinutes: 8,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '8',
        title: 'Acrylic Landscapes',
        instructor: 'Kiran Thapa',
        price: 18000,
        durationHours: 12,
        lessonCount: 18,
        category: 'Painting',
        description: 'Create vibrant landscapes with acrylic paints.',
        lessons: [
          Lesson(
            id: '8-1',
            title: 'Color palettes',
            durationMinutes: 9,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '9',
        title: 'Flutter Mobile Apps',
        instructor: 'Bikash Shrestha',
        price: 26000,
        durationHours: 18,
        lessonCount: 30,
        category: 'Coding',
        description: 'Build production-ready apps with Flutter and Firebase.',
        lessons: [
          Lesson(
            id: '9-1',
            title: 'Widgets and layouts',
            durationMinutes: 12,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '10',
        title: 'Python for Data Science',
        instructor: 'Anisha Rai',
        price: 28000,
        durationHours: 20,
        lessonCount: 34,
        category: 'Coding',
        description: 'Analyze data and build ML models with Python.',
        lessons: [
          Lesson(
            id: '10-1',
            title: 'Data frames',
            durationMinutes: 11,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '11',
        title: 'Content Writing',
        instructor: 'Aayush Rana',
        price: 12000,
        durationHours: 8,
        lessonCount: 14,
        category: 'Writing',
        description: 'Write clear, engaging content for digital platforms.',
        lessons: [
          Lesson(
            id: '11-1',
            title: 'Writing briefs',
            durationMinutes: 7,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '12',
        title: 'Technical Writing',
        instructor: 'Rita Gurung',
        price: 15000,
        durationHours: 10,
        lessonCount: 16,
        category: 'Writing',
        description: 'Create documentation and product guides.',
        lessons: [
          Lesson(
            id: '12-1',
            title: 'Structure and clarity',
            durationMinutes: 8,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '13',
        title: 'Sketching for Designers',
        instructor: 'Nabin Basnet',
        price: 11000,
        durationHours: 6,
        lessonCount: 12,
        category: 'Painting',
        description: 'Learn sketching techniques for visual ideation.',
        lessons: [
          Lesson(
            id: '13-1',
            title: 'Line practice',
            durationMinutes: 6,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '14',
        title: 'Ethical Hacking Basics',
        instructor: 'Sujan Karki',
        price: 32000,
        durationHours: 22,
        lessonCount: 36,
        category: 'Coding',
        description: 'Security fundamentals, scanning, and safe practice labs.',
        lessons: [
          Lesson(
            id: '14-1',
            title: 'Recon overview',
            durationMinutes: 10,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '15',
        title: 'Copywriting Essentials',
        instructor: 'Sarina Shrestha',
        price: 13000,
        durationHours: 9,
        lessonCount: 15,
        category: 'Writing',
        description: 'Craft persuasive copy for ads and campaigns.',
        lessons: [
          Lesson(
            id: '15-1',
            title: 'Headline formulas',
            durationMinutes: 7,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '16',
        title: 'Brand Strategy',
        instructor: 'Anil Gurung',
        price: 22000,
        durationHours: 12,
        lessonCount: 20,
        category: 'Visual identity',
        description: 'Positioning, tone, and identity systems for brands.',
        lessons: [
          Lesson(
            id: '16-1',
            title: 'Brand positioning',
            durationMinutes: 9,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '17',
        title: 'Logo Design',
        instructor: 'Ritika Basnet',
        price: 16000,
        durationHours: 8,
        lessonCount: 14,
        category: 'Visual identity',
        description: 'Create memorable logos and brand marks.',
        lessons: [
          Lesson(
            id: '17-1',
            title: 'Sketching ideas',
            durationMinutes: 7,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '18',
        title: 'Character Illustration',
        instructor: 'Suyog Maharjan',
        price: 17000,
        durationHours: 11,
        lessonCount: 17,
        category: 'Painting',
        description: 'Illustrate characters using traditional techniques.',
        lessons: [
          Lesson(
            id: '18-1',
            title: 'Shapes and forms',
            durationMinutes: 8,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '19',
        title: 'Urban Sketching',
        instructor: 'Nisha Karki',
        price: 15000,
        durationHours: 9,
        lessonCount: 14,
        category: 'Painting',
        description: 'Sketch cityscapes with ink and watercolor.',
        lessons: [
          Lesson(
            id: '19-1',
            title: 'Perspective basics',
            durationMinutes: 7,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '20',
        title: 'Full-Stack Web',
        instructor: 'Ramesh Adhikari',
        price: 36000,
        durationHours: 24,
        lessonCount: 40,
        category: 'Coding',
        description: 'Build full-stack apps with modern tools.',
        lessons: [
          Lesson(
            id: '20-1',
            title: 'Project setup',
            durationMinutes: 12,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '21',
        title: 'React Essentials',
        instructor: 'Sujata Shrestha',
        price: 24000,
        durationHours: 14,
        lessonCount: 26,
        category: 'Coding',
        description: 'Build dynamic web UIs with React.',
        lessons: [
          Lesson(
            id: '21-1',
            title: 'Components',
            durationMinutes: 10,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '22',
        title: 'SEO Writing',
        instructor: 'Kiran Bista',
        price: 14000,
        durationHours: 8,
        lessonCount: 12,
        category: 'Writing',
        description: 'Write search-friendly content that ranks.',
        lessons: [
          Lesson(
            id: '22-1',
            title: 'Keyword research',
            durationMinutes: 6,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '23',
        title: 'Storytelling',
        instructor: 'Asmita Shah',
        price: 18000,
        durationHours: 12,
        lessonCount: 18,
        category: 'Writing',
        description: 'Narrative structure and engaging storytelling.',
        lessons: [
          Lesson(
            id: '23-1',
            title: 'Story arcs',
            durationMinutes: 8,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '24',
        title: 'Pen Testing Lab',
        instructor: 'Sujan Karki',
        price: 38000,
        durationHours: 20,
        lessonCount: 34,
        category: 'Coding',
        description: 'Hands-on penetration testing practice.',
        lessons: [
          Lesson(
            id: '24-1',
            title: 'Lab setup',
            durationMinutes: 11,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '25',
        title: 'Illustration for Brands',
        instructor: 'Bishal Joshi',
        price: 21000,
        durationHours: 13,
        lessonCount: 20,
        category: 'Visual identity',
        description: 'Illustration styles tailored for brand systems.',
        lessons: [
          Lesson(
            id: '25-1',
            title: 'Brand style mapping',
            durationMinutes: 9,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '26',
        title: 'Typography Systems',
        instructor: 'Saraswati Paudel',
        price: 12000,
        durationHours: 6,
        lessonCount: 12,
        category: 'Visual identity',
        description: 'Type pairing, hierarchy, and readable systems.',
        lessons: [
          Lesson(
            id: '26-1',
            title: 'Type anatomy',
            durationMinutes: 6,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '27',
        title: 'Brand Guidelines',
        instructor: 'Anil Gurung',
        price: 28000,
        durationHours: 18,
        lessonCount: 30,
        category: 'Visual identity',
        description: 'Build full identity guidelines and usage rules.',
        lessons: [
          Lesson(
            id: '27-1',
            title: 'Guideline structure',
            durationMinutes: 10,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '28',
        title: 'Oil Painting',
        instructor: 'Sangita Karki',
        price: 24000,
        durationHours: 20,
        lessonCount: 28,
        category: 'Painting',
        description: 'Master oil paint blending and textures.',
        lessons: [
          Lesson(
            id: '28-1',
            title: 'Color mixing',
            durationMinutes: 11,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '29',
        title: 'Portrait Painting',
        instructor: 'Bikram Rai',
        price: 19000,
        durationHours: 14,
        lessonCount: 20,
        category: 'Painting',
        description: 'Paint realistic portraits with light and shadow.',
        lessons: [
          Lesson(
            id: '29-1',
            title: 'Face proportions',
            durationMinutes: 9,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '30',
        title: 'Node.js APIs',
        instructor: 'Ramesh Adhikari',
        price: 32000,
        durationHours: 22,
        lessonCount: 32,
        category: 'Coding',
        description: 'Build scalable APIs with Node and Express.',
        lessons: [
          Lesson(
            id: '30-1',
            title: 'Routing',
            durationMinutes: 12,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '31',
        title: 'UI Testing with Flutter',
        instructor: 'Bikash Shrestha',
        price: 18000,
        durationHours: 8,
        lessonCount: 14,
        category: 'Coding',
        description: 'Write widget tests and golden tests.',
        lessons: [
          Lesson(
            id: '31-1',
            title: 'Test setup',
            durationMinutes: 8,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '32',
        title: 'Data Visualization',
        instructor: 'Anisha Rai',
        price: 26000,
        durationHours: 16,
        lessonCount: 24,
        category: 'Coding',
        description: 'Turn data into dashboards and stories.',
        lessons: [
          Lesson(
            id: '32-1',
            title: 'Chart selection',
            durationMinutes: 9,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '33',
        title: 'Script Writing',
        instructor: 'Smriti Thapa',
        price: 16000,
        durationHours: 10,
        lessonCount: 16,
        category: 'Writing',
        description: 'Write scripts for video and audio content.',
        lessons: [
          Lesson(
            id: '33-1',
            title: 'Story beats',
            durationMinutes: 7,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '34',
        title: 'UX Writing',
        instructor: 'Rita Gurung',
        price: 21000,
        durationHours: 12,
        lessonCount: 18,
        category: 'Writing',
        description: 'Craft microcopy and product messaging.',
        lessons: [
          Lesson(
            id: '34-1',
            title: 'Tone and voice',
            durationMinutes: 8,
            order: 1,
          ),
        ],
      ),
      Course(
        id: '35',
        title: 'Long-form Blogging',
        instructor: 'Aayush Rana',
        price: 11000,
        durationHours: 6,
        lessonCount: 10,
        category: 'Writing',
        description: 'Research, outline, and publish long-form content.',
        lessons: [
          Lesson(
            id: '35-1',
            title: 'Outlining',
            durationMinutes: 6,
            order: 1,
          ),
        ],
      ),
    ];

    final courses = <Course>[];
    for (var i = 0; i < 100; i++) {
      final seed = seeds[i % seeds.length];
      final level = (i ~/ seeds.length) + 1;
      final title = level == 1 ? seed.title : '${seed.title} Level $level';
      final description = level == 1
          ? seed.description
          : '${seed.description} Advanced level $level.';
      courses.add(
        Course(
          id: '${seed.id}-$i',
          title: title,
          instructor: seed.instructor,
          price: seed.price,
          durationHours: seed.durationHours,
          lessonCount: seed.lessonCount,
          category: seed.category,
          description: description,
          isBestseller: seed.isBestseller,
          isPopular: seed.isPopular || i % 5 == 0,
          isNew: seed.isNew || i % 7 == 0,
          imageUrl: seed.imageUrl,
          lessons: seed.lessons,
        ),
      );
    }
    return courses;
  }

  static List<Course> filterCourses({
    List<String>? categories,
    String? durationRange,
    double? minPrice,
    double? maxPrice,
  }) {
    var courses = getCourses();
    
    if (categories != null && categories.isNotEmpty) {
      final lowered = categories.map((c) => c.toLowerCase()).toList();
      courses = courses
          .where((c) => lowered.contains(c.category.toLowerCase()))
          .toList();
    }
    
    if (durationRange != null) {
      final ranges = durationRange.split('-');
      if (ranges.length == 2) {
        final min = int.tryParse(ranges[0].trim());
        final max = int.tryParse(ranges[1].split(' ')[0].trim());
        if (min != null && max != null) {
          courses = courses.where((c) => c.durationHours >= min && c.durationHours <= max).toList();
        }
      }
    }
    
    if (minPrice != null) {
      courses = courses.where((c) => c.price >= minPrice).toList();
    }
    
    if (maxPrice != null) {
      courses = courses.where((c) => c.price <= maxPrice).toList();
    }
    
    return courses;
  }
}

