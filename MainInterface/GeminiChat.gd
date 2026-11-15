extends PanelContainer

const ENDPOINT := "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent"

@export var model := "gemini-3.5-flash"
@export_multiline var extra_context: String = ""

@onready var _api_key: LineEdit = %ApiKey
@onready var _transcript: RichTextLabel = %Transcript
@onready var _status: Label = %Status
@onready var _message: LineEdit = %Message
@onready var _send: Button = %Send
@onready var _request: HTTPRequest = $Request

var _history: Array[Dictionary] = []
var _pending_message := ""


func _ready() -> void:
	_api_key.text = "AQ.Ab8RN6IoLHr6u2a9mfx2JWFy9G68_jFL0YL6qqvxt0I8CfUAvw"
	_send.pressed.connect(_send_message)
	_message.text_submitted.connect(func(_submitted: String) -> void: _send_message())
	_request.request_completed.connect(_on_request_completed)


func _send_message() -> void:
	var prompt := _message.text.strip_edges()
	if prompt.is_empty() or not _pending_message.is_empty():
		return

	var key := _api_key.text.strip_edges()
	if key.is_empty():
		_status.text = "Enter a Gemini API key to send a message."
		_api_key.grab_focus()
		return

	var contents := _history.duplicate()
	contents.append({"role": "user", "parts": [{"text": prompt}]})
	var headers := PackedStringArray(["Content-Type: application/json", "x-goog-api-key: " + key])
	var payload := {"contents": contents}
	var context := extra_context.strip_edges()
	if not context.is_empty():
		payload["systemInstruction"] = {"parts": [{"text": context}]}
	var body := JSON.stringify(payload)
	var error := _request.request(ENDPOINT % model.uri_encode(), headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		_status.text = "Could not start the request. Try again."
		return

	_pending_message = prompt
	_send.disabled = true
	_message.editable = false
	_status.text = "Waiting for a response…"


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var prompt := _pending_message
	_pending_message = ""
	_send.disabled = false
	_message.editable = true

	if result != HTTPRequest.RESULT_SUCCESS:
		_status.text = "The request failed or timed out. Try again."
		return
	if response_code != 200:
		_status.text = "Gemini returned HTTP %d." % response_code
		return

	var response: Variant = JSON.parse_string(body.get_string_from_utf8())
	var reply := _read_reply(response)
	if reply.is_empty():
		_status.text = "Gemini returned no text. Try rephrasing your message."
		return

	_history.append({"role": "user", "parts": [{"text": prompt}]})
	_history.append({"role": "model", "parts": [{"text": reply}]})
	_transcript.add_text("You\n%s\n\nGemini\n%s\n\n" % [prompt, reply])
	_message.clear()
	_status.text = ""


func _read_reply(response: Variant) -> String:
	if not response is Dictionary:
		return ""
	var candidates: Array = response.get("candidates", [])
	if candidates.is_empty():
		return ""
	var content: Dictionary = candidates[0].get("content", {})
	var text_parts := PackedStringArray()
	for part in content.get("parts", []):
		if part.has("text") and not part.get("thought", false):
			text_parts.append(part["text"])
	return "".join(text_parts).strip_edges()
