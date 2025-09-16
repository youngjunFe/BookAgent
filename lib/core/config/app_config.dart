class AppConfig {
  AppConfig._();

  // Flutter 웹용 하드코딩된 환경변수
  static String get supabaseUrl {
    return 'https://bssiddbhnuguloktqsmy.supabase.co';
  }

  static String get supabaseAnonKey {
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJzc2lkZGJobnVndWxva3Rxc215Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ2MjIyMDQsImV4cCI6MjA3MDE5ODIwNH0.s4I3VbC-FVSuwZLnkapmhIR5zC-dasPb8_BVQIxv2Z8';
  }

  static String get agentBaseUrl {
    return 'https://bookagent-production.up.railway.app';
  }
}


