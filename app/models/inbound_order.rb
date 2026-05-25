class InboundOrder < ApplicationRecord
  has_many :inbound_items, dependent: :destroy

  # ยอมให้กดบันทึกรายการสินค้าพร้อมบิลหลักได้ในหน้าเดียว
  accepts_nested_attributes_for :inbound_items, allow_destroy: true, reject_if: :all_blank
  # 2. บังคับให้กรอกข้อมูลแทน (เพิ่ม inbound_number และ received_at เข้าไป)
  validates :inbound_number, presence: true, uniqueness: true
  validates :received_at, presence: true
  validates :supplier_name, :payment_method, :status, presence: true

  # สร้างเลขที่บิลรับเข้าอัตโนมัติก่อนบันทึก (เช่น INB-20260522-0001)
  # before_validation :generate_inbound_number, on: :create
  before_save :calculate_total_price

  # ❌ ลบ after_create :add_stock_for_new_completed_order ออกไป
  # เหลือไว้เฉพาะชุดตรวจจับตอนแก้ไขเปลี่ยนสถานะย้อนหลัง และตอนลบบิล
  after_update :process_stock_by_status, if: :saved_change_to_status?
  before_destroy :return_stock_if_completed

  private

  # def generate_inbound_number
  #  return if inbound_number.present?
  #  date_str = Time.current.strftime("%Y%m%d")
  #  last_order = InboundOrder.where("inbound_number LIKE ?", "INB-#{date_str}-%").last
  #  next_number = last_order ? last_order.inbound_number.split("-").last.to_i + 1 : 1
  #  self.inbound_number = "INB-#{date_str}-#{format('%04d', next_number)}"
  #  self.received_at ||= Time.current
  # end

  # คำนวณราคารวมทั้งหมดของบิลนี้จากรายการย่อย
  def calculate_total_price
    self.total_price = inbound_items.sum { |item| (item.quantity || 0) * (item.unit_cost || 0) }
  end

  # 1️⃣ จัดการสต็อกตามสถานะที่เปลี่ยนไป
  def process_stock_by_status
    case status
    when "completed"
      # ถ้าเปลี่ยนเป็น สำเร็จ -> สั่งเพิ่มสต็อกให้สินค้าทุกชิ้นในบิล
      inbound_items.each(&:trigger_stock_increase)
    when "cancelled"
      # ถ้าถูกยกเลิก (แต่ก่อนหน้านี้เคยสำเร็จมาแล้ว) -> ต้องดึงสต็อกกลับคืน
      # เช็คจาก status เดิมก่อนเปลี่ยน (ถ้าสถานะเก่าคือ completed ค่อยดึงคืน)
      if saved_changes["status"]&.first == "completed"
        inbound_items.each(&:trigger_stock_decrease)
      end
    end
  end

  # 2️⃣ คืนสต็อกกรณีที่ "บิลนี้เคยสำเร็จแล้ว" แต่จู่ๆ โดนผู้ใช้กดลบ (Delete) ทิ้งดื้อๆ
  def return_stock_if_completed
    if status == "completed"
      inbound_items.each(&:trigger_stock_decrease)
    end
  end
end
