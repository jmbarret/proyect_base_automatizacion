# Grupo 02 — Transferencias entre Cuentas
# Módulo: Transferencias internas (mismo banco)

Feature: Transferencias entre Cuentas
  Como usuario del banco
  Quiero transferir dinero entre mis cuentas
  Para mover dinero de forma segura dentro del mismo banco

  Scenario: Transferencia entre cuentas de distintas monedas
    Given el cliente tiene una cuenta origen en "<Moneda_Origen>" con un saldo de <Saldo_Inicial_Origen>
    And tiene una cuenta destino en "<Moneda_Destino>" con un saldo de <Saldo_Inicial_Destino>
    And la tasa de cambio actual de "<Moneda_Origen>" a "<Moneda_Destino>" es de <Tasa_Cambio>
    When el cliente confirma una transferencia de <Monto_Transferir> desde la cuenta origen a la cuenta destino
    Then el saldo de la cuenta origen debería disminuir a <Saldo_Final_Origen>
    And el saldo de la cuenta destino debería aumentar a <Saldo_Final_Destino>
    And el sistema debe generar un comprobante mostrando la tasa aplicada de <Tasa_Cambio>

  @happy_path
  Scenario: Realizar una transferencia interna exitosa
    Given la cuenta destino pertenece al mismo banco
    And la cuenta destino se encuentra activa
    When el cliente realiza una transferencia de 5000000 Gs desde la cuenta origen hacia la cuenta destino
    Then la transferencia se realiza exitosamente
    And el saldo de la cuenta origen se reduce en 5000000 Gs
    And el saldo de la cuenta destino aumenta en 5000000 Gs
    And se genera un comprobante de la transferencia

  Scenario: Transferencia rechazada por saldo insuficiente
    Given el usuario posee una cuenta origen con saldo insuficiente
    And posee una cuenta destino habilitada
    When intenta realizar una transferencia por un monto mayor al saldo disponible
    Then la transferencia debe ser rechazada
    And debe visualizar un mensaje indicando saldo insuficiente

  @edge_case
  Scenario: Transferencia por el monto exacto del saldo disponible
    Given el usuario posee una cuenta origen con un saldo de 500000 Gs
    And posee una cuenta destino habilitada del mismo banco
    When el cliente realiza una transferencia de 500000 Gs desde la cuenta origen hacia la cuenta destino
    Then la transferencia debe ser aprobada
    And el saldo de la cuenta origen debe quedar en 0 Gs
    And el saldo de la cuenta destino debe aumentar en 500000 Gs
    And se debe generar un comprobante de transferencia

  Scenario: Rechazar una transferencia hacia una cuenta inactiva
    Given la cuenta destino pertenece al mismo banco
    And la cuenta destino se encuentra inactiva
    And la cuenta origen dispone de un saldo de 10000000 Gs
    When el cliente realiza una transferencia de 5000000 Gs desde la cuenta origen hacia la cuenta destino
    Then la transferencia debe ser rechazada
    And se debe informar que la cuenta destino se encuentra inactiva
    And el saldo de la cuenta origen no debe ser modificado
    And el saldo de la cuenta destino no debe ser modificado
    And no se debe generar un comprobante de transferencia