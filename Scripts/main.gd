extends Control


@onready var line_edit = %LineEdit
@onready var start_button = %StartButton
@onready var browse_button = %BrowseButton
@onready var file_dialog = $FileDialog
@onready var texture_rect = %TextureRect
@onready var http_request = $HTTPRequest
var file: PackedByteArray
enum ImageFormat {PNG, JPG}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_viewport().files_dropped.connect(self.on_file_dropped)
	browse_button.pressed.connect(self.on_browse_button_pressed)
	file_dialog.file_selected.connect(self.on_file_dialog_selected)
	line_edit.text_changed.connect(self.on_line_edit_text_changed)
	start_button.pressed.connect(self.on_start_button_pressed)
	http_request.request_completed.connect(self._http_request_completed)


func on_file_dropped(val: PackedStringArray) -> void:
	line_edit.text = val[0]
	file = FileAccess.get_file_as_bytes(val[0])
	if val[0].get_extension() == "jpg":
		show_image(file, ImageFormat.JPG)
	elif val[0].get_extension() == "png":
		show_image(file, ImageFormat.PNG)

func on_browse_button_pressed() -> void:
	file_dialog.show()
	

func on_file_dialog_selected(path: String) -> void:
	line_edit.text = path
	file = FileAccess.get_file_as_bytes(path)
	if path.get_extension() == "jpg":
		show_image(file, ImageFormat.JPG)
	elif path.get_extension() == "png":
		show_image(file, ImageFormat.PNG)


func on_line_edit_text_changed(text: String) -> void:
	if text.is_valid_filename():
		file = FileAccess.get_file_as_bytes(text)
		if text.get_extension() == "jpg":
			show_image(file, ImageFormat.JPG)
		elif text.get_extension() == "png":
			show_image(file, ImageFormat.PNG)

func show_image(buffer: PackedByteArray, format: ImageFormat) -> void:
	var image : Image = Image.new()
	var error : Error
	if format == ImageFormat.PNG:
		error = image.load_png_from_buffer(buffer)
	elif format == ImageFormat.JPG:
		error = image.load_jpg_from_buffer(buffer)
	else:
		return push_error("Image Format invalid")
	if error != OK:
		return push_error("Couldn't load the image.")
	texture_rect.texture = ImageTexture.create_from_image(image)


func on_start_button_pressed() -> void:
	if FileAccess.file_exists(line_edit.text):
		var body : PackedByteArray = PackedByteArray()
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
		return push_error("Image couldn't be downloaded. Try a different image.")
	show_image(body, ImageFormat.PNG)
