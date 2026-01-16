import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  const MyButton({
    super.key,
    required this.onPressed,
    required this.text,
    });

    final VoidCallback? onPressed;
    final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed == null ? Colors.grey : Colors.blueAccent,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10
          ),
        ) ,
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}