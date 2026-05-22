class CreateInboundOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :inbound_orders do |t|
      t.string :inbound_number
      t.datetime :received_at
      t.text :note

      t.timestamps
    end
  end
end
