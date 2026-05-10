class StockLog < ApplicationRecord
  belongs_to :product
  # ตรวจสอบว่าต้องมีจำนวนที่เปลี่ยนแปลง และห้ามเป็น 0 (เพราะถ้าเป็น 0 จะบันทึกทำไมจริงไหมครับ?)
  validates :change_amount, presence: true, numericality: { other_than: 0 }
  validates :log_type, presence: true

  # หลังจากสร้าง Log สำเร็จ ให้รัน Method อัปเดตสต็อก
  after_create :update_product_quantity

  def update_product_quantity
    # เอาจำนวนใน Product ปัจจุบัน มาบวกกับค่าที่เปลี่ยนไปใน Log
    new_quantity = product.quantity + change_amount
    product.update!(quantity: new_quantity)
  end
end
