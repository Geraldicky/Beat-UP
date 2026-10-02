const fs = require('fs');
const path = require('path');

const OUT = __dirname;
const W = 1920, H = 1080;
const C = {
  base:'#0B0E14', surface:'#131A24', raised:'#1B2430', border:'#344052',
  text:'#F4F6FB', muted:'#8B96A8', primary:'#A9B8FF', light:'#D8E0FF', warm:'#F2C8B0',
  lilac:'#D3A4FF', cyan:'#7DB4CE', danger:'#B76C75', success:'#7DCE9E',
  normal:'#5697FF', diagonal:'#FFA65C', reverse:'#FF5A64', space:'#F5C96A', white:'#FFFFFF'
};
const artPath = path.resolve(OUT, '../../assets/song_backgrounds/space_invaders.png');
const thumbPath = path.resolve(OUT, '../../assets/song_thumbnails/space_invaders.png');
const art = `data:image/png;base64,${fs.readFileSync(artPath).toString('base64')}`;
const thumb = `data:image/png;base64,${fs.readFileSync(thumbPath).toString('base64')}`;
const imageData = rel => `data:image/png;base64,${fs.readFileSync(path.resolve(OUT, rel)).toString('base64')}`;
const songThumbs = {
  eyes: imageData('../../assets/song_thumbnails/eyes_half_closed.png'),
  crab: imageData('../../assets/song_thumbnails/crab_rave.png'),
  apple: imageData('../../assets/song_thumbnails/bad_apple.png'),
  space: thumb,
  blue: imageData('../../assets/song_thumbnails/blue_zenith.png'),
  bubble: imageData('../../assets/song_thumbnails/bubble_tea.png'),
  immortal: imageData('../../assets/song_backgrounds/immortal_flame.png')
};
const fontData = name => `data:font/ttf;base64,${fs.readFileSync(path.resolve(OUT, `../../assets/fonts/${name}`)).toString('base64')}`;
const fonts = {
  poppins: fontData('Poppins-Regular.ttf'),
  poppinsSemi: fontData('Poppins-SemiBold.ttf'),
  space: fontData('SpaceGrotesk-Variable.ttf'),
  mono: fontData('IBMPlexMono-Regular.ttf')
};

const esc = s => String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
const r = (x,y,w,h,fill=C.surface,rad=12,stroke='none',sw=1,extra='') => `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${rad}" fill="${fill}" stroke="${stroke}" stroke-width="${sw}" ${extra}/>`;
const line = (x1,y1,x2,y2,stroke=C.border,sw=1,extra='') => `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${stroke}" stroke-width="${sw}" ${extra}/>`;
const t = (x,y,s,size=16,fill=C.text,weight=400,anchor='start',family='Poppins',extra='') => `<text x="${x}" y="${y}" fill="${fill}" font-family="${family}" font-size="${size}" font-weight="${weight}" text-anchor="${anchor}" ${extra}>${esc(s)}</text>`;
// 14 px at the 1920 reference canvas resolves to ~10 px at 1366×768.
const label = (x,y,s,fill=C.muted,anchor='start') => t(x,y,s.toUpperCase(),14,fill,400,anchor,'IBM Plex Mono','letter-spacing="1.35"');
const pill = (x,y,w,text,active=false,color=C.primary) => `${r(x,y,w,34,active?color:C.raised,17,active?color:C.border)}${t(x+w/2,y+22,text,12,active?C.base:C.text,600,'middle')}`;
const button = (x,y,w,text,style='primary',focus=false) => {
  const fill = style==='primary'?C.primary:style==='danger'?C.danger:C.raised;
  const fg = style==='primary'?C.base:C.text;
  return `${focus?r(x-4,y-4,w+8,52,'none',12,C.primary,2):''}${r(x,y,w,44,fill,8,style==='secondary'?C.border:fill)}${t(x+w/2,y+28,text,14,fg,600,'middle','Poppins','letter-spacing=".6"')}`;
};
const nav = (x,y,text,state='default') => {
  const selected=state==='selected', focus=state==='focus';
  return `${selected?r(x-16,y-26,210,44,C.raised,8):''}${focus?r(x-19,y-29,216,50,'none',10,C.primary,2):''}${selected?r(x-16,y-26,3,44,C.primary,2):''}${t(x,y,text,16,selected?C.text:C.muted,selected?600:400)}`;
};
const metric = (x,y,w,name,value,accent=C.text) => `${label(x,y,name)}${t(x,y+42,value,34,accent,500,'start','IBM Plex Mono')}`;
const artwork = (x,y,size,opacity=1) => `${r(x,y,size,size,C.raised,16,C.border,1,`filter="url(#shadow)" opacity="${opacity}"`)}<image href="${art}" x="${x}" y="${y}" width="${size}" height="${size}" preserveAspectRatio="xMidYMid slice" clip-path="inset(0 round 16px)" opacity="${opacity}"/>`;
const progress = (x,y,w,p,color=C.primary) => `${r(x,y,w,5,C.raised,3)}${r(x,y,w*p,5,color,3)}`;
const diamond = (cx,cy,size,color,outline=false,opacity=1) => `<rect x="${cx-size/2}" y="${cy-size/2}" width="${size}" height="${size}" rx="5" transform="rotate(45 ${cx} ${cy})" fill="${outline?'none':color}" stroke="${color}" stroke-width="${outline?5:1}" opacity="${opacity}"/>`;
const directionalNote = (cx,cy,size,dir='→',kind='normal',opacity=1) => {
  const color = kind==='diagonal'?C.diagonal:C.normal;
  const base = diamond(cx,cy,size,color,false,opacity);
  const reverse = kind==='reverse'?diamond(cx,cy,size+8,C.reverse,true,opacity):'';
  return `${base}${reverse}${t(cx,cy+6,dir,Math.max(12,size*.58),C.white,600,'middle','Space Grotesk',`opacity="${opacity}"`)}`;
};
const hitZone = (cx,cy,size=54) => `<circle cx="${cx}" cy="${cy}" r="${size*.82}" fill="none" stroke="${C.primary}" stroke-width="2" opacity=".34" filter="url(#glow)"/>${diamond(cx,cy,size,C.white,true,.95)}`;
const difficulty = (x,y,name,stars,selected=false) => `${r(x,y,118,58,selected?C.primary:C.raised,10,selected?C.primary:C.border)}${label(x+14,y+21,name,selected?C.base:C.muted)}${t(x+14,y+45,`${stars} ★`,16,selected?C.base:C.text,600,'start','IBM Plex Mono')}`;
const modifier = (x,y,w,name,value='OFF',active=false) => `${r(x,y,w,48,active?C.raised:C.surface,10,active?C.primary:C.border,active?2:1)}${t(x+16,y+30,name,14,C.text,500)}${label(x+w-16,y+30,value,active?C.primary:C.muted,'end')}`;
const songRow = (x,y,title,artist,bpm,state='default',image=thumb) => {
  const selected=state==='selected';
  return `${selected?r(x,y,440,68,C.raised,10,C.primary,2):r(x,y,440,68,state==='hover'?C.raised:C.surface,10,C.border)}${r(x+10,y+10,48,48,C.raised,7)}<image href="${image}" x="${x+10}" y="${y+10}" width="48" height="48" preserveAspectRatio="xMidYMid slice" clip-path="inset(0 round 7px)"/>${t(x+74,y+27,title,14,C.text,600)}${t(x+74,y+49,artist,12,C.muted)}${label(x+424,y+38,`${bpm} BPM`,selected?C.primary:C.muted,'end')}`;
};
const slider = (x,y,w,p=.55) => `${line(x,y,x+w,y,C.border,8,'stroke-linecap="round"')}${line(x,y,x+w*p,y,C.primary,8,'stroke-linecap="round"')}<circle cx="${x+w*p}" cy="${y}" r="12" fill="${C.primary}"/>`;
const toggle = (x,y,on=true) => `${r(x,y,52,28,on?C.primary:C.raised,14,on?C.primary:C.border)}<circle cx="${x+(on?38:14)}" cy="${y+14}" r="9" fill="${on?C.base:C.muted}"/>`;
const dropdown = (x,y,w,name,value) => `${r(x,y,w,48,C.surface,10,C.border)}${label(x+16,y+30,name)}${t(x+w-36,y+30,value,14,C.text,600,'end')}${t(x+w-18,y+30,'⌄',14,C.muted,600,'middle')}`;
const keyBinding = (x,y,key,dir) => `${r(x,y,88,62,C.raised,10,C.border)}${label(x+14,y+24,key)}${t(x+58,y+43,dir,22,C.text,600,'middle')}`;
const frozenGameplay = (opacity=.42) => {
  const notes=[directionalNote(1480,650,22,'↙','diagonal',opacity),directionalNote(1210,650,22,'←','reverse',opacity),directionalNote(940,650,22,'↑','normal',opacity),diamond(720,650,28,C.space,false,opacity),directionalNote(520,650,22,'↗','diagonal',opacity)].join('');
  return `<g opacity="${opacity}">${label(64,76,'Score')}${t(64,122,'892,340',32,C.text,500,'start','IBM Plex Mono')}${label(960,76,'Combo',C.muted,'middle')}${t(960,132,'368',52,C.primary,600,'middle','Space Grotesk')}${label(1856,76,'Accuracy',C.muted,'end')}${t(1856,122,'98.7%',32,C.text,500,'end','IBM Plex Mono')}${progress(64,160,1792,.63,C.space)}${r(64,570,1792,160,'#101722',16,C.border)}${hitZone(218,650,50)}${notes}</g>`;
};
const shell = (name,body,opts={}) => `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080" viewBox="0 0 1920 1080">
<defs>
  <style><![CDATA[
    @font-face{font-family:'Poppins';src:url('${fonts.poppins}') format('truetype');font-weight:400}@font-face{font-family:'Poppins';src:url('${fonts.poppinsSemi}') format('truetype');font-weight:600}@font-face{font-family:'Space Grotesk';src:url('${fonts.space}') format('truetype');font-weight:100 900}@font-face{font-family:'IBM Plex Mono';src:url('${fonts.mono}') format('truetype');font-weight:400}
    text{dominant-baseline:auto} .hair{shape-rendering:crispEdges}
  ]]></style>
  <filter id="shadow" x="-25%" y="-25%" width="150%" height="150%"><feDropShadow dx="0" dy="18" stdDeviation="28" flood-color="#000" flood-opacity=".42"/></filter>
  <filter id="glow" x="-100%" y="-100%" width="300%" height="300%"><feGaussianBlur stdDeviation="10" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
  <linearGradient id="fade" x1="0" x2="1"><stop offset="0" stop-color="${C.base}"/><stop offset=".55" stop-color="${C.base}" stop-opacity=".2"/><stop offset="1" stop-color="${C.base}"/></linearGradient>
  <pattern id="grid" width="48" height="48" patternUnits="userSpaceOnUse"><path d="M48 0H0V48" fill="none" stroke="${C.border}" stroke-opacity=".08"/></pattern>
</defs>
${r(0,0,W,H,C.base,0)}${r(0,0,W,H,'url(#grid)',0)}
${opts.artBg?`<image href="${art}" x="0" y="0" width="1920" height="1080" preserveAspectRatio="xMidYMid slice" opacity="${opts.artOpacity||.14}"/><rect width="1920" height="1080" fill="url(#fade)"/>`:''}
${body}
${label(72,1042,name)}${label(1848,1042,'1920 × 1080','end')}
</svg>`;

function mainMenu(){return shell('Album Flow — Main Menu',`
${label(72,84,'Beat UP! / Album Flow')}${t(72,148,'BEAT',58,C.text,700,'start','Space Grotesk')}${t(224,148,'UP!',58,C.primary,700,'start','Space Grotesk')}
${t(72,186,'MUSIC LIFTS US HIGHER',13,C.muted,400,'start','IBM Plex Mono','letter-spacing="1.6"')}
${nav(88,300,'PLAY','selected')}${nav(88,356,'CHART STUDIO')}${nav(88,412,'HOW TO PLAY')}${nav(88,468,'CALIBRATION')}${nav(88,524,'SETTINGS')}${nav(88,580,'CREDITS')}${nav(88,636,'EXIT')}
${diamond(88,708,8,C.primary)}${label(108,712,'Enter to open song library',C.muted)}
${artwork(630,218,540)}
${label(1304,270,'Featured track')}${t(1304,338,'SPACE',48,C.text,600,'start','Space Grotesk')}${t(1304,388,'INVADERS',48,C.text,600,'start','Space Grotesk')}${t(1304,426,'Teminite & MDK',17,C.muted)}
${line(1304,474,1800,474)}${t(1304,532,'A bright, intricate rush built for',15,C.muted)}${t(1304,560,'precise directional play.',15,C.muted)}
${r(72,900,1776,100,C.surface,12,C.border)}<image href="${thumb}" x="92" y="920" width="60" height="60" preserveAspectRatio="xMidYMid slice" clip-path="inset(0 round 8px)"/>${label(174,938,'Now playing')}${t(174,970,'Space Invaders',15,C.text,600)}${t(330,970,'Teminite & MDK',13,C.muted)}
${t(820,960,'‹',28,C.muted,400,'middle','Space Grotesk')}${r(860,926,68,48,C.raised,24,C.primary,1)}${t(894,958,'Ⅱ',17,C.text,600,'middle','IBM Plex Mono')}${t(968,960,'›',28,C.muted,400,'middle','Space Grotesk')}
${label(1190,938,'2:12')}${progress(1242,946,410,.38,C.space)}${label(1708,956,'5:48',C.muted,'end')}`);}

function library(){return shell('Album Flow — Song Library',`
${label(72,72,'Beat UP!')}${t(72,126,'SONG LIBRARY',34,C.text,600,'start','Space Grotesk')}${label(504,120,'39 songs')}${pill(72,154,82,'ALL',true)}${pill(164,154,112,'FAVORITES')}${pill(286,154,104,'RECENT')}
${songRow(72,216,'Eyes Half Closed','Crywolf',135,'default',songThumbs.eyes)}${songRow(72,296,'Crab Rave','Noisestorm',125,'hover',songThumbs.crab)}${songRow(72,376,'Bad Apple!!','Alstroemeria Records',140,'default',songThumbs.apple)}${songRow(72,456,'Space Invaders','Teminite & MDK',128,'selected',songThumbs.space)}${songRow(72,536,'Blue Zenith','xi',200,'default',songThumbs.blue)}${songRow(72,616,'Bubble Tea','dark cat',160,'default',songThumbs.bubble)}${songRow(72,696,'Immortal Flame','Panda Eyes & Teminite',174,'default',songThumbs.immortal)}
${label(610,126,'Selected artwork')}${artwork(610,170,610)}${button(610,816,610,'PLAY SPACE INVADERS','primary',true)}
${label(1320,126,'Track 04 / 39')}${t(1320,188,'SPACE INVADERS',40,C.text,600,'start','Space Grotesk')}${t(1320,224,'Teminite & MDK',16,C.muted)}${line(1320,258,1848,258)}
${label(1320,300,'Difficulty')}${difficulty(1320,318,'NORMAL',4)}${difficulty(1452,318,'HARD',7)}${difficulty(1584,318,'MASTER',10,true)}
${metric(1320,430,120,'BPM','128')}${metric(1468,430,120,'LENGTH','5:48')}${metric(1628,430,120,'MODE','8 KEY',C.primary)}
${label(1320,536,'Your best')}${r(1320,554,528,118,C.surface,12,C.border)}${t(1344,601,'S',42,C.primary,600,'start','Space Grotesk')}${label(1416,586,'Score')}${t(1416,616,'1,000,356',20,C.text,500,'start','IBM Plex Mono')}${label(1642,586,'Accuracy')}${t(1642,616,'99.3%',20,C.text,500,'start','IBM Plex Mono')}
${label(1320,726,'Modifiers')}${modifier(1320,744,254,'8 KEY','SIGNATURE',true)}${modifier(1594,744,254,'RANDOM','OFF')}${modifier(1320,804,254,'PRACTICE','OFF')}
${t(1320,910,'Random changes direction only.',12,C.muted)}${t(1320,934,'Note speed follows BPM.',12,C.muted)}`);}

function launch(){return shell('Album Flow — Song Launch',`
${label(72,80,'Now entering')}${t(72,142,'READY?',52,C.text,600,'start','Space Grotesk')}${artwork(160,218,560)}
${label(850,238,'Space Invaders')}${t(850,284,'Teminite & MDK',18,C.muted,400,'start','Poppins')}
${r(850,330,912,154,C.surface,14,C.border)}${label(884,370,'Difficulty')}${t(884,444,'MASTER',64,C.primary,600,'start','Space Grotesk')}${label(1458,370,'Chart level')}${t(1458,440,'10 ★',38,C.text,500,'start','IBM Plex Mono')}
${label(850,530,'Run setup')}${modifier(850,552,286,'CONTROL MODE','8 KEY',true)}${modifier(1154,552,286,'RANDOM','OFF')}${modifier(1458,552,304,'PRACTICE','OFF')}
${label(850,664,'Preparing chart')}${t(850,702,'Loading audio and timing map…',15,C.muted)}${progress(850,744,912,.72,C.primary)}${label(850,790,'128 BPM  •  5:48  •  1,025 notes')}
${r(850,834,912,82,C.surface,12,C.border)}${t(882,870,'NUMPAD READY',15,C.success,600,'start','IBM Plex Mono')}${t(882,898,'Hit zone left  •  Notes travel right to left',13,C.muted)}
${button(1534,946,228,'CANCEL','secondary')}`);}

function gameplay(){const notes=[directionalNote(1580,650,28,'→','normal'),directionalNote(1400,650,28,'↙','diagonal'),directionalNote(1218,650,28,'←','reverse'),directionalNote(1045,650,28,'↑','normal'),diamond(870,650,34,C.space),directionalNote(696,650,28,'↗','diagonal'),directionalNote(540,650,28,'↓','normal')].join(''); return shell('Album Flow — Gameplay',`
${r(0,0,1920,1080,C.base,0,'none',1,'opacity=".34"')}${label(64,76,'Score')}${t(64,122,'892,340',32,C.text,500,'start','IBM Plex Mono')}${label(960,76,'Combo',C.muted,'middle')}${t(960,132,'368',52,C.primary,600,'middle','Space Grotesk')}${label(1856,76,'Accuracy',C.muted,'end')}${t(1856,122,'98.7%',32,C.text,500,'end','IBM Plex Mono')}${progress(64,160,1792,.63,C.space)}
${r(64,570,1792,160,'#101722',16,C.border)}${line(218,590,218,710,C.white,2,'opacity=".22"')}${hitZone(218,650,54)}${label(218,764,'Hit zone',C.primary,'middle')}${notes}
${t(304,532,'PERFECT',24,C.lilac,600,'middle','Space Grotesk')}${t(304,558,'+12 ms',12,C.muted,400,'middle','IBM Plex Mono')}
${label(64,886,'8-key numpad')}${t(64,922,'1  2  3  4  6  7  8  9',17,C.text,500,'start','IBM Plex Mono')}${label(1856,922,'Pause  ESC','end')}`,{artBg:true,artOpacity:.26});}

function pause(){return shell('Album Flow — Pause',`
${frozenGameplay(.44)}${r(0,0,1920,1080,'#05070B',0,'none',1,'opacity=".70"')}${label(128,150,'Pause')}${t(128,220,'TAKE A BREATH',52,C.text,600,'start','Space Grotesk')}${t(128,258,'Space Invaders  •  Master 10★',14,C.muted)}
${nav(144,396,'RESUME','selected')}${nav(144,462,'RESTART')}${nav(144,528,'SETTINGS')}${nav(144,594,'RETURN TO LIBRARY')}
${r(1040,188,680,610,C.surface,16,C.border)}${label(1096,250,'Current run')}${metric(1096,330,180,'Score','892,340')}${metric(1370,330,180,'Combo','368',C.primary)}${metric(1096,450,180,'Accuracy','98.7%')}${metric(1370,450,180,'Elapsed','3:39')}${line(1096,534,1664,534)}${t(1096,588,'Note speed follows BPM.',14,C.muted)}${t(1096,620,'Random changes direction only.',14,C.muted)}${button(1096,690,568,'RESUME','primary',true)}
${label(128,962,'ESC to resume')}`,{artBg:true,artOpacity:.22});}

function result(){return shell('Album Flow — Result',`
${label(72,76,'Result / New personal best')}${artwork(72,126,310)}${t(72,472,'SPACE INVADERS',26,C.text,600,'start','Space Grotesk')}${t(72,504,'Teminite & MDK  •  Master 10★',14,C.muted)}
${label(540,154,'Rank')}${t(540,330,'SS',190,C.primary,700,'start','Space Grotesk')}${t(540,380,'NEW PERSONAL BEST',14,C.success,600,'start','IBM Plex Mono','letter-spacing="1.2"')}
${metric(1030,166,260,'Score','8,742,960',C.text)}${metric(1030,288,260,'Accuracy','99.8%',C.primary)}${metric(1030,410,260,'Max combo','1,324')}
${r(1030,546,760,208,C.surface,14,C.border)}${label(1062,584,'Judgement breakdown')}${t(1062,630,'PERFECT',13,C.lilac,600)}${t(1240,630,'1,318',20,C.text,500,'start','IBM Plex Mono')}${t(1062,670,'GREAT',13,C.success,600)}${t(1240,670,'6',20,C.text,500,'start','IBM Plex Mono')}${t(1450,630,'GOOD',13,C.cyan,600)}${t(1618,630,'0',20,C.text,500,'start','IBM Plex Mono')}${t(1450,670,'MISS',13,C.danger,600)}${t(1618,670,'0',20,C.text,500,'start','IBM Plex Mono')}
${button(1030,826,250,'RETRY','primary',true)}${button(1300,826,310,'RETURN TO LIBRARY','secondary')}`);}

function settings(){const keys=[['7','↖'],['8','↑'],['9','↗'],['4','←'],['6','→'],['1','↙'],['2','↓'],['3','↘']];let kg='';keys.forEach((k,i)=>{const col=i%3,row=Math.floor(i/3),x=1110+col*126+(i>=4?0:0),y=322+row*94;kg+=`${r(x,y,106,72,C.raised,10,C.border)}${t(x+20,y+30,k[0],13,C.muted,400,'start','IBM Plex Mono')}${t(x+53,y+48,k[1],24,C.text,600,'middle')}`});return shell('Album Flow — Settings',`
${label(72,74,'Beat UP!')}${t(72,126,'SETTINGS',40,C.text,600,'start','Space Grotesk')}${nav(88,254,'DISPLAY')}${nav(88,316,'AUDIO')}${nav(88,378,'TIMING')}${nav(88,440,'VISUAL')}${nav(88,502,'INPUT','selected')}${nav(88,564,'ACCESSIBILITY')}
${label(540,210,'Control mode')}${pill(540,238,132,'8 KEY',true)}${pill(684,238,132,'4 KEY')}${t(540,310,'8-key numpad is the signature layout.',15,C.muted)}
${label(540,382,'Lane input')}${modifier(540,402,430,'HOLD BEHAVIOR','STANDARD',true)}${modifier(540,464,430,'GHOST INPUTS','IGNORE')}${modifier(540,526,430,'RUMBLE','OFF')}
${r(540,624,430,112,C.surface,12,C.border)}${label(568,660,'Timing behavior')}${t(568,696,'Note speed follows song BPM automatically.',13,C.text)}${t(568,720,'There is no independent speed setting.',12,C.muted)}
${label(1110,210,'Key bindings / 8 key')}${kg}${button(1110,638,358,'RESET BINDINGS','secondary')}${button(1470,912,306,'APPLY CHANGES','primary',true)}${button(1110,912,338,'BACK','secondary')}`);}

function calibration(){return shell('Album Flow — Calibration',`
${label(72,76,'Settings / Timing')}${t(72,132,'CALIBRATION',44,C.text,600,'start','Space Grotesk')}${t(72,172,'Tap with the pulse until the marker feels centered.',15,C.muted)}
${r(348,248,660,560,C.surface,18,C.border)}<circle cx="678" cy="466" r="136" fill="none" stroke="${C.border}" stroke-width="2"/><circle cx="678" cy="466" r="92" fill="none" stroke="${C.primary}" stroke-width="4" opacity=".7" filter="url(#glow)"/>${diamond(678,466,72,C.primary)}${t(678,650,'120 BPM',20,C.text,500,'middle','IBM Plex Mono')}${label(678,690,'Press any mapped direction on pulse',C.muted,'middle')}
${label(1130,278,'Measured offset')}${t(1130,352,'+12 ms',64,C.primary,600,'start','IBM Plex Mono')}${line(1130,440,1750,440,C.border,8,'stroke-linecap="round"')}${line(1130,440,1482,440,C.primary,8,'stroke-linecap="round"')}<circle cx="1482" cy="440" r="14" fill="${C.primary}"/>${label(1130,478,'-100 ms')}${label(1750,478,'+100 ms',C.muted,'end')}
${r(1130,548,620,132,C.surface,12,C.border)}${label(1160,584,'Confidence')}${t(1160,626,'HIGH',24,C.success,600,'start','IBM Plex Mono')}${t(1350,626,'12 consistent taps',14,C.muted)}
${button(1130,748,188,'RETRY','secondary')}${button(1338,748,188,'RESET','secondary')}${button(1546,748,204,'APPLY','primary',true)}${button(72,936,180,'BACK','secondary')}`);}

function howTo(){const noteBlock=(x,y,title,desc,dir,kind)=>`${kind==='space'?diamond(x+28,y+32,26,C.space):directionalNote(x+28,y+32,22,dir,kind)}${t(x+64,y+28,title,15,C.text,600)}${t(x+64,y+52,desc,13,C.muted)}`;return shell('Album Flow — How To Play',`
${label(72,72,'Beat UP!')}${t(72,124,'HOW TO PLAY',40,C.text,600,'start','Space Grotesk')}${t(72,160,'Read direction, trust rhythm, own the beat.',15,C.muted)}
${r(72,220,540,680,C.surface,16,C.border)}${label(108,266,'01 / Controls')}${t(108,316,'NUMPAD IS THE INSTRUMENT',23,C.text,600,'start','Space Grotesk')}${t(108,354,'8-key mode maps every direction around the center.',13,C.muted)}
${[['7','↖'],['8','↑'],['9','↗'],['4','←'],['',''],['6','→'],['1','↙'],['2','↓'],['3','↘']].map((k,i)=>{let x=156+(i%3)*126,y=420+Math.floor(i/3)*110;return k[0]?`${r(x,y,96,84,C.raised,10,C.border)}${t(x+18,y+30,k[0],12,C.muted,400,'start','IBM Plex Mono')}${t(x+48,y+58,k[1],24,C.text,600,'middle')}`:''}).join('')}${t(108,798,'4-key mode',15,C.text,600)}${t(108,826,'Uses ↑ ↓ ← → while keeping the same lane.',13,C.muted)}
${r(640,220,540,680,C.surface,16,C.border)}${label(676,266,'02 / Note types')}${t(676,316,'ONE SILHOUETTE. CLEAR COLOR.',23,C.text,600,'start','Space Grotesk')}${noteBlock(676,382,'NORMAL','Press the shown direction.','↑','normal')}${noteBlock(676,474,'DIAGONAL','Use the matching diagonal key.','↗','diagonal')}${noteBlock(676,566,'REVERSE','Same silhouette; red outline only.','←','reverse')}${noteBlock(676,658,'SPACE','Press the space bar.','•','space')}${t(676,778,'Random changes direction only.',13,C.muted)}${t(676,806,'Note speed always follows BPM.',13,C.muted)}
${r(1208,220,640,680,C.surface,16,C.border)}${label(1244,266,'03 / Timing')}${t(1244,316,'HIT INSIDE THE LEFT ZONE',23,C.text,600,'start','Space Grotesk')}${line(1288,420,1770,420,C.border,4)}${hitZone(1330,420,42)}${directionalNote(1410,420,24,'←','normal')}${label(1326,506,'Hit zone',C.primary,'middle')}
${t(1244,586,'PERFECT',16,C.lilac,600)}${t(1450,586,'≤ 35 ms',16,C.text,500,'start','IBM Plex Mono')}${t(1244,632,'GREAT',16,C.success,600)}${t(1450,632,'≤ 60 ms',16,C.text,500,'start','IBM Plex Mono')}${t(1244,678,'GOOD',16,C.cyan,600)}${t(1450,678,'≤ 90 ms',16,C.text,500,'start','IBM Plex Mono')}${t(1244,724,'MISS',16,C.danger,600)}${t(1450,724,'> 90 ms',16,C.text,500,'start','IBM Plex Mono')}${t(1244,780,'Space: 60 / 110 / 170 ms',12,C.muted,400,'start','IBM Plex Mono')}${button(72,938,180,'BACK','secondary')}`);}

function credits(){return shell('Album Flow — Credits',`
${label(72,74,'Beat UP!')}${t(72,128,'CREDITS',44,C.text,600,'start','Space Grotesk')}${t(72,166,'Made for rhythm players who like to read the whole lane.',15,C.muted)}
${r(72,230,560,620,C.surface,16,C.border)}${label(112,278,'Production')}${t(112,332,'GAME DESIGN',13,C.muted,400,'start','IBM Plex Mono')}${t(112,362,'Project owner — approval pending',17,C.text,500)}${t(112,422,'PROGRAMMING',13,C.muted,400,'start','IBM Plex Mono')}${t(112,452,'Project owner — approval pending',17,C.text,500)}${t(112,512,'UI / UX',13,C.muted,400,'start','IBM Plex Mono')}${t(112,542,'Album Flow design system',17,C.text,500)}${t(112,602,'CHARTING',13,C.muted,400,'start','IBM Plex Mono')}${t(112,632,'Per-track chart metadata',17,C.text,500)}
${r(660,230,560,620,C.surface,16,C.border)}${label(700,278,'Music')}${t(700,332,'39 licensed / attributed tracks',18,C.text,600)}${t(700,370,'See individual song metadata for artists',14,C.muted)}${t(700,396,'and source attribution.',14,C.muted)}${line(700,446,1180,446)}${label(700,492,'Featured in this mockup')}${t(700,538,'Space Invaders',22,C.text,600,'start','Space Grotesk')}${t(700,568,'Teminite & MDK',15,C.muted)}
${r(1248,230,600,620,C.surface,16,C.border)}${label(1288,278,'Tools & type')}${t(1288,332,'ENGINE',13,C.muted,400,'start','IBM Plex Mono')}${t(1288,362,'Godot Engine',17,C.text,500)}${t(1288,422,'TYPEFACES',13,C.muted,400,'start','IBM Plex Mono')}${t(1288,452,'Space Grotesk',17,C.text,500)}${t(1288,486,'Poppins',17,C.text,500)}${t(1288,520,'IBM Plex Mono',17,C.text,500)}${line(1288,572,1808,572)}${t(1288,622,'Thank you for playing.',24,C.primary,600,'start','Space Grotesk')}${button(72,930,180,'BACK','secondary')}`);}

function studio(){let wave='';for(let i=0;i<96;i++){const x=96+i*13.8;const h=18+Math.abs(Math.sin(i*.57))*76+Math.abs(Math.cos(i*.19))*34;wave+=line(x,300-h/2,x,300+h/2,i%8===0?C.primary:C.cyan,i%8===0?2:1,`opacity="${i%8===0?.9:.45}"`)}
const dirs=['↖','↑','↗','←','→','↙','↓','↘'];let grid='';for(let i=0;i<33;i++){const x=150+i*42.3;grid+=line(x,470,x,790,i%4===0?C.border:'#253041',i%4===0?2:1)}for(let j=0;j<=8;j++)grid+=line(150,470+j*40,1504,470+j*40,'#253041',1);dirs.forEach((d,i)=>grid+=`${label(118,496+i*40,d,C.muted,'middle')}`);
let ns='';[[9,0,'normal'],[12,7,'diagonal'],[15,3,'reverse'],[19,6,'normal'],[22,4,'normal'],[26,2,'diagonal'],[29,5,'reverse']].forEach(n=>ns+=directionalNote(150+n[0]*42.3,490+n[1]*40,18,dirs[n[1]],n[2]));ns+=diamond(150+20*42.3,490+6*40,22,C.space);
const dirPad=[['7','↖'],['8','↑'],['9','↗'],['4','←'],['6','→'],['1','↙'],['2','↓'],['3','↘']].map((k,i)=>{const col=i%3,row=Math.floor(i/3);return keyBinding(1592+col*78,438+row*60,k[0],k[1]).replace('width="88"','width="68"').replace('height="62"','height="48"')}).join('');return shell('Album Flow — Chart Studio',`
${label(64,62,'Chart Studio / Manual authoring')}${t(64,106,'SPACE INVADERS',28,C.text,600,'start','Space Grotesk')}${t(348,104,'Teminite & MDK',14,C.muted)}${pill(668,70,104,'MASTER',true)}${label(802,96,'128 BPM')}${label(914,96,'+205 ms')}${button(1468,64,120,'SAVE','secondary')}${button(1600,64,120,'EXPORT','secondary')}${button(1732,64,124,'PLAYTEST','primary',true)}
${r(64,160,1472,220,C.surface,12,C.border)}${label(96,196,'Waveform')}${wave}${line(96,300,1504,300,C.primary,2)}
${r(64,414,1472,420,C.surface,12,C.border)}${label(96,452,'Timeline / 8 directional lanes / 1⁄4 snap')}${grid}${ns}${line(720,470,720,790,C.space,3,'filter="url(#glow)"')}
${r(1560,160,296,674,C.surface,12,C.border)}${label(1592,200,'Note type')}${modifier(1592,220,232,'NORMAL','1',true)}${modifier(1592,276,232,'REVERSE','2')}${modifier(1592,332,232,'SPACE','3')}${label(1592,416,'Direction / numpad')}${dirPad}${label(1592,646,'Edit')}${button(1592,666,72,'SELECT','secondary')}${button(1670,666,72,'ERASE','secondary')}${button(1748,666,76,'DELETE','secondary')}${label(1592,752,'History')}${button(1592,772,108,'UNDO','secondary')}${button(1712,772,112,'REDO','secondary')}
${r(64,866,1792,98,C.surface,12,C.border)}${button(92,893,120,'PLAY','primary')}${button(224,893,120,'STOP','secondary')}${label(390,925,'03:12.488 / 05:48.009')}${label(914,925,'SNAP 1/4')}${label(1080,925,'ZOOM 125%')}${progress(1260,916,548,.55,C.primary)}`);}

function designSystem(){return shell('Album Flow — Design System',`
${label(72,72,'Beat UP! / Album Flow')}${t(72,128,'DESIGN SYSTEM',42,C.text,600,'start','Space Grotesk')}${t(72,164,'Reusable tokens and review-ready component states.',14,C.muted)}
${label(72,226,'Color')}${Object.entries(C).slice(0,12).map(([k,v],i)=>{const x=72+(i%6)*142,y=250+Math.floor(i/6)*100;return `${r(x,y,120,58,v,10,v===C.base?C.border:v)}${label(x,y+82,k)}`}).join('')}
${label(980,226,'Typography')}${t(980,280,'Screen title',40,C.text,500,'start','Space Grotesk')}${t(980,328,'Section heading',20,C.text,600)}${t(980,372,'Body copy balances density and rhythm.',15,C.muted)}${label(980,412,'META / LABEL')}${t(980,452,'1,024,358',20,C.primary,500,'start','IBM Plex Mono')}
${label(72,500,'Buttons / states')}${button(72,526,160,'DEFAULT','primary')}${button(248,526,160,'HOVER','primary')}${button(424,526,160,'FOCUS','primary',true)}${button(600,526,160,'SECONDARY','secondary')}
${label(980,500,'Navigation / states')}${nav(996,548,'PLAY')}${nav(996,604,'LIBRARY','selected')}${nav(996,660,'SETTINGS','focus')}
${label(72,668,'Song row')}${songRow(72,694,'Space Invaders','Teminite & MDK',128,'selected')}${label(550,668,'Difficulty')}${difficulty(550,694,'NORMAL',4)}${difficulty(682,694,'HARD',7)}${difficulty(814,694,'MASTER',10,true)}
${label(980,748,'Notes')}${directionalNote(1020,802,22,'↑','normal')}${directionalNote(1090,802,22,'↗','diagonal')}${directionalNote(1160,802,22,'←','reverse')}${diamond(1230,802,28,C.space)}${label(1020,850,'Normal',C.muted,'middle')}${label(1090,850,'Diagonal',C.muted,'middle')}${label(1160,850,'Reverse',C.muted,'middle')}${label(1230,850,'Space',C.muted,'middle')}
${label(1390,748,'Progress / focus')}${progress(1390,790,360,.62,C.primary)}${r(1390,830,360,52,'none',10,C.primary,2)}${t(1570,862,'FOCUS HALO',13,C.primary,600,'middle')}`);}

function componentStates(){const stateButton=(x,y,name,state)=>{const disabled=state==='disabled',pressed=state==='pressed',hover=state==='hover';const fill=disabled?C.raised:hover?C.light:pressed?'#8D9CE8':C.primary;return `${state==='focus'?r(x-4,y-4,168,52,'none',12,C.primary,2):''}${r(x,y,160,44,fill,8,disabled?C.border:fill)}${t(x+80,y+28,name,13,disabled?C.muted:C.base,600,'middle')}`};return shell('Album Flow — Component States',`
${label(72,72,'Beat UP! / Design system')}${t(72,128,'COMPONENT STATES',42,C.text,600,'start','Space Grotesk')}${t(72,164,'Complete interactive state coverage for implementation handoff.',15,C.muted)}
${label(72,226,'Button / Primary')}${stateButton(72,252,'DEFAULT','default')}${stateButton(248,252,'HOVER','hover')}${stateButton(424,252,'PRESSED','pressed')}${stateButton(600,252,'FOCUS','focus')}${stateButton(776,252,'DISABLED','disabled')}
${label(1040,226,'Navigation')}${nav(1056,272,'DEFAULT')}${nav(1056,328,'HOVER')}${nav(1056,384,'SELECTED','selected')}${nav(1056,440,'FOCUS','focus')}${t(1056,496,'DISABLED',16,'#596273',400)}
${label(72,366,'Song row / Default + Hover')}${songRow(72,392,'Eyes Half Closed','Crywolf',135,'default',songThumbs.eyes)}${songRow(528,392,'Crab Rave','Noisestorm',125,'hover',songThumbs.crab)}
${label(72,494,'Song row / Selected + Focus')}${songRow(72,520,'Space Invaders','Teminite & MDK',128,'selected',songThumbs.space)}${r(524,516,448,76,'none',13,C.primary,2)}${songRow(528,520,'Bad Apple!!','Alstroemeria Records',140,'default',songThumbs.apple)}
${label(72,650,'Difficulty')}${difficulty(72,678,'NORMAL',4)}${difficulty(204,678,'HARD',7)}${difficulty(336,678,'MASTER',10,true)}
${label(520,650,'Modifiers')}${modifier(520,676,260,'RANDOM','OFF')}${modifier(796,676,260,'8 KEY','SIGNATURE',true)}
${label(1120,650,'Metric')}${metric(1120,680,180,'Accuracy','99.3%',C.primary)}${metric(1340,680,180,'Score','1,000,356')}
${label(72,826,'Artwork treatment')}${artwork(72,850,120)}${label(300,826,'Progress')}${progress(300,872,296,.62,C.primary)}${label(660,826,'Spacing / radii')}${t(660,870,'4  8  12  16  24  32  48  64  96',16,C.text,500,'start','IBM Plex Mono')}${t(660,906,'R8   R12   R16   R18',15,C.muted,400,'start','IBM Plex Mono')}`);}

function gameplayCreatorSystem(){let wave='';for(let i=0;i<48;i++){const x=1010+i*12;const h=12+Math.abs(Math.sin(i*.63))*42;wave+=line(x,710-h/2,x,710+h/2,i%8===0?C.primary:C.cyan,i%8===0?2:1,'opacity=".62"')}return shell('Album Flow — Gameplay & Creator Components',`
${label(72,72,'Beat UP! / Design system')}${t(72,128,'GAMEPLAY & CREATOR',42,C.text,600,'start','Space Grotesk')}${t(72,164,'Input, feedback, note, and manual authoring components.',15,C.muted)}
${label(72,232,'Slider')}${slider(72,278,420,.58)}${label(72,332,'Toggle')}${toggle(72,354,true)}${t(140,374,'ON',14,C.text,600)}${toggle(206,354,false)}${t(274,374,'OFF',14,C.muted,600)}
${label(72,438,'Dropdown')}${dropdown(72,462,420,'CONTROL MODE','8 KEY')}${label(72,550,'Key binding')}${keyBinding(72,578,'7','↖')}${keyBinding(176,578,'8','↑')}${keyBinding(280,578,'9','↗')}
${label(580,232,'Directional notes')}${directionalNote(626,288,34,'↑','normal')}${directionalNote(708,288,34,'↗','diagonal')}${directionalNote(790,288,34,'←','reverse')}${diamond(872,288,42,C.space)}${label(626,344,'Normal',C.muted,'middle')}${label(708,344,'Diagonal',C.muted,'middle')}${label(790,344,'Reverse',C.muted,'middle')}${label(872,344,'Space',C.muted,'middle')}
${label(580,424,'Hit zone')}${hitZone(654,502,56)}${label(580,598,'Judgements')}${t(580,642,'PERFECT',18,C.lilac,600)}${t(730,642,'GREAT',18,C.success,600)}${t(850,642,'GOOD',18,C.cyan,600)}${t(964,642,'MISS',18,C.danger,600)}
${label(1080,232,'Modifier')}${modifier(1080,258,320,'RANDOM','DIRECTION ONLY',true)}${label(1080,340,'Metric')}${metric(1080,370,180,'Combo','368',C.primary)}
${label(1080,510,'Creator timeline note')}${r(1080,542,700,104,C.surface,10,C.border)}${line(1114,594,1746,594,C.border,2)}${directionalNote(1290,594,24,'↙','diagonal')}${directionalNote(1460,594,24,'←','reverse')}${diamond(1620,594,28,C.space)}
${label(980,674,'Waveform')}${r(980,690,680,80,C.surface,10,C.border)}${wave}${label(980,824,'Focus / hover')}${r(980,850,280,52,'none',10,C.primary,2)}${t(1120,882,'FOCUS HALO',14,C.primary,600,'middle')}${r(1290,850,280,52,C.raised,10,C.border)}${t(1430,882,'HOVER SURFACE',14,C.text,600,'middle')}`);}

const screens = [
 ['00_design_system',designSystem],['00b_component_states',componentStates],['00c_gameplay_creator_components',gameplayCreatorSystem],['01_main_menu',mainMenu],['02_song_library',library],['03_song_launch',launch],['04_gameplay',gameplay],['05_pause',pause],['06_result',result],['07_settings',settings],['08_calibration',calibration],['09_how_to_play',howTo],['10_credits',credits],['11_chart_studio',studio]
];
for (const [name,fn] of screens) fs.writeFileSync(path.join(OUT,`${name}.svg`),fn(),'utf8');
const cards=screens.map(([name])=>`<figure><img src="${name}.svg"><figcaption>${name.replace(/^\d+_/,'').replaceAll('_',' ')}</figcaption></figure>`).join('');
fs.writeFileSync(path.join(OUT,'contact-sheet.html'),`<!doctype html><meta charset="utf-8"><style>html,body{margin:0;background:#07090e;color:#d8e0ff;font:12px Poppins,Arial}main{width:1920px;height:1080px;box-sizing:border-box;padding:20px;display:grid;grid-template-columns:repeat(4,1fr);grid-template-rows:repeat(4,1fr);gap:12px}figure{margin:0;background:#131a24;border:1px solid #344052;border-radius:9px;overflow:hidden;display:flex;flex-direction:column}img{display:block;width:100%;aspect-ratio:16/9;object-fit:cover}figcaption{text-transform:uppercase;letter-spacing:1px;padding:5px 9px;color:#8b96a8}</style><main>${cards}</main>`,'utf8');
for (const name of ['02_song_library','07_settings']) {
  fs.writeFileSync(path.join(OUT,`responsive-${name}.html`),`<!doctype html><meta charset="utf-8"><style>html,body{margin:0;width:100%;height:100%;overflow:hidden;background:#0B0E14}img{display:block;width:100vw;height:100vh;object-fit:contain}</style><img src="${name}.svg">`,'utf8');
}
console.log(`Generated ${screens.length} editable SVG frames in ${OUT}`);
