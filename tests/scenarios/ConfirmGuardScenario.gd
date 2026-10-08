extends RefCounted
## Audit des entrées (08/10) : sur le Pixel, un double appui involontaire ne confirme pas une action
## payante ; une vraie seconde touche, plus tard, confirme ; la confirmation armée retombe seule.

static func run(host: Node) -> String:
	var panel: Control = (load("res://ui/components/ProductLifecyclePanel.gd") as Script).new()
	host.add_child(panel)
	var button := Button.new()
	button.text = "Payer"
	host.add_child(button)
	var calls := [0]
	var action := func(): calls[0] += 1
	panel.call("_arm_or_run", button, action)
	panel.call("_arm_or_run", button, action)
	var bounced := int(calls[0])
	panel.set("_armed_at_ms", Time.get_ticks_msec() - 1000)
	panel.call("_arm_or_run", button, action)
	var confirmed := int(calls[0])
	panel.call("_arm_or_run", button, action, false)
	var direct := int(calls[0])
	button.queue_free()
	panel.queue_free()
	if bounced != 0:
		return "Confirm guard: a double tap within %d ms confirmed a paid action" % int(panel.get("CONFIRM_MIN_DELAY_MS"))
	if confirmed != 1:
		return "Confirm guard: a deliberate second tap did not confirm"
	if direct != 2:
		return "Confirm guard: actions without confirmation must run at once"
	return ""
