class OrdersController < ApplicationController
  def index
    @orders = Order.all
  end

  def show
  end

  def new
    @order = Order.new
    # สร้าง Item ว่างไว้ 1 แถวรอให้พนักงานกรอกในหน้าฟอร์ม
    @order.order_items.build
  end

  def create
    @order = Order.new(order_params)

    # ดึงราคาปัจจุบันจากสินค้ามาใส่ใน OrderItem ก่อนเซฟ
    @order.order_items.each do |item|
      item.unit_price = item.product.price if item.product
      item.total_price = item.unit_price * item.quantity if item.unit_price && item.quantity
    end

    @order.total_price = @order.order_items.map(&:total_price).sum

    if @order.save
      redirect_to inventory_path, notice: "บันทึกการขายและตัดสต็อกเรียบร้อยแล้ว!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def order_params
    # สำคัญมาก: ต้องอนุญาต order_items_attributes ด้วย
    params.require(:order).permit(:status, :payment_method, order_items_attributes: [ :product_id, :quantity ])
  end
end
