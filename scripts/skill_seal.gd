extends Button

var face: Font
var skill_name := ""
var kind := "slash"
var cost := 0
var hotkey := 1
var chosen := false

func _ready() -> void:
	focus_mode=Control.FOCUS_NONE
	for state in ["normal","hover","pressed","disabled","focus"]:
		add_theme_stylebox_override(state,StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)

func _draw() -> void:
	var p:=Vector2(size.x/2,43)
	var c:=Color("efc78b")
	match kind:
		"fire":c=Color("ff914f")
		"heal":c=Color("91e8c5")
		"shield":c=Color("97c9ff")
		"stun":c=Color("e7be7b")
		"boss":c=Color("c69cff")
	if disabled:c=c.darkened(.58)
	draw_circle(p,43,Color("090f1b"))
	draw_circle(p,38,Color(c.r*.12,c.g*.12,c.b*.12))
	draw_arc(p,42,0,TAU,72,c,3 if chosen else 1.5,true)
	draw_arc(p,35,-PI*.7,PI*.5,48,Color(c.r,c.g,c.b,.5),1,true)
	if chosen or is_hovered():draw_arc(p,47,-PI*.9,PI*.85,64,c,2,true)
	match kind:
		"fire":
			for s in [-1,1]:
				for i in range(5):
					var a:=p+Vector2(s*float(4+i*5),float(-15+i*5))
					draw_colored_polygon(PackedVector2Array([p+Vector2(0,13),a+Vector2(s*10,-13),a+Vector2(s*5,12)]),Color(c.r,c.g,c.b,.8-i*.08))
			draw_circle(p+Vector2(0,-8),5,c)
		"heal","shield":
			draw_arc(p,21,-PI*.85,PI*.6,48,c,4,true)
			for i in range(5):
				var q:=p+Vector2.from_angle(i*TAU/5)*12
				draw_colored_polygon(PackedVector2Array([p,q+Vector2(-4,-10),q+Vector2(4,-10)]),c)
			draw_circle(p,4,Color("fff4d3"))
		"stun":
			draw_set_transform(p,-.22)
			draw_rect(Rect2(-11,-23,22,46),c)
			for i in range(4):draw_line(Vector2(-6,-14+i*8),Vector2(6,-10+i*8),Color("7b293c"),2,true)
			draw_set_transform(Vector2.ZERO)
		_:
			draw_colored_polygon(PackedVector2Array([p+Vector2(-17,21),p+Vector2(-10,6),p+Vector2(25,-24),p+Vector2(8,9)]),c)
			draw_line(p+Vector2(-19,3),p+Vector2(-1,20),c,4,true)
			draw_arc(p,25,-1.8,.5,32,Color(c.r,c.g,c.b,.5),2,true)
	var f: Font=face if face!=null else ThemeDB.fallback_font
	var label_size:=f.get_string_size(skill_name,HORIZONTAL_ALIGNMENT_LEFT,-1,16)
	draw_string_outline(f,Vector2(p.x-label_size.x/2,103),skill_name,HORIZONTAL_ALIGNMENT_LEFT,-1,16,4,Color("080e1a"))
	draw_string(f,Vector2(p.x-label_size.x/2,103),skill_name,HORIZONTAL_ALIGNMENT_LEFT,-1,16,c)
	draw_circle(p+Vector2(33,28),12,Color("102333"))
	draw_string(f,p+Vector2(28,33),str(cost),HORIZONTAL_ALIGNMENT_LEFT,-1,14,c)
	draw_string(f,p+Vector2(-39,-25),str(hotkey),HORIZONTAL_ALIGNMENT_LEFT,-1,12,c)
