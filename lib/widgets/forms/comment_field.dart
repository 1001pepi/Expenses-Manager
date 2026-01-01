import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommentField extends StatelessWidget {
  final TextEditingController? controller;

  const CommentField({Key? key, this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Comment',
        border: UnderlineInputBorder(),
      ),
      maxLength: 5000,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
    );
  }
}
