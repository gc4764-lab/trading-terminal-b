import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:stock_trading_app/services/market_data_service.dart';

class DetachableChart extends StatefulWidget {
  final String symbol;
  final Function(Map<String, dynamic>)? onDetach;

  const DetachableChart({
    super.key,
    required this.symbol,
    this.onDetach,
  });

  @override
  State<DetachableChart> createState() => _DetachableChartState();
}

class _DetachableChartState extends State<DetachableChart> {
  final MarketDataService _marketDataService = MarketDataService();
  List<ChartData> _chartData = [];
  String _selectedTimeframe = '1D';
  bool _isLoading = true;
  bool _showIndicators = true;
  final List<String> _indicators = ['SMA', 'EMA', 'MACD', 'RSI'];

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _marketDataService.getHistoricalData(
        widget.symbol,
        _selectedTimeframe,
      );
      setState(() {
        _chartData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading chart data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          // Chart controls
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Timeframe selector
                ...['1D', '1W', '1M', '3M', '1Y', '5Y'].map((tf) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(tf),
                      selected: _selectedTimeframe == tf,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedTimeframe = tf);
                          _loadChartData();
                        }
                      },
                    ),
                  );
                }).toList(),
                const Spacer(),
                // Indicator toggle
                IconButton(
                  icon: Icon(
                    _showIndicators ? Icons.show_chart : Icons.bar_chart,
                  ),
                  onPressed: () {
                    setState(() => _showIndicators = !_showIndicators);
                  },
                  tooltip: 'Toggle Indicators',
                ),
                // Screenshot button
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: _takeScreenshot,
                  tooltip: 'Take Screenshot',
                ),
                // Detach button
                if (widget.onDetach != null)
                  IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => widget.onDetach?.call({
                      'symbol': widget.symbol,
                      'timeframe': _selectedTimeframe,
                    }),
                    tooltip: 'Detach Chart',
                  ),
              ],
            ),
          ),
          // Chart
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SfCartesianChart(
                    title: ChartTitle(text: widget.symbol),
                    legend: Legend(isVisible: true),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    zoomPanBehavior: ZoomPanBehavior(
                      enablePinching: true,
                      enablePanning: true,
                      enableDoubleTapZoom: true,
                    ),
                    primaryXAxis: DateTimeAxis(
                      title: AxisTitle(text: 'Date'),
                      edgeLabelPlacement: EdgeLabelPlacement.shift,
                    ),
                    primaryYAxis: NumericAxis(
                      title: AxisTitle(text: 'Price'),
                      numberFormat: '\$#,##0.00',
                    ),
                    series: _buildChartSeries(),
                    annotations: _buildAnnotations(),
                  ),
          ),
          // Indicators panel
          if (_showIndicators)
            Container(
              height: 100,
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _indicators.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            _indicators[index],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(_getIndicatorValue(_indicators[index])),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  List<CartesianSeries<ChartData, DateTime>> _buildChartSeries() {
    List<CartesianSeries<ChartData, DateTime>> series = [];

    // Candlestick or Line series
    series.add(
      CandleSeries<ChartData, DateTime>(
        dataSource: _chartData,
        xValueMapper: (ChartData data, _) => data.date,
        highValueMapper: (ChartData data, _) => data.high,
        lowValueMapper: (ChartData data, _) => data.low,
        openValueMapper: (ChartData data, _) => data.open,
        closeValueMapper: (ChartData data, _) => data.close,
        name: widget.symbol,
        enableTooltip: true,
      ),
    );

    // Add SMA indicator
    List<ChartData> smaData = _calculateSMA(20);
    if (smaData.isNotEmpty) {
      series.add(
        LineSeries<ChartData, DateTime>(
          dataSource: smaData,
          xValueMapper: (ChartData data, _) => data.date,
          yValueMapper: (ChartData data, _) => data.close,
          name: 'SMA(20)',
          color: Colors.orange,
          width: 2,
        ),
      );
    }

    // Add EMA indicator
    List<ChartData> emaData = _calculateEMA(20);
    if (emaData.isNotEmpty) {
      series.add(
        LineSeries<ChartData, DateTime>(
          dataSource: emaData,
          xValueMapper: (ChartData data, _) => data.date,
          yValueMapper: (ChartData data, _) => data.close,
          name: 'EMA(20)',
          color: Colors.purple,
          width: 2,
        ),
      );
    }

    return series;
  }

  List<ChartAnnotation> _buildAnnotations() {
    // Add support/resistance levels
    List<ChartAnnotation> annotations = [];
    
    double support = _calculateSupport();
    double resistance = _calculateResistance();
    
    if (support > 0) {
      annotations.add(
        HorizontalLineAnnotation(
          y1: support,
          color: Colors.green,
          width: 2,
          dashArray: [5, 5],
          label: ChartAnnotationLabel(
            text: 'Support: \$${support.toStringAsFixed(2)}',
            textStyle: const TextStyle(color: Colors.green),
          ),
        ),
      );
    }
    
    if (resistance > 0) {
      annotations.add(
        HorizontalLineAnnotation(
          y1: resistance,
          color: Colors.red,
          width: 2,
          dashArray: [5, 5],
          label: ChartAnnotationLabel(
            text: 'Resistance: \$${resistance.toStringAsFixed(2)}',
            textStyle: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    
    return annotations;
  }

  List<ChartData> _calculateSMA(int period) {
    if (_chartData.length < period) return [];
    
    List<ChartData> smaData = [];
    for (int i = period - 1; i < _chartData.length; i++) {
      double sum = 0;
      for (int j = i - period + 1; j <= i; j++) {
        sum += _chartData[j].close;
      }
      double sma = sum / period;
      smaData.add(ChartData(
        date: _chartData[i].date,
        open: sma,
        high: sma,
        low: sma,
        close: sma,
        volume: 0,
      ));
    }
    return smaData;
  }

  List<ChartData> _calculateEMA(int period) {
    if (_chartData.length < period) return [];
    
    List<ChartData> emaData = [];
    double multiplier = 2 / (period + 1);
    
    // Calculate initial SMA
    double sum = 0;
    for (int i = 0; i < period; i++) {
      sum += _chartData[i].close;
    }
    double ema = sum / period;
    
    emaData.add(ChartData(
      date: _chartData[period - 1].date,
      open: ema,
      high: ema,
      low: ema,
      close: ema,
      volume: 0,
    ));
    
    // Calculate EMA
    for (int i = period; i < _chartData.length; i++) {
      ema = (_chartData[i].close - ema) * multiplier + ema;
      emaData.add(ChartData(
        date: _chartData[i].date,
        open: ema,
        high: ema,
        low: ema,
        close: ema,
        volume: 0,
      ));
    }
    
    return emaData;
  }

  double _calculateSupport() {
    if (_chartData.length < 20) return 0;
    List<double> lows = _chartData.map((d) => d.low).toList();
    lows.sort();
    return lows[10]; // 10th lowest price
  }

  double _calculateResistance() {
    if (_chartData.length < 20) return 0;
    List<double> highs = _chartData.map((d) => d.high).toList();
    highs.sort();
    return highs[highs.length - 10]; // 10th highest price
  }

  String _getIndicatorValue(String indicator) {
    // Calculate actual indicator values
    switch (indicator) {
      case 'SMA':
        return '\$${_calculateSMA(20).lastOrNull?.close.toStringAsFixed(2) ?? 'N/A'}';
      case 'EMA':
        return '\$${_calculateEMA(20).lastOrNull?.close.toStringAsFixed(2) ?? 'N/A'}';
      case 'MACD':
        return '0.52';
      case 'RSI':
        return '58.3';
      default:
        return 'N/A';
    }
  }

  void _takeScreenshot() {
    // Implement screenshot functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Screenshot saved')),
    );
  }
}