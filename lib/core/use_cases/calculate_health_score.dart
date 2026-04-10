class CalculateHealthScore {
  double call({
    required double latency,
    required double loss,
    required double jitter,
    required double dns,
  }) {
    double score = 100;

    // Latency penalty (30% weight)
    if (latency > 200) {
      score -= 30;
    } else if (latency > 100) {
      score -= 15;
    } else if (latency > 50) {
      score -= 5;
    }

    // Packet loss penalty (30% weight)
    if (loss > 5) {
      score -= 30;
    } else if (loss > 1) {
      score -= 15;
    } else if (loss > 0.5) {
      score -= 5;
    }

    // Jitter penalty (20% weight)
    if (jitter > 50) {
      score -= 20;
    } else if (jitter > 30) {
      score -= 10;
    } else if (jitter > 10) {
      score -= 3;
    }

    // DNS penalty (20% weight)
    if (dns > 200) {
      score -= 20;
    } else if (dns > 100) {
      score -= 10;
    } else if (dns > 50) {
      score -= 3;
    }

    return score.clamp(0, 100);
  }
}
