Colección Postman: 'postman/Grupo 2- Tarea2.postman_collection.json', 'postman/Grupo02-Transferencias-Cuentas.postman_collection.json'.

| Escenario BDD | Tipo | Endpoint | Método | Validaciones 
|---|---|---|---|---|---|
| Realizar una transferencia entre cuentas exitosa | Happy Path | `{{baseUrl}}/api/v1/transferencias` | POST | 
| Rechazar una transferencia hacia una cuenta inactiva | Negativo | `{{baseUrl}}/api/v1/transferencias` | POST | 
| Transferencia rechazada por saldo insuficiente | Negativo | `{{baseUrl}}/api/v1/transferencias` | POST | 
| Transferencia por el monto exacto del saldo disponible | Edge Case | `{{baseUrl}}/api/v1/transferencias` | POST | 

### Variables de colección utilizadas

- `baseUrl`: URL base del sandbox AIQUAA (`https://aiquaa-sandbox-api.vercel.app`).
- `apiKey`: API key enviada mediante el header `x-api-key`; su valor se mantiene vacío en el archivo exportado para no publicar credenciales.
