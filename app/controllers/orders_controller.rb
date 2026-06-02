class OrdersController < ApplicationController
  before_action :authenticate_user!

  # 🔒 ล็อกเฉพาะแอ็กชัน destroy (ลบ) และ edit/update ให้เข้าได้เฉพาะ admin
  before_action :ensure_admin!, only: [ :edit, :update, :destroy ]
  def index
    # 1. ดึงออเดอร์ทั้งหมดขึ้นมาตั้งต้นไว้ก่อน
    @orders = Order.all.order(created_at: :desc)

    # 2. ตรวจสอบว่าพนักงานมีการพิมพ์คำค้นหาเข้ามาหรือไม่
    if params[:query].present?
      # search_query = "%#{params[:query].strip}%"
      query_param = params[:query].strip
      @orders = @orders.where("id = ? OR customer_name LIKE ?", query_param, "%#{query_param}%")

      # 🌟 สั่งกรองค้นหาจากเลขที่บิล (เปลี่ยนชื่อ :order_number ให้ตรงกับชื่อคอลัมน์ในตาราง Order ของคุณ)
      # และสามารถสั่งให้เสิร์ชหาชื่อลูกค้า (customer_name) ควบคู่ไปด้วยได้เลยในช่องเดียว!
      # @orders = @orders.where(
      # "order_number LIKE ? OR customer_name LIKE ?",
      # search_query,
      # search_query)
    end

    # 💳 3. กรองข้อมูลตามช่องทางชำระเงิน (รองรับการกดปุ่มภาษาอังกฤษ แต่เสิร์ชหาภาษาไทยใน DB)
    if params[:payment_method].present?
      # แปลงค่าพารามิเตอร์ภาษาอังกฤษที่ส่งมาจากหน้าวิว ให้ตรงกับคำที่บันทึกจริงในฐานข้อมูล
      mapped_method = case params[:payment_method].downcase
      when "cash" then "เงินสด"
      when "transfer" then "โอนเงิน"
      when "credit card", "card" then "บัตรเครดิต"
      else params[:payment_method] # เผื่อกรณีค่าหลุดมาเป็นภาษาไทยอยู่แล้ว
      end

      @orders = @orders.where(payment_method: mapped_method)
    end
  end

  def show
     @order = Order.find(params[:id])
  end

  def new
    @order = Order.new
    # สร้าง Item ว่างไว้ 1 แถวรอให้พนักงานกรอกในหน้าฟอร์ม
    @order.order_items.build
  end

  def create
    # ลบคอมม่าออกจากราคาต่อหน่วยทั้งหมดก่อนสร้าง Object
    if params[:order] && params[:order][:order_items_attributes]
      params[:order][:order_items_attributes].each do |key, item|
        if item[:unit_price].present?
          item[:unit_price] = item[:unit_price].to_s.gsub(",", "")
        end
      end
    end
    @order = Order.new(order_params)

    # ดึงราคาปัจจุบันจากสินค้ามาใส่ใน OrderItem ก่อนเซฟ
    @order.order_items.each do |item|
      item.unit_price = item.product.price if item.product
      item.total_price = item.unit_price * item.quantity if item.unit_price && item.quantity
    end

    @order.total_price = @order.order_items.map(&:total_price).sum

    if @order.save
      redirect_to orders_path, notice: "บันทึกการขายและตัดสต็อกเรียบร้อยแล้ว!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @order = Order.find(params[:id])
    @order.order_items.build if @order.order_items.blank?
  end

  # app/controllers/orders_controller.rb
  def update
    @order = Order.find(params[:id])

    # ล้างเครื่องหมายคอมม่า (ถ้ามี) ก่อนแปลงเป็นตัวเลขลง Database
    if params[:order] && params[:order][:order_items_attributes]
      params[:order][:order_items_attributes].each do |key, item|
        if item[:unit_price].present?
          item[:unit_price] = item[:unit_price].to_s.gsub(",", "")
        end
      end
    end

    if @order.update(order_params)
      # 🟢 บันทึกผ่าน -> ย้ายหน้ากลับไปที่หน้ารายการทั้งหมด (Index) ทันที
      redirect_to orders_path, notice: "อัปเดตรายการขายเรียบร้อยแล้ว"
    else
      # 🔴 บันทึกไม่ผ่าน -> แสดงหน้าเดิมซ้ำ (Edit) พร้อมส่งสเตตัสแจ้งเตือนกลับไป
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @order = Order.find(params[:id])
    @order.destroy
    # 🌟 ตรวจสอบให้มั่นใจว่าตรงนี้สั่งเตะกลับมาที่ orders_path (หน้า index) ไม่ใช่ @order นะครับ
    redirect_to orders_path, notice: "ลบรายการคำสั่งซื้อเรียบร้อยแล้ว", status: :see_other
  end

  private

  def order_params
  params.require(:order).permit(
    :payment_method,
    :status,
    :total_price,
    :customer_name,
    :customer_phone,
    :customer_address,
    # ข้อสำคัญ 🌟: ใน array ของ order_items_attributes ต้องมี :id และ :_destroy อยู่ด้วยเสมอ!
    order_items_attributes: [ :id, :product_id, :quantity, :unit_price, :_destroy ]
  )
  end

  def ensure_admin!
    unless current_user&.admin?
      redirect_to orders_path, alert: "🚫 เฉพาะผู้จัดการร้านเท่านั้นที่สามารถแก้ไขหรือลบข้อมูลได้"
    end
  end
end
