extends Control
class_name GameHUD

@onready var saving_label: Label = $Saving
@onready var saving_timer: Timer = $SavingTimer


func _ready() -> void:
	saving_label.visible = false
	saving_timer.timeout.connect(_on_saving_timer_timeout)
	SaveManager.save_started.connect(_on_save_started)
	SaveManager.save_finished.connect(_on_save_finished)


func set_time_lebal(value: int) -> void:
	$Time.text = "Time: " + str(value)


func set_timer_visible(is_visible: bool) -> void:
	$Time.visible = is_visible
	$TimerPixelatedPng.visible = is_visible


func _on_save_started() -> void:
	saving_label.text = "Saving..."
	saving_label.visible = true
	saving_timer.stop()


func _on_save_finished(success: bool) -> void:
	if not success:
		saving_label.text = "Save failed"
	saving_timer.start()


func _on_saving_timer_timeout() -> void:
	saving_label.visible = false
