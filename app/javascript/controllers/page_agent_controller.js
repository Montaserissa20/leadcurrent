import {Controller} from '@hotwired/stimulus'
import {createAgent,SafeDom,safePath,mask} from 'leadcurrent-page-agent'

export default class extends Controller {
  static targets = ['panel','task','run','stop','status','steps','result','conversation']
  static values = {userId:Number,delay:Number}
  connect() {
    clearTimeout(this.teardownTimer)
    if(this.initialized)return
    this.initialized=true
    this.beforeRender=()=>{if(this.running&&!this.expectedNavigation)this.stop()}
    this.beforeVisit=event=>{if(this.running&&(!this.expectedNavigation||!safePath(new URL(event.detail.url,location.origin).pathname)))this.stop()}
    this.pageHide=()=>{this.stop();this.clear()}
    this.loaded=()=>{document.body.classList.toggle('agent-open',this.element.isConnected&&!this.panelTarget.hidden&&safePath(location.pathname))}
    document.addEventListener('turbo:before-render',this.beforeRender)
    document.addEventListener('turbo:before-visit',this.beforeVisit)
    document.addEventListener('turbo:load',this.loaded)
    window.addEventListener('pagehide',this.pageHide)
  }
  disconnect() {
    this.teardownTimer=setTimeout(()=>{
      if(this.element.isConnected)return
      this.stop();this.agent?.dispose();this.dom?.clear();this.clear()
      document.removeEventListener('turbo:before-render',this.beforeRender)
      document.removeEventListener('turbo:before-visit',this.beforeVisit)
      document.removeEventListener('turbo:load',this.loaded)
      window.removeEventListener('pagehide',this.pageHide)
      document.body.classList.remove('agent-open');this.initialized=false
    },0)
  }
  open(){this.panelTarget.hidden=false;this.element.querySelector('.agent-launcher').setAttribute('aria-expanded','true');document.body.classList.add('agent-open');this.taskTarget.focus()}
  close(){this.stop();this.panelTarget.hidden=true;this.element.querySelector('.agent-launcher').setAttribute('aria-expanded','false');document.body.classList.remove('agent-open');this.element.querySelector('.agent-launcher').focus()}
  keydown(event){
    if(event.key==='Escape'){event.preventDefault();this.close()}
    if(event.key==='Enter'&&(event.ctrlKey||event.metaKey)){event.preventDefault();this.taskTarget.form.requestSubmit()}
  }
  suggest(event){if(!this.running)this.taskTarget.value=event.currentTarget.textContent.trim()}
  resetConversation(){if(!this.running){this.clear();this.taskTarget.focus()}}
  clear(){this.taskTarget.value='';this.stepsTarget.replaceChildren();this.resultTarget.textContent='';this.conversationTarget.replaceChildren();this.conversationId=null;this.setStatus('idle')}
  setStatus(status){this.statusTarget.textContent=status;this.element.dataset.status=status;this.conversationTarget.setAttribute('aria-busy',String(['thinking','acting'].includes(status)))}

  async run(event) {
    event.preventDefault()
    if(this.running)return
    const task=this.taskTarget.value.trim()
    if(!task||task.length>600||!safePath(location.pathname))return
    this.running=true;this.stopping=false;this.proxyError=null;this.proxyErrorCode=null;this.failureCode=null;this.lastAttempt=null;this.lastAgentSuccess=null
    this.requestAbort=new AbortController()
    this.runTarget.disabled=true;this.stopTarget.disabled=false
    this.stepsTarget.replaceChildren();this.resultTarget.textContent=''
    this.message('user',task)
    this.setStatus('thinking')
    try {
      const response=await this.request('/copilot/messages',{message:mask(task,600),page_path:location.pathname,conversation_id:this.conversationId||null},this.requestAbort.signal)
      this.conversationId=response.conversation_id
      if(response.action&&!this.stopping) {
        if(response.kind==='verified_crm')this.reply(response)
        this.activeRunId=response.action.run_id
        this.dom=new SafeDom({navigate:this.navigate.bind(this),userId:this.userIdValue})
        this.agent=createAgent({dom:this.dom,customFetch:this.proxy.bind(this),activity:this.activity.bind(this),delay:this.delayValue})
        let success=false
        try {success=(await this.agent.execute(response.action.task)).success===true} catch(_){success=false}
        this.lastAgentSuccess=success
        if(!this.stopping) {
          const final=await this.request('/copilot/outcome',{conversation_id:this.conversationId,run_id:response.action.run_id,page_path:location.pathname,page_query:location.search,note_present:this.notePresent(),agent_success:success,execution_error:!!(this.proxyError||(this.failureCode&&this.failureCode!=='step_limit'))},this.requestAbort.signal)
          this.reply(final)
          if(this.proxyError)this.resultTarget.textContent=this.proxyError
          this.setStatus(final.verified?'completed':'failed')
        }
      } else if(!this.stopping){this.reply(response);this.setStatus('completed')}
      if(this.stopping){this.setStatus('stopped');this.message('assistant','Stopped. No further browser actions will run. You can continue this conversation.','Status')}
    } catch(error) {
      this.setStatus(this.stopping?'stopped':'failed')
      const text=this.stopping?'Stopped. No further browser actions will run.':error.safeForUser?error.message:'I couldn’t complete that request. Please try again; your conversation is still here.'
      this.message('assistant',text,'Status');this.resultTarget.textContent=text
    } finally {
      this.running=false;this.runTarget.disabled=false;this.stopTarget.disabled=true;this.expectedNavigation=false
      this.dom?.clear();this.agent?.dispose();this.agent=null
      this.activeRunId=null
      this.taskTarget.focus()
    }
  }
  async stop(){if(!this.running)return;this.stopping=true;this.setStatus('stopped');this.requestAbort?.abort();await this.agent?.stop()}

  message(role,text,label) {
    const article=document.createElement('article');article.className='copilot-message';article.dataset.role=role
    const who=document.createElement('strong');who.textContent=role==='user'?'You':'Copilot';article.append(who)
    if(label){const small=document.createElement('small');small.textContent=label;article.append(small)}
    const body=document.createElement('p');body.textContent=mask(text,3500);article.append(body)
    this.conversationTarget.append(article)
    while(this.conversationTarget.children.length>16)this.conversationTarget.firstElementChild.remove()
    this.conversationTarget.scrollTop=this.conversationTarget.scrollHeight
    return article
  }
  reply(data) {
    const labels={guide:'AI explanation · product guide',verified_crm:'Verified CRM data',verified_page:'Verified page',browser_observation:'Observed unsaved form · review required',safety:'Safe Mode',clarification:'Clarification',unverified:'Not verified'}
    const article=this.message('assistant',data.answer,labels[data.kind]||'Copilot')
    if(data.as_of){const small=document.createElement('small');small.textContent='Checked '+new Date(data.as_of).toLocaleTimeString();article.append(small)}
    const rows=[...(data.records||[]),...(data.links||[])]
    if(rows.length){
      const list=document.createElement('ul')
      for(const row of rows){
        const li=document.createElement('li')
        if(typeof row.path==='string'&&/^\/(?:leads(?:\/new|\/\d+)?|opportunities\/\d+|tasks|pipeline|analytics|settings\/password)(?:\?[^#]*)?$/.test(row.path)){
          const link=document.createElement('a');link.href=row.path;link.textContent=mask(row.title,500);li.append(link)
        }else{const title=document.createElement('span');title.textContent=mask(row.title,500);li.append(title)}
        const detail=[row.company,row.status,row.deadline,row.detail].filter(Boolean).join(' · ')
        if(detail){const small=document.createElement('small');small.textContent=mask(detail,700);li.append(small)}
        list.append(li)
      }
      article.append(list)
    }
    this.conversationTarget.scrollTop=this.conversationTarget.scrollHeight
  }
  activity(event) {
    if(this.stopping)return
    if(event.type==='thinking'){this.setStatus('thinking');return}
    if(event.type==='executing'){
      const item=this.dom?.controls.get(event.input?.target)
      this.lastAttempt={tool:event.tool,targetPresent:!!item,targetType:item?.type||null};this.lastControl=item
      this.setStatus('acting')
    }
    if(event.type==='error')this.failureCode=String(event.message||'').includes('six-step limit')?'step_limit':'execution_error'
    if(event.type==='executed'){
      const item=this.lastControl
      const text=event.tool==='done'?'Finished checking the page.':event.tool==='choose_option'?`Selected ${item?.label||'a filter'}.`:event.tool==='fill_field'?item?.type==='note'?'Checked the unsaved note field; nothing submitted.':'Entered search text.':item?.type==='filter'?'Applied the selected filters.':`Opened ${item?.label||'the selected page'}.`
      const li=document.createElement('li');li.textContent=mask(text,350);this.stepsTarget.append(li);this.setStatus('thinking')
    }
  }
  async request(url,payload,signal){
    const response=await this.fetchWithBackoff(url,JSON.stringify(payload),signal)
    const data=await response.json().catch(()=>null)
    if(!response.ok){
      if(data?.error?.code==='conversation_expired')this.conversationId=null
      throw Object.assign(new Error(data?.error?.message||'Your session or AI request is unavailable. Refresh and sign in again.'),{safeForUser:true})
    }
    return data
  }
  async proxy(_url,options){
    const response=await this.fetchWithBackoff('/agent/chat/completions',JSON.stringify({page_path:location.pathname,page_query:location.search,conversation_id:this.conversationId,run_id:this.activeRunId,note_present:this.notePresent(),agent_request:JSON.parse(options.body)}),options.signal)
    if(!response.ok){const data=await response.clone().json().catch(()=>null);this.proxyError=data?.error?.message||'I couldn’t finish this browser action. Please try again.';this.proxyErrorCode=data?.error?.code||null}
    return response
  }
  notePresent(){
    const form=document.querySelector('form.action-form')
    return !!form?.querySelector('[name=body]')?.value.trim()&&form?.querySelector('[name=action_kind]')?.value==='note'&&!form?.querySelector('[name=follow_up_at]')?.value
  }
  async fetchWithBackoff(url,body,signal){
    for(let attempt=0;attempt<2;attempt++){
      signal?.throwIfAborted()
      const response=await fetch(url,{method:'POST',credentials:'same-origin',redirect:'error',signal,headers:{'Content-Type':'application/json','X-CSRF-Token':document.querySelector('meta[name=csrf-token]')?.content||''},body})
      const wait=Number(response.headers.get('Retry-After'))
      if(response.status!==429||attempt||!Number.isFinite(wait)||wait<1||wait>60)return response
      this.resultTarget.textContent=`Waiting ${Math.ceil(wait)} seconds for the shared AI quota. Stop cancels the wait.`
      await new Promise((resolve,reject)=>{
        const abort=()=>{clearTimeout(timer);reject(new DOMException('Stopped','AbortError'))}
        const timer=setTimeout(()=>{signal?.removeEventListener('abort',abort);resolve()},Math.ceil(wait)*1000)
        signal?.addEventListener('abort',abort,{once:true})
        if(signal?.aborted)abort()
      })
      this.resultTarget.textContent=''
    }
  }
  navigate(action,signal){
    return new Promise((resolve,reject)=>{
      let settled=false
      const finish=error=>{if(settled)return;settled=true;clearTimeout(timer);document.removeEventListener('turbo:load',loaded);signal.removeEventListener('abort',aborted);this.expectedNavigation=false;error?reject(error):resolve()}
      const loaded=()=>finish(safePath(location.pathname)?null:new Error('Unsafe destination'))
      const aborted=()=>finish(new DOMException('Stopped','AbortError'))
      const timer=setTimeout(()=>finish(new Error('Navigation did not complete.')),12000)
      document.addEventListener('turbo:load',loaded,{once:true});signal.addEventListener('abort',aborted,{once:true});this.expectedNavigation=true
      try{signal.throwIfAborted();action()}catch(error){finish(error)}
    })
  }
}
