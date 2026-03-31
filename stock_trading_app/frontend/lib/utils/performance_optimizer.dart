import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class PerformanceOptimizer {
  static void optimizeApp() {
    // Enable high-performance rendering
    debugProfileBuildsEnabled = false;
    debugProfilePaintsEnabled = false;
    debugProfileLayoutsEnabled = false;
    
    // Set frame rate for animations
    SchedulerBinding.instance.schedulerPhase;
  }
  
  static Widget optimizeListView({
    required List<Widget> children,
    int cacheExtent = 1000,
  }) {
    return ListView.custom(
      cacheExtent: cacheExtent,
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: false,
      addSemanticIndexes: false,
      childrenDelegate: SliverChildListDelegate(
        children,
        addRepaintBoundaries: true,
        addAutomaticKeepAlives: false,
        addSemanticIndexes: false,
      ),
    );
  }
  
  static Widget optimizeGridView({
    required int itemCount,
    required Widget Function(int index) itemBuilder,
    int crossAxisCount = 2,
    double childAspectRatio = 1.0,
  }) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => RepaintBoundary(
        child: itemBuilder(index),
      ),
      cacheExtent: 500,
    );
  }
  
  static void profilePerformance() {
    // Measure frame rendering time
    SchedulerBinding.instance.addPersistentFrameCallback((timeStamp) {
      final frameTiming = SchedulerBinding.instance.frameTimeline;
      if (frameTiming != null && frameTiming.totalSpan.inMilliseconds > 16) {
        print('Frame drop detected: ${frameTiming.totalSpan.inMilliseconds}ms');
      }
    });
  }
}