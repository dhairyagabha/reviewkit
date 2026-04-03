import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["search", "link", "empty"]

  filter() {
    const query = this.hasSearchTarget ? this.searchTarget.value.trim().toLowerCase() : ""
    let visibleCount = 0

    this.linkTargets.forEach((link) => {
      const path = (link.dataset.path || "").toLowerCase()
      const matches = query.length === 0 || path.includes(query)

      link.hidden = !matches
      if (matches) {
        visibleCount += 1
      }
    })

    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.toggle("hidden", visibleCount > 0)
    }
  }
}
