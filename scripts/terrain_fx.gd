extends Node2D

# The previous geometric cracks/debris failed the same-screen art quality gate.
# Retain impact distortion; archive scar drawing until textured art passes review.
const SCAR_ART_APPROVED := false

var scars: Array=[]
var age:=0.0
var shock:=0.0
var point:=Vector2(.7,.7)

func reset() -> void:
	scars.clear();shock=0
	queue_redraw()

func hit(kind: String,targets: Array[Vector2],ultimate: bool) -> void:
	if targets.is_empty():return
	var center:=Vector2.ZERO
	for p in targets:center+=p
	center/=targets.size()
	point=center/Vector2(1280,720)
	var gentle:=kind in ["heal","shield","moonbolt"]
	if gentle:return
	shock=1.0 if ultimate else .26
	if not SCAR_ART_APPROVED:return
	var cracks: Array=[]
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash(str(center)+str(scars.size()))
	for branch in range(10 if ultimate else 4):
		var direction:=Vector2.from_angle(branch*TAU/(10 if ultimate else 4)+rng.randf_range(-.2,.2))
		var path:=PackedVector2Array([Vector2.ZERO])
		for i in range(1,7):
			var p:=direction*i*(35 if ultimate else 12)+direction.orthogonal()*rng.randf_range(-14,14)
			path.append(Vector2(p.x,p.y*.3))
		cracks.append(path)
	var tint:=Color("ec7650") if kind in ["fire","raven_fire"] else Color("9981d4")
	if kind in ["slash","dragon"]:tint=Color("98b8df")
	scars.append({"p":center,"cracks":cracks,"age":0.0,"tint":tint,"ultimate":ultimate})
	if scars.size()>7:scars.pop_front()

func _process(delta: float) -> void:
	age+=delta
	shock=move_toward(shock,0,delta*2.5)
	for scar in scars:scar.age+=delta
	scars=scars.filter(func(s):return s.age<9.0)
	queue_redraw()

func _draw() -> void:
	for scar in scars:
		var t: float=scar.age
		var alpha:=clampf((9-t)/3,0,1)
		var spread:=clampf(t*7,0,1)
		var c: Color=scar.tint
		for branch in scar.cracks:
			var path:=PackedVector2Array()
			for q in branch:path.append(scar.p+q*spread)
			draw_polyline(path,Color(.015,.013,.025,alpha*.88),6 if scar.ultimate else 3,true)
			draw_polyline(path,Color(c.r,c.g,c.b,alpha*maxf(.07,exp(-t*1.2))*.7),1.5,true)
		if t<1.7:
			var ring:=PackedVector2Array()
			for i in range(65):ring.append(scar.p+Vector2(cos(i*TAU/64),sin(i*TAU/64)*.27)*(40+t*(220 if scar.ultimate else 100)))
			draw_polyline(ring,Color(.68,.6,.56,(1-t/1.7)*.4),10*(1-t/1.7)+1,true)
		if scar.ultimate and t<1.2:
			for i in range(16):
				var direction:=Vector2.from_angle(i*2.399)
				var q: Vector2=scar.p+Vector2(direction.x*175*t,direction.y*42*t-abs(sin(t*PI/1.2))*50)
				var s:=3+float(i%4)*2
				draw_colored_polygon(PackedVector2Array([q+Vector2(-s,0),q+Vector2(-s*.3,-s),q+Vector2(s,-s*.6),q+Vector2(s*.6,s*.4)]),Color(.12,.13,.16,1-t/1.2))
				draw_line(q+Vector2(-s*.3,-s),q+Vector2(s,-s*.6),Color(.52,.44,.39,1-t/1.2),1,true)
