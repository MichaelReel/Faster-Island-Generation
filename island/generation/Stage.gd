class_name Stage
extends Object
"""
Base interface for each stage
"""

signal percent_complete(stage, percent)

func perform() -> void:
	pass
