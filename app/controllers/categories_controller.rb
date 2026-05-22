class CategoriesController < ApplicationController
  before_action :set_category, only: [ :edit, :update, :destroy ]
  def index
    @categories = Category.all
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new
    if @category.save
      redirect_to categories_path, notice: "Add category successfully"
    else
      render :new, status: :unprocessible_entity
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_to categories_path, notice: "อัปเดตหมวดหมู่สำเร็จ"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @category.destroy
    redirect_to categories_path, notice: "Delete Category successfully"
    else
      redirect_to categories_path, alert: "ไม่สามารถลบได้ เนื่องจากมีสินค้าใช้งานหมวดหมู่นี้อยู่จำนวน #{@category.products.count} ชิ้น"
    end
  end


  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :description)
  end
end
