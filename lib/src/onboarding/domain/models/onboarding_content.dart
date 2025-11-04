import 'package:flutter/material.dart';
import 'package:befit_fitness_app/l10n/app_localizations.dart';

/// Model class for onboarding page content
class OnboardingContent {
  final String lottieAssetPath;
  final String Function(BuildContext) descriptionGetter;

  const OnboardingContent({
    required this.lottieAssetPath,
    required this.descriptionGetter,
  });

  String getDescription(BuildContext context) => descriptionGetter(context);
}

/// Repository/provider for onboarding content
class OnboardingContentRepository {
  static List<OnboardingContent> getPages(BuildContext context) => [
        OnboardingContent(
          lottieAssetPath: 'assets/onboarding/lotties/onboarding1.json',
          descriptionGetter: (context) =>
              AppLocalizations.of(context)!.onboardingPage1Description,
        ),
        OnboardingContent(
          lottieAssetPath: 'assets/onboarding/lotties/onboarding2.json',
          descriptionGetter: (context) =>
              AppLocalizations.of(context)!.onboardingPage2Description,
        ),
        OnboardingContent(
          lottieAssetPath: 'assets/onboarding/lotties/onboarding3.json',
          descriptionGetter: (context) =>
              AppLocalizations.of(context)!.onboardingPage3Description,
        ),
      ];

  static OnboardingContent getPage(BuildContext context, int index) {
    final pages = getPages(context);
    if (index < 0 || index >= pages.length) {
      throw ArgumentError('Invalid onboarding page index: $index');
    }
    return pages[index];
  }

  static int get totalPages => 3;
}

