extends Control


@onready var line_edit = %LineEdit
@onready var start_button = %StartButton
@onready var browse_button = %BrowseButton
@onready var file_dialog = $FileDialog
@onready var texture_rect = %TextureRect
@onready var http_request = $HTTPRequest


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_viewport().files_dropped.connect(self.on_file_dropped)
	browse_button.pressed.connect(self.on_browse_button_pressed)
	file_dialog.file_selected.connect(func(path: String): line_edit.set_text(path))
	start_button.pressed.connect(self.on_start_button_pressed)
	http_request.request_completed.connect(self._http_request_completed)


func on_file_dropped(val: PackedStringArray) -> void:
	line_edit.text = val[0]
	

func on_browse_button_pressed() -> void:
	file_dialog.show()


func on_start_button_pressed() -> void:
	if FileAccess.file_exists(line_edit.text):
		var body: PackedByteArray = PackedByteArray()
		var file : PackedByteArray = FileAccess.get_file_as_bytes(line_edit.text)
		body.append_array('--godot\r\nContent-Disposition: form-data; name="file"; filename="image.png"\r\nContent-Type: image/png\r\nContent-Transfer-Encoding: binary\r\n\r\n'.to_utf8_buffer())
		body.append_array(file)
		body.append_array("\r\n--godot--\r\n".to_utf8_buffer())
		var headers = [
			'Content-Type: multipart/form-data; boundary="godot"',
			"Content-Length: " + str(body.size())
		]
		http_request.request_raw("http://demowebcuaminh.xyz/bsx/upload", headers, HTTPClient.METHOD_POST, body)
		start_button.disabled = true
	else:
		OS.alert("Đường dẫn thư mục không hợp lệ")


func _http_request_completed(result, response_code, headers, body) -> void:
	start_button.disabled = false
	if result != HTTPRequest.RESULT_SUCCESS:
		print(response_code)
		print(body)
		return push_error("Image couldn't be downloaded. Try a different image.")
	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	if error != OK:
		return push_error("Couldn't load the image.")
	var texture = ImageTexture.create_from_image(image)
	texture_rect.texture = texture
