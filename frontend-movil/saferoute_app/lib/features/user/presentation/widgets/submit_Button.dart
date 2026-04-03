import 'package:flutter/material.dart';

const _primaryColor = Color(0xFF2563EB);
const _darkColor    = Color(0xFF1E3A8A);

class SubmitButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isGoogle;

  const SubmitButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isGoogle  = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          backgroundColor: isGoogle ? Colors.white : _primaryColor,
          foregroundColor: isGoogle ? _darkColor   : Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isGoogle
                ? const BorderSide(color: Color(0xFFCBD5E1))
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}
