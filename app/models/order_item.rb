class OrderItem < ApplicationRecord
  belongs_to :order, optional: true
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true

  # ❌ ลบ after_save :adjust_product_stock ออกไปเลยครับ
  # ❌ ลบ after_destroy :restore_stock_on_destroy ออกไปเลยครับ
  # เพื่อปล่อยให้ระบบสถานะของ Order (ตัวแม่) เป็นคนควบคุมจังหวะการตัดสต็อกแทน

  # 🌟 Method 1: สำหรับ "หักสต็อกออกจากคลัง" (จะทำงานเมื่อสั่งซื้อสำเร็จ)
  def trigger_stock_decrease
    return unless product && quantity.present? && defined?(StockLog)

    order_identifier = order.respond_to?(:order_number) ? order.order_number : order.id

    StockLog.create!(
      product_id: product.id,
      change_amount: -self.quantity, # ⚠️ ค่าติดลบ (-) เพราะเป็นการขายสินค้าออกไป
      log_type: "Sale",              # ประเภทเป็นบิลขาย
      note: "ขายสินค้าหน้าร้าน บิลหมายเลข: ##{order_identifier}"
    )
  end

  # 🌟 Method 2: สำหรับ "คืนสต็อกกลับเข้าคลัง" (จะทำงานเมื่อบิลถูกยกเลิก หรือโดนลบ)
  def trigger_stock_increase
    return unless product && quantity.present? && defined?(StockLog)

    order_identifier = order.respond_to?(:order_number) ? order.order_number : order.id

    StockLog.create!(
      product_id: product.id,
      change_amount: self.quantity,  # ⚠️ ค่าเป็นบวก (+) เพื่อดึงสต็อกกลับเข้าคลัง
      log_type: "Return",            # ประเภทเป็นการคืนสินค้า
      note: "คืนสต็อก/ยกเลิกรายการขาย บิลหมายเลข: ##{order_identifier}"
    )
  end
end





=begin
  belongs_to :order
  belongs_to :product
  # 🌟 ตรวจเช็คให้ดี: หากคุณมีสองบรรทัดนี้อยู่ ยอดห้ามส่งมาเป็น 0 หรือว่างเด็ดขาด
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true

  # after_create :reduce_product_stock

  # 🌟 ใช้ after_save และ after_destroy ในการควบคุมสต็อก  ต้องเปลี่ยนชื่อตัวเรียกหลัง after_save ให้เป็นชื่อเดียวกับเมธอดด้านล่าง
  after_save :adjust_product_stock
  after_destroy :restore_stock_on_destroy
  # ลบเพื่อปล่อยให้ระบบสถานะของ Order (ตัวแม่) เป็นคนควบคุมจังหวะการตัดสต็อกแทน

  private

  # 🌟 นี่คือเมธอดหลักที่เราใช้จัดการสต็อกทั้งตอนซื้อใหม่และตอนแก้ไขบิล
  def adjust_product_stock
    product = self.product
    return unless product

    # 1. เช็คว่าเป็นออเดอร์สร้างใหม่ หรือเป็นการเอาบิลเก่ามาแก้ไขจำนวนชิ้น
    if saved_change_to_id?
      # เพิ่มรายการสินค้าชิ้นนี้เข้ามาใหม่ในบิลเดิม -> สต็อกลดลงตามจำนวนชิ้นที่สั่ง
      # quantity_change = product.quantity - self.quantity
      quantity_change = -self.quantity
      # กรณีเพิ่มสินค้าแถวใหม่เข้ามาในบิล -> หักสต็อกตามจำนวนปกติ
      new_quantity = product.quantity - self.quantity
    else
      # กรณีแก้ไขจำนวนสินค้าแถวเดิม -> คำนวณหาส่วนต่างเพื่อเพิ่ม/ลดสต็อกให้ถูกต้อง
      old_qty, new_qty = saved_change_to_quantity || [ quantity, quantity ]
      diff = new_qty - old_qty
      quantity_change = -diff # สั่งสินค้าเพิ่ม = สต็อกต้องลดลง (-) / สั่งสินค้าน้อยลง = สต็อกต้องเพิ่มกลับมา (+)(เช่น สั่งเพิ่ม 1 ชิ้น สต็อกต้องลบออก 1)
      new_quantity = product.quantity - diff
    end

    # 2. ทำการบันทึกยอดรวมสินค้าคงคลังสุทธิลงคอลัมน์ quantity ในตาราง products โดยไม่เปิด Validation ซ้ำซ้อน
    product.update_column(:quantity, new_quantity)

    # 3. บันทึกประวัติประทับตราเข้าตาราง stock_logs อัตโนมัติ
    # (เปลี่ยนชื่อโมเดลและชื่อคอลัมน์ให้ตรงกับที่ระบบคุณใช้อยู่จริงนะครับ)
    if quantity_change != 0 && defined?(StockLog)
      # 🌟 ดึงหมายเลข ID ออเดอร์มาใช้แทนเพื่อความปลอดภัย ป้องกันปัญหาระบบหาคอลัมน์ order_number ไม่เจอ
      order_identifier = order.respond_to?(:order_number) ? order.order_number : order.id

      StockLog.create( # ปกติใช้ create!
        product_id: product.id,
        change_amount: quantity_change, # บันทึกยอดความเปลี่ยนแปลง เช่น -1 หรือ +2
        log_type: quantity_change < 0 ? "Sale" : "Adjustment", # 💡 เติมประเภทให้สมบูรณ์
        note: "ปรับปรุงยอดจากบิลหมายเลข: ##{order_identifier}(แก้ไขรายการ)"
      )
    end
    true # 🌟 เพิ่มบรรทัดนี้ปิดท้ายเมธอด เพื่อป้องกันการแอบ Abort
  end

  # เมธอดคืนสต็อกเมื่อมีการกดลบรายการสินค้านั้นออกจากหน้าฟอร์ม
  def restore_stock_on_destroy
    product = self.product
    if product && self.quantity.present?
      # คืนสต็อกเข้าคลังสินค้า
      product.update_column(:quantity, product.quantity + self.quantity)

      # 🌟 สร้าง Log บันทึกกรณีพนักงานกดปุ่มลบรายการสินค้านั้นออกจากบิล
      if defined?(StockLog)
        order_identifier = order.respond_to?(:order_number) ? order.order_number : order.id

        StockLog.create( # ก่อนหน้านี้ใช้ create!
          product_id: product.id,
          change_amount: self.quantity, # 🌟 คืนสต็อก ยอดเป็นบวก (+) ตาม schema จริง
          log_type: "Return",   # 🌟 เพิ่ม :log_type ให้สอดคล้องกับ schema
          note: "คืนสต็อกเนื่องจากลบรายการออกจากบิล: ##{order_identifier}"
          # {order.order_number || order.id}  แบบเดิมใช้โค้ดนี้"
        )
      end
    end
    true # 🌟 เพิ่มบรรทัดนี้ปิดท้ายเมธอดเช่นกันครับ
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
=end
