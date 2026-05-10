# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# ล้างข้อมูลเดิมเพื่อป้องกันข้อมูลซ้ำซ้อน
puts "Clean database..."
StockLog.destroy_all
Product.destroy_all

puts "Seeding 10 products into POSly..."

sample_products = [
  { name: "MacBook Pro M3", sku: "LAP-001", description: "14-inch, 16GB RAM, 512GB SSD", price: 79900, quantity: 12 },
  { name: "iPhone 15 Pro", sku: "PHN-001", description: "Natural Titanium, 128GB", price: 41900, quantity: 20 },
  { name: "AirPods Pro 2", sku: "ACC-001", description: "USB-C, Noise Cancelling", price: 8990, quantity: 45 },
  { name: "Keychron K2 V2", sku: "KB-001", description: "Mechanical Keyboard Brown Switch", price: 3890, quantity: 8 },
  { name: "Logitech MX Master 3S", sku: "MSE-001", description: "Pale Grey Wireless Mouse", price: 4390, quantity: 4 }, # Low stock
  { name: "Dell UltraSharp 27", sku: "MON-001", description: "4K USB-C Hub Monitor", price: 21500, quantity: 15 },
  { name: "iPad Air M2", sku: "TAB-001", description: "11-inch, 128GB, Wi-Fi Blue", price: 23900, quantity: 22 },
  { name: "Sony WH-1000XM5", sku: "ACC-002", description: "Over-ear Wireless Headphones", price: 14900, quantity: 10 },
  { name: "Kindle Paperwhite", sku: "TAB-002", description: "16GB, 6.8-inch display", price: 6500, quantity: 3 }, # Low stock
  { name: "Ergonomic Chair", sku: "FUR-001", description: "High-back mesh with lumbar support", price: 12500, quantity: 6 }
]

sample_products.each do |data|
  p = Product.create!(data)

  # สร้าง Log เริ่มต้นให้ทุกสินค้า
  StockLog.create!(
    product: p,
    change_amount: p.quantity,
    log_type: "Initial Stock",
    note: "Imported from seed file"
  )
end

puts "✅ Successfully created #{Product.count} products!"
