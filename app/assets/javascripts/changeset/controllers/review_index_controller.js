import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["count", "empty", "filter", "row", "search", "select"]

  connect() {
    this.activeStatus = "all"
    this.syncFilterControls()
    this.filter()
  }

  applyStatusFilter(event) {
    this.activeStatus = event.currentTarget.dataset.status || "all"
    this.syncFilterControls()
    this.filter()
  }

  selectStatusFilter(event) {
    this.activeStatus = event.currentTarget.value || "all"
    this.syncFilterControls()
    this.filter()
  }

  openRow(event) {
    if (event.defaultPrevented) return
    if (event.target.closest("a, button, input, label, summary, details, textarea, select, form")) return

    const url = event.currentTarget.dataset.url
    if (url) {
      window.Turbo.visit(url)
    }
  }

  openRowFromKeyboard(event) {
    if (event.key !== "Enter" && event.key !== " ") return

    event.preventDefault()
    this.openRow(event)
  }

  filter() {
    const query = this.hasSearchTarget ? this.searchTarget.value.trim().toLowerCase() : ""
    let visibleCount = 0

    this.rowTargets.forEach((row) => {
      const haystack = (row.dataset.search || "").toLowerCase()
      const matchesQuery = query.length === 0 || haystack.includes(query)
      const matchesStatus = this.activeStatus === "all" || row.dataset.status === this.activeStatus
      const matches = matchesQuery && matchesStatus

      row.hidden = !matches
      if (matches) {
        visibleCount += 1
      }
    })

    if (this.hasCountTarget) {
      this.countTarget.textContent = visibleCount.toString()
    }

    if (this.hasEmptyTarget) {
      this.emptyTarget.hidden = visibleCount > 0
    }
  }

  syncFilterControls() {
    this.filterTargets.forEach((button) => {
      const active = (button.dataset.status || "all") === this.activeStatus

      button.classList.toggle("changeset-index-tab--active", active)
      button.setAttribute("aria-selected", active ? "true" : "false")
      button.tabIndex = active ? 0 : -1

      const count = button.querySelector(".changeset-index-tab__count")
      if (count) {
        count.classList.toggle("changeset-index-tab__count--active", active)
      }
    })

    if (this.hasSelectTarget) {
      this.selectTarget.value = this.activeStatus
    }
  }
}
