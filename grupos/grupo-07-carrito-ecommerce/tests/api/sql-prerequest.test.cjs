const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const newman = require('newman');
const collectionPath = path.resolve(__dirname, '../../../../postman/grupo-07-carrito-ecommerce.postman_collection.json');

for (const scenario of [
  { name: 'sin API key', key: '', status: 200, body: '{"data":[{"id":1}],"rowCount":1}', sqlCalls: 0 },
  { name: 'SQL devuelve 401', key: 'test-only', status: 401, body: '{"error":{"code":"UNAUTHORIZED"}}', sqlCalls: 1 },
  { name: 'SQL devuelve HTML', key: 'test-only', status: 200, body: '<html>error</html>', sqlCalls: 1 },
  { name: 'SQL sin compradores', key: 'test-only', status: 200, body: '{"data":[],"rowCount":0}', sqlCalls: 1 }
]) {
  test('Pre-request bloquea checkout: ' + scenario.name, async () => {
    let sqlCalls = 0;
    let businessCalls = 0;
    const server = http.createServer((req, res) => {
      if (req.url === '/api/v1/sql/select') sqlCalls++;
      else businessCalls++;
      res.writeHead(scenario.status, { 'Content-Type': 'application/json' });
      res.end(scenario.body);
    });
    await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
    try {
      const collection = JSON.parse(fs.readFileSync(collectionPath, 'utf8'));
      const environment = { values: [
        { key: 'baseUrl', value: 'http://127.0.0.1:' + server.address().port, enabled: true },
        { key: 'apiKey', value: scenario.key, enabled: true },
        { key: 'g7UsuarioId', value: '9999', enabled: true }
      ] };
      const summary = await new Promise((resolve, reject) => {
        newman.run({ collection, environment, folder: 'Semana 3 - SQL dinamico', bail: true,
          timeoutRequest: 2000, timeoutScript: 5000, timeout: 10000, reporters: [] },
        (err, result) => err ? reject(err) : resolve(result));
      });
      assert.ok(summary.run.failures.length > 0, 'Debe registrar un fallo real, no un PASS vacio');
      assert.equal(sqlCalls, scenario.sqlCalls);
      assert.equal(businessCalls, 0, 'No debe enviarse POST /ordenes con datos ausentes o residuales');
    } finally {
      await new Promise(resolve => server.close(resolve));
    }
  });
}
