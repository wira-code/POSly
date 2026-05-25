class Order < ApplicationRecord
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items
  validates :payment_method, presence: true
  # validates :total_price, presence: true
  validates :status, presence: true
  validates :customer_name, presence: true
  validates :customer_address, presence: true
  validates :customer_phone, presence: true

  # ทุกครั้งที่สร้าง Order เราจะให้สถานะเริ่มต้นเป็น "completed"
  before_validation :set_default_status

  # สั่งให้ทำงานก่อนที่จะสร้างออเดอร์ใหม่ในระบบ
  before_create :generate_order_number

  # เพิ่มบรรทัดนี้ เพื่อให้สร้างพร้อมกันในฟอร์มเดียวได้
  accepts_nested_attributes_for :order_items, allow_destroy: true, reject_if: :all_blank

  # 🌟 1. เพิ่ม Callbacks สำหรับจัดการระบบสต็อกขาออก
  after_create :cut_stock_for_new_completed_order
  after_update :process_stock_by_status, if: :saved_change_to_status?
  before_destroy :return_stock_if_completed

  # Logic สำหรับคำนวณราคารวมทั้งหมดของบิล
  def calculate_total_price
    self.total_price = order_items.map { |item| item.quantity * item.unit_price }.sum
  end

  private
  def set_default_status
    self.status ||= "completed"
  end

  def generate_order_number
    date_part = Time.current.strftime("%Y%m%d") # ได้เป็น "20260517"

    # นับออเดอร์ที่เกิดในวันนี้เพื่อเอารันหมายเลขลำดับ (เช่น 0001, 0002)
    daily_count = Order.where("created_at >= ?", Time.current.beginning_of_day).count + 1
    sequence_part = daily_count.to_s.rjust(4, "0") # ปรับให้เป็น 4 หลัก เช่น "0001"

    # รวมร่างเป็นรหัสบิล เช่น OD-20260517-0001
    self.order_number = "OD-#{date_part}-#{sequence_part}"
  end

  # 🌟 2. ออเดอร์สร้างเสร็จปุ๊บ (ถ้าเป็น completed เลย) -> สั่งหักสต็อกทันที
  def cut_stock_for_new_completed_order
    if status == "completed"
      order_items.each(&:trigger_stock_decrease)
    end
  end

  # 🌟 3. ออเดอร์มีการ "แก้ไขเปลี่ยนสถานะ" ย้อนหลัง (เช่น จาก completed -> cancelled)
  def process_stock_by_status
    case status
    when "completed"
      order_items.each(&:trigger_stock_decrease)
    when "cancelled"
      # ดึงสต็อกกลับคืนคลัง เฉพาะกรณีที่ก่อนหน้านี้มันเคยตัดสต็อกสำเร็จไปแล้วเท่านั้น
      if saved_changes["status"]&.first == "completed"
        order_items.each(&:trigger_stock_increase)
      end
    end
  end

  # 🌟 4. ดึงสต็อกกลับคืนคลัง กรณีที่บิลนั้นสำเร็จอยู่ แต่โดนแอดมินกดลบ (Delete) บิลทิ้ง
  def return_stock_if_completed
    if status == "completed"
      order_items.each(&:trigger_stock_increase)
    end
  end
end
