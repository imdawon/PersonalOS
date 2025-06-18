import 'package:flutter/material.dart';

class ScrollableFadeContainer extends StatefulWidget {
  final Widget child;
  final double fadeHeight;
  final Color? fadeColor;

  const ScrollableFadeContainer({
    super.key,
    required this.child,
    this.fadeHeight = 30.0,
    this.fadeColor,
  });

  @override
  State<ScrollableFadeContainer> createState() => _ScrollableFadeContainerState();
}

class _ScrollableFadeContainerState extends State<ScrollableFadeContainer> {
  final ScrollController _scrollController = ScrollController();
  bool _showBottomFade = false;
  bool _showTopFade = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateFadeVisibility);
    // Check if we need fade after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFadeVisibility();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateFadeVisibility);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateFadeVisibility() {
    if (!mounted) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    setState(() {
      _showBottomFade = currentScroll < maxScroll - 10; // Show if not at bottom
      _showTopFade = currentScroll > 10; // Show if not at top
    });
  }

  @override
  Widget build(BuildContext context) {
    final fadeColor = widget.fadeColor ?? Theme.of(context).colorScheme.surface;
    
    return Stack(
      children: [
        // Main scrollable content
        SingleChildScrollView(
          controller: _scrollController,
          child: widget.child,
        ),
        
        // Top fade (when scrolled down)
        if (_showTopFade)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: widget.fadeHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    fadeColor,
                    fadeColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        
        // Bottom fade (when there's more content below)
        if (_showBottomFade)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: widget.fadeHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    fadeColor.withOpacity(0.0),
                    fadeColor,
                  ],
                ),
              ),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Colors.grey,
                      ),
                      Text(
                        'Scroll for more',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
} 