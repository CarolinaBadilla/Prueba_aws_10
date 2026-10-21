const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { ConsoleSpanExporter } = require('@opentelemetry/sdk-trace-node');

// Inicializa el SDK de OpenTelemetry
const sdk = new NodeSDK({
  traceExporter: new ConsoleSpanExporter(), // Imprime trazas formateadas en stdout
  instrumentations: [
    getNodeAutoInstrumentations({
      // Auto-instrumenta Express, HTTP y Postgres (pg)
      '@opentelemetry/instrumentation-fs': { enabled: false }, // Ignora I/O de disco para reducir ruido
    }),
  ],
});

sdk.start();

// Cierre limpio al recibir señales del sistema
process.on('SIGTERM', () => {
  sdk.shutdown()
    .then(() => console.log('OpenTelemetry SDK shut down successfully'))
    .catch((err) => console.log('Error shutting down OpenTelemetry SDK', err))
    .finally(() => process.exit(0));
});