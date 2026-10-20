import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit", "loading", "networkError", "result", "question", "copyStatus"]

  guard(event) {
    if (this.pending) {
      event.preventDefault()
      event.stopImmediatePropagation()
    }
  }

  start() {
    this.pending = true
    this.submitTargets.forEach(button => { button.disabled = true })
    this.loadingTarget.hidden = false
    this.networkErrorTarget.hidden = true
    this.resultTarget.setAttribute("aria-busy", "true")
  }

  finish() {
    this.pending = false
    this.submitTargets.forEach(button => { button.disabled = false })
    this.loadingTarget.hidden = true
    this.resultTarget.removeAttribute("aria-busy")
  }

  networkError() {
    this.finish()
    this.networkErrorTarget.hidden = false
  }

  frameMissing(event) {
    event.preventDefault()
    this.networkError()
  }

  clear() {
    this.finish()
    this.questionTarget.value = ""
    this.resultTarget.textContent = "Advice is not saved. Ask again for a fresh reading."
    this.networkErrorTarget.hidden = true
  }

  async copy() {
    const content = this.resultTarget.querySelector('[data-copy-content="draft"]') || this.resultTarget.querySelector('[data-copy-content="advice"]')
    if (!content) return
    try {
      await navigator.clipboard.writeText(content.innerText)
      this.copyStatusTarget.textContent = "Copied for review."
    } catch (_) {
      this.copyStatusTarget.textContent = "Select the response text and copy it manually."
    }
  }
}
