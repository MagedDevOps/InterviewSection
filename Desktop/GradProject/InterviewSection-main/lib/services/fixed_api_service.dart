import 'dart:convert';
import 'package:http/http.dart' as http;

class FixedApiService {
  // OpenRouter API endpoint
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  // API key - in production, use secure storage
  static const String _apiKey =
      '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';

  // Default model to use
  static const String _defaultModel = 'openai/gpt-3.5-turbo';

  // Add a max tokens parameter to limit response size
  static const int _maxTokens = 2048; // Reduced from default 3072

  // Helper method to recursively find questions in a map structure
  static void _findQuestionsInMap(dynamic data, List<String> questions) {
    if (data is Map) {
      data.forEach((key, value) {
        if (value is String && value.contains('?')) {
          questions.add(value);
        } else if (value is Map || value is List) {
          _findQuestionsInMap(value, questions);
        }
      });
    } else if (data is List) {
      for (var item in data) {
        if (item is String && item.contains('?')) {
          questions.add(item);
        } else if (item is Map || item is List) {
          _findQuestionsInMap(item, questions);
        }
      }
    }
  }

  // Generate interview questions based on field, technologies, and difficulty
  static Future<List<String>> generateInterviewQuestions({
    required String field,
    required List<String> technologies,
    required String difficulty,
    int numberOfQuestions = 5,
  }) async {
    try {
      final String techString = technologies.join(', ');

      // Simplified prompt to generate valid JSON array
      final prompt = """
        Generate $numberOfQuestions technical interview questions for a $difficulty-level $field developer skilled in $techString. Return only a JSON array of questions, no explanations or extra text.
      """;

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://interview-service.app',
        },
        body: jsonEncode({
          'model': _defaultModel,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a helpful assistant. Only output a JSON array of questions.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'response_format': {'type': 'json_object'},
          'max_tokens': _maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('Raw API response: ${response.body}');

        // Safely extract content from the response
        if (jsonResponse.containsKey('choices') &&
            jsonResponse['choices'] is List &&
            jsonResponse['choices'].isNotEmpty &&
            jsonResponse['choices'][0].containsKey('message') &&
            jsonResponse['choices'][0]['message'].containsKey('content')) {
          final content = jsonResponse['choices'][0]['message']['content'];
          print('Raw API response content: $content');

          try {
            if (content.trim().isEmpty) {
              throw Exception('Empty response content from API');
            }

            // Parse the content as JSON
            dynamic parsedContent = jsonDecode(content);
            print('Parsed content type: ${parsedContent.runtimeType}');

            // Handle different response formats
            if (parsedContent is Map &&
                parsedContent.containsKey('questions')) {
              // Extract the questions array from the map
              final questionsList = parsedContent['questions'];
              if (questionsList is List) {
                return questionsList.map((q) => q.toString()).toList();
              }
            } else if (parsedContent is List) {
              // Direct array of questions - perfect!
              return parsedContent.map((q) => q.toString()).toList();
            } else if (parsedContent is Map) {
              // Extract questions from the map
              final List<String> extractedQuestions = [];
              _findQuestionsInMap(parsedContent, extractedQuestions);
              if (extractedQuestions.isNotEmpty) {
                return extractedQuestions;
              }
              // If we still have no questions, look for any string that ends with '?'
              final allValues = parsedContent.values.toList();
              final questionStrings =
                  allValues
                      .whereType<String>()
                      .where((s) => s.trim().endsWith('?'))
                      .toList();
              if (questionStrings.isNotEmpty) {
                return questionStrings;
              }
            }

            // If we couldn't parse as expected, check for question marks in the raw content
            final questionRegex = RegExp(r'([^.!?]+\?)', multiLine: true);
            final matches = questionRegex.allMatches(content);
            if (matches.isNotEmpty) {
              return matches
                  .map((m) => m.group(0)!)
                  .map((s) => s.trim())
                  .toList();
            }

            print('Failed to extract questions from response: $parsedContent');
            return _getDefaultQuestions(field, technologies);
          } catch (e) {
            print('Error parsing API response: $e');

            // If JSON parsing fails, try to extract questions with regex
            final questionRegex = RegExp(r'([^.!?]+\?)', multiLine: true);
            final matches = questionRegex.allMatches(content);
            if (matches.isNotEmpty) {
              return matches
                  .map((m) => m.group(0)!)
                  .map((s) => s.trim())
                  .toList();
            }

            return _getDefaultQuestions(field, technologies);
          }
        } else {
          print('Invalid response structure from API: $jsonResponse');
          return _getDefaultQuestions(field, technologies);
        }
      } else if (response.statusCode == 402) {
        // Handle the credit limit exceeded error specifically
        print('Credit limit exceeded: ${response.body}');
        // Return fallback questions but also log the specific error
        return _getDefaultQuestions(field, technologies, isApiLimitError: true);
      } else {
        print(
          'Failed to generate questions: ${response.statusCode}, ${response.body}',
        );
        return _getDefaultQuestions(field, technologies);
      }
    } catch (e) {
      print('Error generating questions: $e');
      return _getDefaultQuestions(field, technologies);
    }
  }

  // Helper method to provide default questions
  static List<String> _getDefaultQuestions(
    String field,
    List<String> technologies, {
    bool isApiLimitError = false,
  }) {
    final String techString = technologies.join(', ');
    final prefix = isApiLimitError ? '[API LIMIT REACHED] ' : '';
    return [
      '$prefix What are your primary strengths in $field development?',
      '$prefix Describe a challenging project you worked on with $techString.',
      '$prefix How do you approach debugging issues in your code?',
      '$prefix What development methodologies are you familiar with?',
      '$prefix How do you stay updated with the latest technologies in your field?',
    ];
  }

  // Evaluate interview answer with reduced token usage
  static Future<Map<String, dynamic>> evaluateAnswer({
    required String question,
    required String answer,
    required String field,
    required List<String> technologies,
    required String difficulty,
  }) async {
    try {
      final String techString = technologies.join(', ');

      // Simplified prompt to reduce token usage
      final prompt = """
      You are an expert technical interviewer. Evaluate the following
       $field interview answer related to $techString.

      Question:
      $question

      Candidate's Answer:
      $answer

      Evaluation Criteria:
      - Assess the technical correctness, clarity, and depth of understanding.
      - Check if the answer demonstrates practical knowledge and relevance to real-world applications.
      - Penalize for inaccuracies, vagueness, or missing key points.
      - Consider communication skills only if they affect technical clarity.

      Return your evaluation as a JSON object with the following format:
      {
        "score": 0-100, 
        "feedback": "Concise, constructive, and technical feedback"
      }
      Only output valid JSON with no extra commentary.
      """;

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://interview-service.app',
        },
        body: jsonEncode({
          'model': _defaultModel,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You evaluate $difficulty $field responses. Return a valid JSON object with a score and feedback.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'response_format': {'type': 'json_object'},
          'max_tokens': _maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('Raw API evaluation response: ${response.body}');

        final content = jsonResponse['choices'][0]['message']['content'];
        print('Raw API evaluation response content: $content');

        try {
          if (content.trim().isEmpty) {
            throw Exception('Empty response content from API');
          }

          dynamic parsedContent = jsonDecode(content);

          if (parsedContent is Map) {
            if (parsedContent.containsKey('score') &&
                parsedContent.containsKey('feedback')) {
              var score = parsedContent['score'];
              if (score is String) {
                try {
                  score = int.parse(score);
                } catch (e) {
                  final numberRegex = RegExp(r'\d+');
                  final match = numberRegex.firstMatch(score);
                  score = match != null ? int.parse(match.group(0)!) : 50;
                }
              }

              return {
                'score': score is num ? score : 50,
                'feedback': parsedContent['feedback'].toString(),
              };
            } else {
              // Try to extract score and feedback
              final Map<String, dynamic> result = {};

              parsedContent.forEach((key, value) {
                if (value is num &&
                    (key.toLowerCase().contains('score') || key == 'rating')) {
                  result['score'] = value;
                } else if (value is String &&
                    (key.toLowerCase().contains('feedback') ||
                        key.toLowerCase().contains('comment') ||
                        key.toLowerCase().contains('review'))) {
                  result['feedback'] = value;
                }
              });

              if (result.containsKey('score') ||
                  result.containsKey('feedback')) {
                if (!result.containsKey('score')) result['score'] = 50;
                if (!result.containsKey('feedback')) {
                  result['feedback'] = 'No detailed feedback available.';
                }
                return result;
              }
            }
          }

          return _getDefaultEvaluation();
        } catch (e) {
          print('Error parsing API evaluation response: $e');
          return _getDefaultEvaluation(error: e.toString());
        }
      } else if (response.statusCode == 402) {
        // Handle credit limit error specifically
        print('Credit limit exceeded: ${response.body}');
        return _getDefaultEvaluation(isApiLimitError: true);
      } else {
        print(
          'Failed to evaluate answer: ${response.statusCode}, ${response.body}',
        );
        return _getDefaultEvaluation();
      }
    } catch (e) {
      print('Error evaluating answer: $e');
      return _getDefaultEvaluation(error: e.toString());
    }
  }

  // Helper method to provide default evaluation
  static Map<String, dynamic> _getDefaultEvaluation({
    bool isApiLimitError = false,
    String? error,
  }) {
    final String message =
        isApiLimitError
            ? 'API credit limit reached. Please upgrade your OpenRouter account for evaluations.'
            : error != null
            ? 'Technical issue: $error. A neutral score has been assigned.'
            : 'Unable to evaluate your answer. A neutral score has been assigned.';

    return {'score': 50, 'feedback': message};
  }
}
