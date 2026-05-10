class Product < ApplicationRecord
  has_many :stock_logs, dependent: :destroy # สินค้า 1 ชิ้น มีประวัติได้หลายรายการ
  has_one_attached :image
  validates :name, presence: true
  validates :sku, uniqueness: true, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, presence: true
  # 4. (Optional) ตัวอย่างการทำ Scope เพื่อเรียกดูสินค้าที่ใกล้หมด
  scope :low_stock, -> { where("quantity <= 5") }
  before_save { self.sku = sku.upcase if sku.present? }
end
