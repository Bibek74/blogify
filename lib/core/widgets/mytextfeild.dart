import 'package:flutter/material.dart';

class MyTextformfield extends StatelessWidget {
  const MyTextformfield({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.controller,
    required this.errorMessage,
    this.validator,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  final String labelText;
  final String hintText;
  final TextEditingController controller;
  final String errorMessage;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        labelText: labelText,
        hintText: hintText,
      ),
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return errorMessage;
        }
        return null;
      },
    );
  }
}