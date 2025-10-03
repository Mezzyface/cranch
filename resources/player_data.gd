extends Resource
class_name PlayerData

var gold: int = 0
var creatures: Array[CreatureData] = []
var inventory: Dictionary = {}  # {item_id: quantity}
