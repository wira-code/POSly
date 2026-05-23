class InboundOrder < ApplicationRecord
  has_many :inbound_items, dependent: :destroy

  # ยอมให้กดบันทึกรายการสินค้าพร้อมบิลหลักได้ในหน้าเดียว
  accepts_nested_attributes_for :inbound_items, allow_destroy: true, reject_if: :all_blank
  # 2. บังคับให้กรอกข้อมูลแทน (เพิ่ม inbound_number และ received_at เข้าไป)
  validates :inbound_number, presence: true, uniqueness: true
  validates :received_at, presence: true
  validates :supplier_name, :payment_method, :status, presence: true

  # สร้างเลขที่บิลรับเข้าอัตโนมัติก่อนบันทึก (เช่น INB-20260522-0001)
  # before_validation :generate_inbound_number, on: :create
  before_save :calculate_total_price

  private

  def generate_inbound_number
    return if inbound_number.present?
    date_str = Time.current.strftime("%Y%m%d")
    last_order = InboundOrder.where("inbound_number LIKE ?", "INB-#{date_str}-%").last
    next_number = last_order ? last_order.inbound_number.split("-").last.to_i + 1 : 1
    self.inbound_number = "INB-#{date_str}-#{format('%04d', next_number)}"
    self.received_at ||= Time.current
  end

  # คำนวณราคารวมทั้งหมดของบิลนี้จากรายการย่อย
  def calculate_total_price
    self.total_price = inbound_items.sum { |item| (item.quantity || 0) * (item.unit_cost || 0) }
  end
end
