class DailyReportsController < ApplicationController
  def index
    # 📅 1. ดักจับวันที่จากฟอร์มตัวกรอง ถ้าผู้ใช้ไม่ได้เลือก ให้ใช้วันนี้ (Date.current) เป็นค่าเริ่มต้น
    @selected_date = params[:date].present? ? Date.parse(params[:date]) : Date.current

    # 🛒 2. ดึงออเดอร์ทั้งหมดที่เกิดขึ้นในวันที่เลือก และมีสถานะสำเร็จ (completed)
    @orders = Order.where(status: "completed")
                   .where(created_at: @selected_date.beginning_of_day..@selected_date.end_of_day)

    # 💰 3. คำนวณยอดรวมแยกตามช่องทางการชำระเงิน (Cash, Transfer, Credit Card)
    @cash_total = @orders.where(payment_method: "เงินสด").sum(:total_price)
    @transfer_total = @orders.where(payment_method: "โอนเงิน").sum(:total_price)
    @credit_total = @orders.where(payment_method: "บัตรเครดิต").sum(:total_price)

    # 📈 4. ยอดขายรวมทั้งหมดของวันนั้น
    @daily_grand_total = @orders.sum(:total_price)
  end
end
