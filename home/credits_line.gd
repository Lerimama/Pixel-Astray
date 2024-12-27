extends Control

export var web_link: String = "http://godotengine.org"
export var web_link_text: String = "Link"
export var name_author_text: String = "Resource name / Author"

onready var name_author_label: Label = $NameAuthor
onready var web_link_btn: Button = $WebLinkBtn


func _ready() -> void:

	name_author_label.text = name_author_text
	web_link_btn.text = web_link_text


func _on_WebLinkBtn_pressed() -> void:
	OS.shell_open(web_link)
