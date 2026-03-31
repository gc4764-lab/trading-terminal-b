import 'dart:ui';
import 'package:flutter/material.dart';

class MemoryOptimizer {
  static final Map<String, ImageProvider> _imageCache = {};
  static final Map<String, Widget> _widgetCache = {};
  
  // Optimize image loading
  static ImageProvider getOptimizedImage(String url, {int? width, int? height}) {
    if (_imageCache.containsKey(url)) {
      return _imageCache[url]!;
    }
    
    final provider = NetworkImage(
      url,
      scale: 1.0,
      headers: {'Cache-Control': 'max-age=3600'},
    );
    
    _imageCache[url] = provider;
    
    // Limit cache size
    if (_imageCache.length > 50) {
      _imageCache.remove(_imageCache.keys.first);
    }
    
    return provider;
  }
  
  // Debounce expensive operations
  static Timer? _debounceTimer;
  static void debounce(VoidCallback callback, {Duration duration = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, callback);
  }
  
  // Throttle operations
  static DateTime? _lastExecution;
  static void throttle(VoidCallback callback, {Duration duration = const Duration(milliseconds: 500)}) {
    final now = DateTime.now();
    if (_lastExecution == null || now.difference(_lastExecution!) >= duration) {
      _lastExecution = now;
      callback();
    }
  }
  
  // Clear caches on low memory
  static void onLowMemory() {
    _imageCache.clear();
    _widgetCache.clear();
    paintingBinding.imageCache?.clear();
    paintingBinding.imageCache?.clearLiveImages();
  }
  
  // Lazy loading for lists
  static Widget lazyLoadList({
    required int itemCount,
    required Widget Function(int index) itemBuilder,
    int batchSize = 10,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        int loadedItems = batchSize;
        
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification) {
              final maxScroll = notification.metrics.maxScrollExtent;
              final currentScroll = notification.metrics.pixels;
              
              if (currentScroll >= maxScroll - 200 && loadedItems < itemCount) {
                setState(() {
                  loadedItems = (loadedItems + batchSize).clamp(0, itemCount);
                });
              }
            }
            return false;
          },
          child: ListView.builder(
            itemCount: loadedItems,
            itemBuilder: (context, index) => itemBuilder(index),
          ),
        );
      },
    );
  }
  
  // Virtual scrolling for large lists
  static Widget virtualScrollList({
    required int itemCount,
    required double itemHeight,
    required Widget Function(int index) itemBuilder,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemExtent: itemHeight,
      cacheExtent: 500, // Cache 500px of items
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: false,
      addSemanticIndexes: false,
      itemBuilder: (context, index) => RepaintBoundary(
        child: itemBuilder(index),
      ),
    );
  }
}