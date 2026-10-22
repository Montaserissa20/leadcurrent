import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["secret"]
  connect() {
    this.clearSecret = () => { if (this.hasSecretTarget) this.secretTarget.textContent = "Credential hidden. Generate a new credential if you did not save it." }
    document.addEventListener("turbo:before-cache", this.clearSecret)
    window.addEventListener("pagehide", this.clearSecret)
  }
  disconnect() {
    this.clearSecret()
    document.removeEventListener("turbo:before-cache", this.clearSecret)
    window.removeEventListener("pagehide", this.clearSecret)
  }
}
