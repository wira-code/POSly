class StockLogsController < ApplicationController
  def create
    @product = Product.find(params[:product_id])
    @stock_log = @product.stock_logs.build(stock_log_params)

    if @stock_log.save
      # สำคัญ: อัปเดตจำนวนสต็อกที่ตัว Product ด้วย
      new_quantity = @product.quantity + @stock_log.amount
      @product.update(quantity: new_quantity)
      redirect_to @product, notice: "Stock updated successfully!"
    else
      redirect_to @product, alert: "Failed to update stock."
    end
  end

  private

  def stock_log_params
    params.require(:stock_log).permit(:amount, :note)
  end
end
