class ProductsController < ApplicationController
  # skip_before_action :authenticate_user!, only: [ :index, :show ]
  before_action :set_product, only: [ :show, :edit, :update, :destroy, :update_stock ]
  # before_action :product_params

  def index # แสดงรายการสินค้าทั้งหมด
    if params[:search].present?
      # ค้นหาจากชื่อ (name) หรือ SKU โดยใช้คำสั่ง LIKE
      @products = Product.where("name ILIKE ? OR sku ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
    else
      @products = Product.all
    end

    # ตัวอย่างการ Filter ตามจำนวนสินค้า (Low Stock)
    if params[:filter] == "low_stock"
      @products = @products.where("quantity <= 5")
    end
    # .order(:created_at => :asc) คือเรียงจากเก่าไปใหม่ (อันใหม่จะอยู่ล่างสุด)
    @products = @products.order(created_at: :asc)
  end


  def show
    @product = Product.find(params[:id])
    # ดึงประวัติการเคลื่อนไหวสต็อก 10 รายการล่าสุด
    @stock_logs = @product.stock_logs.order(created_at: :asc).limit(10)
  end

  def update_stock
    # สร้าง StockLog ใหม่ (จำได้ไหมครับ? เราเขียน after_create ให้อัปเดต quantity ใน Model ไว้แล้ว)
    @product.stock_logs.create(
      change_amount: params[:amount],
      log_type: params[:amount].to_i > 0 ? "Restock" : "Adjustment",
      note: params[:note]
    )
    redirect_to @product, notice: "Stock updated successfully!"
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      # ✅ ต้องมีบรรทัดนี้ เพื่อสร้างประวัติเริ่มต้น
      # @product.stock_logs.create(
      # change_amount: @product.quantity,
      # log_type: "Initial Stock", # ⚠️ คำนี้ต้องสะกดเหมือนใน Model เป๊ะๆ
      # note: "สต็อกเริ่มต้น")
      redirect_to products_path, notice: "Product was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @product = Product.find(params[:id])
  end

  def update
    @product = Product.find(params[:id])
    if @product.update(product_params)
      redirect_to product_path(@product), notice: "Product updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product = Product.find(params[:id])
    @product.destroy
    respond_to do |format|
      # หลังจากลบแล้ว ให้ Redirect กลับไปหน้า Index พร้อมข้อความแจ้งเตือน
      # ใน Rails 7+ ต้องใส่ status: :see_other เพื่อให้ Turbo ทำงานถูกต้อง
      format.html { redirect_to products_path, notice: "Product was successfully deleted.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :sku, :description, :price, :quantity, :image)
  end
end
