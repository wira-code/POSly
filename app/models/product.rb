class Product < ApplicationRecord
  has_many :stock_logs, dependent: :destroy # สินค้า 1 ชิ้น มีประวัติได้หลายรายการ
  belongs_to :category
  has_one_attached :image
  validates :name, presence: true
  validates :sku, uniqueness: true, presence: true
  validates :category, presence: true
  validates :cost, numericality: { greater_than_or_equal_to: 0 }, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, presence: true
  # 4. (Optional) ตัวอย่างการทำ Scope เพื่อเรียกดูสินค้าที่ใกล้หมด
  scope :low_stock, -> { where("quantity <= 5") }
  before_save { self.sku = sku.upcase if sku.present? }
  after_create :create_initial_log
  # หากต้องการให้ดึงชื่อหมวดหมู่มาแสดงได้ง่ายๆ ในหน้า View
  delegate :name, to: :category, prefix: true, allow_nil: true

  private

  def create_initial_log
    # สร้าง Log โดยไม่ต้องไปสั่งอัปเดต quantity ซ้ำ เพราะเราใส่ค่าตอน New Product ไปแล้ว
    stock_logs.create(
      change_amount: quantity,
      log_type: "Initial Stock",
      note: "สร้างสินค้าใหม่")
  end
end

# เมื่อสร้างสินค้าสำเร็จ ให้สร้าง StockLog เริ่มต้นด้วย
# @product.stock_logs.create(change_amount: @product.quantity, log_type: "Initial Stock", note: "สร้างสินค้าใหม่")

# self.stock_logs.create(amount: self.quantity, log_type: "Initial", note: "สต็อกเริ่มต้น")
