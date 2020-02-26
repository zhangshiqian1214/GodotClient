extends Node2D

onready var skynetWsClient = get_node("/root/SkynetWsClient")
onready var skynetTcpClient = get_node("/root/SkynetTcpClient")
onready var common = get_node("/root/Common")

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("Button").hide()
	if skynetWsClient != null:
		skynetWsClient.register_event("net.on_open", self, "on_net_open")
		skynetWsClient.register_event("net.on_close", self, "on_net_close")
		skynetWsClient.register_event("net.on_error", self, "on_net_error")
		#skynetWsClient.connect_server("ws://119.23.21.210:7101")
	if skynetTcpClient != null:
		skynetTcpClient.register_event("net.on_open", self, "on_net_open")
		skynetTcpClient.register_event("net.on_close", self, "on_net_close")
		skynetTcpClient.register_event("net.on_error", self, "on_net_error")
		skynetTcpClient.connect_server("119.23.21.210", 7001)
		

func _exit_tree():
	if skynetWsClient != null:
		skynetWsClient.unregister_event("net.on_open", self)
		skynetWsClient.unregister_event("net.on_close", self)
		skynetWsClient.unregister_event("net.on_error", self)
	if skynetTcpClient != null:
		skynetTcpClient.unregister_event("net.on_open", self)
		skynetTcpClient.unregister_event("net.on_close", self)
		skynetTcpClient.unregister_event("net.on_error", self)
		
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func on_net_open(msg):
	print("LoginScene net open msg=", msg)
	get_node("Button").show()

func on_net_close(msg):
	print("LoginScene net close msg=", msg)
	

func on_net_error(msg):
	print("LoginScene net error msg=", msg)
	

func _on_loading_finish_pressed():
	common.goto_scene("res://LoginScene/LoginScene.tscn")
