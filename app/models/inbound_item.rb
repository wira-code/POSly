class InboundItem < ApplicationRecord
  belongs_to :inbound_order
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_cost, presence: true

  # 🌟 เมื่อบันทึกรายการรับเข้าสำเร็จ ให้ไปเพิ่มสต็อกสินค้าชิ้นนั้นทันที
  after_create :increase_product_stock

  private

  def increase_product_stock
    return unless product

    # 1. บวกสต็อกใหม่เพิ่มเข้าไปจากของเดิม
    new_quantity = product.quantity + self.quantity
    product.update_column(:quantity, new_quantity)

    # 2. อัปเดตราคาทุนของสินค้าตัวนี้ ให้เป็นทุนล่าสุดที่รับเข้ามา (Optional)
    product.update_column(:cost, self.unit_cost) if self.unit_cost.present?

    # 3. บันทึกประวัติลงตาราง StockLog (หน้าประวัติเข้าออกจะได้โชว์อัปเดต)
    if defined?(StockLog)
      StockLog.create!(
        product_id: product.id,
        change_amount: self.quantity, # ยอดรับเข้า เป็นบวก (+)
        log_type: "Adjustment",       # ประเภท ปรับปรุง/รับเข้า
        note: "รับเข้าสินค้าอัตโนมัติ บิลเลขที่: ##{inbound_order.inbound_number}"
      )
    end
  end
end
