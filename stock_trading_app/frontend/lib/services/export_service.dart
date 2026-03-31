import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stock_trading_app/models/order.dart';
import 'package:stock_trading_app/models/position.dart';

class ExportService {
  // Export to CSV
  static Future<File> exportToCSV({
    required List<dynamic> data,
    required List<String> headers,
    required String filename,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename.csv';
    final file = File(filePath);
    
    List<List<dynamic>> rows = [headers];
    rows.addAll(data.map((item) => _convertToRow(item, headers)));
    
    String csv = const ListToCsvConverter().convert(rows);
    await file.writeAsString(csv);
    
    return file;
  }
  
  // Export to Excel
  static Future<File> exportToExcel({
    required List<dynamic> data,
    required List<String> headers,
    required String filename,
    required Map<String, dynamic> sheets,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename.xlsx';
    
    var excel = Excel.createExcel();
    
    sheets.forEach((sheetName, sheetData) {
      var sheet = excel[sheetName];
      
      // Add headers
      sheet.appendRow(headers);
      
      // Add data
      for (var item in sheetData) {
        sheet.appendRow(_convertToRow(item, headers));
      }
    });
    
    final fileBytes = excel.encode();
    await File(filePath).writeAsBytes(fileBytes!);
    
    return File(filePath);
  }
  
  // Export orders
  static Future<void> exportOrders(List<Order> orders) async {
    final headers = [
      'Order ID',
      'Symbol',
      'Side',
      'Type',
      'Quantity',
      'Price',
      'Status',
      'Filled Price',
      'Filled Quantity',
      'Date',
    ];
    
    final file = await exportToCSV(
      data: orders,
      headers: headers,
      filename: 'orders_${DateTime.now().millisecondsSinceEpoch}',
    );
    
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Exported orders',
    );
  }
  
  // Export positions
  static Future<void> exportPositions(List<Position> positions) async {
    final headers = [
      'Symbol',
      'Quantity',
      'Avg Price',
      'Current Price',
      'PnL',
      'PnL %',
      'Value',
    ];
    
    final file = await exportToCSV(
      data: positions,
      headers: headers,
      filename: 'positions_${DateTime.now().millisecondsSinceEpoch}',
    );
    
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Exported positions',
    );
  }
  
  // Generate performance report
  static Future<File> generatePerformanceReport({
    required List<Order> orders,
    required List<Position> positions,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final excel = Excel.createExcel();
    
    // Summary sheet
    final summarySheet = excel['Summary'];
    summarySheet.appendRow(['Performance Report']);
    summarySheet.appendRow(['Period: $startDate to $endDate']);
    summarySheet.appendRow([]);
    summarySheet.appendRow(['Total Trades', orders.length]);
    summarySheet.appendRow(['Winning Trades', _countWinningTrades(orders)]);
    summarySheet.appendRow(['Losing Trades', _countLosingTrades(orders)]);
    summarySheet.appendRow(['Win Rate', _calculateWinRate(orders)]);
    summarySheet.appendRow(['Total PnL', _calculateTotalPnL(positions)]);
    summarySheet.appendRow(['Best Trade', _findBestTrade(orders)]);
    summarySheet.appendRow(['Worst Trade', _findWorstTrade(orders)]);
    
    // Trades sheet
    final tradesSheet = excel['Trades'];
    tradesSheet.appendRow([
      'Date',
      'Symbol',
      'Side',
      'Quantity',
      'Price',
      'Value',
    ]);
    
    for (var order in orders) {
      tradesSheet.appendRow([
        order.createdAt,
        order.symbol,
        order.side,
        order.quantity,
        order.price,
        order.quantity * order.price,
      ]);
    }
    
    // Positions sheet
    final positionsSheet = excel['Positions'];
    positionsSheet.appendRow([
      'Symbol',
      'Quantity',
      'Avg Price',
      'Current Price',
      'PnL',
      'Value',
    ]);
    
    for (var position in positions) {
      positionsSheet.appendRow([
        position.symbol,
        position.quantity,
        position.avgPrice,
        position.currentPrice,
        position.pnl,
        position.quantity * position.currentPrice,
      ]);
    }
    
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/performance_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final fileBytes = excel.encode();
    await File(filePath).writeAsBytes(fileBytes!);
    
    return File(filePath);
  }
  
  static int _countWinningTrades(List<Order> orders) {
    // Implementation
    return 0;
  }
  
  static int _countLosingTrades(List<Order> orders) {
    // Implementation
    return 0;
  }
  
  static double _calculateWinRate(List<Order> orders) {
    // Implementation
    return 0.0;
  }
  
  static double _calculateTotalPnL(List<Position> positions) {
    return positions.fold(0.0, (sum, p) => sum + p.pnl);
  }
  
  static double _findBestTrade(List<Order> orders) {
    // Implementation
    return 0.0;
  }
  
  static double _findWorstTrade(List<Order> orders) {
    // Implementation
    return 0.0;
  }
  
  static List<dynamic> _convertToRow(dynamic item, List<String> headers) {
    return headers.map((header) {
      if (item is Order) {
        switch (header) {
          case 'Order ID': return item.id;
          case 'Symbol': return item.symbol;
          case 'Side': return item.side;
          case 'Type': return item.type;
          case 'Quantity': return item.quantity;
          case 'Price': return item.price;
          case 'Status': return item.status;
          case 'Filled Price': return item.filledPrice ?? '';
          case 'Filled Quantity': return item.filledQuantity ?? '';
          case 'Date': return item.createdAt;
          default: return '';
        }
      } else if (item is Position) {
        switch (header) {
          case 'Symbol': return item.symbol;
          case 'Quantity': return item.quantity;
          case 'Avg Price': return item.avgPrice;
          case 'Current Price': return item.currentPrice;
          case 'PnL': return item.pnl;
          case 'PnL %': return (item.pnl / (item.quantity * item.avgPrice)) * 100;
          case 'Value': return item.quantity * item.currentPrice;
          default: return '';
        }
      }
      return '';
    }).toList();
  }
}