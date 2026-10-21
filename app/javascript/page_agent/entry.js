import './zod_csp.js'
import {PageAgentCore, tool} from '@page-agent/core'
import {PageController} from '@page-agent/page-controller'
import {z} from 'zod/v4'
import {SafeDom, safePath, mask} from './safe_dom.js'
export {SafeDom, safePath, mask}

export function createAgent({dom, customFetch, activity, delay = 400}) {
  const pageController = new PageController({enableMask:false,includeAttributes:['data-agent-target'],highlightOpacity:0,highlightLabelOpacity:0,
    interactiveBlacklist:[() => document.getElementById('leadcurrent-agent')]})
  const target = z.string().regex(/^control_\d{1,4}$/)
  const text = z.string().max(600)
  const agent = new PageAgentCore({pageController,baseURL:location.origin+'/agent',model:'openai/gpt-oss-20b',apiKey:'',maxRetries:0,maxSteps:6,stepDelay:delay/1000,
    experimentalScriptExecutionTool:false,experimentalLlmsTxt:false,customFetch,
    customSystemPrompt:'Use the server-enforced Safe Mode policy. Select one permitted DOM control with AgentOutput each step; finish with done.',
    transformPageContent: content => dom.observe(content),
    onBeforeStep: (_agent, step) => {if (step >= 6) throw new Error('Task reached the six-step limit. Narrow the task and run again.');dom.refresh()},
    customTools:{ask_user:null,wait:null,click_element_by_index:null,input_text:null,select_dropdown_option:null,scroll:null,scroll_horizontally:null,execute_javascript:null,
      click_control:tool({description:'Click a permitted link or apply a GET search/filter, using its control_N token.',inputSchema:z.object({target}),execute:dom.click.bind(dom)}),
      fill_field:tool({description:'Type search text or prepare an UNSAVED note; never submit it.',inputSchema:z.object({target,text}),execute:dom.fill.bind(dom)}),
      choose_option:tool({description:'Choose a visible search/filter option by label; use Me for your own records.',inputSchema:z.object({target,text}),execute:dom.choose.bind(dom)}),
      apply_filters:tool({description:'Set up to four search/select fields from the SAME GET filter form, then apply its Filter button in one step. target is the Filter token; fields contain existing search/select tokens and values. No notes or POST forms.',inputSchema:z.object({target,fields:z.array(z.object({target,text})).min(1).max(4)}),execute:dom.applyFilters.bind(dom)})}})
  agent.addEventListener('activity', event => activity(event.detail))
  return agent
}
