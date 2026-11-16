extends Node

# ========================================
# NASA HEALTH MONITOR - GODOT 4
# Recepcion de BPM y SpO2 por TCP
# ========================================

signal vitales_recibidos(bpm: int, spo2: int)
signal conexion_cambiada(conectado: bool)
signal estado_sensor(mensaje: String)

const ARDUINO_IP := "192.168.28.242"
const PUERTO := 8080

const RECONEXION := 3.0
const TIMEOUT_DATOS := 5.0

var tcp := StreamPeerTCP.new()

var conectado := false
var datos_validos := false

var bpm := -1
var spo2 := -1

var RESULTADOS = []

var buffer := ""
var tiempo_reconexion := 0.0
var ultimo_dato := -1.0


func _ready() -> void:
	print("Iniciando NASA Health Monitor...")
	conectar_arduino()


# ========================================
# CONEXION
# ========================================

func conectar_arduino() -> void:

	tcp.disconnect_from_host()
	tcp = StreamPeerTCP.new()

	var error := tcp.connect_to_host(
		ARDUINO_IP,
		PUERTO
	)

	if error == OK:
		print("Conectando al Arduino...")
	else:
		print("Error al conectar: ", error)


# ========================================
# ACTUALIZACION
# ========================================

func _process(delta: float) -> void:

	tcp.poll()

	var estado := tcp.get_status()

	if estado == StreamPeerTCP.STATUS_CONNECTED:

		tiempo_reconexion = 0.0

		if not conectado:
			conectado = true
			conexion_cambiada.emit(true)
			print("Arduino conectado por WiFi")

		recibir_datos()

	elif estado == StreamPeerTCP.STATUS_CONNECTING:
		pass

	else:

		if conectado:
			conectado = false
			conexion_cambiada.emit(false)
			print("Arduino desconectado")

		invalidar_datos()

		tiempo_reconexion += delta

		if tiempo_reconexion >= RECONEXION:
			tiempo_reconexion = 0.0
			conectar_arduino()

	# Descartar mediciones antiguas
	if ultimo_dato >= 0.0:

		var ahora := Time.get_ticks_msec() / 1000.0

		if ahora - ultimo_dato > TIMEOUT_DATOS:
			invalidar_datos()
			estado_sensor.emit("Sin datos recientes")


# ========================================
# RECIBIR DATOS
# ========================================

func recibir_datos() -> void:

	var disponibles := tcp.get_available_bytes()

	if disponibles <= 0:
		return

	var resultado := tcp.get_data(disponibles)

	if resultado[0] != OK:
		print("Error de lectura TCP")
		return

	var bytes: PackedByteArray = resultado[1]

	buffer += bytes.get_string_from_utf8()

	if buffer.length() > 4096:
		buffer = ""
		return

	while "\n" in buffer:

		var posicion := buffer.find("\n")

		var mensaje := buffer.substr(
			0,
			posicion
		).strip_edges()

		buffer = buffer.substr(posicion + 1)

		if not mensaje.is_empty():
			procesar_mensaje(mensaje)


# ========================================
# INTERPRETAR SIGNOS VITALES
# ========================================


func procesar_mensaje(mensaje: String) -> void:
	print("Recibido: ", mensaje)

	# Formato esperado: DATOS:78,98,1
	if not mensaje.begins_with("DATOS:"):
		return

	var partes := mensaje.trim_prefix("DATOS:").split(",")

	if partes.size() != 3:
		return

	# Comprobar que los valores sean enteros
	for parte in partes:
		if not parte.is_valid_int():
			return

	var nuevo_bpm := int(partes[0])
	var nuevo_spo2 := int(partes[1])
	var valido := int(partes[2])

	# Validar los valores recibidos
	if nuevo_bpm < -1 or nuevo_bpm > 255:
		return

	if nuevo_spo2 < -1 or nuevo_spo2 > 100:
		return

	if valido != 0 and valido != 1:
		return

	# Guardar los tres valores en RESULTADOS
	RESULTADOS = [
		nuevo_bpm,
		nuevo_spo2,
		valido
	]

	# Actualizar tiempo de recepcion
	ultimo_dato = Time.get_ticks_msec() / 1000.0

	# Comprobar si los datos son validos
	datos_validos = (
		valido == 1
		and nuevo_bpm > 0
		and nuevo_spo2 >= 0
	)

	if datos_validos:
		bpm = nuevo_bpm
		spo2 = nuevo_spo2

		vitales_recibidos.emit(bpm, spo2)
		estado_sensor.emit("Midiendo")
	else:
		bpm = -1
		spo2 = -1

		vitales_recibidos.emit(-1, -1)
		estado_sensor.emit("Medicion no disponible")

	print("RESULTADOS: ", RESULTADOS)


# ========================================
# DATOS NO DISPONIBLES
# ========================================

func invalidar_datos() -> void:
	RESULTADOS = [-1, -1, 0]
	var habia_datos := (
		datos_validos
		or bpm != -1
		or spo2 != -1
	)

	datos_validos = false

	bpm = -1
	spo2 = -1

	ultimo_dato = -1.0
	buffer = ""

	if habia_datos:
		vitales_recibidos.emit(-1, -1)

	if not conectado:
		estado_sensor.emit("Arduino desconectado")


# ========================================
# FUNCIONES PUBLICAS
# ========================================

func get_bpm() -> int:
	return bpm


func get_spo2() -> int:
	return spo2


func has_valid_data() -> bool:
	return conectado and datos_validos


func _exit_tree() -> void:
	tcp.disconnect_from_host()
