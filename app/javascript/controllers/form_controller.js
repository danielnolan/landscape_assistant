import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form"
export default class extends Controller {
  static targets = ["disableable"]
  initialize() {
    addEventListener("turbo:submit-start", ((event) => {
      this.disableableTarget.disabled = true;
    }))
    addEventListener("turbo:submit-end", ((event) => {
      this.reset();
      this.disableableTarget.disabled = false;
    }))
  }

  reset() {
    this.element.reset();
  }
}
