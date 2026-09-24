extends RefCounted

static func monthly_progress(
	team: float,
	technology: float,
	budget_ratio: float,
	approach_speed: float,
	sourcing_speed: float,
	supplier_execution: float,
	management: float,
	complexity: float
) -> float:
	var progress := (15.0 + team * 0.34 + budget_ratio * 18.0 + technology * 0.08)
	progress *= approach_speed * sourcing_speed * supplier_execution * management
	var complexity_factor := lerpf(0.86, 1.28, clampf(complexity / 100.0, 0.0, 1.0))
	progress /= complexity_factor
	return maxf(progress, 0.01)

static func estimated_months_from_progress(progress_per_month: float, phase_count: int = 6) -> int:
	var phases := maxi(phase_count, 1)
	var progress := maxf(progress_per_month, 0.01)
	var phase_progress := 0.0
	var completed := 0
	var months := 0
	while completed < phases and months < 240:
		phase_progress += progress
		months += 1
		if phase_progress >= 100.0:
			phase_progress -= 100.0
			completed += 1
	return maxi(months, phases)

static func estimated_months(
	team: float,
	technology: float,
	budget_ratio: float,
	approach_speed: float,
	sourcing_speed: float,
	management: float,
	complexity: float,
	extra_months: int = 0,
	phase_count: int = 6
) -> int:
	var progress := monthly_progress(
		team,
		technology,
		budget_ratio,
		approach_speed,
		sourcing_speed,
		1.0,
		management,
		complexity
	)
	return estimated_months_from_progress(progress, phase_count) + maxi(extra_months, 0)

static func estimated_program_cost(
	months: int,
	monthly_charged_cost: int,
	setup_charged_cost: int = 0,
	upfront_charged_cost: int = 0
) -> int:
	return maxi(months, 0) * maxi(monthly_charged_cost, 0) + maxi(setup_charged_cost, 0) + maxi(upfront_charged_cost, 0)
