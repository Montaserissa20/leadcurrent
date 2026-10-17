import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "toggle"]
  static values = { label: String }

  toggle() {
    const visible = this.inputTarget.type === "password"
    this.inputTarget.type = visible ? "text" : "password"
    this.toggleTarget.textContent = visible ? "Hide" : "Show"
    this.toggleTarget.setAttribute("aria-label", `${visible ? "Hide" : "Show"} ${this.labelValue}`)
    this.toggleTarget.setAttribute("aria-pressed", String(visible))
  }

  clear() {
    this.inputTarget.value = ""
    this.inputTarget.type = "password"
    this.toggleTarget.textContent = "Show"
    this.toggleTarget.setAttribute("aria-label", `Show ${this.labelValue}`)
    this.toggleTarget.setAttribute("aria-pressed", "false")
  }
}
