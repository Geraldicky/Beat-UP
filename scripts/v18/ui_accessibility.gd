extends Node
class_name BeatUpUIAccessibility

# Lightweight global pass: keep mouse UX unchanged while making every ordinary
# button keyboard-focusable and self-describing. Godot's spatial focus search
# handles directional navigation from the actual layout, so this also adapts to
# resized screens without hard-coded neighbour paths.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_scan_tree")

func _scan_tree() -> void:
	_apply_recursive(get_tree().root)

func _apply_recursive(node: Node) -> void:
	_apply_control(node)
	for child: Node in node.get_children():
		_apply_recursive(child)

func _on_node_added(node: Node) -> void:
	call_deferred("_apply_control_id", node.get_instance_id())

func _apply_control_id(instance_id: int) -> void:
	var node = instance_from_id(instance_id)
	if is_instance_valid(node) and node is Node and not node.is_queued_for_deletion():
		_apply_control(node)

func _apply_control(node: Node) -> void:
	if not (node is Control):
		return
	var control: Control = node as Control
	if control is Button:
		var button: Button = control as Button
		button.focus_mode = Control.FOCUS_ALL
		if button.tooltip_text.is_empty() and not button.text.strip_edges().is_empty():
			button.tooltip_text = button.text.strip_edges().replace("\n", " ")
	elif control is LineEdit or control is Slider or control is SpinBox or control is OptionButton:
		control.focus_mode = Control.FOCUS_ALL
