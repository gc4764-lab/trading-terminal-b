import 'dart:convert';
import 'package:http/http.dart' as http;

class APIDocumentation {
  static Future<String> generateMarkdown() async {
    final endpoints = await _fetchEndpoints();
    final markdown = StringBuffer();
    
    markdown.writeln('# API Documentation\n');
    markdown.writeln('## Overview\n');
    markdown.writeln('Base URL: `https://api.stocktradingapp.com/v1`\n');
    markdown.writeln('Authentication: Bearer Token\n');
    
    for (var endpoint in endpoints) {
      markdown.writeln('## ${endpoint['name']}\n');
      markdown.writeln('### ${endpoint['method']} ${endpoint['path']}\n');
      markdown.writeln('${endpoint['description']}\n');
      
      if (endpoint['parameters'].isNotEmpty) {
        markdown.writeln('#### Parameters\n');
        markdown.writeln('| Name | Type | Required | Description |');
        markdown.writeln('|------|------|----------|-------------|');
        
        for (var param in endpoint['parameters']) {
          markdown.writeln('| ${param['name']} | ${param['type']} | ${param['required']} | ${param['description']} |');
        }
        markdown.writeln();
      }
      
      if (endpoint['requestExample'] != null) {
        markdown.writeln('#### Request Example\n');
        markdown.writeln('```json');
        markdown.writeln(jsonEncode(endpoint['requestExample']));
        markdown.writeln('```\n');
      }
      
      if (endpoint['responseExample'] != null) {
        markdown.writeln('#### Response Example\n');
        markdown.writeln('```json');
        markdown.writeln(jsonEncode(endpoint['responseExample']));
        markdown.writeln('```\n');
      }
      
      if (endpoint['errorCodes'] != null) {
        markdown.writeln('#### Error Codes\n');
        markdown.writeln('| Code | Description |');
        markdown.writeln('|------|-------------|');
        
        for (var error in endpoint['errorCodes']) {
          markdown.writeln('| ${error['code']} | ${error['description']} |');
        }
        markdown.writeln();
      }
    }
    
    return markdown.toString();
  }
  
  static Future<List<Map<String, dynamic>>> _fetchEndpoints() async {
    // In production, fetch from actual API endpoints
    return [
      {
        'name': 'Get Watchlist',
        'method': 'GET',
        'path': '/watchlist',
        'description': 'Retrieve user\'s watchlist',
        'parameters': [],
        'responseExample': {
          'watchlist': [
            {
              'id': 'stock_1',
              'symbol': 'AAPL',
              'name': 'Apple Inc.',
              'exchange': 'NASDAQ',
            }
          ]
        },
        'errorCodes': [
          {'code': 401, 'description': 'Unauthorized'},
          {'code': 500, 'description': 'Internal server error'},
        ],
      },
      // Add more endpoints...
    ];
  }
}