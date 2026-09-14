// Newman runner for the two RF-G7-02 SQL cases. Reports intentionally omit headers and bodies.
const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');
const newman = require('newman');
const root = path.resolve(__dirname, '../..');
const folder = 'Semana 3 - SQL dinamico';
const apiKey = process.env.API_KEY;
if (!apiKey) throw new Error('Definir API_KEY en el entorno antes de ejecutar.');
const baseUrl = process.env.BASE_URL || 'https://aiquaa-sandbox-api.vercel.app';
const evidence = path.join(__dirname, 'evidence', 'semana-3-newman.json');
const clean = value => String(value).split(apiKey).join('[REDACTED]');
const report = {
  startedAt: new Date().toISOString(),
  baseUrl, folder,
  newmanVersion: require('newman/package.json').version,
  baseCommit: execFileSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).trim(),
  scope: 'Dos casos RF-G7-02; no ejecuta los 20 requests de regresion existentes.',
  requests: [], assertions: [], diagnostics: []
};
newman.run({
  collection: path.join(root, 'postman', 'grupo-07-carrito-ecommerce.postman_collection.json'),
  environment: { name: 'Grupo 7 Semana 3 (runtime)', values: [
    { key: 'baseUrl', value: baseUrl, enabled: true },
    { key: 'apiKey', value: apiKey, enabled: true }
  ] },
  folder, iterationCount: 1, bail: true,
  timeoutRequest: 20000, timeoutScript: 60000, timeout: 180000,
  delayRequest: 2500, reporters: ['cli']
}, (error, summary) => {
  report.finishedAt = new Date().toISOString();
  report.stats = summary && summary.run.stats;
  report.failures = (summary && summary.run.failures || []).map(f => ({
    source: f.source && f.source.name,
    name: clean(f.error && f.error.name),
    message: clean(f.error && f.error.message)
  }));
  if (error) report.failures.push({ name: error.name, message: clean(error.message) });
  // Prevent an empty/skipped run from being reported as successful.
  const business = report.requests.filter(r => r.url.endsWith('/api/v1/ordenes'));
  report.passed = !error && report.failures.length === 0 &&
    business.length === 2 && business[0].status === 201 && business[1].status === 400 &&
    report.assertions.length > 0 && report.assertions.every(a => a.passed);
  fs.mkdirSync(path.dirname(evidence), { recursive: true });
  fs.writeFileSync(evidence, JSON.stringify(report, null, 2) + '\n');
  console.log('Evidencia sin credenciales: ' + evidence);
  console.log('Resultado: ' + (report.passed ? 'PASS' : 'FAIL'));
  process.exitCode = report.passed ? 0 : 1;
}).on('request', (err, args) => {
  report.requests.push({
    case: args.item && args.item.name,
    method: args.request.method,
    url: clean(args.request.url.toString()),
    status: args.response && args.response.code,
    durationMs: args.response && args.response.responseTime,
    error: err ? clean(err.message) : undefined
  });
}).on('assertion', (err, args) => {
  report.assertions.push({
    case: args.item && args.item.name,
    name: clean(args.assertion),
    passed: !err,
    error: err ? clean(err.message) : undefined
  });
}).on('console', (err, args) => {
  const message = args.messages.map(value => typeof value === 'string' ? value : JSON.stringify(value)).join(' ');
  if (message.startsWith('G7-S3 ')) report.diagnostics.push(clean(message));
});
