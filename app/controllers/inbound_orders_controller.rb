class InboundOrdersController < ApplicationController
  def index
    # @inbound_orders = InboundOrder.all.order(received_at: :desc)
    # 1. ดึงออเดอร์ทั้งหมดขึ้นมาตั้งต้นไว้ก่อน
    @inbound_orders = InboundOrder.all

    # 2. ตรวจสอบว่าพนักงานมีการพิมพ์คำค้นหาเข้ามาหรือไม่
    if params[:query].present?
      search_query = "%#{params[:query].strip}%"

      # 🌟 สั่งกรองค้นหาจากเลขที่บิล (เปลี่ยนชื่อ :order_number ให้ตรงกับชื่อคอลัมน์ในตาราง Order ของคุณ)
      # และสามารถสั่งให้เสิร์ชหาชื่อลูกค้า (customer_name) ควบคู่ไปด้วยได้เลยในช่องเดียว!
      @inbound_orders = @inbound_orders.where(
        "inbound_number LIKE ? OR supplier_name LIKE ?",
        search_query,
        search_query
    )
    end

  # 3. จัดเรียงลำดับให้บิลล่าสุดขึ้นมาแสดงด้านบนสุด (Optional)
  @inbound_orders = @inbound_orders.order(received_at: :asc)
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
  params.require(:inbound_order).permit(
    :inbound_number,
    :received_at,
    :supplier_name,
    :supplier_phone,
    :supplier_address,
    :payment_method,
    :status, :note,
    inbound_items_attributes: [ :id, :product_id, :quantity, :unit_cost, :_destroy ]
    )
  end
end
