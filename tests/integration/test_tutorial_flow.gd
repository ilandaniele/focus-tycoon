extends TestCase

const MAIN_SCENE := preload("res://scenes/main.tscn")

var _main: Node


func before_each() -> void:
	GameState.reset_for_tests("user://test_tutorial_flow/", FakeClock.new())
	GameState.progress["tutorial_step"] = 2
	_main = MAIN_SCENE.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(_main)


func after_each() -> void:
	_main.free()


func test_highlight_resumes_after_closing_build_screen() -> void:
	var hud: Hud = _main.get_node("UI/HUD")
	var tutorial: TutorialOverlay = _main.get_node("UI/TutorialOverlay")
	hud.open_requested.emit("build")
	_main.close_screen()
	assert_true(tutorial.is_processing(), "highlight must keep pulsing once the HUD is back")
