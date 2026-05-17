class Order < ApplicationRecord
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items
  validates :payment_method, presence: true
  validates :status, presence: true
  validates :customer_name, presence: true
  validates :customer_address, presence: true
  validates :customer_phone, presence: true

  # ทุกครั้งที่สร้าง Order เราจะให้สถานะเริ่มต้นเป็น "completed"
  before_validation :set_default_status

  # สั่งให้ทำงานก่อนที่จะสร้างออเดอร์ใหม่ในระบบ
  before_create :generate_order_number

  # เพิ่มบรรทัดนี้ เพื่อให้สร้างพร้อมกันในฟอร์มเดียวได้
  accepts_nested_attributes_for :order_items, allow_destroy: true, reject_if: :all_blank

  # Logic สำหรับคำนวณราคารวมทั้งหมดของบิล
  def calculate_total_price
    self.total_price = order_items.map { |item| item.quantity * item.unit_price }.sum
  end

  private
  def set_default_status
    self.status ||= "completed"
  end

  def generate_order_number
    date_part = Time.current.strftime("%Y%m%d") # ได้เป็น "20260517"

    # นับออเดอร์ที่เกิดในวันนี้เพื่อเอารันหมายเลขลำดับ (เช่น 0001, 0002)
    daily_count = Order.where("created_at >= ?", Time.current.beginning_of_day).count + 1
    sequence_part = daily_count.to_s.rjust(4, "0") # ปรับให้เป็น 4 หลัก เช่น "0001"

    # รวมร่างเป็นรหัสบิล เช่น OD-20260517-0001
    self.order_number = "OD-#{date_part}-#{sequence_part}"
  end
end
