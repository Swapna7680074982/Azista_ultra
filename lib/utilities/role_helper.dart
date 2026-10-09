class RoleHelper {
  /// Maps any backend rolecode or role name to the standard UI display name:
  /// SO -> FSE
  /// AM -> ASM
  /// RM -> RSM
  static String formatRole(String? role) {
    if (role == null || role.trim().isEmpty) return 'FSE';
    final norm = role.trim().toUpperCase();
    if (norm == 'SO' ||
        norm == 'FSE' ||
        norm.contains('SALE OFF') ||
        norm.contains('SALES OFF') ||
        norm.contains('SALE OFFICER') ||
        norm.contains('SALES OFFICER') ||
        norm.contains('SALES') ||
        norm.contains('SALE')) {
      return 'FSE';
    } else if (norm == 'AM' ||
        norm == 'ASM' ||
        norm.contains('AREA') ||
        norm.contains('AREA MANAGER')) {
      return 'ASM';
    } else if (norm == 'RM' ||
        norm == 'RSM' ||
        norm.contains('REGION') ||
        norm.contains('REGIONAL MANAGER')) {
      return 'RSM';
    } else if (norm == 'ADMIN') {
      return 'ADMIN';
    }
    return norm;
  }

  /// Full descriptive title
  static String roleFullTitle(String? role) {
    final f = formatRole(role);
    switch (f) {
      case 'FSE':
        return 'Field Sales Executive (FSE)';
      case 'ASM':
        return 'Area Sales Manager (ASM)';
      case 'RSM':
        return 'Regional Sales Manager (RSM)';
      default:
        return f;
    }
  }

  /// Plural team name for UI headers
  static String teamTitle(String? userRole, int count) {
    final f = formatRole(userRole);
    if (f == 'ASM') {
      return 'FSE MEMBERS ($count)';
    } else if (f == 'RSM') {
      return 'TEAM MEMBERS ($count)';
    }
    return 'TEAM MEMBERS ($count)';
  }
}
