"""Genera diagramas clásicos compartibles, con fuentes Mermaid y sin servicios externos.

Ejecutar: python docs/diseno/generar_flujos.py
Requiere Pillow únicamente para las imágenes PNG. SVG/HTML no usan JavaScript remoto.
Las posiciones se mantienen explícitas para que los recorridos y los retornos sean legibles.
"""
from pathlib import Path
from html import escape
import json
import math
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent / 'flujos'
OUT.mkdir(exist_ok=True)


def node(ident, label, x, y, kind='rect', width=340, height=100):
    return dict(id=ident, label=label, x=x, y=y, kind=kind, w=width, h=height)


def edge(a, b, points, label='', at=None):
    return dict(a=a, b=b, points=points, label=label, at=at)


diagrams = [
    dict(slug='01-acceso', title='1. Acceso y primer ingreso', width=1300, height=1860,
         note='Propuesta actual: registro por invitación, sin correo ni contraseña del estudiante. Recuperación pendiente.',
         nodes=[
             node('start', 'Inicio: abrir Cureando', 480, 100, 'round', 300, 64),
             node('session', '¿Sesión estudiantil\nválida?', 480, 240, 'diamond', 360, 130),
             node('welcome', 'E01 · Bienvenida\nQué hace la app y privacidad\nBotón: Entrar a mi centro', 480, 440, height=112),
             node('invite', 'E02 · Primer ingreso / registro\nCampo: invitación del centro\nBotón: Comprobar invitación', 480, 640, height=112),
             node('valid', '¿Invitación válida y\ncentro disponible?', 480, 840, 'diamond', 370, 140),
             node('invalid', 'Mostrar el problema\nRevisar invitación / Reintentar\nTambién puede ir a Ayuda', 1010, 840, width=350, height=112),
             node('school', 'E02 · Confirmar centro\nMostrar nombre encontrado\nBotón: Entrar a este centro', 480, 1050, height=112),
             node('recognize', '¿Reconoce el centro\ny confirma entrar?', 480, 1250, 'diamond', 370, 140),
             node('register', 'Activar acceso privado al centro\nCrear sesión sin nombre civil\nNo es un formulario adicional', 480, 1460, height=112),
             node('home', 'E03 · Inicio / Home\nContinuar al diagrama 2', 480, 1660, 'round', 340, 90),
             node('help', 'E09 · Ayuda sin iniciar sesión\nVolver a la pantalla anterior', 1010, 440, width=350, height=100),
         ], edges=[
             edge('start', 'session', [(480,132),(480,175)]),
             edge('session', 'welcome', [(480,305),(480,384)], 'No', (502,345)),
             edge('session', 'home', [(300,240),(90,240),(90,1660),(310,1660)], 'Sí: acceso habitual', (100,205)),
             edge('welcome', 'invite', [(480,496),(480,584)], 'Entrar', (500,545)),
             edge('welcome', 'help', [(650,440),(835,440)], 'Buscar ayuda', (675,415)),
             edge('invite', 'valid', [(480,696),(480,770)]),
             edge('valid', 'invalid', [(665,840),(835,840)], 'No', (735,818)),
             edge('invalid', 'invite', [(1010,784),(1010,640),(650,640)], 'Corregir', (1018,717)),
             edge('valid', 'school', [(480,910),(480,994)], 'Sí', (502,955)),
             edge('school', 'recognize', [(480,1106),(480,1180)]),
             edge('recognize', 'invite', [(295,1250),(170,1250),(170,640),(310,640)], 'No: otra invitación', (180,1170)),
             edge('recognize', 'register', [(480,1320),(480,1404)], 'Sí', (502,1360)),
             edge('register', 'home', [(480,1516),(480,1615)]),
         ]),
    dict(slug='02-distribucion', title='2. Distribución de la app del estudiante', width=1600, height=1330,
         note='Esta es la distribución de pantallas y navegación para diseño; no representa carpetas del código.',
         nodes=[
             node('home', 'E03 · Inicio / Home\nCentro + privacidad y sesión\nPedir apoyo + accesos principales', 800, 140, 'round', 440, 120),
             node('choice', '¿Qué quiere hacer?', 800, 360, 'diamond', 380, 130),
             node('report', 'Pedir apoyo · E04\nContar lo ocurrido\nContinuar al diagrama 3', 230, 600, width=310, height=110),
             node('reports', 'Mis reportes · E07\nLista propia: referencia, fecha,\nestado y respuesta nueva', 610, 600, width=310, height=110),
             node('help', 'Ayuda · E09\nRecursos locales verificados\nFuente, horario y contacto', 990, 600, width=310, height=110),
             node('care', 'Cuidarme · E10\nActividades opcionales\nTítulo y descripción breve', 1370, 600, width=310, height=110),
             node('detail', 'Seguimiento · E08\nEstado + relato + conversación\nEnviar mensaje de seguimiento', 610, 850, width=310, height=110),
             node('contact', 'Contacto externo\nConfirmar destino antes de\nllamar o abrir un sitio', 990, 850, width=310, height=110),
             node('activity', 'Actividad · E11\nInstrucciones revisadas\nTerminar o salir libremente', 1370, 850, width=310, height=110),
             node('back', 'Volver a Inicio / cambiar de sección\nBarra inferior: Inicio | Mis reportes | Ayuda | Cuidarme', 800, 1100, 'round', 850, 100),
         ], edges=[
             edge('home', 'choice', [(800,200),(800,295)]),
             edge('choice', 'report', [(610,360),(230,360),(230,545)], 'Reportar', (310,338)),
             edge('choice', 'reports', [(705,392),(610,460),(610,545)], 'Consultar', (590,485)),
             edge('choice', 'help', [(895,392),(990,460),(990,545)], 'Buscar ayuda', (1005,490)),
             edge('choice', 'care', [(990,360),(1370,360),(1370,545)], 'Autocuidado', (1140,338)),
             edge('report', 'back', [(230,655),(230,1100),(375,1100)], 'Al salir del recorrido', (45,1005)),
             edge('reports', 'detail', [(610,655),(610,795)], 'Abrir un reporte', (630,730)),
             edge('help', 'contact', [(990,655),(990,795)], 'Elegir recurso', (1005,730)),
             edge('care', 'activity', [(1370,655),(1370,795)], 'Elegir actividad', (1385,730)),
             edge('detail', 'back', [(610,905),(610,1050)]),
             edge('contact', 'back', [(990,905),(990,1050)]),
             edge('activity', 'back', [(1370,905),(1370,1100),(1225,1100)]),
         ]),
    dict(slug='03-reporte', title='3. Crear reporte y consultar respuesta', width=1400, height=2100,
         note='Si el envío no está confirmado, no mostrar éxito. Comprobar o reintentar sin duplicar el caso.',
         nodes=[
             node('start', 'Desde Inicio: Pedir apoyo', 480, 110, 'round', 380, 70),
             node('form', 'E04 · Contar lo ocurrido\nMe pasó / Lo presencié + relato\nLugar y momento: opcionales', 480, 300, width=400, height=120),
             node('complete', '¿Completó las opciones\ny el relato?', 480, 520, 'diamond', 400, 140),
             node('fix', 'Señalar lo que falta\nSin borrar el texto escrito', 1060, 520, width=360, height=100),
             node('review', 'E05 · Revisar reporte\nResumen + destinatario + horario\nBotones: Editar / Enviar reporte', 480, 760, width=400, height=120),
             node('confirm', '¿Confirma enviar?', 480, 980, 'diamond', 380, 130),
             node('send', 'Enviar reporte\nMostrar: Enviando…\nEvitar pulsaciones repetidas', 480, 1180, width=400, height=110),
             node('received', '¿Recepción confirmada?', 480, 1390, 'diamond', 420, 140),
             node('retry', 'Mostrar pendiente / error\nConservar texto en pantalla\nComprobar y reintentar', 1060, 1390, width=360, height=110),
             node('receipt', 'E06 · Reporte recibido\nReferencia + siguiente paso\nBotón: Ver seguimiento', 480, 1600, width=400, height=110),
             node('detail', 'E08 · Estado y conversación\nCon respuesta: leer y contestar\nSin respuesta: explicar la espera', 480, 1790, width=420, height=110),
             node('finish', 'Fin del recorrido\nVolver a Mis reportes o Inicio', 480, 1970, 'round', 420, 80),
         ], edges=[
             edge('start','form',[(480,145),(480,240)]),
             edge('form','complete',[(480,360),(480,450)]),
             edge('complete','fix',[(680,520),(880,520)],'No',(765,495)),
             edge('fix','form',[(1060,470),(1060,300),(680,300)],'Corregir',(1075,385)),
             edge('complete','review',[(480,590),(480,700)],'Sí',(502,640)),
             edge('review','confirm',[(480,820),(480,915)]),
             edge('confirm','form',[(290,980),(120,980),(120,300),(280,300)],'No: editar',(130,880)),
             edge('confirm','send',[(480,1045),(480,1125)],'Sí',(502,1090)),
             edge('send','received',[(480,1235),(480,1320)]),
             edge('received','retry',[(690,1390),(880,1390)],'No / incierto',(705,1365)),
             edge('retry','send',[(1060,1335),(1060,1180),(680,1180)],'Reintentar',(1075,1260)),
             edge('received','receipt',[(480,1460),(480,1545)],'Sí',(502,1500)),
             edge('receipt','detail',[(480,1655),(480,1735)]),
             edge('detail','finish',[(480,1845),(480,1930)]),
         ]),
    dict(slug='04-personal', title='4. Login y atención del personal', width=1400, height=1810,
         note='Cuenta asignada por la institución. No hay registro público del personal ni acceso a otros centros.',
         nodes=[
             node('start','E01: Acceso del personal',480,110,'round',380,70),
             node('login','R01 · Iniciar sesión\nCorreo institucional + contraseña\nBotón: Iniciar sesión',480,300,width=420,height=120),
             node('valid','¿Acceso validado y\ncuenta autorizada?',480,530,'diamond',420,150),
             node('error','Mostrar error de acceso\nCorregir / pedir ayuda al centro',1090,530,width=400,height=110),
             node('inbox','R02 · Bandeja autorizada\nCentro + filtros por estado\nReferencia, fecha y mensaje nuevo',480,770,width=420,height=120),
             node('cases','¿Hay un caso que abrir?',480,990,'diamond',420,140),
             node('empty','Mostrar bandeja vacía\nVolver o consultar más tarde',1090,990,width=400,height=110),
             node('case','R03 · Atender caso\nLeer relato y conversación\nResponder / registrar atención',480,1220,width=420,height=120),
             node('answer','Enviar respuesta visible\nActualizar estado con permiso\nNotas internas: sección separada',480,1430,width=420,height=120),
             node('student','E08 · El estudiante consulta\nSolo la respuesta visible\nNunca las notas internas',1090,1430,width=400,height=120),
             node('finish','Fin de la atención actual\nVolver a bandeja R02',480,1660,'round',420,90),
         ],edges=[
             edge('start','login',[(480,145),(480,240)]),
             edge('login','valid',[(480,360),(480,455)]),
             edge('valid','error',[(690,530),(890,530)],'No',(775,505)),
             edge('error','login',[(1090,475),(1090,300),(690,300)],'Reintentar',(1100,410)),
             edge('valid','inbox',[(480,605),(480,710)],'Sí',(502,655)),
             edge('inbox','cases',[(480,830),(480,920)]),
             edge('cases','empty',[(690,990),(890,990)],'No',(775,965)),
             edge('empty','inbox',[(1090,935),(1090,770),(690,770)],'Volver',(1100,860)),
             edge('cases','case',[(480,1060),(480,1160)],'Sí',(502,1110)),
             edge('case','answer',[(480,1280),(480,1370)]),
             edge('answer','student',[(690,1430),(890,1430)],'Si responde',(705,1405)),
             edge('answer','finish',[(480,1490),(480,1615)]),
         ]),
]


def font(size):
    for path in ['C:/Windows/Fonts/arial.ttf', '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf']:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default(size=size)


def render(d):
    width, height = d['width'], d['height']
    # Draw at twice the nominal size for crisp sharing and printing.
    scale = 2
    im = Image.new('RGB', (width * scale, height * scale), 'white')
    draw = ImageDraw.Draw(im)
    def xy(points):
        return [(int(x * scale), int(y * scale)) for x, y in points]
    svg = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="{width}" height="{height}" role="img" aria-labelledby="title"><title id="title">{escape(d["title"])}</title><rect width="100%" height="100%" fill="white"/>']
    def text(x, y, value, size=22, centered=False):
        # y is the vertical centre of the first line in both renderers.
        lines = value.split('\n')
        for i, line in enumerate(lines):
            yy = y + i * (size + 8)
            anchor = 'middle' if centered else 'start'
            svg.append(f'<text x="{x}" y="{yy}" text-anchor="{anchor}" dominant-baseline="middle" font-family="Arial,sans-serif" font-size="{size}" fill="black">{escape(line)}</text>')
            draw.text((x * scale, yy * scale), line, font=font(size * scale), fill='black', anchor='mm' if centered else 'lm')
    text(36, 34, d['title'], 27)
    for e in d['edges']:
        points = e['points']
        coords = ' '.join(f'{x},{y}' for x,y in points)
        svg.append(f'<polyline points="{coords}" fill="none" stroke="black" stroke-width="3"/>')
        draw.line(xy(points), fill='black', width=3 * scale, joint='curve')
        a, b = points[-2:]
        angle = math.atan2(b[1]-a[1], b[0]-a[0])
        tri = [b, (b[0]-15*math.cos(angle)+7*math.sin(angle), b[1]-15*math.sin(angle)-7*math.cos(angle)), (b[0]-15*math.cos(angle)-7*math.sin(angle), b[1]-15*math.sin(angle)+7*math.cos(angle))]
        svg.append('<polygon points="'+' '.join(f'{x},{y}' for x,y in tri)+'" fill="black"/>')
        draw.polygon(xy(tri), fill='black')
        if e['label']:
            text(*e['at'], e['label'], 20)
    for n in d['nodes']:
        x,y,w,h=n['x'],n['y'],n['w'],n['h']
        bounds=xy([(x-w/2,y-h/2),(x+w/2,y+h/2)])
        if n['kind']=='diamond':
            pts=[(x,y-h/2),(x+w/2,y),(x,y+h/2),(x-w/2,y)]
            svg.append('<polygon points="'+' '.join(f'{a},{b}' for a,b in pts)+'" fill="white" stroke="black" stroke-width="3"/>')
            draw.polygon(xy(pts), fill='white', outline='black', width=3*scale)
        else:
            radius=h/2 if n['kind']=='round' else 0
            svg.append(f'<rect x="{x-w/2}" y="{y-h/2}" width="{w}" height="{h}" rx="{radius}" fill="white" stroke="black" stroke-width="3"/>')
            draw.rounded_rectangle(bounds, radius=radius*scale, fill='white', outline='black', width=3*scale)
        size=22
        if n['kind'] != 'diamond':
            while size > 16 and max(draw.textlength(line, font=font(size * scale)) / scale for line in n['label'].split('\n')) > w - 30:
                size -= 1
        text(x,y-(len(n['label'].split('\n'))-1)*(size+8)/2,n['label'],size,True)
    svg.append('</svg>')
    source=''.join(svg)
    ET.fromstring(source)
    (OUT/(d['slug']+'.svg')).write_text(source,encoding='utf-8')
    im.save(OUT/(d['slug']+'.png'))
    mermaid=['flowchart TD']
    for n in d['nodes']:
        label=n['label'].replace('\n',' · ')
        if n['kind']=='round':
            shape=f'(["{label}"])'
        elif n['kind']=='diamond':
            shape=f'{{"{label}"}}'
        else:
            shape=f'["{label}"]'
        mermaid.append(f'    {n["id"]}{shape}')
    for e in d['edges']:
        label=f'|"{e["label"]}"|' if e['label'] else ''
        mermaid.append(f'    {e["a"]} -->{label} {e["b"]}')
    mermaid.append('    classDef plain fill:#fff,stroke:#000,color:#000,stroke-width:2px;')
    mermaid.append('    class '+','.join(n['id'] for n in d['nodes'])+' plain;')
    (OUT/(d['slug']+'.mmd')).write_text('\n'.join(mermaid)+'\n',encoding='utf-8')
    return source


images=[render(d) for d in diagrams]
css='''body{font:17px/1.6 Arial,sans-serif;margin:0;color:#111;background:#eee}main{max-width:1150px;margin:auto;padding:24px}header,section{background:white;padding:24px;margin-bottom:24px;border:1px solid #ccc}h1{font-size:30px}h2{font-size:24px}img{display:block;max-width:100%;height:auto;margin:auto}a{color:#154d84}nav a{display:block;margin:8px 0}button{font:inherit;padding:10px 16px;background:#111;color:white;border:0;cursor:pointer}.legend{border:1px solid #aaa;padding:12px}.diagram{overflow:auto}.diagram svg{display:block;width:100%;height:auto}p{max-width:1000px}@media print{body{background:white}main{padding:0}header,section{border:0;padding:0}section{break-before:page}nav,button,.downloads{display:none}.diagram svg{max-height:235mm;width:100%}h2{margin:0}@page{size:A4;margin:12mm}}'''
intro='''<h1>Cureando · Diagramas de flujo</h1><p>Como un diagrama clásico: sigue las flechas y responde las preguntas de los rombos. Los códigos E01–E11 y R01–R03 coinciden con las fichas de pantallas.</p><p class="legend"><b>Óvalo:</b> inicio, fin o conexión a otro recorrido. <b>Rectángulo:</b> pantalla o acción (el texto indica cuál). <b>Rombo:</b> decisión. <b>Flecha:</b> siguiente paso. <b>Sí / No:</b> resultado de la decisión.</p><p><b>Login y registro:</b> la propuesta actual permite al estudiante activar su acceso con una invitación del centro y volver mientras su sesión sea válida. No se ha aprobado un registro con correo/contraseña. El personal sí usa cuenta institucional asignada. Recuperación de acceso pendiente.</p><p><b>Orden de diseño:</b> primero acceso e Inicio; después reporte y seguimiento; luego atención del personal. Ayuda y autocuidado completan la navegación. Ayuda también se puede abrir antes de entrar al centro.</p><p><a href="../pantallas-explicadas.html">Ver qué textos, campos y botones lleva cada pantalla</a></p><button onclick="window.print()">Imprimir / Guardar PDF</button>'''
nav='<nav>'+''.join(f'<a href="#{d["slug"]}">{d["title"]}</a>' for d in diagrams)+'</nav>'
sections=[]
for d,svg in zip(diagrams,images):
    slug=d['slug']
    sections.append(f'<section id="{slug}"><h2>{escape(d["title"])}</h2><p>{escape(d["note"])}</p><p class="downloads"><a href="{slug}.png">Imagen PNG para compartir</a> · <a href="{slug}.svg">SVG</a> · <a href="{slug}.mmd">Fuente Mermaid</a></p><div class="diagram">{svg.replace("id=\"title\"", f"id=\"{slug}-title\"").replace("aria-labelledby=\"title\"", f"aria-labelledby=\"{slug}-title\"")}</div></section>')
html='<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Cureando · Diagramas de flujo</title><style>'+css+'</style></head><body><main><header>'+intro+nav+'</header>'+''.join(sections)+'</main></body></html>'
(OUT/'index.html').write_text(html,encoding='utf-8')
md=['# Cureando — Diagramas de flujo para diseño','', 'Estado: propuesta. Estos diagramas describen pantallas y navegación, no estructura de carpetas.','', '[Abrir versión visual](index.html). Hay imágenes PNG para compartir y SVG para escalar sin perder calidad.','', 'El acceso estudiantil propuesto es por invitación y sesión privada, no por correo/contraseña; recuperación pendiente. El personal usa cuentas asignadas. Ver [contenido de cada pantalla](../pantallas-explicadas.md).','']
for d in diagrams:
    md += ['## '+d['title'],'',d['note'],'','![Diagrama de flujo]('+d['slug']+'.png)','','```mermaid',(OUT/(d['slug']+'.mmd')).read_text(encoding='utf-8').strip(),'```','']
(OUT/'README.md').write_text('\n'.join(md),encoding='utf-8')
for d in diagrams:
    ids={n['id'] for n in d['nodes']}
    assert all(e['a'] in ids and e['b'] in ids for e in d['edges'])
    assert all(len([e for e in d['edges'] if e['a']==n['id'] and e['label']]) >= 2 for n in d['nodes'] if n['kind']=='diamond')
print(f'{len(diagrams)} diagramas generados: PNG, SVG, Mermaid, HTML y Markdown. Decisiones Sí/No y destinos verificados.')
