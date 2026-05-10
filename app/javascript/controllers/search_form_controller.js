import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search-form"
export default class extends Controller {
  static targets = [ "form" ]

  search() {
    // ล้างเวลาเดิมทิ้ง (Debounce) เพื่อไม่ให้ยิง Request ถี่เกินไปขณะพิมพ์
    clearTimeout(this.timeout)

    // รอ 300ms หลังจากหยุดพิมพ์ค่อยส่งข้อมูล
    this.timeout = setTimeout(() => {
      this.formTarget.requestSubmit()
    }, 300)
  }
}
