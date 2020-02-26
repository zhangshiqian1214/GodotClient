extends Node2D
onready var skynetWsClient = get_node("/root/SkynetWsClient")
onready var skynetTcpClient = get_node("/root/SkynetTcpClient")
onready var common = get_node("/root/Common")



# Called when the node enters the scene tree for the first time.
func _ready():
	if skynetWsClient != null:
		skynetWsClient.register_event("net.on_open", self, "on_net_open")
		skynetWsClient.register_event("net.on_close", self, "on_net_close")
		skynetWsClient.register_event("net.on_error", self, "on_net_error")
		skynetWsClient.register_event("account.login", self, "on_account_login")
		skynetWsClient.register_event("account.register", self, "on_account_register")
	if skynetTcpClient != null:
		skynetTcpClient.register_event("net.on_open", self, "on_net_open")
		skynetTcpClient.register_event("net.on_close", self, "on_net_close")
		skynetTcpClient.register_event("net.on_error", self, "on_net_error")
		skynetTcpClient.register_event("account.login", self, "on_account_login")
		skynetTcpClient.register_event("account.register", self, "on_account_register")
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func on_net_open(msg):
	print("LoginScene net open")

func on_net_close(msg):
	print("LoginScene net close")
	

func on_net_error(msg):
	print("LoginScene net error")
	

func on_account_login(data, ud):
	print("LoginScene on_account_login data=", data, " ud=", ud)
	

func on_account_register(data, ud):
	print("LoginScene on_account_register data=", data, " ud=", ud)
	


func _on_LoginBtn_pressed():
	var req = {
		"account" : $LoginAndRegister/Account/LineEdit.text,
		"password" : $LoginAndRegister/Password/LineEdit.text,
		"platform" : "default"
	}
	skynetTcpClient.request("account.login", req)


func _on_RegisterBtn_pressed():
	var req = {
		"platform" : "default",
		"account" : $LoginAndRegister/Account/LineEdit.text,
		"password" : $LoginAndRegister/Password/LineEdit.text,
		"email" : $LoginAndRegister/Account/LineEdit.text+"@"+$LoginAndRegister/Password/LineEdit.text,
		"imei" : "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
	}
	skynetTcpClient.request("account.register", req)
