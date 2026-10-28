extends Node
## Un battement partagé pour les dessins animés, indépendant de l'horloge du jeu.
signal tick(delta: float)

const INTERVAL := 1.0 / 20.0
var _elapsed := 0.0
var _since_tick := 0.0
var _menus: Array[WeakRef] = []

func watch_animation(item: CanvasItem, callback: Callable) -> void:
	item.set_process(false)
	item.visibility_changed.connect(_sync_animation.bind(item, callback))
	item.tree_exiting.connect(_stop_animation.bind(callback))
	_sync_animation(item, callback)

func _sync_animation(item: CanvasItem, callback: Callable) -> void:
	if item.is_visible_in_tree():
		if not tick.is_connected(callback):
			tick.connect(callback)
	else:
		_stop_animation(callback)

func _stop_animation(callback: Callable) -> void:
	if tick.is_connected(callback):
		tick.disconnect(callback)

func watch_menu(menu: CanvasItem) -> void:
	_menus.append(weakref(menu))
	menu.visibility_changed.connect(update_power_mode)
	update_power_mode()

func update_power_mode() -> void:
	var covered := false
	for i in range(_menus.size() - 1, -1, -1):
		var menu := _menus[i].get_ref() as CanvasItem
		if menu == null:
			_menus.remove_at(i)
		elif menu.is_visible_in_tree():
			covered = true
	var idle := not CompanyManager.created or TimeManager.time_scale <= 0.0 or covered
	if OS.low_processor_usage_mode != idle:
		OS.low_processor_usage_mode = idle

func _process(delta: float) -> void:
	update_power_mode()
	advance(delta)

func advance(delta: float) -> void:
	_elapsed += maxf(delta, 0.0)
	_since_tick += maxf(delta, 0.0)
	if _elapsed + 0.000001 < INTERVAL:
		return
	# Une image lente produit un seul battement avec tout le temps écoulé,
	# jamais une rafale de redessins pour rattraper le retard.
	var elapsed := _since_tick
	_elapsed = maxf(_elapsed - floorf((_elapsed + 0.000001) / INTERVAL) * INTERVAL, 0.0)
	_since_tick = 0.0
	tick.emit(elapsed)
