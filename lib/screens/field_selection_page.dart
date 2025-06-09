import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/field_data.dart';
import '../utils/background_decorations.dart';
import '../widgets/gradient_button.dart';
import 'interview_screen.dart';
import 'history_screen.dart';

class FieldSelectionPage extends StatefulWidget {
  const FieldSelectionPage({super.key});

  @override
  State<FieldSelectionPage> createState() => _FieldSelectionPageState();
}

class _FieldSelectionPageState extends State<FieldSelectionPage> {
  String? selectedField;
  List<String> selectedTechnologies = [];
  String? selectedDifficulty;

  bool get isMultiSelect =>
      selectedField != null &&
      FieldData.multiSelectTracks.contains(selectedField);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        children: [
          const BackgroundDecorations(),
          Padding(
            padding: const EdgeInsets.only(top: 40, left: 16),
            child: Align(
              alignment: Alignment.topLeft,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryScreen(),
                        ),
                      );
                    },
                    tooltip: 'View Interview History',
                  ),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const CircleAvatar(
                radius: 30,
                backgroundImage: AssetImage("assets/images/home4.png"),
              ),
              const SizedBox(height: 16),

              // Instruction text
              const Text(
                "Choose the field and determine the level.",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.lightText,
                ),
              ),
              const SizedBox(height: 24),

              // Field selection
              const Text(
                'Select Track:',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.lightText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    FieldData.fieldTechnologies.keys.map((field) {
                      return ChoiceChip(
                        label: Text(field),
                        selected: selectedField == field,
                        onSelected: (selected) {
                          setState(() {
                            selectedField = selected ? field : null;
                            selectedTechnologies.clear();
                            selectedDifficulty = null;
                          });
                        },
                        backgroundColor: AppColors.darkPurple,
                        selectedColor: Colors.purple[400],
                        labelStyle: TextStyle(
                          color:
                              selectedField == field
                                  ? Colors.white
                                  : Colors.white70,
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 24),

              if (selectedField != null) ...[
                Text(
                  'Select Technology${isMultiSelect ? ' (Multiple allowed)' : ''}:',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      FieldData.fieldTechnologies[selectedField]!.map((tech) {
                        return ChoiceChip(
                          label: Text(tech),
                          selected: selectedTechnologies.contains(tech),
                          onSelected: (selected) {
                            setState(() {
                              if (isMultiSelect) {
                                if (selected) {
                                  selectedTechnologies.add(tech);
                                } else {
                                  selectedTechnologies.remove(tech);
                                }
                              } else {
                                selectedTechnologies = selected ? [tech] : [];
                              }
                              if (selectedTechnologies.isEmpty) {
                                selectedDifficulty = null;
                              }
                            });
                          },
                          backgroundColor: AppColors.darkPurple,
                          selectedColor: Colors.purple[400],
                          labelStyle: TextStyle(
                            color:
                                selectedTechnologies.contains(tech)
                                    ? Colors.white
                                    : Colors.white70,
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              if (selectedTechnologies.isNotEmpty) ...[
                const Text(
                  'Select Difficulty:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      FieldData.difficulties.map((difficulty) {
                        return ChoiceChip(
                          label: Text(difficulty),
                          selected: selectedDifficulty == difficulty,
                          onSelected: (selected) {
                            setState(() {
                              selectedDifficulty = selected ? difficulty : null;
                            });
                          },
                          backgroundColor: AppColors.darkPurple,
                          selectedColor: Colors.purple[400],
                          labelStyle: TextStyle(
                            color:
                                selectedDifficulty == difficulty
                                    ? Colors.white
                                    : Colors.white70,
                          ),
                        );
                      }).toList(),
                ),
              ],
              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GradientButton(
                  text: "Start",
                  onPressed:
                      selectedField != null &&
                              selectedTechnologies.isNotEmpty &&
                              selectedDifficulty != null
                          ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => InterviewScreen(
                                      field: selectedField!,
                                      technologies: selectedTechnologies,
                                      difficulty: selectedDifficulty!,
                                    ),
                              ),
                            );
                          }
                          : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
