class AddSupplierDetailsToInboundOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :inbound_orders, :supplier_name, :string
    add_column :inbound_orders, :supplier_phone, :string
    add_column :inbound_orders, :supplier_address, :text
    add_column :inbound_orders, :payment_method, :string
    add_column :inbound_orders, :status, :string
    add_column :inbound_orders, :total_price, :decimal
  end
end
