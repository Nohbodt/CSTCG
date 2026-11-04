class_name PackOpening
extends VBoxContainer
## Runs presentation against already committed Game.pending_pack contents.

signal finished(destination: int)
signal inspect_card(card_id: String)

const U = preload("res://scripts/ui.gd")
const C = preload("res://scripts/catalog.gd")
const Stage = preload("res://scripts/presentation/collectible_stage.gd")

var reduced_motion = false
var use_3d = true
var sound_enabled = true
var start_sealed = true
var stage: Control
var names: HBoxContainer
var actions: HBoxContainer
var status: Label
var footer: Label
var pack_id = "contender"
var transition = false

func _ready() -> void:
	name = "PackOpening"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)
	var pending = Game.data.pending_pack
	pack_id = pending.pack_id
	var pack = C.PACKS[pack_id]
	var top = U.hbox(10)
	top.add_child(U.label(pack.name + " / PACK ROOM", 22, U.TEXT, true))
	top.add_child(U.spacer())
	top.add_child(U.badge("PREMIUM FOIL" if pack.get("flair", 0) > 0 else "PLAYER PACK", pack.color))
	add_child(top)
	status = U.label("", 12, U.MUTED)
	add_child(status)
	stage = Stage.new()
	stage.name = "CollectibleStage"
	stage.mode = "opening"
	stage.pack_id = pack_id
	stage.cards = pending.cards.duplicate()
	stage.new_flags = pending.new_flags.duplicate()
	stage.revealed = int(pending.revealed)
	stage.sealed = start_sealed and pending.revealed == 0
	stage.reduced_motion = reduced_motion
	stage.use_3d = use_3d
	stage.sound_enabled = sound_enabled
	stage.custom_minimum_size.y = 260 if get_viewport_rect().size.y < 820 else 345
	stage.animation_finished.connect(_animation_done)
	add_child(stage)
	names = U.hbox(8)
	add_child(names)
	actions = U.hbox(10)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(actions)
	footer = U.paragraph("", 11)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(footer)
	_sync()

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _sync() -> void:
	if not is_inside_tree() or Game.data.pending_pack.is_empty():
		return
	var pending = Game.data.pending_pack
	var pack = C.PACKS[pack_id]
	_clear(names)
	_clear(actions)
	status.text = "%s  /  %d PLAYER CARDS  /  %d OF %d REVEALED" % [pack.guarantee, pending.cards.size(), stage.revealed, pending.cards.size()]
	if transition:
		status.text = ("SPECTRAL CHARGE / " if pack.get("flair", 0) > 0 else "BREAKING THE SEAL / ") + "Your cards are secured."
		actions.add_child(U.button("Skip animation", stage.skip_animation))
		footer.text = "Escape closes this opening. Your cards and reveal progress are preserved."
		return
	if stage.sealed:
		actions.add_child(U.button("Tear open   →", _tear, true))
		footer.text = "Your cards are already secured. Close and resume whenever you like."
		return
	for i in range(pending.cards.size()):
		var index = i
		var shown = i < stage.revealed
		var card = C.card(pending.cards[i])
		var label = card.handle if shown else "%02d / SEALED" % (i + 1)
		var button = U.button(label, func(): inspect_card.emit(pending.cards[index]))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 12)
		button.disabled = not shown
		button.tooltip_text = ("NEW SIGNING · " if pending.new_flags[i] else "DUPLICATE · ") + "Inspect " + card.handle if shown else "Reveal this card to inspect it."
		names.add_child(button)
	if pending.revealed < pending.cards.size():
		actions.add_child(U.button("Reveal card %d / %d   →" % [pending.revealed + 1, pending.cards.size()], func(): _reveal(false), true))
		actions.add_child(U.button("Reveal all", func(): _reveal(true)))
		footer.text = "The last slot is guaranteed. Every concealed sleeve uses the same finish."
	else:
		actions.add_child(U.button("Build your five   →", func(): finished.emit(1), true))
		actions.add_child(U.button("Back to pack room", func(): finished.emit(2)))
		footer.text = "%d new signings · %d duplicates. Inspect a card to compare it with your starting player." % [pending.new_flags.count(true), pending.new_flags.count(false)]

func _tear() -> void:
	if transition:
		return
	transition = true
	_sync()
	stage.play_open()

func _reveal(all_cards: bool) -> void:
	if transition:
		return
	if not Game.reveal_cards(all_cards):
		footer.text = Game.last_error if not Game.last_error.is_empty() else "The reveal could not be saved. Try again."
		return
	transition = true
	_sync()
	stage.reveal_to(int(Game.data.pending_pack.revealed))

func _animation_done(_kind: String) -> void:
	transition = false
	_sync()
	# Keep keyboard navigation at the next action when controls are replaced.
	if actions.get_child_count() > 0:
		call_deferred("_focus_action", weakref(actions.get_child(0)))

func _focus_action(reference: WeakRef) -> void:
	var target = reference.get_ref()
	if is_instance_valid(target) and target.is_inside_tree():
		target.grab_focus()
