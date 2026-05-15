class AddCustomerDetailsToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :customer_name, :string
    add_column :orders, :customer_address, :text
    add_column :orders, :customer_phone, :string
  end
end
