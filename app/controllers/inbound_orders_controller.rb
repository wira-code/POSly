class InboundOrdersController < ApplicationController
  def index
    @inbound_orders = InboundOrder.all.order(created_at: :desc)
  end

  def show
    @inbound_order = InboundOrder.find(params[:id])
  end

  def new
    @inbound_order = InboundOrder.new
    # สั่งให้สร้างช่องรายการสินค้าเริ่มต้นรอไว้ 1 แถวในหน้าฟอร์ม
    @inbound_order.inbound_items.build
  end

  def create
    @inbound_order = InboundOrder.new(inbound_order_params)
    if @inbound_order.save
      redirect_to inbound_orders_path, notice: "บันทึกรับเข้าสินค้าเรียบร้อยแล้ว"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def inbound_order_params
    params.require(:inbound_order).permit(:note, inbound_items_attributes: [ :id, :product_id, :quantity, :unit_cost, :_destroy ])
  end
end
