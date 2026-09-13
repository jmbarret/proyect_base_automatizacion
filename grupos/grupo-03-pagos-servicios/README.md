# Grupo 03 — Pagos de Servicios

**Módulo:** Pago de facturas (ANDE, ESSAP, telefonía)
**Rama:** `grupo-03-pagos-servicios`

## Integrantes

- (completar: nombre y email — ver `inscripcion-grupos-bdd2.xlsx`)
- Juan Morel - jospz077@gmail.com
- Ana Segovia - annyse.28@gmail.com
- Lennys Cantero - lennyscantero@gmail.com
- Enzo Ruiz Diaz - enzoruizdiaz96@gmail.com
- Stefanía Cubas - stefi.cubas08@gmail.comm

## Alcance

- TODO: objetivo del flujo automatizado
- TODO: supuestos
- TODO: riesgos
- TODO: cobertura incluida / excluida

## Entregables

Checklist según [ENTREGABLES.md](../../ENTREGABLES.md):

- [ ] Análisis y alcance
- [ ] BDD — `features/` (mínimo 3 escenarios: happy path, negativo, edge case)
- [x] API — colección Postman/Newman (si aplica al módulo)
  - Colección única del grupo: [`postman/Grupo 3 - Pago de Servicios.postman_collection.json`](../../postman/Grupo%203%20-%20Pago%20de%20Servicios.postman_collection.json)
  - Environment: [`postman/Grupo 3 - Factura ANDE.postman_environment.json`](../../postman/Grupo%203%20-%20Factura%20ANDE.postman_environment.json)
- [ ] UI — `tests/e2e/` con Playwright
- [ ] Evidencias en `evidence/`
- [ ] CI/CD verde
- [ ] PR a `main` usando la plantilla del repo


# Trazabilidad BDD → API

## Scenario: Pago exitoso de factura de ANDE
      Given el usuario posee factura ANDE pendiente de pago
      When el usuario realiza el pago de la factura
      Then la factura cambia a estado pagada
      And se genera el comprobante de pago procesado
      And el monto del comprobante de pago coincide con el monto de la factura

Postman: POST https://aiquaa-sandbox-api.vercel.app/api/v1/facturas/{{ID_tabla}}/pagar
Body: {
  "metodoPago": "tarjeta"
}

Test: // Validar que la API responda 200 OK
pm.test("Pago confirmado correctamente", function () {
    pm.response.to.have.status(200);
});

// Validar que factura cambia a estado pagada
pm.test("El estado de la factura se actualizó a pagada", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.data.factura.estado).to.eql("pagada");
});

// Validar que el pago fue procesado correctamente
pm.test("Se generó el comprobante de pago en estado 'procesado'", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.data.pago.estado).to.eql("procesado");
});

// Validar consistencia de datos entre Factura y Pago
pm.test("El monto pagado coincide con el monto de la factura", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.data.pago.monto).to.eql(jsonData.data.factura.monto);
    pm.expect(jsonData.data.pago.factura_id).to.eql(jsonData.data.factura.id);
});

## Scenario: Pago exitoso de una factura ESSAP
      Given el usuario tiene una factura de ESSAP pendiente de pago
      When el usuario realiza el pago de la factura
      Then el sistema debe confirmar el pago correctamente
      And se genera el comprobante de pago procesado
      And el monto de pago coincide con el de la factura

Postman: https://aiquaa-sandbox-api.vercel.app/api/v1/facturas/{{ID_tabla}}/pagar

Body: {
  "metodoPago": "tarjeta"
}

Test: 
// Validar que la API responda200 OK
pm.test("Pago confirmado correctamente", function () {
    pm.response.to.have.status(200);
});

// Validar que factura cambia a estado pagada
pm.test("El estado de la factura se actualizó a pagada", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.data.factura.estado).to.eql("pagada");
});

// Validar que el pago fue procesado correctamente
pm.test("Se generó el comprobante de pago en estado 'procesado'", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.data.pago.estado).to.eql("procesado");
});

// Validar consistencia de datos entre Factura y Pago
pm.test("El monto pagado coincide con el monto de la factura", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.data.pago.monto).to.eql(jsonData.data.factura.monto);
    pm.expect(jsonData.data.pago.factura_id).to.eql(jsonData.data.factura.id);
});

## Scenario: Pago de una factura de ANDE inexistente
    Given que el usuario ingresa un identificador de factura que no existe en el sistema
    When el usuario realiza el pago de la factura inexistente
    Then el sistema rechaza la operación
    And muestra el mensaje indicando que la factura no fue encontrada o ya pagada

Postman: POST https://aiquaa-sandbox-api.vercel.app/api/v1/facturas/{{ID_tabla}}/pagar
Body: {
  "metodoPago": "tarjeta"
}

Test:// Validar que la API responda con 404 Not Found
pm.test("La API rechaza la solicitud con código 404 Not Found", function () {
    pm.response.to.have.status(404);
});

// Validar el código de error interno de la API
pm.test("Respuesta no encontrado(NOT_FOUND)", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.error.code).to.eql("NOT_FOUND");
});

// Validar que el mensaje confirme que la factura no fue encontrada
pm.test("El mensaje indica que la factura no existe ", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.error.message).to.eql("Factura no encontrada o ya pagada.");
});

## Scenario: Pago de una factura con numero invalido de ESSAP 
      Given el usuario ingresa un numero identificador de ESSAP inexistente
      When el usuario intenta realizar el pago
      Then el sistema debe mostrar un mensaje de error
      And muestra el mensaje indicando que la factura no fue encontrada o ya fue pagada

Postman: https://aiquaa-sandbox-api.vercel.app/api/v1/facturas/{{ID_tabla}}/pagar

Body: {
  "metodoPago": "tarjeta"
}
Test:
// Validar que la API responda con 404 Not Found
pm.test("La API rechaza la solicitud con código 404 Not Found", function () {
    pm.response.to.have.status(404);
});

// Validar el código de error interno de la API
pm.test("Respuesta no encontrado(NOT_FOUND)", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.error.code).to.eql("NOT_FOUND");
});

// Validar que el mensaje confirme que la factura no fue encontrada
pm.test("El mensaje indica que la factura no existe ", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.error.message).to.eql("Factura no encontrada o ya pagada.");
});


## Scenario: Factura de ANDE ya pagada anteriormente
    Given la factura de ANDE ya fue pagada con anterioridad
    When el usuario intenta pagar nuevamente la misma factura
    Then el sistema indica que la factura no fue encontrada o ya se encuentra pagada

Postman: POST https://aiquaa-sandbox-api.vercel.app/api/v1/facturas/{{ID_tabla}}/pagar
Body: {
  "metodoPago": "tarjeta"
}

Test:// Validar que la API responda con 404 Not Found
pm.test("La API rechaza la solicitud con código 404 Not Found", function () {
    pm.response.to.have.status(404);
});

// Validar el código de error interno de la API
pm.test("Respuesta no encontrado(NOT_FOUND)", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.error.code).to.eql("NOT_FOUND");
});

// Validar que el mensaje confirme que la factura no fue encontrada o ya está pagada
pm.test("El mensaje indica que la factura no existe o ya se encuentra pagada", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.error.message).to.eql("Factura no encontrada o ya pagada.");
});

## Scenario: Factura de ESSAP ya pagada anteriormente
      Given la factura de ESSAP ya fue pagada con anterioridad
      When el usuario intenta pagar nuevamente la misma factura
      Then el sistema indica que la factura no fue encontrada o ya se encuentra pagada

Postman: https://aiquaa-sandbox-api.vercel.app/api/v1/facturas/{{ID_tabla}}/pagar

Body: {
  "metodoPago": "tarjeta"
}
Test: // Validar que la API responda con 404 Not Found
pm.test("La API rechaza la solicitud con código 404 Not Found", function () {
    pm.response.to.have.status(404);
});

// Validar el código de error interno de la API
pm.test("Respuesta no encontrado(NOT_FOUND)", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.error.code).to.eql("NOT_FOUND");
});

// Validar que el mensaje confirme que la factura no fue encontrada o ya está pagada
pm.test("El mensaje indica que la factura no existe o ya se encuentra pagada", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.error.message).to.eql("Factura no encontrada o ya pagada.");
});

## Scenario: Pago de factura de telefonia con numero de linea invalido
    Given el usuario ingresa un numero de linea de telefonia invalido
    When el usuario intenta consultar la factura
    Then el sistema muestra un mensaje indicando que no se encontro la linea
    And no permite continuar con el pago

Postman: GET https://aiquaa-sandbox-api.vercel.app/api/v1/facturas/{{ID_tabla}}
(Pre-request: busca vía /api/v1/sql/select una factura de TELEFONIA cuyo numero_factura sea el número de línea inválido; al no existir ninguna, ID_tabla queda en 0)

Test: pm.test("La API responde con 404 Not Found al consultar la linea invalida", function () {
    pm.response.to.have.status(404);
});

pm.test("El codigo de error indica que no se encontro la factura/linea", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.error.code).to.eql("NOT_FOUND");
});

pm.test("El sistema no permite continuar con el pago (no hay factura sobre la cual pagar)", function () {
    pm.expect(pm.collectionVariables.get("ID_tabla")).to.eql(0);
});

## Scenario: Pago de factura de telefonia el mismo dia del vencimiento
    Given el usuario tiene una factura de telefonia pendiente con vencimiento en el dia de hoy
    When el usuario realiza el pago antes de la hora limite
    Then el sistema procesa el pago correctamente
    And el sistema muestra el comprobante de pago

Postman: POST https://aiquaa-sandbox-api.vercel.app/api/v1/facturas/{{ID_tabla}}/pagar
Body: {
  "metodoPago": "tarjeta"
}
(Pre-request: busca vía /api/v1/sql/select una factura de TELEFONIA pendiente/vencida cuyo fecha_vencimiento = CURRENT_DATE, siguiendo el mismo patrón que "Pago exitoso de factura de ANDE")

Test: pm.test("Pago confirmado correctamente", function () {
    pm.response.to.have.status(200);
});

pm.test("El estado de la factura se actualizo a pagada", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.data.factura.estado).to.eql("pagada");
});

pm.test("Se genero el comprobante de pago en estado 'procesado'", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.data.pago.estado).to.eql("procesado");
});

pm.test("El monto pagado coincide con el monto de la factura", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.data.pago.monto).to.eql(jsonData.data.factura.monto);
    pm.expect(jsonData.data.pago.factura_id).to.eql(jsonData.data.factura.id);
});

pm.test("La factura pagada es la que vencia hoy (segun la busqueda del pre-request)", function () {
    pm.expect(pm.collectionVariables.get("ID_tabla")).to.not.eql(0);
});

## Scenario: Pago exitoso de factura de ANDE - creación de factura
  Given el usuario completa los datos de una factura pendiente para el proveedor ANDE
  When el usuario envía el registro de la factura al sistema
  Then el sistema crea la factura correctamente
  And el estado inicial de la factura es "pendiente"

Postman: https://aiquaa-sandbox-api.vercel.app/api/v1/facturas


pm.test('Código de estado es 201 Created', function () {
    pm.response.to.have.status(201);
});

pm.test('La respuesta contiene el objeto data', function () {
    var datosRespuesta = pm.response.json();
    pm.expect(datosRespuesta.data).to.exist;
});

pm.test('El proveedor de la factura es ANDE', function () {
    var datosRespuesta = pm.response.json();
    pm.expect(datosRespuesta.data.proveedor).to.eql('ANDE');
});

pm.test('El estado inicial es pendiente', function () {
    var datosRespuesta = pm.response.json();
    pm.expect(datosRespuesta.data.estado).to.eql('pendiente');
});

pm.test('Se genera un id para la factura', function () {
    var datosRespuesta = pm.response.json();
    pm.expect(datosRespuesta.data.id).to.exist;
});

pm.test('El monto coincide con lo enviado', function () {
    var datosRespuesta = pm.response.json();
    pm.expect(datosRespuesta.data.monto).to.eql("1000.00");
});

pm.test('El tiempo de respuesta es menor a 3000ms', function () {
    pm.expect(pm.response.responseTime).to.be.below(3000);
});

## Scenario: Intento de pago de factura con monto invalido
    Given el usuario posee una factura pendiente de pago
    When el usuario intenta registrar un pago con un monto invalido o menor o igual a cero
    Then el sistema rechaza la transaccion con un código de error de validacion
    And el estado de la factura se mantiene como pendiente

Postman: POST {{baseUrl}}/api/v1/facturas/{{ID_tabla}}/pagar
Body: {
  "metodoPago": "tarjeta",
  "monto": -5000
}

Test: 
// Validar que la API rechace la petición por validación (400 Bad Request)
pm.test("La API responde con código 400 Bad Request", function () {
    pm.response.to.have.status(400);
});

// Validar estructura del error
pm.test("El código de error indica solicitud inválida", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.error.code).to.eql("INVALID_INPUT");
});