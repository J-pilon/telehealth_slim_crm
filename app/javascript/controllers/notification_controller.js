import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="notification"
export default class extends Controller {
  static targets = ["message"]
  static values = { 
    type: { type: String, default: 'info' },
    duration: { type: Number, default: 5000 },
    autoHide: { type: Boolean, default: true }
  }

  connect() {
    console.log("Notification controller connected")
    
    if (this.autoHideValue) {
      this.timeout = setTimeout(() => {
        this.hide()
      }, this.durationValue)
    }
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  show(message, type = 'info', duration = 5000) {
    this.messageTarget.textContent = message
    this.typeValue = type
    this.durationValue = duration
    
    // Update classes based on type
    this.updateClasses(type)
    
    // Show the notification
    this.element.classList.remove('hidden')
    this.element.classList.add('animate-fade-in')
    
    // Auto-hide if enabled
    if (this.autoHideValue) {
      if (this.timeout) {
        clearTimeout(this.timeout)
      }
      this.timeout = setTimeout(() => {
        this.hide()
      }, this.durationValue)
    }
  }

  hide() {
    this.element.classList.add('animate-fade-out')
    
    setTimeout(() => {
      this.element.classList.add('hidden')
      this.element.classList.remove('animate-fade-in', 'animate-fade-out')
    }, 300)
  }

  updateClasses(type) {
    // Remove all type classes
    this.element.classList.remove(
      'bg-blue-500', 'bg-green-500', 'bg-yellow-500', 'bg-red-500',
      'text-blue-100', 'text-green-100', 'text-yellow-100', 'text-red-100',
      'border-blue-400', 'border-green-400', 'border-yellow-400', 'border-red-400'
    )

    // Add appropriate classes based on type
    switch (type) {
      case 'success':
        this.element.classList.add('bg-green-500', 'text-green-100', 'border-green-400')
        break
      case 'warning':
        this.element.classList.add('bg-yellow-500', 'text-yellow-100', 'border-yellow-400')
        break
      case 'error':
        this.element.classList.add('bg-red-500', 'text-red-100', 'border-red-400')
        break
      default: // info
        this.element.classList.add('bg-blue-500', 'text-blue-100', 'border-blue-400')
    }
  }

  // Static method to show notifications from anywhere
  static show(message, type = 'info', duration = 5000) {
    const notification = document.querySelector('[data-controller="notification"]')
    if (notification) {
      const controller = this.application.getControllerForElementAndIdentifier(notification, 'notification')
      controller.show(message, type, duration)
    }
  }
}

