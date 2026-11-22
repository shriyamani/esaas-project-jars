import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "postBtn",
    "eventBtn",
    "expirationSection",
    "eventSection",
    "eventDate",
    "eventTime",
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
    if (this.hasEventTimeTarget) this.eventTimeTarget.value = ""
    if (this.hasLocationTarget) this.locationTarget.value = ""
    this.selectPost()
  }

  userSelectEvent() {
    this.selectEvent()
  }

  selectPost() {
    if (this.hasPostBtnTarget) this.postBtnTarget.classList.add("is-active")
    if (this.hasEventBtnTarget) this.eventBtnTarget.classList.remove("is-active")
    if (this.hasExpirationSectionTarget) this.expirationSectionTarget.classList.remove("is-hidden")
    if (this.hasEventSectionTarget) this.eventSectionTarget.classList.add("is-hidden")
  }

  selectEvent() {
    if (this.hasPostBtnTarget) this.postBtnTarget.classList.remove("is-active")
    if (this.hasEventBtnTarget) this.eventBtnTarget.classList.add("is-active")
    if (this.hasExpirationSectionTarget) this.expirationSectionTarget.classList.add("is-hidden")
    if (this.hasEventSectionTarget) this.eventSectionTarget.classList.remove("is-hidden")
  }
}
