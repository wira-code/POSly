class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.decimal :total_price
      t.string :status
      t.string :payment_method

      t.timestamps
    end
  end
end
