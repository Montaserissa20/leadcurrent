import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["feedback"]

  async copy(event) {
    const button = event.currentTarget
    const source = document.getElementById(button.dataset.copySource)
    if (!source || !this.element.contains(source)) return
    this.resetFeedback()
    const version = this.copyVersion = (this.copyVersion || 0) + 1
    try {
      await navigator.clipboard.writeText(source.textContent)
      if (!this.element.isConnected || version !== this.copyVersion) return
      this.feedbackTarget.textContent = "Copied. Configure your private credential before running an example."
      this.copiedButton = button
      this.originalLabel = button.textContent
      button.textContent = "Copied!"
      this.feedbackTimer = setTimeout(() => {
        this.resetFeedback()
      }, 2500)
    } catch (_) {
      if (!this.element.isConnected || version !== this.copyVersion) return
      // Clipboard restrictions are reported, never silently treated as success.
      const selection = window.getSelection()
      const range = document.createRange()
      range.selectNodeContents(source)
      selection.removeAllRanges()
      selection.addRange(range)
      this.feedbackTarget.textContent = "Clipboard unavailable. Example selected; press Ctrl+C or Command+C to copy."
      source.closest("pre")?.focus()
    }
  }

  resetFeedback() {
    clearTimeout(this.feedbackTimer)
    if (this.copiedButton?.isConnected) this.copiedButton.textContent = this.originalLabel
    if (this.hasFeedbackTarget) this.feedbackTarget.textContent = ""
    this.copiedButton = null
  }

  disconnect() { this.copyVersion = (this.copyVersion || 0) + 1; this.resetFeedback() }
}
