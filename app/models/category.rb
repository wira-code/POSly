class Category < ApplicationRecord
  #  เป็นแบบนี้: บล็อกการลบ และแจ้งเตือนถ้ายังมีสินค้าอยู่
  has_many :products, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
