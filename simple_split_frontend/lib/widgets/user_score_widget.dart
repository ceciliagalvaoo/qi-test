import 'package:flutter/material.dart';
import '../utils/theme.dart';

class UserScoreWidget extends StatelessWidget {
  final double score;
  final String? description;

  const UserScoreWidget({
    super.key,
    required this.score,
    this.description,
  });

  Color _getScoreColor() {
    if (score >= 7.0) {
      return const Color(0xFF4CAF50); // Verde
    } else if (score >= 4.0) {
      return const Color(0xFFFFC107); // Amarelo
    } else {
      return const Color(0xFFF44336); // Vermelho
    }
  }

  String _getScoreLabel() {
    if (score >= 9.0) {
      return 'Excelente';
    } else if (score >= 7.0) {
      return 'Bom';
    } else if (score >= 4.0) {
      return 'Regular';
    } else {
      return 'Baixo';
    }
  }

  IconData _getScoreIcon() {
    if (score >= 7.0) {
      return Icons.star;
    } else if (score >= 4.0) {
      return Icons.star_half;
    } else {
      return Icons.star_border;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor();

    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scoreColor.withOpacity(0.1),
              scoreColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            // Ícone e círculo de score
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: scoreColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getScoreIcon(),
                color: Colors.white,
                size: 28,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Informações do score
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Meu Score',
                        style: AppTextStyles.callout.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    children: [
                      Text(
                        score.toStringAsFixed(1),
                        style: AppTextStyles.title2.copyWith(
                          color: scoreColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '/10.0',
                        style: AppTextStyles.callout.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scoreColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getScoreLabel(),
                          style: AppTextStyles.caption2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  if (description != null)
                    Text(
                      description!,
                      style: AppTextStyles.footnote.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScoreProgressBar extends StatelessWidget {
  final double score;
  final double maxScore;

  const ScoreProgressBar({
    super.key,
    required this.score,
    this.maxScore = 10.0,
  });

  Color _getScoreColor() {
    if (score >= 7.0) {
      return const Color(0xFF4CAF50); // Verde
    } else if (score >= 4.0) {
      return const Color(0xFFFFC107); // Amarelo
    } else {
      return const Color(0xFFF44336); // Vermelho
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = score / maxScore;
    final scoreColor = _getScoreColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progresso do Score',
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            Text(
              '${score.toStringAsFixed(1)}/${maxScore.toStringAsFixed(0)}',
              style: AppTextStyles.footnote.copyWith(
                color: scoreColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: scoreColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}