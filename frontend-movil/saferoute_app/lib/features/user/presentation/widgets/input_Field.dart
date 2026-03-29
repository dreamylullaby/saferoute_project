import 'package:flutter/material.dart';

class InputField extends StatelessWidget {

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;

  const InputField({

    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false

  });

  @override
  Widget build(BuildContext context) {

    return TextFormField(

      controller: controller,

      obscureText: isPassword,

      validator: (value){

        if(value == null || value.isEmpty){
          return "Campo obligatorio";
        }

        if(label == "Correo" && !value.contains("@")){
          return "Correo inválido";
        }

        return null;

      },

      decoration: InputDecoration(

        labelText: label,

        prefixIcon: Icon(icon),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12)
        ),

      ),

    );

  }

}