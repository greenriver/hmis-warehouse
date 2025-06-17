import * as Sentry from '@sentry/browser';

const config = window.sentryConfig || {};
const hostname = window.location.hostname;

// The base trace rate for performance monitoring.
// This should be provided during the build process. It can be set to 0 to disable tracing.
// It defaults to 1.0 in production and staging, and 0.0 in other environments if not set.
const getBaseTraceRate = () => {
  if (config.traceRate) {
    return parseFloat(config.traceRate);
  }
  if (config.environment === 'production' || config.environment === 'staging') {
    return 1.0;
  }
  return 0.0;
};

if (config.dsn) {
  Sentry.init({
    dsn: config.dsn,
    environment: config.environment || 'development',
    initialScope: {
      tags: { hostname },
    },
    tracesSampler: (samplingContext) => {
      if (samplingContext.parentSampled !== undefined) {
        return samplingContext.parentSampled;
      }
      const baseTraceRate = getBaseTraceRate();
      if (baseTraceRate === 0.0) return 0.0;
      const transactionName = samplingContext.transactionContext.name;
      let traceWeight = 1.0;
      if (transactionName) {
        if (transactionName.match(/^\/system_status/)) {
          traceWeight = 0.0;
        } else if (transactionName.match(/^\/messages\/poll/) || transactionName === '/') {
          traceWeight = 0.01;
        }
      }
      return traceWeight * baseTraceRate;
    },
    // Add integrations here if needed
    allowUrls: [hostname],
    ignoreErrors: [],
    beforeSend(event) {
      return event;
    },
  });
}

// Export Sentry for use in other files
export default Sentry; 