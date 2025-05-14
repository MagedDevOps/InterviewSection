import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // OpenRouter API endpoint
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  // API key - in production, use secure storage
  static const String _apiKey =
      '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';

  // Default model to use
  static const String _defaultModel = 'openai/gpt-4o';

  // Generate interview questions based on field, technologies, and difficulty
  static Future<List<String>> generateInterviewQuestions({
    required String field,
    required List<String> technologies,
    required String difficulty,
    int numberOfQuestions = 5,
  }) async {
    try {
      final techString = technologies.join(', ');

      final prompt =
          """Generate $numberOfQuestions interview questions for a $difficulty level $field developer 
      with expertise in $techString. The questions should be challenging but appropriate for the $difficulty level.
      Format the response as a JSON array of strings, with each string being a question.
      Do not include answers or explanations.""";

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer':
              'https://interview-service.app', // Replace with your app domain
        },
        body: jsonEncode({
          'model': _defaultModel,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an expert technical interviewer for $field positions.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        // Safely extract content from the response
        if (jsonResponse.containsKey('choices') &&
            jsonResponse['choices'] is List &&
            jsonResponse['choices'].isNotEmpty &&
            jsonResponse['choices'][0].containsKey('message') &&
            jsonResponse['choices'][0]['message'].containsKey('content')) {
          final content = jsonResponse['choices'][0]['message']['content'];

          try {
            // Print the raw content for debugging
            print('Raw API response content: $content');

            // Parse the content as JSON
            final dynamic parsedContent = jsonDecode(content);
            print('Parsed content type: ${parsedContent.runtimeType}');

            // Handle different response formats
            if (parsedContent is List) {
              // If it's already a list, cast and return
              return parsedContent.map((q) => q.toString()).toList();
            } else if (parsedContent is Map) {
              // If it's a map, check for various possible structures
              if (parsedContent.containsKey('questions')) {
                // If it has a 'questions' key
                final questions = parsedContent['questions'];
                if (questions is List) {
                  return questions.map((q) => q.toString()).toList();
                }
              } else {
                // Try to extract any list or string values from the map
                final possibleQuestions = [];

                // Look for any list values in the map
                parsedContent.forEach((key, value) {
                  if (value is List) {
                    possibleQuestions.addAll(value.map((q) => q.toString()));
                  } else if (value is String && value.trim().isNotEmpty) {
                    // If it's a string value, add it as a question
                    possibleQuestions.add(value);
                  }
                });

                if (possibleQuestions.isNotEmpty) {
                  return List<String>.from(possibleQuestions);
                }
              }
            } else if (parsedContent is String) {
              // If it's a string, try to split it into lines
              final lines =
                  parsedContent
                      .split('\n')
                      .map((line) => line.trim())
                      .where((line) => line.isNotEmpty)
                      .toList();

              if (lines.isNotEmpty) {
                return lines;
              }
            }

            // Fallback: if we can't parse it as expected, return an error
            print('Failed to extract questions from response: $parsedContent');
            throw Exception('Unexpected response format from API');
          } catch (e) {
            throw Exception('Error parsing API response: $e');
          }
        } else {
          throw Exception('Invalid response structure from API');
        }
      } else {
        throw Exception('Failed to generate questions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating questions: $e');
    }
  }

  // Evaluate interview answer
  static Future<Map> evaluateAnswer({
    required String question,
    required String answer,
    required String field,
    required List<String> technologies,
    required String difficulty,
  }) async {
    try {
      final techString = technologies.join(', ');

      final prompt =
          """Evaluate the following interview answer for a $difficulty level $field developer 
      with expertise in $techString. 
      
Question: $question

Answer: $answer

Provide a score from 0-100 and brief feedback. 
      Format the response as a JSON object with 'score' (number) and 'feedback' (string) fields.""";

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer':
              'https://interview-service.app', // Replace with your app domain
        },
        body: jsonEncode({
          'model': _defaultModel,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an expert technical interviewer for $field positions.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        // Safely extract content from the response
        if (jsonResponse.containsKey('choices') &&
            jsonResponse['choices'] is List &&
            jsonResponse['choices'].isNotEmpty &&
            jsonResponse['choices'][0].containsKey('message') &&
            jsonResponse['choices'][0]['message'].containsKey('content')) {
          final content = jsonResponse['choices'][0]['message']['content'];

          try {
            // Print the raw content for debugging
            print('Raw API evaluation response content: $content');

            // Parse the content as JSON
            final dynamic parsedContent = jsonDecode(content);
            print(
              'Parsed evaluation content type: ${parsedContent.runtimeType}',
            );

            // Ensure we have a valid response with score and feedback
            if (parsedContent is Map) {
              // Check if it has the expected fields
              if (parsedContent.containsKey('score') &&
                  parsedContent.containsKey('feedback')) {
                return parsedContent;
              } else {
                // Try to extract score and feedback from different structure
                final Map<String, dynamic> result = {};

                // Look for score in any numeric field
                parsedContent.forEach((key, value) {
                  if (value is num &&
                      (key.toLowerCase().contains('score') ||
                          key == 'rating')) {
                    result['score'] = value;
                  } else if (value is String &&
                      (key.toLowerCase().contains('feedback') ||
                          key.toLowerCase().contains('comment') ||
                          key.toLowerCase().contains('review'))) {
                    result['feedback'] = value;
                  }
                });

                if (result.containsKey('score') &&
                    result.containsKey('feedback')) {
                  return result;
                }
              }
            }

            // If we couldn't extract the expected format, log and throw exception
            print('Failed to extract evaluation from response: $parsedContent');
            return {
              'score': 0,
              'feedback':
                  'Error: Could not parse evaluation response. Please try again.',
            };
          } catch (e) {
            print('Error parsing API evaluation response: $e');
            throw Exception('Error parsing API response: $e');
          }
        } else {
          throw Exception('Invalid response structure from API');
        }
      } else {
        throw Exception('Failed to evaluate answer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error evaluating answer: $e');
    }
  }
}
