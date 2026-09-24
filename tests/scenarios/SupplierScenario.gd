extends RefCounted

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

static func run() -> String:
	var sourcing_keys := GameData.get_approach_keys()
	for sourcing_key in ["INTERNAL","PURCHASE","LICENSE","SUBCONTRACT","PARTNER"]:
		if not sourcing_keys.has(sourcing_key):
			return "Strategic sourcing is missing active choice: %s" % sourcing_key
	if sourcing_keys.has("HYBRID") or sourcing_keys.has("EXTERNAL"):
		return "Legacy sourcing choices leaked back into the new-game UI"
	var internal_sourcing := GameData.sourcing_profile("INTERNAL")
	var purchase_sourcing := GameData.sourcing_profile("PURCHASE")
	var license_sourcing := GameData.sourcing_profile("LICENSE")
	var partner_sourcing := GameData.sourcing_profile("PARTNER")
	if float(internal_sourcing.get("ip_ownership", 0.0)) <= float(purchase_sourcing.get("ip_ownership", 0.0)):
		return "Internal sourcing does not preserve more IP ownership than buying external technology"
	if float(purchase_sourcing.get("dependency", 0.0)) <= float(partner_sourcing.get("dependency", 0.0)):
		return "Buying external technology should create more supplier dependency than co-development"
	if float(license_sourcing.get("royalty_rate", 0.0)) <= 0.0:
		return "Licensed technology does not carry a real royalty"
	if float(GameData.approach_data("PURCHASE").get("speed", 0.0)) <= float(GameData.approach_data("INTERNAL").get("speed", 0.0)):
		return "Buying technology should accelerate development relative to fully internal R&D"

	var license_suppliers := SupplierManager.supplier_keys_for_mode("LICENSE")
	if license_suppliers.size() < 2:
		return "Licensed sourcing does not expose multiple real technology suppliers"
	var supplier_ai_initial_state := SupplierManager.get_state().duplicate(true)
	var supplier_cash_before_ai := {}
	for supplier_id_value in SupplierManager.suppliers.keys():
		var supplier_id := str(supplier_id_value)
		var supplier := SupplierManager.get_supplier(supplier_id)
		supplier_cash_before_ai[supplier_id] = int(supplier.get("supplier_cash", 0))
		if not supplier.has("ai_supplier_history") or not supplier.has("external_load"):
			return "Technology supplier is missing autonomous business state"
		if int(supplier.get("external_load", 0)) > maxi(int(supplier.get("capacity_slots", 1)) - 1, 0):
			return "External supplier workload consumed the last open-market capacity slot"
	for _supplier_month in range(5):
		SupplierManager.process_month()
	var supplier_finances_changed := false
	for supplier_id_value in SupplierManager.suppliers.keys():
		var supplier_id := str(supplier_id_value)
		var supplier := SupplierManager.get_supplier(supplier_id)
		if supplier.get("ai_supplier_history", []).is_empty():
			return "Autonomous technology supplier never made a business decision"
		if int(supplier.get("external_load", 0)) > maxi(int(supplier.get("capacity_slots", 1)) - 1, 0):
			return "Autonomous supplier external business crowded the player out of all open capacity"
		if int(supplier.get("supplier_cash", 0)) != int(supplier_cash_before_ai.get(supplier_id, 0)):
			supplier_finances_changed = true
	if not supplier_finances_changed:
		return "Autonomous supplier economy remained completely static"
	SupplierManager.load_state(supplier_ai_initial_state)

	var license_supplier_a := str(license_suppliers[0])
	var license_supplier_b := str(license_suppliers[1])
	var quote_a := SupplierManager.quote("LICENSE", license_supplier_a, "BALANCED")
	var quote_b := SupplierManager.quote("LICENSE", license_supplier_b, "BALANCED")
	if quote_a.is_empty() or quote_b.is_empty() or str(quote_a.get("supplier_name", "")) == str(quote_b.get("supplier_name", "")):
		return "Technology suppliers do not produce distinct supplier quotes"
	if float(quote_a.get("supplier_reliability", 0.0)) == float(quote_b.get("supplier_reliability", 0.0)) and int(quote_a.get("setup_cost", 0)) == int(quote_b.get("setup_cost", 0)):
		return "Supplier choice has no meaningful economic or reliability difference"
	var rival_capacity_state := SupplierManager.get_state().duplicate(true)
	SupplierManager.reset()
	var rival_capacity_quote_before := SupplierManager.quote("LICENSE", license_supplier_a, "BALANCED")
	var rival_reservation := SupplierManager.request_rival_capacity("RIVAL-CAPACITY-PROBE", "Rival Capacity Probe", "LICENSE", 10, 100000)
	if rival_reservation.is_empty():
		return "Rival company could not reserve a real technology-supplier slot"
	var rival_capacity_quote_after := SupplierManager.quote("LICENSE", license_supplier_a, "BALANCED")
	if int(rival_capacity_quote_after.get("supplier_rival_load", 0)) <= int(rival_capacity_quote_before.get("supplier_rival_load", 0)):
		return "Rival supplier reservation did not increase named competitive load"
	if int(rival_capacity_quote_after.get("available_capacity_slots", 0)) < 1:
		return "Rival supplier reservation removed the last fair player-access slot"
	SupplierManager.release_rival_capacity("RIVAL-CAPACITY-PROBE")
	SupplierManager.load_state(rival_capacity_state)

	var rival_sourcing_market_state := MarketManager.get_state().duplicate(true)
	var rival_sourcing_supplier_state := SupplierManager.get_state().duplicate(true)
	SupplierManager.reset()
	var rival_probe: Dictionary = MarketManager.competitors.get("CPU", [])[1]
	rival_probe["ai_research_drive"] = 100.0
	rival_probe["ai_growth_drive"] = 100.0
	rival_probe["ai_adaptability"] = 100.0
	rival_probe["ai_financial_prudence"] = 0.0
	rival_probe["risk_tolerance"] = 100.0
	rival_probe["cash"] = 450000
	MarketManager._clear_competitor_sourcing(rival_probe)
	var rival_cash_before_sourcing := int(rival_probe.get("cash", 0))
	MarketManager._ensure_competitor_sourcing(rival_probe)
	var rival_sourcing_mode := str(rival_probe.get("ai_sourcing_mode", ""))
	if rival_sourcing_mode == "" or rival_sourcing_mode == "INTERNAL":
		return "Aggressive rival CEO did not select an available external technology strategy"
	if str(rival_probe.get("ai_supplier_id", "")).is_empty() or SupplierManager.rival_reservation_for(str(rival_probe.get("id", ""))).is_empty():
		return "Rival external sourcing did not reserve supplier capacity"
	if int(rival_probe.get("cash", 0)) >= rival_cash_before_sourcing:
		return "Rival external sourcing did not charge a real setup cost"
	if int(rival_probe.get("ai_supplier_monthly_fee", 0)) <= 0:
		return "Rival supplier contract has no recurring economic cost"
	if absf(float(rival_probe.get("ai_supplier_speed_factor", 1.0)) - 1.0) < 0.001 and absf(float(rival_probe.get("ai_supplier_knowledge_factor", 1.0)) - 1.0) < 0.001:
		return "Rival supplier strategy has no development trade-off"
	var rival_generation_before_sourcing := int(rival_probe.get("generation_index", 1))
	var rival_supplier_name := str(rival_probe.get("ai_supplier_name", ""))
	MarketManager._launch_competitor_generation(rival_probe)
	if int(rival_probe.get("generation_index", 1)) <= rival_generation_before_sourcing:
		return "Rival supplier-backed generation did not launch"
	if not SupplierManager.rival_reservation_for(str(rival_probe.get("id", ""))).is_empty():
		return "Rival supplier capacity was not released after generation launch"
	var rival_history: Array = rival_probe.get("history", [])
	if rival_history.is_empty() or str(rival_history[0].get("sourcing_mode", "")) != rival_sourcing_mode or str(rival_history[0].get("supplier_name", "")) != rival_supplier_name:
		return "Rival generation history lost its real supplier strategy"
	MarketManager.load_state(rival_sourcing_market_state)
	SupplierManager.load_state(rival_sourcing_supplier_state)

	var balanced_quote := SupplierManager.quote("LICENSE", license_supplier_a, "BALANCED")
	var supplier_market_probe := SupplierManager.get_state().duplicate(true)
	SupplierManager.suppliers[license_supplier_a]["market_cost_factor"] = 1.10
	var tighter_market_quote := SupplierManager.quote("LICENSE", license_supplier_a, "BALANCED")
	if int(tighter_market_quote.get("setup_cost", 0)) <= int(balanced_quote.get("setup_cost", 0)):
		return "Autonomous supplier commercial stance did not change a real future quote"
	SupplierManager.load_state(supplier_market_probe)
	balanced_quote = SupplierManager.quote("LICENSE", license_supplier_a, "BALANCED")
	var price_quote := SupplierManager.quote("LICENSE", license_supplier_a, "PRICE")
	if int(price_quote.get("setup_cost", 0)) >= int(balanced_quote.get("setup_cost", 0)):
		return "Price-priority negotiation did not reduce the supplier setup cost"
	if float(price_quote.get("speed_factor", 1.0)) >= float(balanced_quote.get("speed_factor", 1.0)):
		return "Price-priority negotiation did not trade speed for better pricing"

	var sourcing_research_state := ResearchManager.get_state().duplicate(true)
	var sourcing_economy_state := Economy.get_state().duplicate(true)
	var sourcing_supplier_state := SupplierManager.get_state().duplicate(true)
	var sourcing_cash_before := Economy.money
	var licensed_probe_started := ResearchManager.start_project(
		"Licence probe", "CPU", MarketManager.default_segment(), "LICENSE", "BALANCED", 20_000,
		CPU_DESIGN.default_design(), {}, {}, "GENERAL", license_supplier_a, "PRICE"
	)
	if not licensed_probe_started:
		return "Could not start a licensed CPU project with a selected technology supplier"
	var expected_license_setup := int(price_quote.get("setup_cost", 0))
	if Economy.money != sourcing_cash_before - expected_license_setup:
		return "Selected supplier setup cost was not charged at project start"
	var licensed_probe: Dictionary = ResearchManager.projects[-1]
	if str(licensed_probe.get("sourcing", {}).get("mode", "")) != "LICENSE" or float(licensed_probe.get("sourcing", {}).get("royalty_rate", 0.0)) <= 0.0:
		return "R&D project did not preserve its licensed sourcing terms"
	if str(licensed_probe.get("supplier_id", "")) != license_supplier_a or str(licensed_probe.get("negotiation", "")) != "PRICE":
		return "R&D project did not preserve the chosen supplier and negotiated terms"
	var supplier_contract_id := str(licensed_probe.get("supplier_contract_id", ""))
	if supplier_contract_id.is_empty():
		return "External R&D project did not create a signed supplier contract"
	var signed_contract := SupplierManager.get_contract(supplier_contract_id)
	if str(signed_contract.get("status", "")) != "RND" or str(signed_contract.get("contract_term", "")) != "STANDARD":
		return "Signed supplier contract did not preserve its R&D status or duration"
	if str(signed_contract.get("ip_term", "")) != "SHARED" or str(signed_contract.get("exclusivity", "")) != "NONE":
		return "Signed supplier contract did not preserve default IP/exclusivity terms"
	var company_ip_quote := SupplierManager.contract_quote("LICENSE", license_supplier_a, "BALANCED", "STANDARD", "NONE", "COMPANY", "NONE")
	var shared_ip_quote := SupplierManager.contract_quote("LICENSE", license_supplier_a, "BALANCED", "STANDARD", "NONE", "SHARED", "NONE")
	if float(company_ip_quote.get("ip_ownership", 0.0)) <= float(shared_ip_quote.get("ip_ownership", 0.0)) or int(company_ip_quote.get("setup_cost", 0)) <= int(shared_ip_quote.get("setup_cost", 0)):
		return "Demanding more supplier-contract IP did not increase both ownership and negotiation cost"
	var volume_quote := SupplierManager.contract_quote("LICENSE", license_supplier_a, "BALANCED", "STANDARD", "NONE", "SHARED", "MEDIUM")
	if int(volume_quote.get("guaranteed_units", 0)) <= 0 or float(volume_quote.get("unit_cost_factor", 1.0)) >= float(shared_ip_quote.get("unit_cost_factor", 1.0)):
		return "Guaranteed supplier volume did not create a real unit-cost concession"
	var committed_supplier := SupplierManager.get_supplier(license_supplier_a)
	if not committed_supplier.get("active_project_ids", []).has(str(licensed_probe.get("id", ""))):
		return "Selected technology supplier did not reserve capacity for the R&D project"
	var trust_before_completion := float(committed_supplier.get("trust", 0.0))
	SupplierManager.complete_project(licensed_probe)
	signed_contract = SupplierManager.get_contract(supplier_contract_id)
	if str(signed_contract.get("status", "")) != "COMMERCIAL" or int(signed_contract.get("remaining_months", 0)) != int(signed_contract.get("duration_months", -1)):
		return "Supplier contract did not begin its commercial term after R&D completion"
	if float(SupplierManager.get_supplier(license_supplier_a).get("trust", 0.0)) <= trust_before_completion:
		return "Successful supplier relationship did not build trust"
	var renegotiated := SupplierManager.renegotiate_contract(supplier_contract_id, "BALANCED", "LONG", "TECHNOLOGY", "COMPANY", "MEDIUM")
	if renegotiated.is_empty() or not bool(renegotiated.get("accepted", false)):
		return "Established supplier relationship could not renegotiate a reasonable long-term contract"
	if str(renegotiated.get("exclusivity", "")) != "TECHNOLOGY" or int(renegotiated.get("guaranteed_units", 0)) != 2000:
		return "Supplier contract renegotiation did not persist exclusivity and volume terms"
	var blocked_other_supplier := SupplierManager.contract_quote("LICENSE", license_supplier_b, "BALANCED", "STANDARD", "NONE", "SHARED", "NONE")
	if bool(blocked_other_supplier.get("accepted", true)):
		return "Technology exclusivity did not block signing the same licensed technology with another supplier"
	SupplierManager.record_product_sales(supplier_contract_id, 500)
	if int(SupplierManager.get_contract(supplier_contract_id).get("units_delivered", 0)) != 500:
		return "Supplier contract did not record commercial units against its volume commitment"
	var contract_roundtrip := SupplierManager.get_state().duplicate(true)
	SupplierManager.load_state(contract_roundtrip)
	if str(SupplierManager.get_contract(supplier_contract_id).get("id", "")) != supplier_contract_id:
		return "Supplier contracts did not survive a save-state round-trip"
	var break_contract_before := SupplierManager.get_contract(supplier_contract_id)
	var break_penalty := int(break_contract_before.get("termination_penalty", 0))
	var cash_before_break := Economy.money
	var trust_before_break := float(SupplierManager.get_supplier(license_supplier_a).get("trust", 0.0))
	if not SupplierManager.break_contract(supplier_contract_id):
		return "Commercial supplier contract could not be broken when the company could afford its penalty"
	if str(SupplierManager.get_contract(supplier_contract_id).get("status", "")) != "TERMINATED" or Economy.money > cash_before_break - break_penalty:
		return "Supplier contract break did not apply its termination state and financial penalty"
	if float(SupplierManager.get_supplier(license_supplier_a).get("trust", 0.0)) >= trust_before_break:
		return "Breaking a supplier contract did not damage trust"
	var purchased_quote := SupplierManager.quote("PURCHASE", SupplierManager.recommended_supplier("PURCHASE"), "BALANCED")
	if ProductManager._base_unit_cost({"sector":"CPU","approach":"PURCHASE","sourcing":purchased_quote,"cpu_design":CPU_DESIGN.default_design(),"final_metrics":{"reliability":60.0}}) <= ProductManager._base_unit_cost({"sector":"CPU","approach":"INTERNAL","cpu_design":CPU_DESIGN.default_design(),"final_metrics":{"reliability":60.0}}):
		return "Purchased supplier technology did not create the expected per-unit sourcing cost premium"
	ResearchManager.load_state(sourcing_research_state)
	Economy.load_state(sourcing_economy_state)
	SupplierManager.load_state(sourcing_supplier_state)

	var expiry_contract := SupplierManager.sign_contract("EXPIRY-PROBE", "LICENSE", license_supplier_a, "BALANCED", "SHORT", "NONE", "SHARED", "MEDIUM")
	if expiry_contract.is_empty():
		return "Could not create a supplier contract for expiry/volume testing"
	var expiry_project := {"id":"EXPIRY-PROBE","name":"Expiry probe","supplier_id":license_supplier_a,"supplier_contract_id":str(expiry_contract.get("id", ""))}
	SupplierManager.complete_project(expiry_project)
	var expiry_id := str(expiry_contract.get("id", ""))
	SupplierManager.contracts[expiry_id]["remaining_months"] = 1
	var cash_before_expiry := Economy.money
	SupplierManager.process_month()
	if str(SupplierManager.get_contract(expiry_id).get("status", "")) != "EXPIRED" or Economy.money >= cash_before_expiry:
		return "Supplier contract expiry did not penalize an unmet guaranteed volume"
	SupplierManager.load_state(sourcing_supplier_state)
	Economy.load_state(sourcing_economy_state)


	return ""
