extends Control

## Вертикальная шкала силы броска. Растёт от вертикального драга по мячу
## (см. Ball.gd). Fill — дочерний ColorRect с анкорами 0..1 от родителя.

@onready var fill: ColorRect = $Fill
@onready var percent_label: Label = $PercentLabel


func show_meter() -> void:
	visible = true
	set_power(0.0)


func hide_meter() -> void:
	visible = false


func set_power(power: float) -> void:
	var clamped := clampf(power, 0.0, 1.0)
	fill.anchor_top = 1.0 - clamped
	percent_label.text = "%d%%" % int(round(clamped * 100.0))
