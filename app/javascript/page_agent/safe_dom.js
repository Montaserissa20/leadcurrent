// Capabilities refer only to visible, existing interface controls. No route/task keyword executor.
export function safePath(path) {
  return /^(\/|\/(leads|opportunities|tasks|analytics|pipeline|activity)|\/(leads|opportunities)\/\d+)$/.test(path)
}
export function mask(text, limit = 4000) {
  return String(text).replace(/\b(?:gsk_|sk-(?:proj-)?|ghp_)[A-Za-z0-9_-]{12,}\b/g, '[credential omitted]')
    .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, '[email omitted]')
    .replace(/(?<!\w)(?:\+\d[\d ()-]{6,}\d|\d{3}[ ()-]\d{3}[ -]\d{4}|\d{10,15})(?!\w)/g, '[phone omitted]').slice(0, limit)
}
const visible = el => el?.isConnected && !el.disabled && el.checkVisibility({checkVisibilityCSS:true}) && !el.closest('[hidden], [inert], #leadcurrent-agent');
const allowedQuery = new Set(['q','status','owner_id','attention','contact_id','lead_id','opportunity_id','commit']);

export class SafeDom {
  constructor({navigate, userId}) { this.navigate = navigate; this.userId = String(userId); this.controls = new Map() }
  allowedLink(el) {
    if (!(el instanceof HTMLAnchorElement) || el.target || el.hasAttribute('download') || el.hasAttribute('data-method') || el.dataset.turboMethod || el.closest('form')) return false
    const url = new URL(el.href, location.origin)
    return url.origin === location.origin && !url.username && !url.password && safePath(url.pathname) && [...url.searchParams.keys()].every(key => allowedQuery.has(key))
  }
  allowedForm(form) {
    if (!(form instanceof HTMLFormElement) || form.method.toLowerCase() !== 'get' || form.target || !form.matches('form.filters')) return false
    const url = new URL(form.action, location.origin)
    return url.origin === location.origin && /^\/(leads|opportunities|tasks|activity)$/.test(url.pathname) && [...form.elements].every(el => (!el.name || allowedQuery.has(el.name)) && !['formaction','formmethod','formtarget'].some(attr => el.hasAttribute(attr)))
  }
  refresh() {
    if (!safePath(location.pathname)) throw new Error('Agent is disabled on this page.')
    document.querySelectorAll('[data-agent-target]').forEach(el => el.removeAttribute('data-agent-target'))
    this.controls.clear()
    const add = (el, type, label) => {
      if (!visible(el)) return
      const id = `control_${this.controls.size + 1}`
      el.dataset.agentTarget = id
      this.controls.set(id, {el, type, label:mask(label, 180)})
    }
    document.querySelectorAll('nav[aria-label="Main navigation"] a, #main-content a').forEach(el => {
      if (!this.allowedLink(el)) return
      const row = el.closest('tr, .record-row')
      const extra = [row?.querySelector('.badge')?.textContent, row?.querySelector('.urgent')?.textContent].filter(Boolean).join('; ')
      const label = el.getAttribute('aria-label') || el.textContent.trim()
      add(el, 'link', `${label}${extra ? '; '+extra : ''}`)
    })
    document.querySelectorAll('form.filters').forEach(form => {
      if (!this.allowedForm(form)) return
      form.querySelectorAll('input[type=search]').forEach(el => add(el, 'search', el.labels?.[0]?.textContent || 'Search'))
      form.querySelectorAll('select').forEach(el => add(el, 'select', el.labels?.[0]?.textContent || el.name))
      form.querySelectorAll('input[type=submit], button[type=submit]').forEach(el => add(el, 'filter', el.value || el.textContent))
    })
    if (/^\/(leads|opportunities)\/\d+$/.test(location.pathname)) {
      document.querySelectorAll('form.action-form input[name=body]').forEach(el => {
        const kind = el.form?.querySelector('[name=action_kind]')
        if (kind?.querySelector('option[value=note]')) add(el, 'note', 'Prepare an unsaved follow-up note; user must manually Save action')
      })
    }
  }
  // Documented transformPageContent hook: reduce the actual library extraction to approved visible controls.
  // Free-text customer histories, sidebars, actor/contact details and existing form values are never included.
  observe(extracted) {
    const lines = [`Visible page: ${mask(document.querySelector('#main-content h1')?.textContent || '', 180)}`, `Applied URL: ${mask(location.pathname + location.search, 300)}`]
    const deadline = document.querySelector('.deadline-banner')
    if (deadline) lines.push(mask(deadline.textContent, 220))
    const rank = item => item.el.closest('nav') ? 0 : item.type !== 'link' ? 1 : 2
    const ordered = [...this.controls].sort((a,b) => rank(a[1])-rank(b[1]))
    for (const [id, item] of ordered) {
      if (!visible(item.el) || !extracted.includes(id)) continue
      let detail = ''
      if (item.type === 'select') {
        const options = [...item.el.options].filter(o => !o.disabled && (item.el.name !== 'owner_id' || !o.value || o.value === this.userId))
        const selected = item.el.selectedOptions[0]
        const current = item.el.name === 'owner_id' && selected?.value === this.userId ? 'Me' : selected?.textContent || ''
        detail = ' selected: '+current+'; options: '+options.map(o => item.el.name === 'owner_id' && o.value === this.userId ? 'Me' : o.textContent).join(' | ')
      }
      if (item.type === 'search') detail = ' current query: '+mask(item.el.value, 100)
      if (item.type === 'note') detail = item.el.value.trim() ? ' UNSAVED TEXT PRESENT: do not overwrite; finish with done and ask the user to review.' : ' current field: empty'
      lines.push(`${id} ${item.type}: ${item.label}${detail}`)
    }
    return mask(lines.join('\n'), 4000)
  }
  get(target, types) {
    const item = this.controls.get(target)
    if (!item || !types.includes(item.type) || !visible(item.el) || item.el.dataset.agentTarget !== target || !safePath(location.pathname)) throw new Error('Safe Mode blocked an unavailable or forbidden control.')
    return item
  }
  async click({target}, {signal}) {
    signal.throwIfAborted()
    const {el,type,label} = this.get(target, ['link','filter'])
    if (type === 'link' && !this.allowedLink(el) || type === 'filter' && !this.allowedForm(el.form)) throw new Error('Safe Mode blocks write controls and external links.')
    el.classList.add('agent-focus')
    el.scrollIntoView({block:'center'})
    await this.navigate(() => type === 'link' ? el.click() : el.form.requestSubmit(el), signal)
    return `Clicked ${label}. Page is now ${location.pathname}${mask(location.search,180)}. No CRM data submitted.`
  }
  async fill({target,text}, {signal}) {
    signal.throwIfAborted()
    const {el,type} = this.get(target, ['search','note'])
    if (typeof text !== 'string' || text.length > 600) throw new Error('Text exceeds the safe preparation limit.')
    if (type === 'search' && !this.allowedForm(el.form)) throw new Error('Only GET search fields are allowed.')
    if (type === 'note') {
      if (el.value.trim()) return 'An unsaved note is already present and was not overwritten. Finish with done; the user must review it.'
      const kind = el.form?.querySelector('select[name=action_kind]')
      if (!el.form?.matches('form.action-form') || !kind?.querySelector('option[value=note]')) throw new Error('Note preparation is unavailable.')
      kind.value = 'note'
      kind.dispatchEvent(new Event('change', {bubbles:true}))
      // A prepared note must not also schedule a task when the human later submits it.
      const follow = el.form.querySelector('input[name=follow_up_at]')
      if (follow) follow.value = ''
    }
    el.scrollIntoView({block:'center'})
    el.classList.add('agent-focus')
    Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set.call(el, mask(text, 600))
    el.dispatchEvent(new Event('input',{bubbles:true}))
    el.dispatchEvent(new Event('change',{bubbles:true}))
    return type === 'note' ? 'UNSAVED note prepared. No contact or task recorded. The user must review and manually click Save action.' : `Search query set to ${mask(text,100)}; apply the visible Filter control next.`
  }
  async choose({target,text}, {signal}) {
    signal.throwIfAborted()
    const {el,label} = this.get(target,['select'])
    if (!this.allowedForm(el.form)) throw new Error('Safe Mode only permits search filters.')
    const option = [...el.options].find(o => !o.disabled && (el.name === 'owner_id' ? (text === 'Me' && o.value === this.userId) || (!o.value && o.textContent === text) : o.textContent === text))
    if (!option) throw new Error('Choose a permitted visible filter option.')
    el.value = option.value
    el.dispatchEvent(new Event('change',{bubbles:true}))
    el.classList.add('agent-focus')
    return `Selected ${label} = ${mask(text,100)}. Apply Filter next.`
  }
  async applyFilters({target,fields},{signal}) {
    signal.throwIfAborted()
    const filter=this.get(target,['filter'])
    const form=filter.el.form
    if(!this.allowedForm(form)||!Array.isArray(fields)||fields.length<1||fields.length>4||new Set(fields.map(field=>field.target)).size!==fields.length)throw new Error('Safe Mode blocks an invalid filter batch.')
    // Validate the ENTIRE operation before changing any field. Every target must be in this one GET form.
    const operations=fields.map(field=>{
      const item=this.get(field.target,['search','select'])
      if(item.el.form!==form||typeof field.text!=='string'||field.text.length>600)throw new Error('Safe Mode blocks fields outside this GET filter form.')
      if(item.type==='select'&&![...item.el.options].some(o=>!o.disabled&&(item.el.name==='owner_id'?(field.text==='Me'&&o.value===this.userId)||(!o.value&&o.textContent===field.text):o.textContent===field.text)))throw new Error('Choose a permitted visible filter option.')
      return {field,type:item.type}
    })
    for(const {field,type} of operations){
      signal.throwIfAborted()
      await (type==='select'?this.choose(field,{signal}):this.fill(field,{signal}))
    }
    return this.click({target},{signal})
  }
  clear() {
    document.querySelectorAll('[data-agent-target]').forEach(el => el.removeAttribute('data-agent-target'))
    document.querySelectorAll('.agent-focus').forEach(el => el.classList.remove('agent-focus'))
    this.controls.clear()
  }
}
