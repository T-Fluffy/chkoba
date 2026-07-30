extends Node

signal peer_connected(id: int)
signal peer_disconnected(id: int)
signal client_connected
signal connection_failed

var is_host: bool = false
var _peer: ENetMultiplayerPeer = null

func host_game(port: int = 34123):
	if _peer:
		disconnect_peer()
	_peer = ENetMultiplayerPeer.new()
	_peer.create_server(port, 2)
	multiplayer.multiplayer_peer = _peer
	is_host = true
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func join_game(ip: String, port: int = 34123):
	if _peer:
		disconnect_peer()
	_peer = ENetMultiplayerPeer.new()
	_peer.create_client(ip, port)
	multiplayer.multiplayer_peer = _peer
	is_host = false
	multiplayer.connected_to_server.connect(_on_client_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)

func disconnect_peer():
	multiplayer.multiplayer_peer = null
	if _peer:
		_peer.close()
		_peer = null
	is_host = false

func _on_peer_connected(id: int):
	peer_connected.emit(id)

func _on_peer_disconnected(id: int):
	peer_disconnected.emit(id)

func _on_client_connected():
	client_connected.emit()

func _on_connection_failed():
	connection_failed.emit()
