class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name, null: false # ห้ามเป็นค่าว่าง
      t.string :sku, null: false # ห้ามเป็นค่าว่าง
      t.text :description, precision: 10, scale: 2, default: 0.0 # ราคาเริ่มที่ 0
      t.decimal :price, precision: 10, scale: 2
      t.integer :quantity, default: 0, null: false # จำนวนเริ่มที่ 0 และห้ามเป็นค่าว่าง

      t.timestamps
    end
    add_index :products, :sku, unique: true # ทำให้ SKU ค้นหาเร็วและห้ามซ้ำในระบบ
  end
end
