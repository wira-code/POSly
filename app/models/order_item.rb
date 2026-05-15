class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  after_create :reduce_product_stock

  private

  def reduce_product_stock
    # สร้าง StockLog ประเภท "Sale" เพื่อไปตัดยอดใน Inventory อัตโนมัติ
    # เราส่งค่าติดลบ เพราะเป็นการขายออก
    product.stock_logs.create!(
      change_amount: -self.quantity,
      log_type: "Sale",
      note: "ขายสินค้า (Order ##{order.id})"
    )
  end
end
