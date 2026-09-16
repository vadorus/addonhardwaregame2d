extends Control

var company_label: Label
var date_label: Label
var money_label: Label
var status_label: Label
var tabs: TabContainer
var setup_layer: Control
var month_layer: Control
var month_report_label: Label

var dashboard_label: Label
var alerts_label: Label
var company_rep_label: Label
var staff_label: Label
var candidate_label: Label
var tech_label: Label
var projects_label: Label
var patents_label: Label
var products_label: Label
var product_details_label: Label
var market_label: Label
var contract_label: Label
var media_label: Label

var setup_name: LineEdit
var setup_sector: OptionButton
var recruit_department: OptionButton
var rd_name: LineEdit
var rd_sector: OptionButton
var rd_segment: OptionButton
var rd_approach: OptionButton
var rd_focus: OptionButton
var rd_budget: SpinBox
var product_select: OptionButton
var product_price: SpinBox
var product_capacity: SpinBox
var market_product_select: OptionButton
var policy_marketing: SpinBox
var policy_support: SpinBox
var policy_environment: SpinBox
var policy_support_level: OptionButton
var department_select: OptionButton
var autonomy_select: OptionButton
var leader_select: OptionButton
var subsidiary_name: LineEdit
var subsidiary_sector: OptionButton
var subsidiary_capital: SpinBox

func _ready():
	_build_ui()
	_connect_signals()
	_refresh_all()
	setup_layer.visible = not CompanyManager.created

func _process(_delta):
	if CompanyManager.created:
		date_label.text = "Jour %d • Mois %d • %d" % [TimeManager.day, TimeManager.month, TimeManager.year]
		money_label.text = "%s €" % _money(Economy.money)

func _connect_signals():
	Economy.money_changed.connect(func(_v): _refresh_top())
	Economy.month_closed.connect(_on_month_closed)
	CompanyManager.company_changed.connect(_refresh_all)
	CompanyManager.reputation_changed.connect(_refresh_all)
	PersonnelManager.staff_changed.connect(_refresh_all)
	PersonnelManager.candidate_changed.connect(func(_c): _refresh_personnel())
	ResearchManager.projects_changed.connect(_refresh_all)
	ResearchManager.phase_report_created.connect(func(_p,_r): _refresh_all())
	ProductManager.products_changed.connect(_refresh_all)
	MarketManager.market_changed.connect(_refresh_all)
	MediaManager.news_changed.connect(_refresh_media)
	PatentManager.patents_changed.connect(_refresh_all)
	SaveManager.save_completed.connect(_on_save_message)

func _build_ui():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var root_box := VBoxContainer.new()
	root_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_box.add_theme_constant_override("separation", 6)
	add_child(root_box)

	var top := HBoxContainer.new()
	top.custom_minimum_size.y = 54
	top.add_theme_constant_override("separation", 12)
	root_box.add_child(top)
	company_label = _label("Tech Empire", 20)
	company_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(company_label)
	date_label = _label("Jour 1 • Mois 1 • 2025", 16)
	top.add_child(date_label)
	money_label = _label("500 000 €", 18)
	top.add_child(money_label)
	for data in [["⏸",0.0],["x1",1.0],["x2",2.0],["x3",3.0]]:
		var b := Button.new()
		b.text = str(data[0])
		var speed := float(data[1])
		b.pressed.connect(func(): TimeManager.time_scale = speed)
		top.add_child(b)
	var save_btn := Button.new()
	save_btn.text = "Sauver"
	save_btn.pressed.connect(func(): SaveManager.save_game())
	top.add_child(save_btn)
	var load_btn := Button.new()
	load_btn.text = "Charger"
	load_btn.pressed.connect(_load_game)
	top.add_child(load_btn)

	status_label = _label("", 13)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_box.add_child(status_label)

	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_box.add_child(tabs)
	_create_dashboard_tab()
	_create_company_tab()
	_create_personnel_tab()
	_create_research_tab()
	_create_products_tab()
	_create_market_tab()
	_create_media_tab()
	_build_setup_layer()
	_build_month_layer()

func _create_dashboard_tab():
	var scroll := _tab_scroll("Tableau de bord")
	var box: VBoxContainer = scroll.get_child(0)
	dashboard_label = _rich_label()
	box.add_child(dashboard_label)
	box.add_child(_section("Alertes de direction"))
	alerts_label = _rich_label()
	box.add_child(alerts_label)

func _create_company_tab():
	var scroll := _tab_scroll("Entreprise")
	var box: VBoxContainer = scroll.get_child(0)
	company_rep_label = _rich_label()
	box.add_child(company_rep_label)
	box.add_child(_section("Budgets mensuels"))
	var grid := GridContainer.new(); grid.columns = 2; box.add_child(grid)
	grid.add_child(_label("Marketing",14)); policy_marketing = _spin(0,200000,1000,6000); grid.add_child(policy_marketing)
	grid.add_child(_label("SAV / support",14)); policy_support = _spin(0,200000,1000,5000); grid.add_child(policy_support)
	grid.add_child(_label("Environnement",14)); policy_environment = _spin(0,200000,500,2500); grid.add_child(policy_environment)
	grid.add_child(_label("Politique SAV",14)); policy_support_level = OptionButton.new(); _fill_simple(policy_support_level, {"MINIMAL":"Minimal","STANDARD":"Standard","PREMIUM":"Premium"}); grid.add_child(policy_support_level)
	var apply := Button.new(); apply.text = "Appliquer les politiques"; apply.pressed.connect(_apply_policies); box.add_child(apply)
	box.add_child(_section("Délégation des départements"))
	var dgrid := GridContainer.new(); dgrid.columns = 2; box.add_child(dgrid)
	dgrid.add_child(_label("Département",14)); department_select = OptionButton.new(); _fill_text(department_select, ["R&D","Production","Marketing","Support","Finance"]); department_select.item_selected.connect(func(_i): _refresh_leader_choices()); dgrid.add_child(department_select)
	dgrid.add_child(_label("Autonomie",14)); autonomy_select = OptionButton.new(); _fill_simple(autonomy_select,{"DIRECT":"Direct","SUPERVISED":"Supervisé","AUTONOMOUS":"Autonome"}); dgrid.add_child(autonomy_select)
	dgrid.add_child(_label("Responsable",14)); leader_select = OptionButton.new(); dgrid.add_child(leader_select)
	var delegate_btn := Button.new(); delegate_btn.text = "Affecter responsable et autonomie"; delegate_btn.pressed.connect(_apply_department); box.add_child(delegate_btn)
	box.add_child(_section("Groupe / filiales"))
	var sgrid := GridContainer.new(); sgrid.columns=2; box.add_child(sgrid)
	sgrid.add_child(_label("Nom",14)); subsidiary_name=LineEdit.new(); subsidiary_name.placeholder_text="Nova Cloud"; sgrid.add_child(subsidiary_name)
	sgrid.add_child(_label("Secteur",14)); subsidiary_sector=OptionButton.new(); _fill_sector_options(subsidiary_sector); sgrid.add_child(subsidiary_sector)
	sgrid.add_child(_label("Capital",14)); subsidiary_capital=_spin(50000,5000000,10000,100000); sgrid.add_child(subsidiary_capital)
	var sub_btn:=Button.new(); sub_btn.text="Créer une filiale"; sub_btn.pressed.connect(_create_subsidiary); box.add_child(sub_btn)

func _create_personnel_tab():
	var scroll := _tab_scroll("Personnel")
	var box: VBoxContainer = scroll.get_child(0)
	staff_label = _rich_label(); box.add_child(staff_label)
	box.add_child(_section("Recrutement"))
	recruit_department = OptionButton.new(); _fill_text(recruit_department,["R&D","Production","Marketing","Support","Finance"]); box.add_child(recruit_department)
	var gen := Button.new(); gen.text="Chercher un candidat"; gen.pressed.connect(_generate_candidate); box.add_child(gen)
	candidate_label = _rich_label(); box.add_child(candidate_label)
	var hire := Button.new(); hire.text="Recruter ce candidat"; hire.pressed.connect(_hire_candidate); box.add_child(hire)

func _create_research_tab():
	var scroll := _tab_scroll("R&D")
	var box: VBoxContainer = scroll.get_child(0)
	box.add_child(_section("Lancer un développement produit"))
	var scope_note := _label("Vertical slice actuelle : processeurs (CPU). Les autres branches sont affichées mais verrouillées pour plus tard.", 13)
	scope_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(scope_note)
	var grid := GridContainer.new(); grid.columns=2; box.add_child(grid)
	grid.add_child(_label("Nom du produit",14)); rd_name=LineEdit.new(); rd_name.placeholder_text="X-Core One"; grid.add_child(rd_name)
	grid.add_child(_label("Secteur",14)); rd_sector=OptionButton.new(); _fill_sector_options(rd_sector); grid.add_child(rd_sector)
	grid.add_child(_label("Client cible",14)); rd_segment=OptionButton.new(); _fill_segment_options(rd_segment); grid.add_child(rd_segment)
	grid.add_child(_label("Approche",14)); rd_approach=OptionButton.new(); _fill_approach_options(rd_approach); grid.add_child(rd_approach)
	grid.add_child(_label("Priorité",14)); rd_focus=OptionButton.new(); _fill_focus_options(rd_focus); grid.add_child(rd_focus)
	grid.add_child(_label("Budget mensuel R&D",14)); rd_budget=_spin(10000,250000,2500,45000); grid.add_child(rd_budget)
	var start:=Button.new(); start.text="Lancer le projet"; start.pressed.connect(_start_project); box.add_child(start)
	box.add_child(_section("Technologies et savoir-faire")); tech_label=_rich_label(); box.add_child(tech_label)
	box.add_child(_section("Projets en cours / rapports d'équipe")); projects_label=_rich_label(); box.add_child(projects_label)
	box.add_child(_section("Brevets")); patents_label=_rich_label(); box.add_child(patents_label)
	var pat_row:=HBoxContainer.new(); box.add_child(pat_row)
	var file_pat:=Button.new(); file_pat.text="Déposer le premier brevet candidat (8 000 €)"; file_pat.pressed.connect(_file_patent); pat_row.add_child(file_pat)
	var lic_pat:=Button.new(); lic_pat.text="Activer/désactiver licence du 1er brevet"; lic_pat.pressed.connect(_toggle_patent_license); pat_row.add_child(lic_pat)

func _create_products_tab():
	var scroll := _tab_scroll("Produits")
	var box: VBoxContainer = scroll.get_child(0)
	products_label=_rich_label(); box.add_child(products_label)
	box.add_child(_section("Industrialiser / lancer"))
	product_select=OptionButton.new(); product_select.item_selected.connect(func(_i): _refresh_product_details()); box.add_child(product_select)
	product_details_label=_rich_label(); box.add_child(product_details_label)
	var grid:=GridContainer.new(); grid.columns=2; box.add_child(grid)
	grid.add_child(_label("Prix de vente",14)); product_price=_spin(1,1000000,5,300); grid.add_child(product_price)
	grid.add_child(_label("Capacité mensuelle",14)); product_capacity=_spin(1,1000000,100,5000); grid.add_child(product_capacity)
	var launch:=Button.new(); launch.text="Lancer sur le marché"; launch.pressed.connect(_launch_product); box.add_child(launch)

func _create_market_tab():
	var scroll := _tab_scroll("Marché")
	var box: VBoxContainer = scroll.get_child(0)
	market_product_select=OptionButton.new(); market_product_select.item_selected.connect(func(_i): _refresh_market()); box.add_child(market_product_select)
	market_label=_rich_label(); box.add_child(market_label)
	box.add_child(_section("Contrats B2B")); contract_label=_rich_label(); box.add_child(contract_label)
	var accept:=Button.new(); accept.text="Accepter la première proposition B2B"; accept.pressed.connect(_accept_contract); box.add_child(accept)

func _create_media_tab():
	var scroll := _tab_scroll("Presse & médias")
	var box: VBoxContainer = scroll.get_child(0)
	media_label=_rich_label(); box.add_child(media_label)

func _build_setup_layer():
	setup_layer = ColorRect.new()
	setup_layer.color = Color(0.05,0.06,0.08,0.97)
	setup_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(setup_layer)
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); setup_layer.add_child(center)
	var panel:=PanelContainer.new(); panel.custom_minimum_size=Vector2(560,420); center.add_child(panel)
	var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",14); panel.add_child(box)
	var title:=_label("Créer votre entreprise technologique",26); title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; box.add_child(title)
	var desc:=_label("La vertical slice actuelle commence par la branche CPU. Développez vos équipes, vos technologies et plusieurs générations de processeurs avant l’ouverture des autres secteurs.",15); desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(desc)
	setup_name=LineEdit.new(); setup_name.placeholder_text="Nom de l'entreprise"; setup_name.text="Nova Technologies"; box.add_child(setup_name)
	setup_sector=OptionButton.new(); _fill_sector_options(setup_sector); box.add_child(setup_sector)
	var start:=Button.new(); start.text="Créer l'entreprise"; start.custom_minimum_size.y=48; start.pressed.connect(_start_new_game); box.add_child(start)
	var load:=Button.new(); load.text="Charger une sauvegarde"; load.pressed.connect(_load_game); box.add_child(load)

func _build_month_layer():
	month_layer=ColorRect.new(); month_layer.color=Color(0,0,0,0.72); month_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); month_layer.visible=false; add_child(month_layer)
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); month_layer.add_child(center)
	var panel:=PanelContainer.new(); panel.custom_minimum_size=Vector2(560,430); center.add_child(panel)
	var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",12); panel.add_child(box)
	box.add_child(_section("Rapport mensuel")); month_report_label=_rich_label(); box.add_child(month_report_label)
	var cont:=Button.new(); cont.text="Continuer"; cont.custom_minimum_size.y=44; cont.pressed.connect(_close_month_report); box.add_child(cont)

func _tab_scroll(title: String) -> ScrollContainer:
	var scroll:=ScrollContainer.new(); scroll.name=title; scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var box:=VBoxContainer.new(); box.size_flags_horizontal=Control.SIZE_EXPAND_FILL; box.add_theme_constant_override("separation",10); box.custom_minimum_size.x=900; scroll.add_child(box); tabs.add_child(scroll); return scroll

func _label(text: String, size: int=14) -> Label:
	var l:=Label.new(); l.text=text; l.add_theme_font_size_override("font_size",size); return l

func _section(text: String) -> Label:
	var l:=_label(text,19); l.custom_minimum_size.y=32; return l

func _rich_label() -> Label:
	var l:=_label("",14); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; l.size_flags_horizontal=Control.SIZE_EXPAND_FILL; return l

func _spin(minv: float,maxv: float,stepv: float,valuev: float) -> SpinBox:
	var s:=SpinBox.new(); s.min_value=minv; s.max_value=maxv; s.step=stepv; s.value=valuev; s.allow_greater=true; return s

func _fill_text(option: OptionButton, items: Array):
	option.clear(); for item in items: option.add_item(str(item)); option.set_item_metadata(option.item_count-1,str(item))

func _fill_simple(option: OptionButton, items: Dictionary):
	option.clear(); for key in items.keys(): option.add_item(str(items[key])); option.set_item_metadata(option.item_count-1,str(key))

func _fill_sector_options(option: OptionButton):
	option.clear()
	for key in GameData.get_sector_keys():
		var sector_key := str(key)
		var active := GameData.is_sector_active(sector_key)
		var item_label := str(GameData.SECTORS[key].label)
		if not active:
			item_label += " — à venir"
		option.add_item(item_label)
		var item_index := option.item_count - 1
		option.set_item_metadata(item_index, sector_key)
		option.set_item_disabled(item_index, not active)

func _fill_segment_options(option: OptionButton):
	option.clear(); for key in GameData.get_segment_keys(): option.add_item(str(GameData.SEGMENTS[key].label)); option.set_item_metadata(option.item_count-1,str(key))

func _fill_approach_options(option: OptionButton):
	option.clear(); for key in GameData.get_approach_keys(): option.add_item(str(GameData.APPROACHES[key].label)); option.set_item_metadata(option.item_count-1,str(key))

func _fill_focus_options(option: OptionButton):
	option.clear(); for key in GameData.get_focus_keys(): option.add_item(str(GameData.FOCUS_OPTIONS[key].label)); option.set_item_metadata(option.item_count-1,str(key))

func _meta(option: OptionButton) -> String:
	if option.item_count == 0: return ""
	return str(option.get_item_metadata(option.selected))

func _money(value: int) -> String:
	var s:=str(abs(value)); var out:=""; var count:=0
	for i in range(s.length()-1,-1,-1):
		if count>0 and count%3==0: out=" "+out
		out=s.substr(i,1)+out; count+=1
	return ("-" if value<0 else "")+out

func _start_new_game():
	SimulationManager.reset_all(setup_name.text,_meta(setup_sector))
	setup_layer.visible=false
	status_label.text="Entreprise créée. Votre première décision : lancer un projet R&D."
	_refresh_all()

func _load_game():
	if SaveManager.load_game():
		setup_layer.visible=false
		_refresh_all()

func _on_save_message(ok: bool, message: String):
	status_label.text=("✓ " if ok else "⚠ ")+message

func _on_month_closed(report: Dictionary):
	TimeManager.time_scale=0.0
	var inc_lines:=_breakdown(report.income_breakdown)
	var exp_lines:=_breakdown(report.expense_breakdown)
	month_report_label.text="Mois %d / %d\n\nRevenus : %s €\n%s\n\nDépenses : %s €\n%s\n\nRésultat : %s €\nTrésorerie : %s €" % [int(report.month),int(report.year),_money(int(report.income)),inc_lines,_money(int(report.expenses)),exp_lines,_money(int(report.result)),_money(int(report.money))]
	month_layer.visible=true
	_refresh_all()

func _breakdown(data: Dictionary) -> String:
	if data.is_empty(): return "  —"
	var lines:=[]
	for key in data: lines.append("  • %s : %s €" % [str(key),_money(int(data[key]))])
	return "\n".join(lines)

func _close_month_report():
	month_layer.visible=false
	TimeManager.time_scale=1.0

func _refresh_top():
	company_label.text=CompanyManager.company_name if CompanyManager.created else "Tech Empire"
	money_label.text="%s €" % _money(Economy.money)

func _refresh_all():
	_refresh_top(); _refresh_dashboard(); _refresh_company(); _refresh_personnel(); _refresh_research(); _refresh_products(); _refresh_market(); _refresh_media()

func _refresh_dashboard():
	if dashboard_label==null: return
	if not CompanyManager.created:
		dashboard_label.text="Créez ou chargez une entreprise pour commencer."; return
	var launched:=0; var active_projects:=0; var monthly_sales:=0
	for p in ProductManager.products:
		if str(p.status)=="LAUNCHED": launched+=1; monthly_sales+=int(p.last_month_sales)
	for p in ResearchManager.projects:
		if str(p.status)=="DEVELOPMENT": active_projects+=1
	dashboard_label.text="%s\nSecteur de départ : %s\nTrésorerie : %s €\nEmployés : %d\nProjets R&D actifs : %d\nProduits commercialisés : %d\nVentes du dernier mois : %s unités\nImage de marque : %.1f/100" % [CompanyManager.company_name,GameData.SECTORS.get(CompanyManager.starting_sector,{}).get("label",CompanyManager.starting_sector),_money(Economy.money),PersonnelManager.staff.size(),active_projects,launched,_money(monthly_sales),CompanyManager.get_brand_score()]
	alerts_label.text="\n".join(CompanyManager.alerts.slice(0,8)) if not CompanyManager.alerts.is_empty() else "Aucune alerte importante."

func _refresh_company():
	if company_rep_label==null or not CompanyManager.created: return
	var r:=CompanyManager.reputation
	var lines:=["Image de l'entreprise :"]
	for key in ["innovation","reliability","value","support","sustainability","prestige","professional"]: lines.append("• %s : %.1f/100" % [key.capitalize(),float(r[key])])
	lines.append("\nFiliales : %d" % CompanyManager.subsidiaries.size())
	for sub in CompanyManager.subsidiaries: lines.append("• %s — %s — capital %s €" % [str(sub.name),str(sub.sector),_money(int(sub.capital))])
	company_rep_label.text="\n".join(lines)
	policy_marketing.value=float(CompanyManager.policies.marketing_budget); policy_support.value=float(CompanyManager.policies.support_budget); policy_environment.value=float(CompanyManager.policies.environment_budget)
	_select_meta(policy_support_level,str(CompanyManager.policies.support_level)); _refresh_leader_choices()

func _apply_policies():
	CompanyManager.policies.marketing_budget=int(policy_marketing.value); CompanyManager.policies.support_budget=int(policy_support.value); CompanyManager.policies.environment_budget=int(policy_environment.value); CompanyManager.policies.support_level=_meta(policy_support_level); CompanyManager.company_changed.emit(); status_label.text="Politiques mises à jour."

func _refresh_leader_choices():
	if leader_select==null or department_select==null: return
	var dept:=_meta(department_select); leader_select.clear(); leader_select.add_item("Aucun"); leader_select.set_item_metadata(0,"")
	for emp in PersonnelManager.staff:
		leader_select.add_item("%s — L%d / Comp%d / %.1f ans" % [str(emp.name),int(emp.leadership),int(emp.skill),float(emp.experience_years)]); leader_select.set_item_metadata(leader_select.item_count-1,str(emp.id))
	if CompanyManager.departments.has(dept): _select_meta(autonomy_select,str(CompanyManager.departments[dept].autonomy)); _select_meta(leader_select,str(CompanyManager.departments[dept].leader_id))

func _apply_department():
	var dept:=_meta(department_select); CompanyManager.set_department_autonomy(dept,_meta(autonomy_select)); CompanyManager.set_department_leader(dept,_meta(leader_select)); status_label.text="Organisation du département %s mise à jour." % dept; _refresh_all()

func _create_subsidiary():
	if CompanyManager.create_subsidiary(subsidiary_name.text,_meta(subsidiary_sector),int(subsidiary_capital.value)): subsidiary_name.text=""; status_label.text="Filiale créée."
	else: status_label.text="Capital insuffisant ou montant trop faible."
	_refresh_all()

func _refresh_personnel():
	if staff_label==null: return
	var lines:=["Effectif : %d" % PersonnelManager.staff.size()]
	for emp in PersonnelManager.staff:
		var leader_mark:=""
		for dept in CompanyManager.departments:
			if str(CompanyManager.departments[dept].leader_id)==str(emp.id): leader_mark=" ★ responsable %s" % dept
		lines.append("• %s — %s | %s | compétence %d | expérience %.1f ans | leadership %d | spé. %s | %s €/mois%s" % [str(emp.name),str(emp.role),str(emp.department),int(emp.skill),float(emp.experience_years),int(emp.leadership),str(emp.specialization),_money(int(emp.salary)),leader_mark])
	staff_label.text="\n".join(lines)
	if PersonnelManager.candidate.is_empty(): candidate_label.text="Aucun candidat sélectionné."
	else:
		var c:=PersonnelManager.candidate; candidate_label.text="%s — %s\nCompétence %d | aptitude %d | expérience %.1f ans | leadership %d\nSpécialisation : %s | salaire : %s €/mois | prime d'embauche : %s €" % [str(c.name),str(c.department),int(c.skill),int(c.aptitude),float(c.experience_years),int(c.leadership),str(c.specialization),_money(int(c.salary)),_money(int(c.salary)*2)]

func _generate_candidate(): PersonnelManager.generate_candidate(_meta(recruit_department)); _refresh_personnel()
func _hire_candidate():
	if PersonnelManager.hire_candidate(): status_label.text="Candidat recruté."; PersonnelManager.generate_candidate(_meta(recruit_department))
	else: status_label.text="Recrutement impossible."; _refresh_all()

func _refresh_research():
	if tech_label==null: return
	var tech_lines:=[]
	for key in ResearchManager.technologies.keys(): tech_lines.append("• %s : %.1f" % [str(key).capitalize(),float(ResearchManager.technologies[key])])
	tech_label.text="\n".join(tech_lines) if not tech_lines.is_empty() else "Aucun savoir-faire initialisé."
	var lines:=[]
	for p in ResearchManager.projects:
		var phase:="Terminé"
		if str(p.status)=="DEVELOPMENT": phase="%s — %.0f%%" % [GameData.PHASES[int(p.phase_index)],float(p.phase_progress)]
		lines.append("%s [%s] — %s — %d mois — %s" % [str(p.name),GameData.SECTORS[str(p.sector)].label,phase,int(p.months_spent),GameData.APPROACHES[str(p.approach)].label])
		if not p.reports.is_empty(): lines.append("  Chef d'équipe : %s" % str(p.reports[0].text))
	projects_label.text="\n\n".join(lines) if not lines.is_empty() else "Aucun projet. Lancez votre premier développement ci-dessus."
	var pats:=[]
	for c in PatentManager.candidates: pats.append("Candidat : %s — force %d" % [str(c.title),int(c.strength)])
	for p in PatentManager.patents: pats.append("Brevet : %s — %s" % [str(p.title),"licencié" if bool(p.licensed) else "exclusif"])
	patents_label.text="\n".join(pats) if not pats.is_empty() else "Aucun brevet pour le moment. Les projets très innovants peuvent générer des inventions brevetables."

func _start_project():
	var name:=rd_name.text.strip_edges(); if name.is_empty(): name="Projet %s" % GameData.SECTORS[_meta(rd_sector)].label
	if ResearchManager.start_project(name,_meta(rd_sector),_meta(rd_segment),_meta(rd_approach),_meta(rd_focus),int(rd_budget.value)): rd_name.text=""; status_label.text="Projet R&D lancé."
	else: status_label.text="Impossible de lancer le projet : trésorerie ou capacité R&D insuffisante."
	_refresh_all()

func _file_patent(): status_label.text="Brevet déposé." if PatentManager.file_first_candidate() else "Aucun brevet candidat ou trésorerie insuffisante."; _refresh_all()
func _toggle_patent_license(): PatentManager.toggle_license_first(); _refresh_all()

func _refresh_products():
	if products_label==null: return
	var current_id:=_meta(product_select) if product_select.item_count>0 else ""; var lines:=[]
	for p in ProductManager.products: lines.append("• %s — %s — %s | coût %s € | prix %s € | ventes totales %s | satisfaction %.1f" % [str(p.name),GameData.SECTORS[str(p.sector)].label,str(p.status),_money(int(p.unit_cost)),_money(int(p.price)),_money(int(p.units_sold_total)),float(p.customer_satisfaction)])
	products_label.text="\n".join(lines) if not lines.is_empty() else "Aucun produit. Terminez d'abord un projet R&D."
	product_select.clear()
	for p in ProductManager.products: product_select.add_item("%s — %s" % [str(p.name),str(p.status)]); product_select.set_item_metadata(product_select.item_count-1,str(p.id))
	if current_id!="": _select_meta(product_select,current_id)
	_refresh_product_details(); _refresh_market_product_options()

func _refresh_product_details():
	if product_details_label==null or product_select.item_count==0: product_details_label.text="Aucun produit sélectionné."; return
	var p:=ProductManager.get_product(_meta(product_select)); if p.is_empty(): return
	var m: Dictionary = p.get("metrics", {}); var metric_lines: Array = []
	for metric in GameData.METRICS: metric_lines.append("%s %.1f" % [GameData.metric_label(metric),float(m[metric])])
	product_details_label.text="%s\nApproche : %s | interne %.0f%%\n%s" % [str(p.name),GameData.APPROACHES[str(p.approach)].label,float(p.internal_ratio)*100.0," • ".join(metric_lines)]
	product_price.value=float(p.price); product_capacity.value=float(p.production_capacity)

func _launch_product():
	if product_select.item_count==0: return
	if ProductManager.launch_product(_meta(product_select),int(product_price.value),int(product_capacity.value)): status_label.text="Produit lancé : la presse et les clients vont maintenant le juger."
	else: status_label.text="Ce produit est déjà lancé ou indisponible."; _refresh_all()

func _refresh_market_product_options():
	if market_product_select==null: return
	var current:=_meta(market_product_select) if market_product_select.item_count>0 else ""; market_product_select.clear()
	for p in ProductManager.products:
		if str(p.status)=="LAUNCHED": market_product_select.add_item(str(p.name)); market_product_select.set_item_metadata(market_product_select.item_count-1,str(p.id))
	if current!="": _select_meta(market_product_select,current)

func _refresh_market():
	if market_label==null: return
	_refresh_market_product_options()
	if market_product_select.item_count==0: market_label.text="Lancez un produit pour obtenir benchmarks, retours clients et parts de marché."; contract_label.text="Aucun contrat."; return
	var p:=ProductManager.get_product(_meta(market_product_select)); if p.is_empty(): return
	var bench:=MarketManager.benchmark_for(p); var lines:=["Benchmark %s :" % str(p.name)]
	for i in range(bench.size()): lines.append("%d. %s — %.1f pts — %s €%s" % [i+1,str(bench[i].name),float(bench[i].score),_money(int(bench[i].price))," ← vous" if bool(bench[i].player) else ""])
	lines.append("\nÉvaluation par clientèle :")
	for seg in GameData.SEGMENTS.keys(): lines.append("• %s : %.1f/100" % [GameData.SEGMENTS[seg].label,MarketManager.evaluate_product(p,str(seg))])
	lines.append("\nDernier mois : %s ventes | %.1f%% part estimée | %d retours SAV | satisfaction %.1f/100" % [_money(int(p.last_month_sales)),float(p.last_month_share)*100.0,int(p.last_month_returns),float(p.customer_satisfaction)])
	market_label.text="\n".join(lines)
	var c_lines:=[]
	for c in MarketManager.contracts:
		c_lines.append("• %s — %s — %s unités/mois à %s € — %d mois — %s" % [str(c.customer),str(c.product_name),_money(int(c.units_per_month)),_money(int(c.unit_price)),int(c.remaining_months),str(c.status)])
	contract_label.text="\n".join(c_lines) if not c_lines.is_empty() else "Aucune proposition. Les produits adaptés au calcul, à l'efficacité ou à la fiabilité peuvent attirer des entreprises."

func _accept_contract(): status_label.text="Contrat B2B accepté." if MarketManager.accept_first_pending_contract() else "Aucune proposition en attente."; _refresh_all()

func _refresh_media():
	if media_label==null: return
	var lines:=[]
	for n in MediaManager.news.slice(0,20): lines.append("[%02d/%d] %s — %s\n%s" % [int(n.month),int(n.year),str(n.category),str(n.headline),str(n.body)])
	media_label.text="\n\n".join(lines) if not lines.is_empty() else "Aucune actualité."

func _select_meta(option: OptionButton, wanted: String):
	for i in range(option.item_count):
		if str(option.get_item_metadata(i))==wanted: option.select(i); return
