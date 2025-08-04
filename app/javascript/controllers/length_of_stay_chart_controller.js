import { Controller } from "@hotwired/stimulus"
import { bb, bar } from "billboard.js";
import "billboard.js/dist/billboard.css";

export default class extends Controller {
  static targets = ["formContainer", "organizationTitle", "tableBody", "chart", "downloadLink"]
  static values = {
    headers: Array,
    chartKeys: Array
  }

  connect() {
    this.dirty = false
    this.chart = null
    // The original code uses App.util.colorList. We'll use this color palette as a fallback.
    this.colors = ['#45789C', '#F15A24', '#FBB03B', '#8E5EA2', '#3CBA9F', '#2A7F62', '#8BC34A', '#FFC107', '#03A9F4', '#E91E63']
    this.form.addEventListener('submit', this.submit.bind(this))
  }

  disconnect() {
    this.form.removeEventListener('submit', this.submit.bind(this))
    if (this.chart) {
      this.chart.destroy()
    }
  }

  get form() {
    return this.formContainerTarget.querySelector('form');
  }

  get submitButton() {
    return this.form.querySelector('.jSubmit');
  }

  async submit(event) {
    event.preventDefault()

    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
    this.chartTarget.style.height = "0px"


    this.organizationTitleTarget.style.display = 'none'

    const selectElement = this.form.querySelector('select');
    const orgName = selectElement && selectElement.selectedIndex > -1
      ? selectElement.options[selectElement.selectedIndex].text
      : '';

    this.tableBodyTarget.innerHTML = `<tr><td class='loading-cell' colspan=${this.headersValue.length + 1}>Loading...</td></tr>`

    this.addDot()
    this.submitButton.disabled = true;

    const formData = new URLSearchParams(new FormData(this.form)).toString()
    const url = `${this.form.action}?${formData}`

    try {
      const response = await fetch(url)
      this.tableBodyTarget.innerHTML = '' // Clear loading message
      if (response.ok) {
        const data = await response.json()
        if (this.dirty) {
          this.dirty = false
          this.formContainerTarget.innerHTML = data.form
          // re-attach listener after form is replaced
          this.form.addEventListener('submit', this.submit.bind(this))
        }
        this.organizationTitleTarget.textContent = orgName
        this.organizationTitleTarget.style.display = 'block'

        this.tableBodyTarget.innerHTML = ''
        const table = data.table
        table.forEach(row => {
          const key = row[0]
          const hash = row[1]
          const tr = document.createElement('tr')
          const keyTd = document.createElement('td')
          keyTd.textContent = key
          tr.appendChild(keyTd)

          this.headersValue.forEach((header, j) => {
            const td = document.createElement('td')
            td.textContent = hash[header]
            if (j % 2 === 0) {
              td.classList.add('lightest-gray')
            }
            tr.appendChild(td)
          })
          this.tableBodyTarget.appendChild(tr)
        })

        this.makeChart(table)

        const href = this.downloadLinkTarget.href.replace(/(\?.*)?$/, `?${formData}`)
        this.downloadLinkTarget.setAttribute('href', href)
        this.submitButton.disabled = false
      } else if (response.status === 400) {
        const html = await response.text()
        this.formContainerTarget.innerHTML = html
        this.dirty = true
        // re-attach listener after form is replaced
        this.form.addEventListener('submit', this.submit.bind(this))

      } else {
        alert(await response.text())
        this.submitButton.disabled = false
      }
    } catch (e) {
      console.error(e);
      this.tableBodyTarget.innerHTML = ''
      alert(e.message)
      this.submitButton.disabled = false
    }
  }

  addDot() {
    const loadingCell = this.tableBodyTarget.querySelector('.loading-cell')
    if (loadingCell && loadingCell.textContent.startsWith("Loading")) {
      loadingCell.textContent += ' .'
      this.dotTimer = setTimeout(() => this.addDot(), 1000)
    }
  }

  makeChart(data) {
    // const { bb } = window.bb;
    const anyNonZero = data.some(d => {
      return this.chartKeysValue.some(k => d[1][k] > 0)
    })

    if (!anyNonZero) {
      this.chartTarget.style.height = '0px'
      return
    }

    const columns = data.map(d => {
      const projectName = d[0]
      const values = this.chartKeysValue.map(k => d[1][k])
      return [projectName, ...values]
    })

    const height = 300 + Math.ceil(data.length / 15) * 50
    this.chartTarget.height = height
    this.chartTarget.style.height = `${height}px`

    const colorPattern = data.map((_, i) => this.colors[i % this.colors.length]);

    const chartConfig = {
      bindto: this.chartTarget,
      data: {
        columns: columns,
        type: bar(),
      },
      axis: {
        x: {
          type: 'category',
          categories: this.chartKeysValue,
        },
      },
      color: {
        pattern: colorPattern,
      },
      legend: {
        show: true,
      },
    }

    this.chart = bb.generate(chartConfig)
  }
}
