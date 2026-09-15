shader_type canvas_item;
uniform float realm = 0.0;
uniform vec4 realm_tint : source_color = vec4(1.0,0.3,0.12,1.0);
uniform float clock = 0.0;
uniform float shock = 0.0;
uniform vec2 impact_point=vec2(.7,.7);
float hash21(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);}
float fbm(vec2 p){float v=0.0;float a=.5;for(int i=0;i<4;i++){v+=a*noise(p);p=p*2.03+vec2(7.1,4.2);a*=.5;}return v;}
void fragment(){
 vec2 uv=UV;
 uv.x+=sin(uv.y*18.0+clock*1.5)*0.002*realm;
 vec2 delta=uv-impact_point;
 uv+=normalize(delta+vec2(.0001))*sin(length(delta)*80.0-clock*12.0)*shock*.003;
 vec4 base=texture(TEXTURE,uv);
 float gray=dot(base.rgb,vec3(0.299,0.587,0.114));
 vec3 changed=mix(vec3(gray)*0.25,base.rgb*realm_tint.rgb*1.8,0.6);
 float moon=exp(-length((uv-vec2(.39,.105))*vec2(1.0,.57))*15.0);
 float floor_light=exp(-length((uv-vec2(.66,.71))*vec2(1.0,.55))*8.0);
 changed+=realm_tint.rgb*(moon*.8+floor_light*.3);
 vec3 final_color=mix(base.rgb,changed,realm);
 vec2 sky=uv-vec2(.48,.18);
 float angle=atan(sky.y*.65,sky.x);
 float radius=length(sky*vec2(1.0,.65));
 vec2 swirl=vec2(angle*1.8+clock*.23+radius*10.0,radius*17.0-clock*.12);
 float clouds=smoothstep(.35,.78,fbm(swirl));
 float sky_mask=(1.0-smoothstep(.32,.51,uv.y))*smoothstep(.04,.12,radius);
 final_color=mix(final_color,vec3(.02,.025,.05)+realm_tint.rgb*clouds*.17,sky_mask*clouds*(.08+realm*.68));
 float cloud_edge=smoothstep(.64,.72,fbm(swirl+vec2(.02,.02)))*sky_mask;
 final_color+=realm_tint.rgb*cloud_edge*realm*.12;
 COLOR=vec4(final_color,base.a);
}
