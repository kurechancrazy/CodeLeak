extends GutTest


func test_default_wave_number_is_one() -> void:
	var wave: WaveData = WaveData.new()
	assert_eq(wave.wave_number, 1)


func test_default_spawn_count_is_ten() -> void:
	var wave: WaveData = WaveData.new()
	assert_eq(wave.spawn_count, 10)


func test_default_spawn_interval() -> void:
	var wave: WaveData = WaveData.new()
	assert_almost_eq(wave.spawn_interval, 1.5, 0.001)


func test_default_boss_id_is_empty() -> void:
	var wave: WaveData = WaveData.new()
	assert_eq(wave.boss_id, "")


func test_default_enemy_ids_is_empty() -> void:
	var wave: WaveData = WaveData.new()
	assert_eq(wave.enemy_ids.size(), 0)


func test_set_properties() -> void:
	var wave: WaveData = WaveData.new()
	wave.wave_number = 5
	wave.spawn_count = 20
	wave.boss_id = "boss_dragon"
	assert_eq(wave.wave_number, 5)
	assert_eq(wave.spawn_count, 20)
	assert_eq(wave.boss_id, "boss_dragon")
