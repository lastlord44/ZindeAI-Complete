class HealthStatus {
  final String status;
  final WorkerInfo worker;
  final SystemHealth system;
  final Map<String, ProviderStatus> providers;
  final ConfigurationInfo configuration;
  final int responseTimeMs;

  HealthStatus({
    required this.status,
    required this.worker,
    required this.system,
    required this.providers,
    required this.configuration,
    required this.responseTimeMs,
  });

  String get message => status;

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    final providersMap = <String, ProviderStatus>{};
    if (json['providers'] != null) {
      (json['providers'] as Map<String, dynamic>).forEach((key, value) {
        providersMap[key] = ProviderStatus.fromJson(value);
      });
    }

    return HealthStatus(
      status: json['status'] ?? 'unknown',
      worker: WorkerInfo.fromJson(json['worker'] ?? {}),
      system: SystemHealth.fromJson(json['system'] ?? {}),
      providers: providersMap,
      configuration: ConfigurationInfo.fromJson(json['configuration'] ?? {}),
      responseTimeMs: json['response_time_ms'] ?? 0,
    );
  }
}

class WorkerInfo {
  final String name;
  final String version;
  final String buildId;
  final String environment;
  final String region;
  final int uptimeSeconds;
  final String timestamp;
  final String timezone;

  WorkerInfo({
    required this.name,
    required this.version,
    required this.buildId,
    required this.environment,
    required this.region,
    required this.uptimeSeconds,
    required this.timestamp,
    required this.timezone,
  });

  factory WorkerInfo.fromJson(Map<String, dynamic> json) {
    return WorkerInfo(
      name: json['name'] ?? '',
      version: json['version'] ?? '',
      buildId: json['build_id'] ?? '',
      environment: json['environment'] ?? '',
      region: json['region'] ?? '',
      uptimeSeconds: json['uptime_seconds'] ?? 0,
      timestamp: json['timestamp'] ?? '',
      timezone: json['timezone'] ?? '',
    );
  }
}

class SystemHealth {
  final String overallStatus;
  final int healthyProviders;
  final int degradedProviders;
  final int circuitBrokenProviders;
  final bool fallbackAvailable;
  final bool degradeModeRisk;

  SystemHealth({
    required this.overallStatus,
    required this.healthyProviders,
    required this.degradedProviders,
    required this.circuitBrokenProviders,
    required this.fallbackAvailable,
    required this.degradeModeRisk,
  });

  factory SystemHealth.fromJson(Map<String, dynamic> json) {
    return SystemHealth(
      overallStatus: json['overall_status'] ?? 'unknown',
      healthyProviders: json['healthy_providers'] ?? 0,
      degradedProviders: json['degraded_providers'] ?? 0,
      circuitBrokenProviders: json['circuit_broken_providers'] ?? 0,
      fallbackAvailable: json['fallback_available'] ?? false,
      degradeModeRisk: json['degrade_mode_risk'] ?? false,
    );
  }
}

class ProviderStatus {
  final String status;
  final bool available;
  final ProviderMetrics metrics;
  final CircuitBreakerInfo circuitBreaker;
  final int? lastErrorTimestamp;

  ProviderStatus({
    required this.status,
    required this.available,
    required this.metrics,
    required this.circuitBreaker,
    this.lastErrorTimestamp,
  });

  factory ProviderStatus.fromJson(Map<String, dynamic> json) {
    return ProviderStatus(
      status: json['status'] ?? 'unknown',
      available: json['available'] ?? false,
      metrics: ProviderMetrics.fromJson(json['metrics'] ?? {}),
      circuitBreaker:
          CircuitBreakerInfo.fromJson(json['circuit_breaker'] ?? {}),
      lastErrorTimestamp: json['last_error_timestamp'],
    );
  }
}

class ProviderMetrics {
  final int errorsLastMinute;
  final int errorsCurrentWindow;
  final int dailyRequests;
  final int dailyRateLimit;
  final int rateLimitPercentage;
  final int? quotaPercentage;

  ProviderMetrics({
    required this.errorsLastMinute,
    required this.errorsCurrentWindow,
    required this.dailyRequests,
    required this.dailyRateLimit,
    required this.rateLimitPercentage,
    this.quotaPercentage,
  });

  factory ProviderMetrics.fromJson(Map<String, dynamic> json) {
    return ProviderMetrics(
      errorsLastMinute: json['errors_last_minute'] ?? 0,
      errorsCurrentWindow: json['errors_current_window'] ?? 0,
      dailyRequests: json['daily_requests'] ?? 0,
      dailyRateLimit: json['daily_rate_limit'] ?? 0,
      rateLimitPercentage: json['rate_limit_percentage'] ?? 0,
      quotaPercentage: json['quota_percentage'],
    );
  }
}

class CircuitBreakerInfo {
  final bool active;
  final int? cooldownUntil;
  final int? cooldownRemainingSeconds;

  CircuitBreakerInfo({
    required this.active,
    this.cooldownUntil,
    this.cooldownRemainingSeconds,
  });

  factory CircuitBreakerInfo.fromJson(Map<String, dynamic> json) {
    return CircuitBreakerInfo(
      active: json['active'] ?? false,
      cooldownUntil: json['cooldown_until'],
      cooldownRemainingSeconds: json['cooldown_remaining_seconds'],
    );
  }
}

class ConfigurationInfo {
  final int circuitBreakerThreshold;
  final int circuitBreakerWindow;
  final int circuitBreakerCooldown;
  final int quotaThreshold;
  final int maxRetries;

  ConfigurationInfo({
    required this.circuitBreakerThreshold,
    required this.circuitBreakerWindow,
    required this.circuitBreakerCooldown,
    required this.quotaThreshold,
    required this.maxRetries,
  });

  factory ConfigurationInfo.fromJson(Map<String, dynamic> json) {
    return ConfigurationInfo(
      circuitBreakerThreshold: json['circuit_breaker_threshold'] ?? 5,
      circuitBreakerWindow: json['circuit_breaker_window'] ?? 60,
      circuitBreakerCooldown: json['circuit_breaker_cooldown'] ?? 120,
      quotaThreshold: json['quota_threshold'] ?? 90,
      maxRetries: json['max_retries'] ?? 3,
    );
  }
}
