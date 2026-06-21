import 'package:flutter/material.dart';
import 'package:frontend/core/constants/colors.dart';
import '../models/ai_suggestion.dart';
import '../services/ai_service.dart';

class AISuggestionsWidget extends StatefulWidget {
  final String consultationId;
  final Function(AISuggestion suggestion) onSuggestionSelected;
  final VoidCallback? onRefresh;

  const AISuggestionsWidget({
    super.key,
    required this.consultationId,
    required this.onSuggestionSelected,
    this.onRefresh,
  });

  @override
  State<AISuggestionsWidget> createState() => _AISuggestionsWidgetState();
}

class _AISuggestionsWidgetState extends State<AISuggestionsWidget> {
  final AIService _aiService = AIService();

  bool _isLoading = false;
  bool _isExpanded = false;
  AISuggestionsResponse? _suggestionsResponse;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);

    try {
      final response = await _aiService.getAISuggestions(widget.consultationId);
      setState(() {
        _suggestionsResponse = response;
        _isLoading = false;
        // Auto-expand si on a des suggestions
        _isExpanded = response.suggestions.isNotEmpty;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading AI suggestions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _suggestionsResponse?.aiAvailable == true
              ? Colors.blue.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Content (expandable)
          if (_isExpanded) _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getHeaderColor(),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: _isExpanded ? Radius.zero : const Radius.circular(12),
            bottomRight: _isExpanded ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Row(
          children: [
            // AI Icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getHeaderIcon(),
                color: Colors.white,
                size: 18,
              ),
            ),

            const SizedBox(width: 10),

            // Title and status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '🤖 AI Suggestions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (_isLoading) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    _getStatusText(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Suggestion count
            if (_suggestionsResponse?.suggestions.isNotEmpty == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_suggestionsResponse!.suggestions.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(width: 8),

            // Expand/Collapse icon
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Getting AI suggestions...'),
            ],
          ),
        ),
      );
    }

    if (_suggestionsResponse == null || !_suggestionsResponse!.success) {
      return _buildErrorState();
    }

    if (_suggestionsResponse!.suggestions.isEmpty) {
      return _buildEmptyState();
    }

    return _buildSuggestionsList();
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 32,
          ),
          const SizedBox(height: 8),
          const Text(
            'AI Service Unavailable',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _suggestionsResponse?.error ?? 'Unable to get AI suggestions',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadSuggestions,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.psychology_outlined,
            color: Colors.grey[400],
            size: 32,
          ),
          const SizedBox(height: 8),
          const Text(
            'No AI Suggestions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'AI couldn\'t find specific medication recommendations for this consultation',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          if (_suggestionsResponse?.processingTime != null) ...[
            const SizedBox(height: 8),
            Text(
              'Processing time: ${_suggestionsResponse!.processingTime}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Processing info
          if (_suggestionsResponse?.processingTime != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.speed, size: 12, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Processed in ${_suggestionsResponse!.processingTime}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Suggestions list
          ...(_suggestionsResponse!.suggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final suggestion = entry.value;
            return _buildSuggestionCard(suggestion, index);
          })),

          // Footer actions
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '💡 AI analyzed patient data to suggest these medications',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              TextButton.icon(
                onPressed: _loadSuggestions,
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Refresh'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  textStyle: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(AISuggestion suggestion, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),

        // Leading icon based on category
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: suggestion.confidenceColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            suggestion.categoryIcon,
            color: suggestion.confidenceColor,
            size: 18,
          ),
        ),

        // Medication info
        title: Row(
          children: [
            Expanded(
              child: Text(
                suggestion.medication,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Confidence badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: suggestion.confidenceColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                suggestion.confidencePercentage,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              suggestion.category,
              style: TextStyle(
                fontSize: 12,
                color: suggestion.confidenceColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (suggestion.reason != null) ...[
              const SizedBox(height: 2),
              Text(
                suggestion.reason!,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),

        // Add button
        trailing: ElevatedButton.icon(
          onPressed: () => widget.onSuggestionSelected(suggestion),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            textStyle: const TextStyle(fontSize: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }

  Color _getHeaderColor() {
    if (_isLoading) return Colors.blue;
    if (_suggestionsResponse?.success == true) {
      return _suggestionsResponse!.suggestions.isNotEmpty
          ? Colors.green
          : Colors.orange;
    }
    return Colors.red;
  }

  IconData _getHeaderIcon() {
    if (_isLoading) return Icons.psychology;
    if (_suggestionsResponse?.success == true) {
      return _suggestionsResponse!.suggestions.isNotEmpty
          ? Icons.auto_awesome
          : Icons.psychology_outlined;
    }
    return Icons.error_outline;
  }

  String _getStatusText() {
    if (_isLoading) return 'Analyzing patient data...';
    if (_suggestionsResponse?.success == true) {
      if (_suggestionsResponse!.suggestions.isNotEmpty) {
        return '${_suggestionsResponse!.suggestions.length} medications suggested';
      }
      return 'No specific suggestions found';
    }
    return 'AI service unavailable';
  }
}
