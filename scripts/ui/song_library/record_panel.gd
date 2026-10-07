extends PanelContainer

const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")

func set_record_available(available: bool) -> void:
	var cluster := $RecordMargin/AlbumFlowScoreCluster
	cluster.get_node("AlbumFlowRecordMetrics").visible = available
	cluster.get_node("BreakdownRule").visible = available
	cluster.get_node("EmptyRecord").visible = not available
	cluster.get_node("EmptyRecordHint").visible = not available

func _ready() -> void:
	$RecordMargin/AlbumFlowScoreCluster/EmptyRecord.set_meta("album_role", "empty_record")
	$RecordMargin/AlbumFlowScoreCluster/EmptyRecordHint.set_meta("album_role", "empty_record_hint")
	MinimalThemeScript.apply_body($RecordMargin/AlbumFlowScoreCluster/EmptyRecord, 24, Color(MinimalThemeScript.TEXT, 0.72))
	MinimalThemeScript.apply_body($RecordMargin/AlbumFlowScoreCluster/EmptyRecordHint, 13, MinimalThemeScript.MUTED)
	var caption := $RecordMargin/AlbumFlowScoreCluster/RecordTitleRow/BestCaption as Label
	caption.set_meta("album_role", "caption")
	var record_date := $RecordMargin/AlbumFlowScoreCluster/RecordTitleRow/RecordDate as Label
	record_date.set_meta("album_role", "record_date")
	var combo := $RecordMargin/AlbumFlowScoreCluster/BestComboValue as Label
	combo.set_meta("album_role", "combo_value")

	var accuracy_caption := $RecordMargin/AlbumFlowScoreCluster/AlbumFlowRecordMetrics/AccuracyStack/AccuracyCaption as Label
	accuracy_caption.set_meta("album_role", "metric_caption")
	var accuracy_value := $RecordMargin/AlbumFlowScoreCluster/AlbumFlowRecordMetrics/AccuracyStack/BestAccuracyValue as Label
	accuracy_value.set_meta("album_role", "accuracy_value")
	var score_caption := $RecordMargin/AlbumFlowScoreCluster/AlbumFlowRecordMetrics/ScoreStack/ScoreCaption as Label
	score_caption.set_meta("album_role", "metric_caption")
	var score_value := $RecordMargin/AlbumFlowScoreCluster/AlbumFlowRecordMetrics/ScoreStack/BestScoreValue as Label
	score_value.set_meta("album_role", "score_value")
	var rank_value := $RecordMargin/AlbumFlowScoreCluster/AlbumFlowRecordMetrics/AlbumFlowBestCard/BestMargin/BestRankValue as Label
	rank_value.set_meta("album_role", "rank")
	var rank_diamond := $RecordMargin/AlbumFlowScoreCluster/AlbumFlowRecordMetrics/AlbumFlowBestCard/RankDiamond as Control
	rank_diamond.set("kind", "rank")
	rank_diamond.set("ink", MinimalThemeScript.GOLD)

	_setup_judgement("PerfectCell", MinimalThemeScript.PERFECT_PINK)
	_setup_judgement("GreatCell", MinimalThemeScript.SUCCESS)
	_setup_judgement("GoodCell", MinimalThemeScript.GOOD_CYAN)
	_setup_judgement("MissCell", MinimalThemeScript.DANGER)

func _setup_judgement(cell_name: String, color: Color) -> void:
	var cell := $RecordMargin/AlbumFlowScoreCluster/AlbumFlowJudgementBreakdown.get_node(cell_name)
	var caption := cell.get_node("Caption") as Label
	var value := cell.get_node("Value") as Label
	caption.set_meta("album_role", "judgement_caption")
	caption.set_meta("judgement_color", color)
	value.set_meta("album_role", "judgement_value")
	value.set_meta("judgement_color", color)
	MinimalThemeScript.apply_mono(caption, 9, Color(MinimalThemeScript.TEXT, 0.52))
	MinimalThemeScript.apply_numeric(value, 20, color)
