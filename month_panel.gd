extends Control

@onready var title_label = $VBoxContainer/TitleLabel
@onready var report_label = $VBoxContainer/ReportLabel
@onready var continue_btn = $VBoxContainer/ContinueBtn

func _ready():
	visible = false
	continue_btn.pressed.connect(_on_continue_pressed)

func show_report(report: Dictionary):
	TimeManager.time_scale = 0  # ⏸️ pause du temps
	var text := ""
	text += "Revenus : %d €\n" % report.income
	text += "Dépenses : %d €\n" % report.expenses
	text += "Résultat : %d €\n" % report.result
	text += "Argent total : %d €" % report.money

	report_label.text = text
	visible = true





func _on_continue_pressed():
	visible = false
	TimeManager.time_scale = 1  # ▶️ reprise du temps
