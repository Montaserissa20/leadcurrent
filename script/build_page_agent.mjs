import {build} from 'esbuild';
import fs from 'node:fs';
fs.mkdirSync('app/assets/builds', {recursive:true});
const license=['page-agent-LICENSE.txt','zod-LICENSE.txt','chalk-LICENSE.txt','browser-use-NOTICE.txt'].map(name=>fs.readFileSync('vendor/licenses/'+name,'utf8')).join('\n\n');
await build({entryPoints:['app/javascript/page_agent/entry.js'],outfile:'app/assets/builds/page_agent.js',bundle:true,format:'esm',platform:'browser',target:['es2022'],minify:true,drop:['console','debugger'],legalComments:'linked',banner:{js:'/*!\n'+license+'\n*/'},metafile:true}).then(result=>{
  fs.mkdirSync('.local',{recursive:true});
  fs.writeFileSync('.local/page-agent-build.json',JSON.stringify({inputs:Object.keys(result.metafile.inputs),outputs:result.metafile.outputs},null,2));
});
