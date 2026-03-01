class MockData {
  static List<Map<String, dynamic>> get educationItems => [
        {
          'title': 'How to identify Cyber Stalking',
          'category': 'Cyber Safety',
          'imageUrl':
              'https://images.unsplash.com/photo-1563986768609-322da13575f3?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
          'content': 'Cyber stalking involves the use of the internet...',
        },
        {
          'title': 'Protecting Your Social Media',
          'category': 'Privacy',
          'imageUrl':
              'https://images.unsplash.com/photo-1614064641913-6b71a2eaa48a?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
          'content': 'Ensure your privacy settings are up to date...',
        },
        {
          'title': 'What to do if your pictures are leaked',
          'category': 'Emergency',
          'imageUrl':
              'https://images.unsplash.com/photo-1510511459019-5d67afae2611?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
          'content': 'First, do not panic. Document the evidence...',
        },
        {
          'title': 'Understanding Consent Online',
          'category': 'Education',
          'imageUrl':
              'https://images.unsplash.com/photo-1573164713988-8665fc963095?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
          'content': 'Digital consent is just as important as physical...',
        },
        {
          'title': 'Digital Footprint Basics',
          'category': 'Awareness',
          'imageUrl':
              'https://images.unsplash.com/photo-1451187580459-43490279c0fa?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
          'content': 'Everything you post online leaves a trace...',
        },
      ];

  static List<Map<String, dynamic>> get dummyReports => [
        {'id': 'CAS-1021', 'type': 'Cyber Stalking', 'status': 'Pending'},
        {'id': 'CAS-1022', 'type': 'Image Abuse', 'status': 'Investigating'},
        {'id': 'CAS-1023', 'type': 'Online Harassment', 'status': 'Resolved'},
        {'id': 'CAS-1024', 'type': 'Identity Theft', 'status': 'Pending'},
        {'id': 'CAS-1025', 'type': 'Defamation', 'status': 'Resolved'},
      ];
}
