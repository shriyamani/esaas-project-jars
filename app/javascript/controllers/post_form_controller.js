import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "postBtn",
    "eventBtn",
    "expirationSection",
    "eventSection",
    "customExpiration",
    "eventDate",
    "eventStartTime",
    "eventEndTime",
    "location"
  ]

  connect() {
    if (this.hasEventDateTarget && this.eventDateTarget.value.trim() !== "") {
      this.selectEvent()
    } else {
      this.selectPost()
    }
  }

  userSelectPost() {
    if (this.hasEventDateTarget) this.eventDateTarget.value = ""
    if (this.hasEventStartTimeTarget) this.eventStartTimeTarget.value = ""
    if (this.hasEventEndTimeTarget) this.eventEndTimeTarget.value = ""
    if (this.hasLocationTarget) this.locationTarget.value = ""
    this.selectPost()
  }

  userSelectEvent() {
    this.selectEvent()
  }

  selectPost() {
    if (this.hasPostBtnTarget) this.postBtnTarget.classList.add("is-active")
    if (this.hasEventBtnTarget) this.eventBtnTarget.classList.remove("is-active")
    if (this.hasExpirationSectionTarget) {
      this.expirationSectionTarget.classList.remove("is-hidden")
      this.setDisabled(this.expirationSectionTarget, false)
    }
    if (this.hasEventSectionTarget) this.eventSectionTarget.classList.add("is-hidden")
    this.syncCustomExpiration()
  }

  selectEvent() {
    if (this.hasPostBtnTarget) this.postBtnTarget.classList.remove("is-active")
    if (this.hasEventBtnTarget) this.eventBtnTarget.classList.add("is-active")
    if (this.hasExpirationSectionTarget) {
      this.expirationSectionTarget.classList.add("is-hidden")
      this.setDisabled(this.expirationSectionTarget, true)
    }
    if (this.hasEventSectionTarget) this.eventSectionTarget.classList.remove("is-hidden")
  }

  syncCustomExpiration() {
    if (!this.hasCustomExpirationTarget || !this.hasExpirationSectionTarget) return
    if (this.expirationSectionTarget.classList.contains("is-hidden")) return
    const custom = this.expirationSectionTarget.querySelector('input[name="post[expiration_preset]"][value="Custom"]')
    this.customExpirationTarget.disabled = !(custom && custom.checked)
  }

  setDisabled(container, disabled) {
    container.querySelectorAll("input, select, textarea").forEach((el) => { el.disabled = disabled })
  }
}
