// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenRouter API Test',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const OpenRouterApiTest(),
    );
  }
}

class OpenRouterApiTest extends StatefulWidget {
  const OpenRouterApiTest({super.key});

  @override
  State<OpenRouterApiTest> createState() => _OpenRouterApiTestState();
}

class _OpenRouterApiTestState extends State<OpenRouterApiTest> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController(
    // Note: Replace this placeholder text with your actual API key when testing
    text: "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",
  );
  final TextEditingController _endpointController = TextEditingController(
    text: "https://openrouter.ai/api/v1/chat/completions",
  );

  String _response = "";
  bool _isLoading = false;
  String _modelName = "openai/gpt-4o";
  double _temperature = 0.7;
  int _maxTokens = 1024;
  bool _useJsonFormat = true;

  Future<void> _sendRequest() async {
    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a prompt')));
      return;
    }

    setState(() {
      _isLoading = true;
      _response = "Loading...";
    });

    try {
      // Build the request body
      final Map<String, dynamic> requestBody = {
        'model': _modelName,
        'messages': [
          {'role': 'user', 'content': _promptController.text},
        ],
        'temperature': _temperature,
        'max_tokens': _maxTokens,
      };
      
      // Add response_format if JSON is requested
      if (_useJsonFormat) {
        requestBody['response_format'] = {'type': 'json_object'};
      }
      
      // Print the request for debugging
      print('Request body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse(_endpointController.text.trim()),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_apiKeyController.text.trim()}',
          'HTTP-Referer': 'https://interview-service.app',
        },
        body: jsonEncode(requestBody),
      );

      setState(() {
        _isLoading = false;
        if (response.statusCode == 200) {
          final decodedResponse = jsonDecode(response.body);
          
          // Print the raw response for debugging
          print('Raw API response: ${response.body}');
          
          // Extract and print the content specifically
          if (decodedResponse.containsKey('choices') && 
              decodedResponse['choices'] is List && 
              decodedResponse['choices'].isNotEmpty && 
              decodedResponse['choices'][0].containsKey('message') && 
              decodedResponse['choices'][0]['message'].containsKey('content')) {
            
            final content = decodedResponse['choices'][0]['message']['content'];
            print('Content from response: $content');
            
            // Try to parse the content as JSON if JSON format was requested
            if (_useJsonFormat) {
              try {
                final parsedContent = jsonDecode(content);
                print('Parsed content type: ${parsedContent.runtimeType}');
                print('Parsed content: $parsedContent');
              } catch (e) {
                print('Error parsing content as JSON: $e');
              }
            }
          }
          
          _response = const JsonEncoder.withIndent(
            '  ',
          ).convert(decodedResponse);
        } else {
          _response = 'Error: ${response.statusCode}\n${response.body}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _response = 'Exception: $e';
      });
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _apiKeyController.dispose();
    _endpointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenRouter API Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _endpointController,
              decoration: const InputDecoration(
                labelText: 'API Endpoint',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _modelName,
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'openai/gpt-4o', child: Text('GPT-4o')),
                DropdownMenuItem(
                  value: 'openai/gpt-4-turbo',
                  child: Text('GPT-4 Turbo'),
                ),
                DropdownMenuItem(
                  value: 'anthropic/claude-3-opus-20240229',
                  child: Text('Claude 3 Opus'),
                ),
                DropdownMenuItem(
                  value: 'anthropic/claude-3-sonnet-20240229',
                  child: Text('Claude 3 Sonnet'),
                ),
                DropdownMenuItem(
                  value: 'anthropic/claude-3-haiku-20240307',
                  child: Text('Claude 3 Haiku'),
                ),
                DropdownMenuItem(
                  value: 'meta-llama/llama-3-70b-instruct',
                  child: Text('Llama 3 70B'),
                ),
                DropdownMenuItem(
                  value: 'google/gemini-pro',
                  child: Text('Gemini Pro'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _modelName = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Temperature: ${_temperature.toStringAsFixed(1)}'),
                      Slider(
                        value: _temperature,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        onChanged: (value) {
                          setState(() {
                            _temperature = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Max Tokens: $_maxTokens'),
                      Slider(
                        value: _maxTokens.toDouble(),
                        min: 100,
                        max: 4000,
                        divisions: 39,
                        onChanged: (value) {
                          setState(() {
                            _maxTokens = value.toInt();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Request JSON Format'),
                    value: _useJsonFormat,
                    onChanged: (value) {
                      setState(() {
                        _useJsonFormat = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Prompt',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendRequest,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Send Request'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: SingleChildScrollView(
                  child: Text(_response),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}