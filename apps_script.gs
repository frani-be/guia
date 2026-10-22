// Registra cada acceso a la guía en una planilla de Google Sheets.
//
// Cómo desplegarlo:
//   1. Crea una planilla nueva en sheets.google.com (ej. "Accesos guía freelancer")
//   2. En la planilla: Extensiones > Apps Script, borra el contenido y pega este archivo
//   3. Implementar > Nueva implementación > tipo "Aplicación web"
//      - Ejecutar como: yo
//      - Quién tiene acceso: "Cualquier persona"
//   4. Copia la URL /exec que te entrega y ponla en .env como LOG_URL
//
// Cada acceso anota una fila: fecha | usuario (sufijo de la clave) | user-agent.

function doGet(e) {
  var u = ((e && e.parameter && e.parameter.u) || '').toString().slice(0, 64);
  var ua = ((e && e.parameter && e.parameter.ua) || '').toString().slice(0, 250);
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheets()[0];
  sheet.appendRow([new Date(), u, ua]);
  return ContentService.createTextOutput('ok');
}
