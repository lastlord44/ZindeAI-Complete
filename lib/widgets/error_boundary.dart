import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// Error Boundary Widget - Hataları yakalar ve loglar
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;
  final String? tag;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.tag,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool hasError = false;
  Object? error;
  StackTrace? stackTrace;

  @override
  void initState() {
    super.initState();
    Logger.debug('ErrorBoundary initialized', tag: widget.tag ?? 'ErrorBoundary');
  }

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      Logger.error('ErrorBoundary caught error', 
          tag: widget.tag ?? 'ErrorBoundary',
          error: error,
          stackTrace: stackTrace);
      
      return widget.fallback ?? _DefaultErrorWidget(
        error: error,
        onRetry: () {
          setState(() {
            hasError = false;
            error = null;
            stackTrace = null;
          });
          Logger.info('ErrorBoundary retry triggered', tag: widget.tag ?? 'ErrorBoundary');
        },
      );
    }

    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Error boundary'yi yeniden başlat
    if (hasError) {
      setState(() {
        hasError = false;
        error = null;
        stackTrace = null;
      });
    }
  }
}

/// Default error widget
class _DefaultErrorWidget extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const _DefaultErrorWidget({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Bir hata oluştu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error?.toString() ?? 'Bilinmeyen hata',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}

/// Error boundary ile widget'ı sarmalama helper'ı
Widget withErrorBoundary(
  Widget child, {
  Widget? fallback,
  String? tag,
}) {
  return ErrorBoundary(
    tag: tag,
    fallback: fallback,
    child: child,
  );
}

/// Async operation error handler
class AsyncErrorHandler {
  static Future<T> handle<T>(
    Future<T> Function() operation, {
    String? tag,
    T? fallback,
    bool logError = true,
  }) async {
    try {
      Logger.debug('Async operation started', tag: tag);
      final result = await operation();
      Logger.success('Async operation completed', tag: tag);
      return result;
    } catch (error, stackTrace) {
      if (logError) {
        Logger.error('Async operation failed', 
            tag: tag,
            error: error,
            stackTrace: stackTrace);
      }
      
      if (fallback != null) {
        Logger.info('Using fallback value', tag: tag);
        return fallback;
      }
      
      rethrow;
    }
  }
}







