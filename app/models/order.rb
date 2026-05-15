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
end
