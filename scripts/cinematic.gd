extends Node2D

var face: Font
var portrait: Texture2D
var crop:=Rect2()
var label:=""
var tint:=Color.WHITE
var age:=0.0
var playing:=false
var realm:=0.0
var realm_kind:="fire"
var duration:=.85

func start(texture: Texture2D,region: Rect2,title: String,color: Color) -> void:
	portrait=texture;crop=region;label=title;tint=color;age=0;playing=true
	show()
	await get_tree().create_timer(duration).timeout
	playing=false
	queue_redraw()

func _process(delta: float) -> void:
	if playing:age+=delta
	queue_redraw()

func _draw() -> void:
	if not playing:return
	var fade:=minf(age*8,(duration-age)*8)
	fade=clampf(fade,0,1)
	var slide:=pow(1-clampf(age*4,0,1),3)*-330
	draw_rect(Rect2(0,95,1280,440),Color(.015,.018,.04,fade*.83))
	for i in range(26):
		var y:=140+float(i)*14
		draw_line(Vector2(fmod(i*187+age*950,1500)-200,y),Vector2(fmod(i*187+age*950,1500)+120,y-65),Color(tint.r,tint.g,tint.b,fade*.17),2,true)
	draw_colored_polygon(PackedVector2Array([Vector2(0,95),Vector2(530,95),Vector2(330,535),Vector2(0,535)]),Color(tint.r*.2,tint.g*.15,tint.b*.15,fade))
	if portrait!=null:
		var h:=440.0
		draw_texture_rect_region(portrait,Rect2(80+slide,97,crop.size.x/crop.size.y*h,h),crop,Color(1,1,1,fade))
	draw_line(Vector2(0,95),Vector2(1280,95),Color(tint.r,tint.g,tint.b,fade),2,true)
	draw_line(Vector2(0,535),Vector2(1280,535),Color(tint.r,tint.g,tint.b,fade),2,true)
	draw_string(face,Vector2(720-slide*.35,275),"秘  技  ·  解  放",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color(tint.r,tint.g,tint.b,fade))
	draw_string_outline(face,Vector2(715-slide*.3,347),label,HORIZONTAL_ALIGNMENT_LEFT,-1,47,6,Color(0,0,0,fade))
	draw_string(face,Vector2(715-slide*.3,347),label,HORIZONTAL_ALIGNMENT_LEFT,-1,47,Color(tint.r,tint.g,tint.b,fade))
	draw_line(Vector2(720,374),Vector2(1140,374),Color(tint.r,tint.g,tint.b,fade),2,true)
