// lib/shared/widgets/table_header.dart
import 'package:flutter/material.dart';

class TableHeader extends StatelessWidget {
  final String title;
  final Color color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? flex;
  final EdgeInsetsGeometry? padding;
  final Widget? icon;
  final bool sortable;
  final VoidCallback? onSort;
  final bool isAscending;

  const TableHeader(
    this.title, {
    super.key,
    this.color = Colors.black,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.flex,
    this.padding,
    this.icon,
    this.sortable = false,
    this.onSort,
    this.isAscending = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget headerContent = Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: fontWeight ?? FontWeight.bold,
                color: color,
                fontSize: fontSize ?? 14,
              ),
              textAlign: textAlign ?? TextAlign.left,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (sortable) ...[
            const SizedBox(width: 4),
            Icon(
              isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: color.withOpacity(0.7),
            ),
          ],
        ],
      ),
    );

    if (sortable && onSort != null) {
      headerContent = InkWell(
        onTap: onSort,
        borderRadius: BorderRadius.circular(4),
        child: headerContent,
      );
    }

    if (flex != null) {
      return Expanded(
        flex: flex!,
        child: headerContent,
      );
    }

    return Expanded(child: headerContent);
  }
}

// 🆕 WIDGET SPÉCIALISÉ POUR LES HEADERS DE TABLEAUX AVEC STYLES PRÉDÉFINIS
class AppTableHeader extends StatelessWidget {
  final String title;
  final int? flex;
  final bool sortable;
  final VoidCallback? onSort;
  final bool isAscending;
  final IconData? icon;

  const AppTableHeader({
    super.key,
    required this.title,
    this.flex,
    this.sortable = false,
    this.onSort,
    this.isAscending = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TableHeader(
      title,
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      flex: flex,
      sortable: sortable,
      onSort: onSort,
      isAscending: isAscending,
      icon: icon != null ? Icon(icon!, size: 16, color: Colors.white) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}

// 🆕 WIDGET POUR HEADERS AVEC COULEURS PERSONNALISÉES
class ColoredTableHeader extends StatelessWidget {
  final String title;
  final Color backgroundColor;
  final Color textColor;
  final int? flex;
  final IconData? icon;
  final bool sortable;
  final VoidCallback? onSort;
  final bool isAscending;

  const ColoredTableHeader({
    super.key,
    required this.title,
    required this.backgroundColor,
    this.textColor = Colors.white,
    this.flex,
    this.icon,
    this.sortable = false,
    this.onSort,
    this.isAscending = true,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex ?? 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: TableHeader(
          title,
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          flex: null, // Déjà wrapped dans Expanded
          icon: icon != null ? Icon(icon!, size: 14, color: textColor) : null,
          sortable: sortable,
          onSort: onSort,
          isAscending: isAscending,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

// 🆕 EXTENSION POUR CRÉER DES HEADERS RAPIDEMENT
extension TableHeaderExtensions on String {
  Widget toTableHeader({
    Color color = Colors.black,
    int? flex,
    bool sortable = false,
    VoidCallback? onSort,
    bool isAscending = true,
    IconData? icon,
  }) {
    return TableHeader(
      this,
      color: color,
      flex: flex,
      sortable: sortable,
      onSort: onSort,
      isAscending: isAscending,
      icon: icon != null ? Icon(icon, size: 14, color: color) : null,
    );
  }

  Widget toAppTableHeader({
    int? flex,
    bool sortable = false,
    VoidCallback? onSort,
    bool isAscending = true,
    IconData? icon,
  }) {
    return AppTableHeader(
      title: this,
      flex: flex,
      sortable: sortable,
      onSort: onSort,
      isAscending: isAscending,
      icon: icon,
    );
  }
}
