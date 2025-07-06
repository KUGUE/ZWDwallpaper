import 'dart:ui';
import 'package:flutter/material.dart';

class DashboardButton extends StatelessWidget {
  final VoidCallback onOpen;
  const DashboardButton({required this.onOpen, super.key});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 24,
      bottom: 24,
      child: GestureDetector(
        onTap: onOpen,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xCC23272A),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(2, 4),
                  ),
                ],
              ),
              child: const Center(
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 24,
                  child: Icon(Icons.home, color: Color(0xFF23272A), size: 32),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
