import 'package:bmd_flutter_tools/utilities/utilities__theme.dart';
import 'package:bmd_flutter_tools/widgets/navigation_bar__primary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sficon/flutter_sficon.dart';
import 'package:go_router/go_router.dart';

class AccountCreatedConfirmationView extends ConsumerStatefulWidget {
  const AccountCreatedConfirmationView({super.key});

  @override
  ConsumerState<AccountCreatedConfirmationView> createState() =>
      _AccountCreatedConfirmationViewState();
}

class _AccountCreatedConfirmationViewState
    extends ConsumerState<AccountCreatedConfirmationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: BeColorSwatch.green,
                    ),
                    padding: const EdgeInsets.all(32),
                    child: const SFIcon(
                      SFIcons.sf_checkmark,
                      fontSize: 72,
                      color:    BeColorSwatch.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    "Your account has been created!",
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      color: BeColorSwatch.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    "You're all set. Continue to finish your profile.",
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: BeColorSwatch.darkGray,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!mounted) {
                        return;
                      }
                      context.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                    ),
                    child: const Text("Continue"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
