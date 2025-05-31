import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prenova/core/theme/app_pallete.dart';

class FancyDropdown extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<DropdownItem> items;
  final VoidCallback? onViewAll;

  const FancyDropdown({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    this.onViewAll,
  }) : super(key: key);

  @override
  State<FancyDropdown> createState() => _FancyDropdownState();
}

class _FancyDropdownState extends State<FancyDropdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _toggleExpanded,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.color.withOpacity(0.1),
                            widget.color.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 24,
                        color: widget.color,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppPallete.textColor,
                        ),
                      ),
                    ),
                    if (widget.items.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${widget.items.length}',
                          style: TextStyle(
                            color: widget.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: Duration(milliseconds: 300),
                      child: Icon(
                        LucideIcons.chevronDown,
                        color: widget.color,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: widget.color.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    if (widget.items.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              LucideIcons.inbox,
                              color: Colors.grey,
                              size: 32,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No items yet',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...widget.items.map((item) => _buildDropdownItem(item)),
                    if (widget.onViewAll != null && widget.items.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: widget.onViewAll,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.color.withOpacity(0.1),
                            foregroundColor: widget.color,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'View All',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(LucideIcons.arrowRight, size: 16),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownItem(DropdownItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              if (item.icon != null)
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    size: 16,
                    color: widget.color,
                  ),
                ),
              if (item.icon != null) SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppPallete.textColor,
                      ),
                    ),
                    if (item.subtitle != null)
                      Text(
                        item.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppPallete.textColor.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
              if (item.trailing != null) item.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class DropdownItem {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  DropdownItem({
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
  });
}