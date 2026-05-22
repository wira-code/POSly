class CreateInboundItems < ActiveRecord::Migration[8.1]
  def change
    create_table :inbound_items do |t|
      t.references :inbound_order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity
      t.decimal :unit_cost

      t.timestamps
    end
  end
end
