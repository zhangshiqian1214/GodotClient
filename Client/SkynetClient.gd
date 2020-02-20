extends Node


onready var _sproto = get_node("Sproto")

var _client = WebSocketClient.new()
var _fmt = WebSocketPeer.WRITE_MODE_BINARY
var _response_callbacks = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	var f = File.new()
	if (f.open("res://protocol.spb", File.READ)) == OK:
		var buffer = f.get_buffer(f.get_len())
		var tmp = Array(buffer)
		_sproto.loadsproto(tmp)
		f.close()
	_client.connect("connection_established", self, "_on_connection_established")
	_client.connect("connection_closed", self, "_on_connection_closed")
	_client.connect("connection_error", self, "_on_connection_error")
	_client.connect("data_received", self, "_on_data_received")
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_client.poll()


func _on_connection_established(protocol):
	_client.get_peer(1).set_write_mode(_fmt)
	set_process(true)
	if not _response_callbacks.has("net.on_open"):
		return
	for i in _response_callbacks["net.on_open"]:
		var callback = _response_callbacks["net.on_open"][i].callback
		if callback != null:
			callback.call_func(_client.get_peer(1).get_connected_host(), _client.get_peer(1).get_connected_port())
		
	
func _on_connection_closed():
	set_process(false)
	if not _response_callbacks.has("net.on_close"):
		return
	for i in _response_callbacks["net.on_close"]:
		var callback = _response_callbacks["net.on_close"][i].callback
		if callback != null:
			callback.call_func(_client.get_peer(1).get_connected_host(), _client.get_peer(1).get_connected_port())
	
	
func _on_connection_error():
	set_process(false)
	if not _response_callbacks.has("net.on_error"):
		return
	for i in _response_callbacks["net.on_error"]:
		var callback = _response_callbacks["net.on_error"][i].callback
		if callback != null:
			callback.call_func(_client.get_peer(1).get_connected_host(), _client.get_peer(1).get_connected_port())
		
	

func _on_data_received():
	var bytes = _client.get_peer(1).get_packet()
	var host = _client.get_peer(1).get_connected_host()
	var port = _client.get_peer(1).get_connected_port()
	#var msg = packet.get_string_from_utf8()
	
	var result = _sproto.dispatch(bytes)
	if result == null:
		return
	if result[0] != "RESPONSE":
		return
	var protoname = result[1]
	if protoname == null or protoname == "":
		return
	if not _response_callbacks.has(protoname):
		return
	var data = result[2]
	var session = result[3]
	var ud = result[4]
	for i in _response_callbacks[protoname]:
		var callback = _response_callbacks[protoname][i].callback
		if callback != null:
			callback.call_func(data, ud)
		
	

func connect_server(host):
	var err = _client.connect_to_url(host)
	if err != OK:
		set_process(false)
	else:
		set_process(true)

# 
func disconnect_server():
	_client.disconnect_from_host()
	set_process(false)
	

# request("auth.login", req, ud, callback)
func request(method, req, ud, callback):
	var bytes = _sproto.request(method, req, ud)
	var err = _client.get_peer(1).put_packet(bytes)
	return err
	
# register_event("auth.login", obj, "on_auth_login")
func register_event(event, obj, funcname):
	var callback = funcref(obj, funcname)
	if not _response_callbacks.has(event):
		_response_callbacks[event] = []
	for i in _response_callbacks[event]:
		if _response_callbacks[event][i].obj == obj:
			return
	_response_callbacks[event].push({ "obj":obj, "callback":callback })
	return
	
# unregister_event("auth.login", obj)
func unregister_event(event, obj):
	if not _response_callbacks.has(event):
		return
	for i in _response_callbacks[event]:
		if _response_callbacks[event][i].obj == obj:
			_response_callbacks[event].remove(i)
			return
	return
	

