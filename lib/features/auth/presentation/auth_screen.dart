import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.gapXl,
              AppSpacing.gapXl,
              // Logo Placeholder
              const Center(
                child: Icon(
                  Icons.storefront_rounded,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
              AppSpacing.gapLg,
              // Title
              const Text(
                'Nexlist',
                textAlign: TextAlign.center,
                style: AppTypography.h1,
              ),
              AppSpacing.gapXs,
              const Text(
                'The Campus Marketplace',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
              const Spacer(),
              
              // Login Form
              const Text(
                'Login or Sign up',
                style: AppTypography.h3,
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapLg,
              
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your 10-digit number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              AppSpacing.gapLg,
              
              ElevatedButton(
                onPressed: () {},
                child: const Text('Send OTP'),
              ),
              AppSpacing.gapXl,
              
              // Terms disclaimer
              Text(
                'By continuing, you verify that you are a student and agree to our Terms of Service.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(fontSize: 10),
              ),
              AppSpacing.gapLg,
            ],
          ),
        ),
      ),
    );
  }
}
