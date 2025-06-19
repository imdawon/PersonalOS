import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';

class SkillsScreen extends StatelessWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.skills.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(child: Text(provider.error!));
        }

        if (provider.skills.isEmpty) {
          return const Center(child: Text('No skills yet. Start classifying activities!'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.skills.length,
          itemBuilder: (context, index) {
            final skill = provider.skills[index];
            final double progress = skill.xpForNextLevel == 0
                ? 1.0
                : skill.currentXp / skill.xpForNextLevel;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_outline, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            skill.userDefinedName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text('Lvl. ${skill.level}', style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    ),
                    const SizedBox(height: 6),
                    Text('${skill.currentXp}/${skill.xpForNextLevel} XP to next level', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
} 