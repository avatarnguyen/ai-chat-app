import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable authentication form widgets with enhanced validation and accessibility
class AuthFormWidgets {
  AuthFormWidgets._();

  /// Email input field with built-in validation
  static Widget emailField({
    required TextEditingController controller,
    String? labelText,
    String? hintText,
    TextInputAction? textInputAction,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onFieldSubmitted,
    bool enabled = true,
    bool autofocus = false,
    String? Function(String?)? validator,
  }) {
    return _CustomTextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction ?? TextInputAction.next,
      onEditingComplete: onEditingComplete,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
      autofocus: autofocus,
      validator: validator ?? _validateEmail,
      labelText: labelText ?? 'Email Address',
      hintText: hintText ?? 'Enter your email address',
      prefixIcon: const Icon(Icons.email_outlined),
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\s')), // No spaces
      ],
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
    );
  }

  /// Password input field with visibility toggle
  static Widget passwordField({
    required TextEditingController controller,
    required bool isPasswordVisible,
    required VoidCallback onToggleVisibility,
    String? labelText,
    String? hintText,
    TextInputAction? textInputAction,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onFieldSubmitted,
    bool enabled = true,
    bool autofocus = false,
    String? Function(String?)? validator,
    bool isNewPassword = false,
  }) {
    return _CustomTextFormField(
      controller: controller,
      obscureText: !isPasswordVisible,
      textInputAction: textInputAction ?? TextInputAction.done,
      onEditingComplete: onEditingComplete,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
      autofocus: autofocus,
      validator:
          validator ??
          (isNewPassword ? _validateNewPassword : _validatePassword),
      labelText: labelText ?? 'Password',
      hintText:
          hintText ??
          (isNewPassword ? 'Create a strong password' : 'Enter your password'),
      prefixIcon: const Icon(Icons.lock_outlined),
      suffixIcon: IconButton(
        icon: Icon(
          isPasswordVisible ? Icons.visibility_off : Icons.visibility,
          semanticLabel: isPasswordVisible ? 'Hide password' : 'Show password',
        ),
        onPressed: onToggleVisibility,
      ),
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
    );
  }

  /// Confirm password field with matching validation
  static Widget confirmPasswordField({
    required TextEditingController controller,
    required TextEditingController passwordController,
    required bool isPasswordVisible,
    required VoidCallback onToggleVisibility,
    String? labelText,
    String? hintText,
    TextInputAction? textInputAction,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onFieldSubmitted,
    bool enabled = true,
    bool autofocus = false,
  }) {
    return _CustomTextFormField(
      controller: controller,
      obscureText: !isPasswordVisible,
      textInputAction: textInputAction ?? TextInputAction.done,
      onEditingComplete: onEditingComplete,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
      autofocus: autofocus,
      validator:
          (value) => _validateConfirmPassword(value, passwordController.text),
      labelText: labelText ?? 'Confirm Password',
      hintText: hintText ?? 'Re-enter your password',
      prefixIcon: const Icon(Icons.lock_outlined),
      suffixIcon: IconButton(
        icon: Icon(
          isPasswordVisible ? Icons.visibility_off : Icons.visibility,
          semanticLabel: isPasswordVisible ? 'Hide password' : 'Show password',
        ),
        onPressed: onToggleVisibility,
      ),
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
    );
  }

  /// Display name input field
  static Widget displayNameField({
    required TextEditingController controller,
    String? labelText,
    String? hintText,
    TextInputAction? textInputAction,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onFieldSubmitted,
    bool enabled = true,
    bool autofocus = false,
    String? Function(String?)? validator,
  }) {
    return _CustomTextFormField(
      controller: controller,
      keyboardType: TextInputType.name,
      textInputAction: textInputAction ?? TextInputAction.next,
      onEditingComplete: onEditingComplete,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
      autofocus: autofocus,
      validator: validator ?? _validateDisplayName,
      labelText: labelText ?? 'Display Name',
      hintText: hintText ?? 'Enter your display name',
      prefixIcon: const Icon(Icons.person_outlined),
      textCapitalization: TextCapitalization.words,
      inputFormatters: [LengthLimitingTextInputFormatter(50)],
    );
  }

  /// Submit button with loading state
  static Widget submitButton({
    required VoidCallback? onPressed,
    required String text,
    bool isLoading = false,
    String? loadingText,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    double? width,
    double height = 56,
  }) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: backgroundColor?.withOpacity(0.6),
        ),
        child:
            isLoading
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          foregroundColor ?? Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(loadingText ?? 'Loading...'),
                  ],
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  /// OAuth button with provider styling
  static Widget oauthButton({
    required VoidCallback? onPressed,
    required String text,
    required IconData icon,
    bool isLoading = false,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? borderColor,
    double? width,
    double height = 56,
  }) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon:
            isLoading
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      foregroundColor ?? Colors.black,
                    ),
                  ),
                )
                : Icon(icon, color: foregroundColor),
        label: Text(
          text,
          style: TextStyle(
            color: foregroundColor,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(
            color: borderColor ?? Colors.grey.shade300,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  /// Form section divider with text
  static Widget sectionDivider({required String text, double spacing = 24}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  /// Password strength indicator
  static Widget passwordStrengthIndicator({
    required String password,
    bool isVisible = true,
  }) {
    if (!isVisible || password.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = _calculatePasswordStrength(password);
    final requirements = _getPasswordRequirements(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strength.value,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(strength.color),
                minHeight: 4,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              strength.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: strength.color,
              ),
            ),
          ],
        ),
        if (strength.value < 1.0) ...[
          const SizedBox(height: 8),
          ...requirements.map(
            (req) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Icon(
                    req.isMet
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 16,
                    color: req.isMet ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    req.text,
                    style: TextStyle(
                      fontSize: 12,
                      color: req.isMet ? Colors.green : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Error message widget
  static Widget errorMessage({
    required String? message,
    EdgeInsets padding = const EdgeInsets.symmetric(vertical: 8),
  }) {
    if (message == null || message.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.red.shade700, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Success message widget
  static Widget successMessage({
    required String? message,
    EdgeInsets padding = const EdgeInsets.symmetric(vertical: 8),
  }) {
    if (message == null || message.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.green.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.green.shade700, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom text form field with consistent styling
class _CustomTextFormField extends StatelessWidget {
  const _CustomTextFormField({
    required this.controller,
    this.keyboardType,
    this.textInputAction,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.validator,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final bool autofocus;
  final String? Function(String?)? validator;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onEditingComplete: onEditingComplete,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
      autofocus: autofocus,
      validator: validator,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

/// Validation functions
String? _validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your email address';
  }
  if (!RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  ).hasMatch(value)) {
    return 'Please enter a valid email address';
  }
  return null;
}

String? _validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your password';
  }
  if (value.length < 6) {
    return 'Password must be at least 6 characters long';
  }
  return null;
}

String? _validateNewPassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter a password';
  }
  if (value.length < 8) {
    return 'Password must be at least 8 characters long';
  }
  if (!RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]',
  ).hasMatch(value)) {
    return 'Password must contain uppercase, lowercase, number, and special character';
  }
  return null;
}

String? _validateConfirmPassword(String? value, String password) {
  if (value == null || value.isEmpty) {
    return 'Please confirm your password';
  }
  if (value != password) {
    return 'Passwords do not match';
  }
  return null;
}

String? _validateDisplayName(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your display name';
  }
  if (value.length < 2) {
    return 'Display name must be at least 2 characters long';
  }
  if (value.length > 50) {
    return 'Display name must be less than 50 characters';
  }
  return null;
}

/// Password strength calculation
class _PasswordStrength {
  const _PasswordStrength({
    required this.value,
    required this.label,
    required this.color,
  });

  final double value;
  final String label;
  final Color color;
}

_PasswordStrength _calculatePasswordStrength(String password) {
  if (password.isEmpty) {
    return const _PasswordStrength(
      value: 0.0,
      label: 'Weak',
      color: Colors.red,
    );
  }

  int score = 0;

  // Length check
  if (password.length >= 8) score++;
  if (password.length >= 12) score++;

  // Character variety checks
  if (RegExp(r'[a-z]').hasMatch(password)) score++;
  if (RegExp(r'[A-Z]').hasMatch(password)) score++;
  if (RegExp(r'\d').hasMatch(password)) score++;
  if (RegExp(r'[@$!%*?&]').hasMatch(password)) score++;

  switch (score) {
    case 0:
    case 1:
    case 2:
      return const _PasswordStrength(
        value: 0.25,
        label: 'Weak',
        color: Colors.red,
      );
    case 3:
    case 4:
      return const _PasswordStrength(
        value: 0.5,
        label: 'Fair',
        color: Colors.orange,
      );
    case 5:
      return const _PasswordStrength(
        value: 0.75,
        label: 'Good',
        color: Colors.blue,
      );
    case 6:
      return const _PasswordStrength(
        value: 1.0,
        label: 'Strong',
        color: Colors.green,
      );
    default:
      return const _PasswordStrength(
        value: 0.0,
        label: 'Weak',
        color: Colors.red,
      );
  }
}

class _PasswordRequirement {
  const _PasswordRequirement({required this.text, required this.isMet});

  final String text;
  final bool isMet;
}

List<_PasswordRequirement> _getPasswordRequirements(String password) {
  return [
    _PasswordRequirement(
      text: 'At least 8 characters',
      isMet: password.length >= 8,
    ),
    _PasswordRequirement(
      text: 'Contains lowercase letter',
      isMet: RegExp(r'[a-z]').hasMatch(password),
    ),
    _PasswordRequirement(
      text: 'Contains uppercase letter',
      isMet: RegExp(r'[A-Z]').hasMatch(password),
    ),
    _PasswordRequirement(
      text: 'Contains number',
      isMet: RegExp(r'\d').hasMatch(password),
    ),
    _PasswordRequirement(
      text: 'Contains special character',
      isMet: RegExp(r'[@$!%*?&]').hasMatch(password),
    ),
  ];
}
