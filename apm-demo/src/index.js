const apm = require('elastic-apm-node').start({
  serviceName: process.env.ELASTIC_APM_SERVICE_NAME || 'aquarela-apm-demo',
  serverUrl: process.env.ELASTIC_APM_SERVER_URL || 'http://localhost:8200',
  environment: process.env.ELASTIC_APM_ENVIRONMENT || 'prod',
  captureBody: 'all',
  centralConfig: false,
});

const express = require('express');
const client = require('prom-client');

const app = express();
const port = Number(process.env.PORT || 3000);
const registry = new client.Registry();

client.collectDefaultMetrics({ register: registry });

const httpDuration = new client.Histogram({
  name: 'apm_demo_http_request_duration_seconds',
  help: 'Duration of HTTP requests handled by the demo service.',
  labelNames: ['method', 'route', 'status_code'],
  registers: [registry],
});

const errorCounter = new client.Counter({
  name: 'apm_demo_errors_total',
  help: 'Number of application errors returned by the demo service.',
  labelNames: ['route'],
  registers: [registry],
});

app.use((req, res, next) => {
  const endTimer = httpDuration.startTimer({ method: req.method, route: req.path });

  res.on('finish', () => {
    endTimer({ status_code: String(res.statusCode) });
  });

  next();
});

app.get('/', (req, res) => {
  res.json({
    service: 'aquarela-apm-demo',
    status: 'ok',
    endpoints: ['/healthz', '/metrics', '/work', '/failure'],
  });
});

app.get('/healthz', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', registry.contentType);
  res.end(await registry.metrics());
});

app.get('/work', async (req, res) => {
  const delay = Number(req.query.delay || 250);
  const span = apm.startSpan('simulated-work', 'custom');

  await new Promise((resolve) => setTimeout(resolve, delay));

  if (span) {
    span.end();
  }

  res.json({
    message: 'work completed',
    delay,
    timestamp: new Date().toISOString(),
  });
});

app.get('/failure', (req, res, next) => {
  next(new Error('simulated failure for Elastic APM evidence'));
});

app.use((err, req, res, next) => {
  errorCounter.inc({ route: req.path });
  apm.captureError(err);

  res.status(500).json({
    error: err.message,
  });
});

app.listen(port, () => {
  // Keep startup logging small so the app is easy to inspect in Kibana.
  console.log(`aquarela-apm-demo listening on port ${port}`);
});
