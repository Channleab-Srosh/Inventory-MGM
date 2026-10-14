import 'package:flutter/material.dart';

/// A small reusable widget so we don't repeat
/// `CircularProgressIndicator()` boilerplate everywhere.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}