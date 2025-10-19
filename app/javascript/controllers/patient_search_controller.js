import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="patient-search"
export default class extends Controller {
  static targets = ["input", "results", "loading"]
  static values = { 
    url: String,
    minLength: { type: Number, default: 2 },
    debounceDelay: { type: Number, default: 300 }
  }

  connect() {
    console.log("Patient search controller connected")
    this.timeout = null
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  search(event) {
    const query = event.target.value.trim()
    
    // Clear previous timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Clear results if query is too short
    if (query.length < this.minLengthValue) {
      this.clearResults()
      return
    }

    // Show loading state
    this.showLoading()

    // Debounce the search
    this.timeout = setTimeout(() => {
      this.performSearch(query)
    }, this.debounceDelayValue)
  }

  async performSearch(query) {
    try {
      const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        const data = await response.json()
        this.displayResults(data)
      } else {
        this.showError('Search failed. Please try again.')
      }
    } catch (error) {
      console.error('Search error:', error)
      this.showError('Network error occurred')
    } finally {
      this.hideLoading()
    }
  }

  displayResults(patients) {
    if (!this.hasResultsTarget) return

    if (patients.length === 0) {
      this.resultsTarget.innerHTML = '<div class="p-4 text-center text-gray-500">No patients found</div>'
      return
    }

    const html = patients.map(patient => this.formatPatient(patient)).join('')
    this.resultsTarget.innerHTML = html
    this.resultsTarget.classList.remove('hidden')
  }

  formatPatient(patient) {
    return `
      <div class="p-3 border-b border-gray-200 cursor-pointer hover:bg-gray-100 last:border-b-0" 
           data-action="click->patient-search#selectPatient"
           data-patient-id="${patient.id}"
           data-patient-name="${patient.full_name}"
           data-patient-email="${patient.email}">
        <div class="flex items-center space-x-3">
          <div class="flex-shrink-0 w-10 h-10">
            <div class="flex justify-center items-center w-10 h-10 bg-gray-300 rounded-full">
              <span class="text-sm font-medium text-gray-700">
                ${patient.full_name}
              </span>
            </div>
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-gray-900 truncate">
              ${patient.full_name}
            </p>
            <p class="text-sm text-gray-500 truncate">
              ${patient.email}
            </p>
            <p class="text-xs text-gray-400">
              MR# ${patient.medical_record_number}
            </p>
          </div>
          <div class="flex-shrink-0">
            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
              patient.status === 'active' 
                ? 'bg-green-100 text-green-800' 
                : 'bg-gray-100 text-gray-800'
            }">
              ${patient.status}
            </span>
          </div>
        </div>
      </div>
    `
  }

  selectPatient(event) {
    const patientElement = event.currentTarget
    const patientId = patientElement.dataset.patientId
    const patientName = patientElement.dataset.patientName
    const patientEmail = patientElement.dataset.patientEmail
    
    // Update the input field
    if (this.hasInputTarget) {
      this.inputTarget.value = patientName
    }
    
    // Clear results
    this.clearResults()
    
    // Dispatch custom event with patient data
    this.dispatch('patientSelected', { 
      detail: { 
        id: patientId,
        name: patientName,
        email: patientEmail,
        element: patientElement
      }
    })
  }

  clearResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.innerHTML = ''
      this.resultsTarget.classList.add('hidden')
    }
    this.hideLoading()
  }

  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove('hidden')
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add('hidden')
    }
  }

  showError(message) {
    if (this.hasResultsTarget) {
      this.resultsTarget.innerHTML = `<div class="p-4 text-center text-red-500">${message}</div>`
      this.resultsTarget.classList.remove('hidden')
    }
  }

  // Hide results when clicking outside
  hideResults(event) {
    if (!this.element.contains(event.target)) {
      this.clearResults()
    }
  }
}

