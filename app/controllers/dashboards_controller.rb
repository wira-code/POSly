class DashboardsController < ApplicationController
  def index
    # ช่วงเวลาของวันนี้ (เริ่มตั้งแต่ 00:00 น. ถึง 23:59 น.)
    today_range = Time.current.beginning_of_day..Time.current.end_of_day
    yesterday_range = Time.current.yesterday.beginning_of_day..Time.current.yesterday.end_of_day

    # 1️⃣ ยอดขายรวม (Total Sales) และ จำนวนออเดอร์ (Total Orders) ของวันนี้
    today_orders = Order.where(status: "completed", created_at: today_range)
    @total_sales_today = today_orders.sum(:total_price)
    @total_orders_today = today_orders.count

    # (โบนัส) คำนวณ % เปรียบเทียบกับเมื่อวาน เพื่อเอาไปโชว์ว่ายอดโตขึ้นหรือลดลง
    yesterday_sales = Order.where(status: "completed", created_at: yesterday_range).sum(:total_price)
    @sales_growth_percentage = calculate_growth(yesterday_sales, @total_sales_today)

    # 2️⃣ กำไรขั้นต้นของวันนี้ (Gross Profit = ยอดขายของไอเทมทั้งหมด - ต้นทุนของไอเทมทั้งหมด)
    # เราจะดึง OrderItem ของวันนี้ออกมาคิดราคารวม หักด้วยต้นทุน ณ ตอนรับเข้า (cost) ของ Product ชิ้นนั้น ๆ
    @gross_profit_today = today_orders.joins(order_items: :product).sum(
      "order_items.quantity * order_items.unit_price - order_items.quantity * COALESCE(products.cost, 0)"
    )

    # 3️⃣ มูลค่าสินค้าคงคลังสุทธิปัจจุบัน (Inventory Value = จำนวนสินค้าคงเหลือในสต็อกทั้งหมด * ราคาทุนล่าสุด)
    @inventory_value = Product.sum("quantity * COALESCE(cost, 0)")

    # 🌟 [เพิ่มใหม่] 1. สินค้าสต็อกใกล้หมด (เอาสินค้าที่เหลือต่ำกว่า 5 ชิ้น)
    # สมมติเกณฑ์มาตรฐานคือ 5 ชิ้น หรือถ้าคุณมีคอลัมน์ threshold ก็เปลี่ยนเป็น: .where("quantity <= low_stock_threshold")
    @low_stock_products = Product.where("quantity <= ?", 5).order(quantity: :asc).limit(5)

    # 🌟 [เพิ่มใหม่] 2. นับจำนวนบิลค้างรับ (Inbound) และบิลค้างส่ง/รอชำระ (Outbound)
    @pending_inbound_count = InboundOrder.where(status: "pending").count
    @pending_outbound_count = Order.where(status: "pending").count

    # 🌟 [เพิ่มบรรทัดนี้] เก็บวันที่ปัจจุบัน จัดฟอร์แมต เช่น "25/05/2026"
    @current_date = Time.current.strftime("%d/%m/%Y")

    # 📈 1. กราฟยอดขายรายวันย้อนหลัง 7 วัน (Sales Trend Line Chart)
    # ผลลัพธ์ที่ได้จะเป็น Hash ที่คู่กันระหว่าง { "วัน" => ยอดขายรวมของวันนั้น }
    @sales_trend = Order.where(status: "completed")
                        .where(created_at: 7.days.ago.beginning_of_day..Time.current.end_of_day)
                        .group_by_day(:created_at, format: "%d %b")
                        .sum(:total_price)

    # 🔝 2. สินค้าขายดีที่สุด Top 5 (Best Sellers)
    # ดึงชื่อสินค้า และรวมจำนวนชิ้นที่ขายได้จาก OrderItem
    @top_products = OrderItem.joins(:order, :product)
                             .where(orders: { status: "completed" })
                             .group("products.name")
                             .sum("order_items.quantity")
                             .sort_by { |_key, value| -value } # เรียงจากมากไปน้อย
                             .first(5) # เอาแค่ 5 อันดับแรก
                             .to_h

    # 🍕 3. สัดส่วนช่องทางการชำระเงิน (Payment Method Breakdown)
    # นับจำนวนครั้งที่ใช้แต่ละช่องทาง เช่น { "เงินสด" => 10, "โอนเงิน" => 5 }
    @payment_methods = Order.where(status: "completed")
                            .group(:payment_method)
                            .count
  end

  private

  # เมธอดช่วยคำนวณเปอร์เซ็นต์การเติบโต
  def calculate_growth(past, current)
    return 0 if past.to_f == 0
    ((current.to_f - past.to_f) / past.to_f * 100).round(2)
  end
end
