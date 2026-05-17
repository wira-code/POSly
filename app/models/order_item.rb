class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  # after_create :reduce_product_stock

  # 🌟 ตรวจสอบตรงนี้: ต้องเปลี่ยนชื่อตัวเรียกหลัง after_save ให้เป็นชื่อเดียวกับเมธอดด้านล่าง
  after_save :adjust_product_stock
  after_destroy :restore_stock_on_destroy

  private

  # 🌟 นี่คือเมธอดหลักที่เราใช้จัดการสต็อกทั้งตอนซื้อใหม่และตอนแก้ไขบิล
  def adjust_product_stock
    product = self.product
    return unless product

    # 1. คำนวณหาจำนวนที่เปลี่ยนแปลง (เพื่อนำไปบันทึกลง Log)
    if saved_change_to_id?
      # เพิ่มรายการสินค้าชิ้นนี้เข้ามาใหม่ในบิลเดิม -> สต็อกลดลงตามจำนวนชิ้นที่สั่ง
      quantity_change = -self.quantity
      # กรณีเพิ่มสินค้าแถวใหม่เข้ามาในบิล -> หักสต็อกตามจำนวนปกติ
      new_quantity = product.quantity - self.quantity
    else
      # กรณีแก้ไขจำนวนสินค้าแถวเดิม -> คำนวณหาส่วนต่างเพื่อเพิ่ม/ลดสต็อกให้ถูกต้อง
      old_qty, new_qty = saved_change_to_quantity || [ quantity, quantity ]
      diff = new_qty - old_qty
      quantity_change = -diff  # ถ้าสั่งเพิ่มขึ้น ค่าติดลบจะมากขึ้น (เช่น สั่งเพิ่ม 1 ชิ้น สต็อกต้องลบออก 1)
      new_quantity = product.quantity - diff
    end

    # 2. อัปเดตยอดสต็อกใหม่ลงเซิร์ฟเวอร์ทันที
    product.update_column(:quantity, new_quantity)

    # 🌟 3. เพิ่มคำสั่งสร้าง Log ลงตารางประวัติ (Stock Logs) อัตโนมัติ 🌟
    # (เปลี่ยนชื่อโมเดลและชื่อคอลัมน์ให้ตรงกับที่ระบบคุณใช้อยู่จริงนะครับ)
    if quantity_change != 0 && defined?(StockLog)
      StockLog.create!(
        product_id: product.id,
        change_amount: quantity_change, # บันทึกยอดความเปลี่ยนแปลง เช่น -1 หรือ +2
        note: "ปรับปรุงยอดจากบิลหมายเลข: #{order.order_number || order.id} (แก้ไขรายการ)"
      )
    end
  end

  # เมธอดคืนสต็อกเมื่อมีการกดลบรายการสินค้านั้นออกจากหน้าฟอร์ม
  def restore_stock_on_destroy
    product = self.product
    if product && self.quantity.present?
      # คืนสต็อกเข้าคลังสินค้า
      product.update_column(:quantity, product.quantity + self.quantity)

      # 🌟 สร้าง Log บันทึกกรณีพนักงานกดปุ่มลบรายการสินค้านั้นออกจากบิล
      if defined?(StockLog)
        StockLog.create!(
         product_id: product.id,
          change_amount: self.quantity, # 🌟 แก้ไขเป็น :change_amount ตาม schema จริง
          log_type: "Return",   # 🌟 เพิ่ม :log_type ให้สอดคล้องกับ schema
          note: "คืนสต็อกเนื่องจากลบรายการออกจากบิล: #{order.order_number || order.id}"
        )
      end
    end
  end
end

# private

# def reduce_product_stock
# สร้าง StockLog ประเภท "Sale" เพื่อไปตัดยอดใน Inventory อัตโนมัติ
# เราส่งค่าติดลบ เพราะเป็นการขายออก
#  product.stock_logs.create!(
#    change_amount: -self.quantity,
#    log_type: "Sale",
#    note: "ขายสินค้า (Order ##{order.id})"
# )
# end
