extends Node
onready var sproto = get_node("/root/Sproto")
onready var connection = WebSocketClient.new()
onready var fmt = WebSocketPeer.WRITE_MODE_BINARY
onready var response_callbacks = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(false)
	connection.connect("connection_established", self, "_on_connection_established")
	connection.connect("connection_closed", self, "_on_connection_closed")
	connection.connect("connection_error", self, "_on_connection_error")
	connection.connect("data_received", self, "_on_data_received")
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	connection.poll()


func _on_connection_established(protocol):
	connection.get_peer(1).set_write_mode(fmt)
	set_process(true)
	var msg = "connection open"
	if not response_callbacks.has("net.on_open"):
		return
	for cbInfo in response_callbacks["net.on_open"]:
		var callback = cbInfo.callback
		if callback != null:
			callback.call_func(msg)
		
	
func _on_connection_closed(msg):
	print("_on_connection_closed msg=", msg)
	set_process(false)
	if not response_callbacks.has("net.on_close"):
		return
	for cbInfo in response_callbacks["net.on_close"]:
		var callback = cbInfo.callback
		if callback != null:
			callback.call_func("hello world")
	
	
func _on_connection_error(msg):
	print("_on_connection_error msg=", msg)
	set_process(false)
	if not response_callbacks.has("net.on_error"):
		return
	for cbInfo in response_callbacks["net.on_error"]:
		var callback = cbInfo.callback
		if callback != null:
			callback.call_func(msg)
		
	

func _on_data_received():
	var bytes = connection.get_peer(1).get_packet()
	var host = connection.get_peer(1).get_connected_host()
	var port = connection.get_peer(1).get_connected_port()
	#var msg = packet.get_string_from_utf8()
	
	var result = sproto.dispatch(bytes)
	if result == null:
		return
	if result[0] != "RESPONSE":
		return
	var protoname = result[1]
	if protoname == null or protoname == "":
		return
	if not response_callbacks.has(protoname):
		return
	var data = result[2]
	var session = result[3]
	var ud = result[4]
	for cbInfo in response_callbacks[protoname]:
		var callback = cbInfo.callback
		if callback != null:
			callback.call_func(data, ud)
		
	

func connect_server(host):
	var err = connection.connect_to_url(host)
	if err != OK:
		set_process(false)
	else:
		set_process(true)
	return err

# 
func disconnect_server():
	connection.disconnect_from_host()
	set_process(false)
	

# request("auth.login", req, ud)
func request(method, req, ud=null):
	var bytes = sproto.request(method, req, ud)
	var err = connection.get_peer(1).put_packet(bytes)
	return err
	
# register_event("auth.login", obj, "on_auth_login")
func register_event(event, obj, funcname):
	var callback = funcref(obj, funcname)
	if not response_callbacks.has(event):
		response_callbacks[event] = []
	for cbInfo in response_callbacks[event]:
		if cbInfo.obj == obj:
			return
	response_callbacks[event].push_back({ "obj":obj, "callback":callback })
	return
	
# unregister_event("auth.login", obj)
func unregister_event(event, obj):
	if not response_callbacks.has(event):
		return
	for i in range(response_callbacks[event].size()):
		if response_callbacks[event][i].obj == obj:
			response_callbacks[event].remove(i)
			return
	return
	

