const fs=require('fs'), path=require('path');
const repo=path.resolve(process.argv[2]||'.');
let failures=0; const ok=m=>console.log('[OK] '+m), bad=m=>{console.error('[FAIL] '+m); failures++};
function read(p){try{return JSON.parse(fs.readFileSync(p,'utf8'))}catch(e){bad(`${p}: ${e.message}`);return null}}
const expectedShips={
'acclamator-i-class-assault-ship.json':['Acclamator I-class Assault Ship',64],
'acclamator-ii-class-assault-ship.json':['Acclamator II-class Assault Ship',71],
'consular-class-charger-c70.json':['Consular-class Charger c70',42],
'consular-class-armed-cruiser.json':['Consular-class Armed Cruiser',37]};
for(const [fn,[name,pts]] of Object.entries(expectedShips)){
 const p=path.join(repo,'data','ship-card','galactic-republic',fn), d=read(p);
 if(!d||!Array.isArray(d)||d.length!==1){bad(`${fn} must contain exactly one record`);continue}
 const x=d[0]; if(x.name!==name)bad(`${fn}: name mismatch`); if(x.faction!=='Galactic Republic')bad(`${fn}: faction mismatch`); if(x.points!==pts)bad(`${fn}: expected ${pts} points`); else ok(`${name} (${pts})`);
}
const squadrons={'v-19-torrent-squadron.json':['V-19 Torrent Squadron',12],'axe.json':['Axe',17]};
for(const [fn,[name,pts]] of Object.entries(squadrons)){const d=read(path.join(repo,'data','squadron-card','galactic-republic',fn));if(d&&d[0]&&d[0].name===name&&d[0].points===pts)ok(`${name} (${pts})`);else bad(`${fn}: expected ${name} / ${pts}`)}
const expectedUpgrades={
'commander.json':['Obi-Wan Kenobi','Bail Organa'],'defensive-retrofit.json':['Reactive Gunnery'],'fleet-support.json':['Munitions Resupply','Parts Resupply'],'offensive-retrofit.json':['Hyperspace Rings'],'officer.json':['Clone Captain Zak','Clone Navigation Officer'],'ordnance.json':['Assault Concussion Missiles'],'support-team.json':['Auxiliary Shields Team'],'title.json':['Implacable','Nevoota Bee','Radiant VII','Swift Return'],'turbolasers.json':['Swivel-Mount Batteries'],'weapons-team.json':['Clone Gunners']};
for(const [fn,names] of Object.entries(expectedUpgrades)){const d=read(path.join(repo,'data','upgrade-card',fn));if(!Array.isArray(d))continue; const lower=d.map(x=>String(x.name).toLowerCase()); for(const n of names){const count=lower.filter(x=>x===n.toLowerCase()).length;if(count===1)ok(`${n} present once`);else bad(`${n}: expected once, found ${count}`)}}
const meta=read(path.join(repo,'metadata','products','swm34.json')); if(meta&&meta.code==='SWM34')ok('SWM34 metadata'); else bad('SWM34 metadata missing/invalid');
if(failures){console.error(`\n${failures} validation failure(s).`);process.exit(1)} console.log('\nMilestone 1.1 validation passed.');
