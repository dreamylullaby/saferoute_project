import 'package:flutter/material.dart';

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
    this.isGoogle = false

  });

  @override
  Widget build(BuildContext context) {

    return SizedBox(

      width: double.infinity,

      child: ElevatedButton(

        onPressed: isLoading ? null : onPressed,

        style: ElevatedButton.styleFrom(

          padding: const EdgeInsets.all(15),

          backgroundColor:
            isGoogle ? Colors.white : Colors.blue,

          foregroundColor:
            isGoogle ? Colors.black : Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)
          )

        ),

        child: isLoading
          ? const CircularProgressIndicator()
          : Text(text),

      ),

    );

  }

}