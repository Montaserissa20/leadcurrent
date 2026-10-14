import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["sidebar"]
  connect() {
    let theme
    try { theme = localStorage.getItem("leadcurrent-theme") } catch (_) {}
    this.element.dataset.theme = theme || (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")
  }
  toggleTheme() {
    const theme = this.element.dataset.theme === "dark" ? "light" : "dark"
    this.element.dataset.theme = theme
    try { localStorage.setItem("leadcurrent-theme", theme) } catch (_) {}
  }
  toggleMenu(event) {
    if (this.hasSidebarTarget) {
      const open = this.sidebarTarget.classList.toggle("open")
      event.currentTarget.setAttribute("aria-expanded", String(open))
    }
  }
}
