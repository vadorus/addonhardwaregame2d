extends Control
## V0.10 / Gammes — illustration dessinée d'un composant, qui suit l'époque :
## mémoire (puce à pattes avant 1982, barrette ensuite, dissipateur coloré pour les passionnés),
## alimentation (boîtier métal, ventilateur, câbles), boîtier (beige des années 80-90, noir avec
## éclairage bleu après 2003). Sans image : tout est vectoriel, net sur tous les écrans.

var family := "MEMORY"
var year := 1980
var accent := Color("d9822b")
var locked := false
var spin := 0.0

const INK := Color("3b2b1e")

func setup(family_id: String, at_year: int, is_locked: bool = false) -> void:
	family = family_id
	year = at_year
	locked = is_locked
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _process(delta: float) -> void:
	# Le ventilateur de l'alimentation tourne doucement (petit signe de vie, pas une animation lourde).
	if family == "PSU" and is_visible_in_tree() and not locked:
		spin = fmod(spin + delta * 2.2, TAU)
		queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if r.size.x < 8.0 or r.size.y < 8.0:
		return
	match family:
		"MEMORY":
			_draw_memory(r)
		"PSU":
			_draw_psu(r)
		_:
			_draw_case(r)
	if locked:
		draw_rect(r, Color(0.96, 0.92, 0.85, 0.72))
		var c := r.get_center()
		var s := minf(r.size.x, r.size.y) * 0.18
		draw_rect(Rect2(c + Vector2(-s, -s * 0.2), Vector2(s * 2.0, s * 1.6)), INK.lerp(Color.WHITE, 0.2))
		draw_arc(c + Vector2(0, -s * 0.2), s * 0.65, PI, TAU, 16, INK.lerp(Color.WHITE, 0.2), s * 0.28, true)

func _draw_memory(r: Rect2) -> void:
	var w := r.size.x
	var h := r.size.y
	if year < 1982:
		# Une puce DIP : corps noir, pattes argent, encoche.
		var body := Rect2(Vector2(w * 0.18, h * 0.28), Vector2(w * 0.64, h * 0.44))
		for i in range(8):
			var x := body.position.x + body.size.x * (0.08 + 0.12 * i)
			draw_rect(Rect2(Vector2(x, body.position.y - h * 0.10), Vector2(body.size.x * 0.05, h * 0.10)), Color("c9c4bb"))
			draw_rect(Rect2(Vector2(x, body.end.y), Vector2(body.size.x * 0.05, h * 0.10)), Color("c9c4bb"))
		draw_rect(body, Color("26211c"))
		draw_circle(Vector2(body.position.x + body.size.x * 0.06, body.get_center().y), h * 0.05, Color("4a423a"))
		draw_rect(Rect2(body.position + Vector2(body.size.x * 0.22, body.size.y * 0.38), Vector2(body.size.x * 0.5, body.size.y * 0.1)), Color("8c8478"))
		return
	# Une barrette : circuit vert, puces noires, contacts dorés ; dissipateur coloré après 2000.
	var pcb := Rect2(Vector2(w * 0.06, h * 0.30), Vector2(w * 0.88, h * 0.42))
	draw_rect(pcb, Color("1f6b45"))
	draw_rect(Rect2(pcb.position, Vector2(pcb.size.x, pcb.size.y * 0.06)), Color("2a8a5a"))
	for i in range(20):
		var x := pcb.position.x + pcb.size.x * (0.03 + 0.048 * i)
		draw_rect(Rect2(Vector2(x, pcb.end.y - pcb.size.y * 0.16), Vector2(pcb.size.x * 0.03, pcb.size.y * 0.16)), Color("e3b341"))
	draw_rect(Rect2(Vector2(pcb.position.x + pcb.size.x * 0.47, pcb.end.y - pcb.size.y * 0.16), Vector2(pcb.size.x * 0.03, pcb.size.y * 0.16)), Color("1f6b45"))
	if year >= 2000:
		var spreader := Rect2(pcb.position + Vector2(pcb.size.x * 0.02, -pcb.size.y * 0.10), Vector2(pcb.size.x * 0.96, pcb.size.y * 0.78))
		draw_rect(spreader, accent.darkened(0.15))
		for i in range(6):
			var x := spreader.position.x + spreader.size.x * (0.08 + 0.15 * i)
			draw_rect(Rect2(Vector2(x, spreader.position.y - pcb.size.y * 0.12), Vector2(spreader.size.x * 0.08, pcb.size.y * 0.14)), accent)
		draw_rect(Rect2(spreader.position + Vector2(spreader.size.x * 0.3, spreader.size.y * 0.35), Vector2(spreader.size.x * 0.4, spreader.size.y * 0.16)), Color(1, 1, 1, 0.65))
	else:
		for i in range(4):
			var x := pcb.position.x + pcb.size.x * (0.06 + 0.235 * i)
			draw_rect(Rect2(Vector2(x, pcb.position.y + pcb.size.y * 0.16), Vector2(pcb.size.x * 0.16, pcb.size.y * 0.5)), Color("26211c"))

func _draw_psu(r: Rect2) -> void:
	var w := r.size.x
	var h := r.size.y
	var box := Rect2(Vector2(w * 0.14, h * 0.16), Vector2(w * 0.58, h * 0.62))
	draw_rect(box, Color("9aa0a6") if year < 2000 else Color("2b2f33"))
	draw_rect(Rect2(box.position, Vector2(box.size.x, box.size.y * 0.08)), Color(1, 1, 1, 0.25))
	var fan_c := box.get_center()
	var fan_r := minf(box.size.x, box.size.y) * 0.36
	draw_circle(fan_c, fan_r, Color("1b1d20"))
	for i in range(5):
		var a := spin + TAU * float(i) / 5.0
		var p1 := fan_c + Vector2(cos(a), sin(a)) * fan_r * 0.2
		var p2 := fan_c + Vector2(cos(a + 0.6), sin(a + 0.6)) * fan_r * 0.85
		draw_line(p1, p2, Color("6d7278") if year < 2000 else accent, fan_r * 0.18, true)
	draw_circle(fan_c, fan_r * 0.18, Color("4a4e53"))
	draw_arc(fan_c, fan_r, 0, TAU, 32, Color("c9ccd0"), 1.5, true)
	# Câbles qui sortent sur le côté.
	var colors := [Color("f2c230"), Color("1b1b1b"), Color("d33b2c"), Color("1b1b1b")]
	for i in range(colors.size()):
		var y := box.position.y + box.size.y * (0.3 + 0.12 * i)
		var start := Vector2(box.end.x, y)
		draw_polyline(PackedVector2Array([start, start + Vector2(w * 0.08, h * 0.02), start + Vector2(w * 0.16, h * 0.10)]), colors[i], maxf(2.0, h * 0.025), true)
	draw_rect(Rect2(Vector2(box.end.x + w * 0.14, box.position.y + box.size.y * 0.62), Vector2(w * 0.08, h * 0.14)), Color("f5f1e8"))

func _draw_case(r: Rect2) -> void:
	var w := r.size.x
	var h := r.size.y
	var modern := year >= 2003
	var tower := Rect2(Vector2(w * 0.32, h * 0.08), Vector2(w * 0.36, h * 0.84))
	var shell := Color("2a2a2e") if modern else (Color("e8dcc0") if year < 1995 else Color("d9d5cc"))
	draw_rect(Rect2(tower.position + Vector2(w * 0.03, h * 0.02), tower.size), Color(0, 0, 0, 0.18))
	draw_rect(tower, shell)
	draw_rect(Rect2(tower.position, Vector2(tower.size.x * 0.08, tower.size.y)), shell.lightened(0.12))
	# Baies 5,25" et lecteur.
	for i in range(2 if modern else 3):
		draw_rect(Rect2(tower.position + Vector2(tower.size.x * 0.14, tower.size.y * (0.08 + 0.1 * i)), Vector2(tower.size.x * 0.72, tower.size.y * 0.07)), shell.darkened(0.18))
	if year < 1998:
		draw_rect(Rect2(tower.position + Vector2(tower.size.x * 0.3, tower.size.y * 0.42), Vector2(tower.size.x * 0.4, tower.size.y * 0.03)), INK)
	# Bouton et voyant.
	draw_circle(tower.position + Vector2(tower.size.x * 0.5, tower.size.y * 0.62), tower.size.x * 0.09, shell.darkened(0.3))
	draw_circle(tower.position + Vector2(tower.size.x * 0.5, tower.size.y * 0.72), tower.size.x * 0.035, Color("3d9be9") if modern else Color("4bd16b"))
	# Grille d'aération en bas.
	for i in range(5):
		var y := tower.position.y + tower.size.y * (0.80 + 0.03 * i)
		draw_line(Vector2(tower.position.x + tower.size.x * 0.2, y), Vector2(tower.end.x - tower.size.x * 0.2, y), shell.darkened(0.3), 1.5)
	if modern:
		draw_line(Vector2(tower.position.x + 2, tower.position.y), Vector2(tower.position.x + 2, tower.end.y), Color("3d9be9"), 2.0)
