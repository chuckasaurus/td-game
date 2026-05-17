extends Node

signal class_buffs_changed

var _class_buffs: Array[TowerBuff] = []


func add_class_buff(buff: TowerBuff) -> void:
	if buff == null or _class_buffs.has(buff):
		return
	_class_buffs.append(buff)
	class_buffs_changed.emit()


func remove_class_buff(buff: TowerBuff) -> void:
	if _class_buffs.erase(buff):
		class_buffs_changed.emit()


func has_class_buff(buff: TowerBuff) -> bool:
	return _class_buffs.has(buff)


func get_buffs_for(tower_data: TowerData) -> Array[TowerBuff]:
	var matching: Array[TowerBuff] = []
	if tower_data == null:
		return matching
	for b in _class_buffs:
		if b.matches(tower_data):
			matching.append(b)
	return matching


func all_class_buffs() -> Array[TowerBuff]:
	return _class_buffs.duplicate()


func clear() -> void:
	if _class_buffs.is_empty():
		return
	_class_buffs.clear()
	class_buffs_changed.emit()
