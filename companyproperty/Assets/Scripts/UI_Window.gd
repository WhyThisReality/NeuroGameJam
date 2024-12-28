extends Node
class_name UI_Window

@onready var game = get_tree().current_scene

var work_task := false
var focus := false
var has_lifespan = false
var lifespan = 0 #miliseconds; 0 if no lifespan

var dragging = false
var drag_pos = Vector2()
var offset = Vector2()

var mouse_over = false;
var last_higlihted = false; # for if input will register to the current window

@onready var node: Node = $".."
@onready var panel: Panel = $"."
@onready var progress_bar: ProgressBar = $VBoxContainer/HBoxContainer/ProgressBar
@onready var content_space: Panel = $VBoxContainer/ContentSpace

@export var content : PackedScene
var content_node = null

var top = false; #if this is the topmost

func _ready() -> void:
	var content_inst : Content = content.instantiate()
	content_inst.content_self = self
	content_space.add_child(content_inst)
	content_node = content_inst
	if lifespan:
		content_inst.task_finish.connect(Callable(self, "task_finish")) # We connect the signal "task finish" to the function below, if the signal is called from the "content" node it will trigger the function below
		content_inst.task_fail.connect(Callable(self, "task_fail"))

const TASKCOMPLETE = preload("res://Assets/Sounds/SFX/taskcomplete.mp3")
func task_finish():
	content_node.triggered = true
	has_lifespan = false
	game.rtl.text = "[center][b]- TASK COMPLETE -"
	AudioManager.play(TASKCOMPLETE)
	game.AP.play("TaskComplete")
	print("TASK FINISHED")

const BUZZER = preload("res://Assets/Sounds/SFX/buzzer.mp3")
func task_fail():
	content_node.triggered = true
	has_lifespan = false
	game.rtl.text = "[center][b][color=red]- TASK FAIL -"
	AudioManager.play(BUZZER)
	game.AP.play("TaskFail")
	print("TASK FAILED")

func setup_window(time):
	lifespan = time
	
	if has_lifespan:
		call_deferred("_setup_progress_bar", time) # this is here because otherwise it odesnt calc button size and return s 0

func _setup_progress_bar(time):
	# Configure progress bar lifespan
	if time > 0:
		progress_bar.max_value = time

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and !dragging and mouse_within(get_viewport().get_mouse_position()) and focus:
			offset = panel.get_screen_position() - get_viewport().get_mouse_position();
			dragging = true;#Toggle Dragging when clicked
			get_parent().move_child(self, get_parent().get_child_count()-1)
		if event.button_index == MOUSE_BUTTON_LEFT and !event.pressed and dragging:
			dragging = false;

func _process(delta: float):#I hope this is equivalent to update?
	if has_lifespan:
		lifespan += -1 * delta * 200
		if lifespan <= 0:
			get_tree().current_scene.failedTask(self)
			task_fail()
		else:
			progress_bar.value = lifespan
		
	if dragging == true:
		drag_pos = get_viewport().get_mouse_position() + offset;#Drag position is set to mouse position
		panel.global_position = drag_pos#Thus, set transform position to drag position
		
func mouse_within(point):
	var x = panel.global_position.x
	var y = panel.global_position.y
	var x2 = x + self.size.x
	var y2 = y + self.size.y
	#TODO: make a check if it is the topmost
	return point.x >= x and point.x <= x2 and point.y >= y and point.y <= y2


# ------------------------------------------
# "Window Focus"
# ------------------------------------------

func _on_progress_bar_mouse_entered() -> void:
	focus = true

func _on_progress_bar_mouse_exited() -> void:
	focus = false


# ------------------------------------------
# X Button
# ------------------------------------------

func _x_button_pressed() -> void:
	#autofails if you try to X out of a task window (failed task closes it)
	if has_lifespan:
		get_tree().current_scene.failedTask(self)
	else:
		get_tree().current_scene.deleteWindow(self)
