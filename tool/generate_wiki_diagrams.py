#!/usr/bin/env python3
"""Generate exact conceptual SVGs using only the Python standard library."""
import argparse
from html import escape
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / 'doc/wiki/images'
BLUE, ORANGE, GREEN, MUTED = '#1758a8', '#a45100', '#087454', '#536579'


class Scene:
    def __init__(self, name, description):
        self.name = name
        self.items = [f'<title id="title">{escape(name)}</title>',
                      f'<desc id="description">{escape(description)}</desc>',
                      '<rect width="800" height="360" rx="16" fill="#f6f8fc"/>']
        self.text(30, 36, name, '#172a42', 21)

    def text(self, x, y, text, color=MUTED, size=16):
        self.items.append(f'<text x="{x}" y="{y}" fill="{color}" font-family="Arial, sans-serif" font-size="{size}">{escape(text)}</text>')

    def line(self, x1, y1, x2, y2, color=MUTED, arrow=False, dash=False, width=3):
        self.items.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color}" stroke-width="{width}"'
                          + (' marker-end="url(#arrow)"' if arrow else '')
                          + (' stroke-dasharray="7 6"' if dash else '') + '/>')

    def circle(self, x, y, r, color=BLUE, fill='none', dash=False):
        self.items.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" stroke="{color}" stroke-width="2"'
                          + (' stroke-dasharray="7 6"' if dash else '') + '/>')

    def agent(self, x, y, label='p', color=BLUE):
        self.circle(x, y, 11, color, color)
        self.text(x-8, y+31, label, color)

    def target(self, x, y, label='target'):
        self.circle(x, y, 9, ORANGE)
        self.line(x-14, y, x+14, y, ORANGE, width=2)
        self.line(x, y-14, x, y+14, ORANGE, width=2)
        self.text(x+15, y-12, label, ORANGE)

    def svg(self):
        return ('<svg xmlns="http://www.w3.org/2000/svg" width="800" height="360" viewBox="0 0 800 360" role="img" aria-labelledby="title description">\n'
                '<defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="context-stroke"/></marker></defs>\n'
                + '\n'.join(self.items) + '\n</svg>\n')


def diagrams():
    scenes = {}
    def new(name, desc):
        s = Scene(name, desc)
        scenes[name] = s
        return s

    s = new('Foundations', 'Current velocity and desired velocity share an origin; correction points from the current velocity tip to the desired velocity tip.')
    s.agent(140, 260)
    s.line(140,260,290,130,BLUE,True); s.text(240,110,'v: current / atual',BLUE)
    s.line(140,260,590,260,ORANGE,True); s.text(470,290,'u: desired / desejada',ORANGE)
    s.line(290,130,590,260,GREEN,True); s.text(440,170,'u - v',GREEN)
    s.text(30,335,'a = limit((u - v) / T, A)    |    pNext = p + vNext * dt')

    for name in ['Seek','Flee']:
        s = new(name, 'Desired velocity points toward the fixed target for Seek and away for Flee; current velocity is independent.')
        s.agent(300,210); s.target(590,150)
        s.line(300,210,590,150,ORANGE,dash=True)
        if name=='Seek': s.line(300,210,475,174,GREEN,True)
        else: s.line(300,210,125,246,GREEN,True)
        s.line(300,210,300,110,BLUE,True); s.text(312,105,'v',BLUE)
        s.text(50,310,'u = normalize(' + ('target - p' if name=='Seek' else 'p - target') + ') * V',GREEN)

    s = new('Arrive', 'Concentric stop and slowing radii around a destination reduce desired speed with distance.')
    s.target(515,190); s.circle(515,190,125,ORANGE,dash=True); s.circle(515,190,35,ORANGE)
    s.agent(120,190); s.line(120,190,300,190,GREEN,True)
    s.agent(420,190,'inside R1'); s.line(420,190,465,190,GREEN,True)
    s.text(495,75,'R1: slowing',ORANGE); s.text(554,229,'R0: stop',ORANGE)
    s.text(40,330,'Outside R1: u = V    |    Inside R0: u = 0; actual v still needs braking')

    for name in ['Pursuit','Evade']:
        s = new(name, 'A constant-velocity target prediction is used as the Seek or Flee destination.')
        s.agent(175,250); s.agent(480,170,'target',ORANGE)
        s.line(480,170,580,90,ORANGE,True); s.target(580,90,'predicted')
        s.line(175,250,580,90,MUTED,dash=True)
        if name=='Pursuit': s.line(175,250,395,163,GREEN,True)
        else: s.line(175,250,65,294,GREEN,True)
        s.text(35,335,'predicted = target.position + target.velocity * horizon',GREEN)

    s = new('Wander', 'The wandering target lies on a forward circle, with a retained angular state.')
    s.agent(150,210); s.line(150,210,300,210,BLUE,True); s.text(180,185,'heading',BLUE)
    s.circle(470,210,85,ORANGE); s.line(150,210,470,210,MUTED,dash=True)
    s.target(521,142,'circle target'); s.line(470,210,521,142,ORANGE)
    s.line(150,210,390,166,GREEN,True)
    s.text(325,242,'distance'); s.text(520,228,'radius',ORANGE)
    s.text(35,330,'angle += random(-1, 1) * jitter * dt; keep one instance per agent')

    s = new('Brake', 'Braking acceleration opposes current velocity; it does not change position directly.')
    s.agent(340,190); s.line(340,190,590,190,BLUE,True); s.text(550,170,'v',BLUE)
    s.line(340,220,160,220,GREEN,True); s.text(95,250,'a opposes v',GREEN)
    s.text(50,315,'a = limit(-v / T, A)    |    vNext can remain nonzero')

    for name in ['Separation','Alignment','Cohesion','Flocking']:
        s = new(name, 'Local neighbor contributions are combined around a central observer; arrows show different local rules, not trajectories.')
        s.agent(310,190); s.circle(310,190,125,BLUE,dash=True)
        others=[(370,130),(390,210),(280,260)]
        for i,(x,y) in enumerate(others):
            s.agent(x,y,f'n{i+1}',ORANGE)
        if name=='Separation':
            for x,y in others: s.line(310,190,310+(310-x)*.8,190+(190-y)*.8,GREEN,True)
            s.text(480,170,'Nearer = stronger repulsion',GREEN)
            s.text(480,200,'Mean, not raw sum')
        elif name=='Alignment':
            for x,y in others: s.line(x,y,x+35,y-25,ORANGE,True)
            s.line(310,190,370,147,GREEN,True)
            s.text(475,175,'Match mean neighbor velocity',GREEN)
        elif name=='Cohesion':
            s.target(347,200,'local center')
            s.line(310,190,347,200,GREEN,True)
            s.text(475,160,'Positional attraction',GREEN)
            s.text(475,195,'No shared-velocity damping')
        else:
            s.line(310,190,240,150,GREEN,True); s.text(485,135,'Separation: keep space')
            s.line(310,190,365,130,BLUE,True); s.text(485,175,'Alignment: match velocity')
            s.line(310,190,350,205,ORANGE,True); s.text(485,215,'Cohesion: stay near')
            s.text(485,265,'a = limit(weighted sum, A)',GREEN)
        s.text(35,340,'Use the same old frame for every agent, then replace the whole population')

    s = new('Path-Following', 'An agent follows an ordered set of capture circles, not a continuously projected path.')
    pts=[(240,240),(430,105),(640,220)]
    s.agent(90,240)
    s.line(240,240,430,105,ORANGE,dash=True); s.line(430,105,640,220,ORANGE,dash=True)
    for i,(x,y) in enumerate(pts):
        s.target(x,y,f'waypoint {i}'); s.circle(x,y,35,ORANGE,dash=True)
    s.line(90,240,210,240,GREEN,True)
    s.text(35,325,'Inside capture circle: advance index; final open waypoint keeps Arrive')

    s = new('Obstacle-Avoidance', 'The forward scan meets an inflated obstacle surface before its center. Tangential steering and braking respond to the first entry.')
    s.agent(110,210); s.line(110,210,670,210,BLUE,True); s.text(605,240,'scan',BLUE)
    s.circle(450,185,55,ORANGE,fill='#ffe7ca'); s.circle(450,185,85,ORANGE,dash=True)
    s.text(410,85,'expanded R',ORANGE)
    s.agent(369,210,'entry',ORANGE); s.line(110,210,75,285,GREEN,True)
    s.text(155,290,'lateral + braking',GREEN)
    s.text(35,335,'R = obstacle.radius + agentRadius + safetyMargin; choose first surface')

    s = new('Leader-Following', 'An arrival target is placed behind leader velocity; a local exclusion circle has priority.')
    s.agent(520,170,'leader',ORANGE); s.line(520,170,680,170,ORANGE,True)
    s.circle(520,170,45,ORANGE,dash=True); s.target(350,170,'trailing target')
    s.line(350,170,520,170,MUTED,dash=True)
    s.agent(140,260,'follower'); s.line(140,260,310,187,GREEN,True)
    s.text(35,330,'target = leader.position - heading * distance    |    clearance before arrival')

    s = new('Queue-Following', 'Only strictly forward occupants within the lane count as blockers; the nearest one limits forward motion.')
    s.line(65,135,710,135,MUTED,dash=True); s.line(65,245,710,245,MUTED,dash=True)
    s.agent(170,190); s.agent(390,190,'blocker',ORANGE); s.agent(590,190,'farther',ORANGE)
    s.agent(350,85,'outside lane',MUTED)
    s.line(170,190,285,190,BLUE,True); s.line(170,220,390,220,GREEN)
    s.text(265,245,'gap',GREEN); s.text(540,285,'direction +X',BLUE)
    s.text(35,335,'Cap forward acceleration from gap and blocker speed; keep lateral request')

    s = new('Wall-Following', 'A forward probe projects onto a finite wall; the target advances along the tangent and offsets along its normal.')
    s.line(100,120,690,120,ORANGE,width=5); s.text(590,100,'wall segment',ORANGE)
    s.agent(170,230); s.line(170,230,330,230,BLUE,True); s.text(270,260,'probe',BLUE)
    s.line(330,230,330,120,MUTED,dash=True); s.text(280,100,'projection')
    s.line(330,120,500,120,GREEN,True); s.line(500,120,500,190,GREEN,True)
    s.target(500,190,'offset target'); s.line(170,230,460,195,GREEN,True)
    s.text(510,270,'left normal = +Y (screen)',GREEN)
    s.text(35,335,'target = projection + tangent * lookAhead + chosenNormal * wallOffset')

    s = new('Weighted-Blend', 'Weighted acceleration vectors sum before a final magnitude cap; weights are not normalized.')
    s.agent(210,260); s.line(210,260,440,260,BLUE,True); s.text(290,285,'w1 * a1',BLUE)
    s.line(440,260,440,100,ORANGE,True); s.text(455,190,'w2 * a2',ORANGE)
    s.line(210,260,440,100,GREEN,True); s.text(230,150,'sum',GREEN)
    s.text(50,330,'a = limit(sum(weight * acceleration), A); opposite contributions can cancel')

    s = new('Priority-Steering', 'An ordered decision list selects the first output above epsilon and skips remaining behaviors.')
    for y,label,color in [(105,'1. avoidance: zero → continue',MUTED),(180,'2. arrival: |a| > epsilon → SELECT',GREEN),(255,'3. wander: skipped',MUTED)]:
        s.circle(90,y,12,color,color); s.text(125,y+6,label,color,20)
    s.text(45,330,'No weighted sum. Stateful rules advance only when actually evaluated.')

    s = new('Spatial-Index', 'Cell bounds produce candidates, while the exact distance circle decides which neighbors qualify.')
    for x in range(140,621,80): s.line(x,70,x,310,'#b8c4d6',width=1)
    for y in range(70,311,80): s.line(140,y,620,y,'#b8c4d6',width=1)
    s.circle(380,190,90,GREEN,dash=True); s.agent(380,190)
    s.agent(420,140,'included',GREEN); s.agent(475,100,'candidate only',ORANGE)
    s.text(40,345,'Index candidates → original order → exact radius filter; same answer as linear')

    s = new('Recipes', 'A fixed-step simulation reads old snapshots, computes new snapshots, then lets the renderer read them.')
    for x,label,color in [(150,'old snapshots',BLUE),(400,'fixed-step update',GREEN),(650,'renderer',ORANGE)]:
        s.circle(x,180,58,color); s.text(x-80,270,label,color,18)
    s.line(210,180,340,180,GREEN,True); s.line(460,180,590,180,GREEN,True)
    s.text(80,330,'Stateful calculate(): simulation only. Rendering reads the completed frame.')
    s = new('Continuous-Path', 'A predicted position projects onto a finite polyline. Arc-distance look-ahead crosses the corner and chooses a target on the next edge.')
    s.line(100,245,475,245,ORANGE,width=4)
    s.line(475,245,475,85,ORANGE,width=4)
    s.agent(250,180)
    s.line(250,180,340,180,BLUE,True); s.text(280,150,'predicted p + v*time',BLUE)
    s.line(340,180,340,245,MUTED,dash=True)
    s.agent(340,245,'projection',GREEN)
    s.line(340,245,475,245,GREEN,True)
    s.line(475,245,475,165,GREEN,True)
    s.target(475,165,'arc target')
    s.text(540,235,'ahead along route',GREEN)
    s.text(35,335,'FollowPolyline: finite projection + arc target; FollowPath keeps waypoint capture')
    return scenes


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    different = []
    OUT.mkdir(parents=True, exist_ok=True)
    for name, scene in diagrams().items():
        path = OUT / f'{name}.svg'
        content = scene.svg()
        if not path.exists() or path.read_text() != content:
            different.append(name)
            if not args.check: path.write_text(content)
    print(f'{len(diagrams())} diagrams; {len(different)} ' + ('out of date' if args.check else 'updated'))
    if args.check and different: raise SystemExit(1)


if __name__ == '__main__':
    main()
