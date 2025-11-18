class PasswordValidator {
  /// Validează puterea parolei
  /// Returnează un Map cu rezultatul validării
  static Map<String, dynamic> validate(String password) {
    final errors = <String>[];

    // Verifică lungimea minimă
    if (password.length < 8) {
      errors.add('Minimum 8 characters required');
    }

    // Verifică literă mare
    if (!password.contains(RegExp(r'[A-Z]'))) {
      errors.add('At least one uppercase letter (A-Z)');
    }

    // Verifică literă mică
    if (!password.contains(RegExp(r'[a-z]'))) {
      errors.add('At least one lowercase letter (a-z)');
    }

    // Verifică cifră
    if (!password.contains(RegExp(r'[0-9]'))) {
      errors.add('At least one number (0-9)');
    }

    // Verifică caracter special
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add('At least one special character (!@#\$%^&*...)');
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'strength': _calculateStrength(password),
    };
  }

  /// Calculează puterea parolei (0-100)
  static int _calculateStrength(String password) {
    int strength = 0;

    // Lungime
    if (password.length >= 8) strength += 20;
    if (password.length >= 12) strength += 10;
    if (password.length >= 16) strength += 10;

    // Litere mari
    if (password.contains(RegExp(r'[A-Z]'))) strength += 15;

    // Litere mici
    if (password.contains(RegExp(r'[a-z]'))) strength += 15;

    // Cifre
    if (password.contains(RegExp(r'[0-9]'))) strength += 15;

    // Caractere speciale
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 15;

    return strength.clamp(0, 100);
  }

  /// Returnează mesajul de putere bazat pe scor
  static String getStrengthMessage(int strength) {
    if (strength < 40) return 'Weak';
    if (strength < 70) return 'Medium';
    if (strength < 90) return 'Strong';
    return 'Very Strong';
  }

  /// Returnează culoarea pentru indicator bazat pe putere
  static String getStrengthColor(int strength) {
    if (strength < 40) return '#EF4444'; // red
    if (strength < 70) return '#F59E0B'; // orange
    if (strength < 90) return '#10B981'; // green
    return '#059669'; // dark green
  }
}
