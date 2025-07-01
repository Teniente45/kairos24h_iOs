/*******************************
 * LOGS DE FICHAR.KT
 *******************************
 *  // print("[DEBUG] Fichar: onCreate iniciado")
 *
 *  // print("[ERROR] Fichar: No se cuenta con el permiso ACCESS_FINE_LOCATION")
 *
 *  // print("[ERROR] Fichar: Ubicación inválida, no se enviará el fichaje")
 *
 *  // print("[DEBUG] Fichar: URL que se va a enviar desde WebView: $urlFichaje")
 *
 *  // print("[ERROR] Fichar: Alerta: $alertTipo")
 *
 *  // print("[ERROR] Fichar: Error de seguridad al acceder a la ubicación: ${e.message}")
 *
 *  // print("[DEBUG] Seguridad: lComGPS=$lComGPS, lComIP=$lComIP, lBotonesFichajeMovil=$lBotonesFichajeMovil")
 *
 *  // print("[WARNING] Seguridad: El fichaje está deshabilitado por GPS: lComGPS=$lComGPS")
 *
 *  // print("[WARNING] Seguridad: El fichaje está deshabilitado por IP: lComIP=$lComIP")
 *
 *  // print("[WARNING] Seguridad: Los botones de fichaje están deshabilitados: lBotonesFichajeMovil=$lBotonesFichajeMovil")
 *
 *  // print("[ERROR] Fichar: GPS desactivado.")
 *
 *  // print("[ERROR] Fichar: No se pudo obtener la ubicación.")
 *
 *  // print("[ERROR] Fichar: Ubicación falsa detectada.")
 *
 *  // print("[ERROR] Fichar: Error obteniendo ubicación: ${e.message}")
 */

/*******************************
 * LOGS DE PANTALLAFUNCIONAL.KT
 *******************************
 * // print("[DEBUG] MiHorario: URL solicitada: $urlHorario")
 *
 * // print("[DEBUG] MiHorario: Respuesta completa del servidor:\n$responseBody")
 *
 * // print("[DEBUG] MiHorario: Valor N_HORINI: $horaIni")
 *
 * // print("[DEBUG] MiHorario: Valor N_HORFIN: $horaFin")
 *
 * // print("[ERROR] MiHorario: Error al parsear JSON: ${e.message}\nResponse body: $responseBody")
 *
 * // print("[ERROR] MiHorario: Error al obtener horario: ${e.message}")
 *
 * // print("[DEBUG] Fichaje: Permiso concedido. Procesando fichaje de: $tipo")
 *
 * // print("[ERROR] Fichaje: webView es null. No se puede fichar.")
 *
 * // print("[DEBUG] Fichaje: Permiso denegado para ACCESS_FINE_LOCATION")
 *
 * // print("[ERROR] Seguridad: Intento de fichaje con VPN activa")
 *
 * // print("[ERROR] Fichar: No hay conexión a Internet")
 *
 * // print("[ERROR] Fichar: No se cuenta con el permiso ACCESS_FINE_LOCATION")
 *
 * // print("[ERROR] Seguridad: GPS desactivado")
 *
 * // print("[ERROR] Seguridad: Ubicación simulada detectada")
 *
 * // print("[WARNING] Fichaje: Fichaje repetido ignorado")
 *
 * // print("[DEBUG] Fichaje: Fichaje Entrada: Permiso concedido. Procesando fichaje de ENTRADA")
 *
 * // print("[DEBUG] Fichaje: Fichaje Salida: Permiso concedido. Procesando fichaje de SALIDA")
 *
 * // print("[DEBUG] RecuadroFichajesDia: Fecha usada para la petición: ${fechaSeleccionada.value}")
 *
 * // print("[DEBUG] RecuadroFichajesDia: URL completa invocada: $urlFichajes")
 *
 * // print("[DEBUG] RecuadroFichajesDia: Respuesta desde consultarFichajeExterno (URL: ${response.request.url}): $responseBody")
 *
 * // print("[DEBUG] RecuadroFichajesDia: Fichaje $i → nMinEnt: $nMinEnt, nMinSal: $nMinSal, LCUMENT: $lcumEnt, LCUMSAL: $lcumSal")
 *
 * // print("[ERROR] RecuadroFichajesDia: Error al parsear JSON: ${e.message}")
 *
 * // print("[ERROR] RecuadroFichajesDia: Error al obtener fichajes: ${e.message}")
 *
 * // print("[DEBUG] AlertasDiarias: URL de alertas: $urlAlertas")
 *
 * // print("[DEBUG] JSONAlertas: D_AVISO: $dAviso")
 *
 * // print("[DEBUG] JSONAlertas: T_AVISO: $tAviso")
 *
 * // print("[DEBUG] JSONAlertas: T_URL: $tUrl")
 *
 * // print("[DEBUG] JSONAlertas: Array 'dataAvisos' vacío o nulo")
 *
 * // print("[ERROR] AlertasDiarias: Error obteniendo alertas: ${e.message}")
 *
 *
 *
/**
 * *******************************************
 * *********** logica_BB_DD.kt ***************
 * *******************************************
 *
 * // print("[DEBUG] SQLite: Insertando en tabla l_informados: L_INFORMADO=$lInformado, xFichaje=$xFichaje")
 *
 * // print("[DEBUG] modificacionBBDD: Columna cEmpCppExt añadida a l_informados")
 *
 * // print("[DEBUG] modificacionBBDD: Tabla l_informados no existía, creada desde onUpgrade")
 *
 * // print("[DEBUG] FichajeApp: Lógica de reintento automático iniciada correctamente.")
 *
 * // print("[DEBUG] ReintentoFichaje: Preparando reenvío de fichaje con ID=$id")
 *
 * // print("[DEBUG] ReintentoFichaje: Invocando URL: $url")
 *
 * // print("[DEBUG] ReintentoFichaje: Respuesta recibida: $body")
 *
 * // print("[DEBUG] ReintentoFichaje: L_INFORMADO = S → Actualizando ID=$id a informado")
 *
 * // print("[DEBUG] EXPORTACION: Archivo generado en: ${archivo.absolutePath}")
 *
 * // print("[ERROR] EXPORTACION: Error al exportar la tabla $tabla: ${e.message}")
 *
 *
 * *******************************************
 * *********** relojFichajes.kt ***************
 * *******************************************
 *
 * // print("[DEBUG] relojFichajes: Lógica de reintento automático iniciada correctamente.")
 *
 * // print("[DEBUG] FichajeApp: URL generada para fichaje: $url")
 *
 * // print("[DEBUG] FichajeApp: Invocando URL al servidor: $url")
 *
 * // print("[DEBUG] FichajeApp: Respuesta del servidor: $responseText")
 *
 * // print("[DEBUG] SQLite: Registro insertado: xFichaje=${jsonResponse.optString("xFichaje")}, cTipFic=${jsonResponse.optString("cTipFic")}")
 *
 * // print("[DEBUG] FichajeApp: No hay conexión. Fichaje guardado localmente.")
 *
 * // print("[ERROR] Audio: No se encontró el archivo de audio: $nombreArchivo")
 *
 * // print("[ERROR] DB_DUMP")
 *
 *
 * *******************************************
 * *********** paginaLogin.kt ***************
 * *******************************************
 *
 *// print("[DEBUG] Redireccion")
 *
 *
*/
