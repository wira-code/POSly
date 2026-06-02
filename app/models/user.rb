class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # ตั้งค่าตัวช่วยเช็คประเภทสิทธิ์
  def admin?
    role == "admin"
  end

  def staff?
    role == "staff"
  end
end
