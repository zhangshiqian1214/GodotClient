extends Node2D

onready var _skynetClient = get_node("/root/Main/SkynetClient")

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	print("_skynetClient=", _skynetClient)
	if _skynetClient != null:
		_skynetClient.register_event("net.on_open", self, "on_net_open")
		_skynetClient.register_event("net.on_close", self, "on_net_close")
		_skynetClient.register_event("net.on_data", self, "on_net_data")
		_skynetClient.register_event("net.on_error", self, "on_net_error")
		_skynetClient.register_event("account.login", self, "on_account_login")
		_skynetClient.register_event("account.register", self, "on_account_register")
		_skynetClient.connect_server("ws://119.23.21.210:7101")
		
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func on_net_open(ip, port):
	pass
	
func on_net_close(ip, port):
	pass
	
func on_net_data(ip, port):
	pass
	
func on_net_error(ip, port):
	pass
	
func on_account_login(data, ud):
	pass

func on_account_register(data, ud):
	pass
