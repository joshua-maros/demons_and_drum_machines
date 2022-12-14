extends Spatial

const Cassette = preload("res://scenes/objects/cassette/Cassette.gd")
const SnappyAnimTimer = preload("res://scripts/animation/SnappyAnimTimer.gd")

export var screen_mat: ShaderMaterial
var source_data: Array = []
var last_start_beat = 64
var end = 0.0
var wheel_readout_source = SnappyAnimTimer.new()

func _process(delta):
	update_knob_limits()
	update_screen()
	stop_if_past_end()
	var should_play = $PlaybackSwitch.activated and source() != null
	if should_play and not $Player.playing:
		play()
	if not should_play and $Player.playing:
		stop()
	update_slot_locks()
	update_wheels(delta)
	animate_cassettes()

# Called when the node enters the scene tree for the first time.
func _ready():
	$DurationKnob.target_value = 4.0

func snapping():
	if $DurationKnob.get_target_value() > 8.0:
		return 0.5
	else:
		return 0.25

func snap(value):
	return round(value / snapping()) * snapping()

func source() -> Cassette:
	return $InputSlot.get_cassette()

func source_beats() -> float:
	if source() != null:
		return source().audio.beats()
	else:
		return 9e9

func source_duration() -> float:
	if source() != null:
		return source().audio.duration()
	else:
		return 0.0

func animate_cassettes():
	var spin = $PlaybackSwitch.activated
	if $InputSlot.get_cassette() != null:
		$InputSlot.get_cassette().spin = spin
	if $OutputSlot.get_cassette() != null:
		$OutputSlot.get_cassette().spin = spin

func update_knob_limits():
	$StartKnob.set_range(0.0, source_beats() - 0.25)
	$StartKnob.set_snapping(snapping())
	$DurationKnob.set_range(0.25, min(source_beats() - $StartKnob.target_value, 16.0))
	$DurationKnob.set_snapping(snapping())

func update_slot_locks():
	$InputSlot.locked = $PlaybackSwitch.activated
	$OutputSlot.locked = $PlaybackSwitch.activated

func wheel_div_10(original_angle: float) -> float:
	var divided = original_angle / 10.0
	var fractional_part = fmod(divided, 36.0)
	var end_buffer = 3.6
	if fractional_part < (36.0 - end_buffer):
		return divided - fractional_part
	else:
		return divided - fractional_part + 36.0 * (fractional_part - 36 + end_buffer) / end_buffer

func update_wheels(delta):
	var position = $StartKnob.get_display_value()
	if $PlaybackSwitch.activated:
		wheel_readout_source.process(1.0, true)
		position = position_to_beat($Player.get_playback_position())
	else:
		wheel_readout_source.snappiness = -1.5
		var progress = wheel_readout_source.process(delta, false)
		position = lerp(position, end, progress)
	var x = position * 360.0
	x = wheel_div_10(x)
	$NumWheel1.rotation_degrees.x = 18 + x
	x = wheel_div_10(x)
	$NumWheel2.rotation_degrees.x = 18 + x
	x = wheel_div_10(x)
	$NumWheel3.rotation_degrees.x = 18 + x

func update_screen():
	screen_mat.set_shader_param("Start", snap($StartKnob.get_display_value()))
	screen_mat.set_shader_param("Duration", snap($DurationKnob.target_value))

func stop():
	end = position_to_beat($Player.get_playback_position())
	var exact_end = last_start_beat + $DurationKnob.get_target_value()
	if abs(beat_to_position(end) - beat_to_position(exact_end)) <= 0.1:
		end = exact_end
	if $InputSlot.get_cassette() != null and $OutputSlot.get_cassette() != null:
		$OutputSlot.get_cassette().audio \
			= $InputSlot.get_cassette().audio.trim(last_start_beat, end)
	$Player.stop()
	$Player.seek(0.0)
	$PlaybackSwitch.deactivate()

func stop_if_past_end():
	var end = beat_to_position(last_start_beat + $DurationKnob.get_target_value())
	# Stop it slightly early so we don't overshoot and play part of the next
	# beat, which will not show up in the recording.
	var buffer = 0.1
	if $DurationKnob.get_target_value() < 1.0:
		buffer = 0.05
	var past_end = $Player.get_playback_position() >= min(end, source_duration()) - buffer
	if past_end and $PlaybackSwitch.activated:
		stop()

func play():
	source().audio.play_audio($Player)
	last_start_beat = $StartKnob.get_target_value()
	$Player.play(beat_to_position(last_start_beat))

func beat_to_position(beat: float):
	if source() == null:
		return 0
	else:
		return beat * source().audio.beat_time() + source().audio.start_time()

func position_to_beat(position: float):
	if source() == null:
		return 0
	else:
		return (position - source().audio.start_time()) / source().audio.beat_time()

func _on_InputSlot_inserted(obj):
	$StartKnob.set_animated(0.0)
