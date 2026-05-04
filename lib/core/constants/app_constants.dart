class AppConstants {
  AppConstants._();

  static const int otpExpiryMinutes = 10;
  static const int minMatchScoreToApply = 40;
  static const int strongMatchThreshold = 80;

  static const List<String> skillOptions = [
    'Flutter', 'React', 'Node.js', 'Python', 'Java', 'Kotlin', 'Swift',
    'Go', 'Rust', 'TypeScript', 'JavaScript', 'C++', 'AWS', 'GCP', 'Azure',
    'Docker', 'Kubernetes', 'SQL', 'MongoDB', 'Firebase', 'GraphQL',
    'Machine Learning', 'Data Science', 'DevOps', 'System Design', 'Agile',
  ];

  static const List<String> commonTags = [
    'urgent', 'remote-friendly', 'startup', 'mnc', 'fintech',
    'healthtech', 'edtech', 'ai/ml', 'senior', 'lead',
  ];

  static const List<String> freeEmailDomains = [
    'gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com',
    'icloud.com', 'aol.com', 'mail.com', 'protonmail.com',
  ];

  static const Map<String, List<String>> skillAliases = {
    'javascript': ['js', 'javascript', 'es6', 'es2015', 'ecmascript'],
    'typescript': ['ts', 'typescript'],
    'react': ['react', 'reactjs', 'react.js'],
    'node': ['node', 'nodejs', 'node.js'],
    'python': ['python', 'python3', 'py'],
    'java': ['java', 'core java', 'java8', 'java11'],
    'kubernetes': ['kubernetes', 'k8s'],
    'aws': ['aws', 'amazon web services', 'amazon aws'],
    'gcp': ['gcp', 'google cloud', 'google cloud platform'],
    'azure': ['azure', 'microsoft azure'],
    'sql': ['sql', 'mysql', 'postgresql', 'postgres', 'mssql'],
    'mongodb': ['mongodb', 'mongo'],
    'docker': ['docker', 'container', 'containerization'],
    'git': ['git', 'github', 'gitlab', 'version control'],
    'machine learning': ['ml', 'machine learning', 'deep learning', 'ai'],
    'flutter': ['flutter', 'dart flutter'],
    'spring': ['spring', 'spring boot', 'spring framework'],
    'react native': ['react native', 'rn', 'react-native'],
    'data analysis': ['data analysis', 'data analytics', 'analytics'],
    'system design': ['system design', 'distributed systems', 'architecture'],
  };

  static const Map<String, List<String>> titleImpliedSkills = {
    'software engineer': ['coding', 'system design', 'git', 'debugging'],
    'frontend': ['javascript', 'react', 'css', 'html'],
    'backend': ['api', 'database', 'sql', 'server'],
    'fullstack': ['javascript', 'react', 'node', 'sql'],
    'data scientist': ['python', 'machine learning', 'sql', 'statistics'],
    'devops': ['kubernetes', 'docker', 'aws', 'ci/cd'],
    'product manager': ['product strategy', 'agile', 'roadmap', 'stakeholder'],
    'data engineer': ['python', 'sql', 'etl', 'spark'],
    'android': ['android', 'kotlin', 'java'],
    'ios': ['ios', 'swift', 'objective-c'],
  };

  static const List<List<String>> regionGroups = [
    ['bangalore', 'bengaluru', 'blr'],
    ['hyderabad', 'hyd', 'secunderabad'],
    ['mumbai', 'bombay', 'bom', 'pune', 'navi mumbai'],
    ['delhi', 'ncr', 'gurgaon', 'gurugram', 'noida', 'faridabad'],
    ['chennai', 'madras', 'coimbatore'],
    ['kolkata', 'calcutta'],
  ];
}
