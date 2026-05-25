class InboundItem < ApplicationRecord
  belongs_to :inbound_order
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_cost, presence: true

  # 🌟 เมื่อบันทึกรายการรับเข้าสำเร็จ ให้ไปเพิ่มสต็อกสินค้าชิ้นนั้นทันที
  # after_create :increase_product_stock

  # 🌟 เพิ่มบรรทัดนี้: เมื่อตัวลูกสร้างเสร็จสมบูรณ์ในฐานข้อมูล ให้เช็คเพื่อบวกสต็อก
  after_create_commit :increase_stock_if_order_completed

  # แล้วอัปเดตราคาทุนตอนบันทึกปกติแทน
  after_save :update_product_cost

  # 🌟 Method สำหรับ "เพิ่มสต็อก" (จะทำงานเมื่อบิลเปลี่ยนเป็น completed)
  def trigger_stock_increase
    return unless product && quantity.present? && defined?(StockLog)
    order_identifier = inbound_order.respond_to?(:inbound_number) ? inbound_order.inbound_number : inbound_order.id

    StockLog.create!(
      product_id: product.id,
      change_amount: self.quantity, # ค่าเป็นบวก (+) เพื่อเพิ่มสต็อก
      log_type: "Adjustment",
      note: "รับเข้าสินค้าอัตโนมัติ บิลเลขที่: ##{inbound_order.inbound_number}"
    )
  end

  # 🌟 Method สำหรับ "คืนสต็อก/หักออก" (จะทำงานเมื่อบิลถูก Cancelled หรือ Deleted)
  def trigger_stock_decrease
    return unless product && quantity.present? && defined?(StockLog)

    order_identifier = inbound_order.respond_to?(:inbound_number) ? inbound_order.inbound_number : inbound_order.id

    StockLog.create!(
      product_id: product.id,
      change_amount: -self.quantity, # ⚠️ ใส่เครื่องหมายลบ (-) เพื่อหักสต็อกคืน!
      log_type: "Adjustment",
      note: "คืนสต็อก/ยกเลิกรายการ บิลเลขที่: ##{inbound_order.inbound_number}"
    )
  end

  private

  def update_product_cost
    product.update_column(:cost, self.unit_cost) if product && self.unit_cost.present?
  end

  # 🌟 เมธอดเช็คความพร้อมตอนสร้างไอเทมใหม่ป้ายแดง
  def increase_stock_if_order_completed
    # ถ้าบิลตัวแม่มีอยู่จริง และสถานะของแม่เป็น completed ให้สั่งบวกสต็อกทันที
    if inbound_order && inbound_order.status == "completed"
      trigger_stock_increase
    end
  end
end


#  private

#  def increase_product_stock
#    return unless product
#
# () 1. บวกสต็อกใหม่เพิ่มเข้าไปจากของเดิม
# () new_quantity = product.quantity + self.quantity
# () product.update_column(:quantity, new_quantity)

# () 2. อัปเดตราคาทุนของสินค้าตัวนี้ ให้เป็นทุนล่าสุดที่รับเข้ามา (Optional)
#    product.update_column(:cost, self.unit_cost) if self.unit_cost.present?

# () 3. บันทึกประวัติลงตาราง StockLog (หน้าประวัติเข้าออกจะได้โชว์อัปเดต)
#    if defined?(StockLog)
#      StockLog.create!(
#        product_id: product.id,
#        change_amount: self.quantity, # ยอดรับเข้า เป็นบวก (+)
#        log_type: "Adjustment",       # ประเภท ปรับปรุง/รับเข้า
#        note: "รับเข้าสินค้าอัตโนมัติ บิลเลขที่: ##{inbound_order.inbound_number}"
#      )
#    end
#  end
