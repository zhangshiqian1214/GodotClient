extends Node
onready var sproto = get_node("/root/Sproto")
onready var connection = StreamPeerTCP.new()
onready var response_callbacks = {}
onready var buffer = PoolByteArray()
onready var connectStatus = StreamPeerTCP.STATUS_NONE


# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(false)
	buffer.resize(0)

#recv some bytes
func _try_recv_data():
	var result = connection.get_partial_data(1024)
	if result.empty() or result[0] != OK:
		return false
	var data = result[1]
	if data.size() > 0:
		for i in range(data.size()):
			buffer.push_back(data[i])
	return true

#delete some element in the head
func _pop_buffer(size):
	for i in range(size, buffer.size()):
		buffer[i-size] = buffer[i]
	buffer.resize(buffer.size()-size)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if connection.get_status() == StreamPeerTCP.STATUS_ERROR:
		_on_connection_error()
		return
	if connection.get_status() == StreamPeerTCP.STATUS_NONE and connectStatus == StreamPeerTCP.STATUS_CONNECTED:
		_on_connection_closed()
		return
	if connection.get_status() == StreamPeerTCP.STATUS_CONNECTED and connectStatus == StreamPeerTCP.STATUS_CONNECTING:
		_on_connection_established()
	while true:
		if !_try_recv_data():
			break
		if buffer.size() < 2:
			break
		var size = buffer[0] * 256 + buffer[1]
		if buffer.size() < size + 2:
			return
		var bytes = PoolByteArray()
		for i in range(size):
			bytes.push_back(buffer[2+i])
		_pop_buffer(size+2)
		_on_data_received(bytes)
	
func _on_connection_established():
	set_process(true)
	connectStatus = StreamPeerTCP.STATUS_CONNECTED
	var msg = "connection open from tcp"
	if not response_callbacks.has("net.on_open"):
		return
	for cbInfo in response_callbacks["net.on_open"]:
		var callback = cbInfo.callback
		if callback != null:
			callback.call_func(msg)
	


func _on_connection_closed():
	set_process(false)
	connectStatus = StreamPeerTCP.STATUS_NONE
	var msg = "connection close from tcp"
	if not response_callbacks.has("net.on_close"):
		return
	for cbInfo in response_callbacks["net.on_close"]:
		var callback = cbInfo.callback
		if callback != null:
			callback.call_func(msg)
	
func _on_connection_error():
	set_process(false)
	connectStatus = StreamPeerTCP.STATUS_NONE
	var msg = "connection error from tcp"
	if not response_callbacks.has("net.on_error"):
		return
	for cbInfo in response_callbacks["net.on_error"]:
		var callback = cbInfo.callback
		if callback != null:
			callback.call_func(msg)
		
	

func _on_data_received(bytes):
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
	return

#connect_server("127.0.0.1", 8080)
func connect_server(host, port):
	if connection.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		disconnect_server()
	var err = connection.connect_to_host(host, port)
	if err != OK:
		set_process(false)
	else:
		set_process(true)
	if connection.get_status() == StreamPeerTCP.STATUS_CONNECTING:
		connectStatus = StreamPeerTCP.STATUS_CONNECTING
	return err
	


func disconnect_server():
	connection.disconnect_from_host()

	
# request("auth.login", req, ud)
func request(method, req, ud=null):
	var bytes = sproto.request(method, req, ud)
	var pbytes = PoolByteArray()
	pbytes.resize(0)
	pbytes.push_back(bytes.size() >> 8 & 0xFF)
	pbytes.push_back(bytes.size() & 0xFF)
	pbytes.append_array(bytes)
	var err = connection.put_data(pbytes)
	if err != OK:
		_on_connection_error()
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
	



