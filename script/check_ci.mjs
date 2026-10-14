import {spawnSync} from 'node:child_process';
const result=spawnSync('git',['credential','fill'],{input:'protocol=https\nhost=github.com\n\n',encoding:'utf8',env:{...process.env,GCM_INTERACTIVE:'never',GIT_TERMINAL_PROMPT:'0'}});
const values=Object.fromEntries((result.stdout||'').trim().split('\n').map(line=>{const n=line.indexOf('=');return [line.slice(0,n),line.slice(n+1)];}));
const headers={Authorization:'Bearer '+values.password,Accept:'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28'};
const commit = spawnSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).stdout.trim();
const response=await fetch('https://api.github.com/repos/Montaserissa20/leadcurrent/actions/runs?per_page=10&head_sha='+commit,{headers});
if(!response.ok) throw new Error('CI status unavailable: '+response.status);
const runs=(await response.json()).workflow_runs.filter(r => r.head_sha === commit && r.name === 'LeadCurrent CI');
console.log('Checking exact local HEAD: ' + commit);
console.log(JSON.stringify(runs.map(r=>({id:r.id,sha:r.head_sha,status:r.status,conclusion:r.conclusion,url:r.html_url})),null,2));
if(process.argv.includes('--logs') && runs[0]) {
 const jobs=await (await fetch('https://api.github.com/repos/Montaserissa20/leadcurrent/actions/runs/'+runs[0].id+'/jobs',{headers})).json();
 console.log(JSON.stringify(jobs.jobs?.map(j=>({id:j.id,status:j.status,conclusion:j.conclusion,steps:j.steps.map(s=>({name:s.name,conclusion:s.conclusion}))})),null,2));
 for(const job of (jobs.jobs||[]).filter(j=>j.conclusion==='failure')){
   const logResponse=await fetch('https://api.github.com/repos/Montaserissa20/leadcurrent/actions/jobs/'+job.id+'/logs',{headers});
   const lines=(await logResponse.text()).split('\n');
   for(let i=0;i<lines.length;i++) if(/Error:|Failure:|##\[error\]|Finished in|runs, .*assertions/.test(lines[i])) console.log(lines.slice(Math.max(0,i-2),i+10).join('\n'));
 }
}
