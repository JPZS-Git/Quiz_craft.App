import 'package:flutter/material.dart';
import 'widgets/dots_indicator.dart'; 

import '../onboarding/pages/consent_page.dart';
import '../onboarding/pages/go_to_access_page_ob_page.dart';
import '../onboarding/pages/how_it_works_ob_page.dart';
import '../onboarding/pages/welcome_ob_page.dart';

class OnboardingPage extends StatefulWidget {
  static const routeName = '/onboarding';
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final List<Widget> _pages;
  final _pageController = PageController();
  int _currentPage = 0;

  late final int _totalPagesInOBPage;
  late final int _policiesRequiredIndex;
  late final int _lastPageIndex;

  @override
  void initState() {
    super.initState();

    // ✅ Passamos o callback _goToNextPage() para o botão "Começar"
    _pages = [
      WellcomeOBPage(onNext: _goToNextPage),
      HowItWorksOBPage(onNext: _goToNextPage),
      const GoToAccessPageOBpage(),
      ConsentPageOBPage(onConsentGiven: _onConsentGiven),
    ];

    _totalPagesInOBPage = _pages.length;
    _policiesRequiredIndex = _totalPagesInOBPage - 2;
    _lastPageIndex = _totalPagesInOBPage - 1;

    _pageController.addListener(() {
      final page = _pageController.page?.round();
      if (page != null && page != _currentPage) {
        setState(() {
          _currentPage = page;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isAcceptancePage => _currentPage == _lastPageIndex;
  bool get _isIntroPage => _currentPage < _policiesRequiredIndex;

  void _onConsentGiven() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _goToNextPage() => _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

  void _goToPreviousPage() => _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

  void _skipToPolicies() => _pageController.jumpToPage(_policiesRequiredIndex);

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    children: _pages.map((page) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        child: page,
                      );
                    }).toList(),
                  ),
                ),

                if (_isIntroPage)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: DotsIndicator(
                      totalDots: _policiesRequiredIndex,
                      currentIndex: _currentPage,
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0 && !_isAcceptancePage)
                        IconButton(
                          onPressed: _goToPreviousPage,
                          icon: Icon(Icons.arrow_back, size: 36, color: accentColor),
                        )
                      else
                        const SizedBox(width: 48),

                      const Spacer(),

                      if (_isIntroPage)
                        IconButton(
                          onPressed: _goToNextPage,
                          icon: Icon(Icons.arrow_forward, size: 36, color: accentColor),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
              ],
            ),

            if (_isIntroPage)
              Positioned(
                top: 16,
                right: 16,
                child: TextButton(
                  onPressed: _skipToPolicies,
                  child: Text(
                    'Pular',
                    style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

