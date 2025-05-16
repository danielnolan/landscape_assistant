import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form"
export default class extends Controller {
  static targets = ["disableable"]
  connect() {
    addEventListener("turbo:submit-start", ((event) => {
      this.disableableTarget.disable();
    }))
    addEventListener("turbo:submit-end", ((event) => {
      this.reset();
      this.disableableTarget.enable();
    }))
  }

  reset() {
    this.element.reset();
  }
}
