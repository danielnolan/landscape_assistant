import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form"
export default class extends Controller {
  connect() {
    addEventListener("turbo:submit-end", ((event) => {
      this.reset();
    }))
  }

  reset() {
    this.element.reset();
  }
}
