class CreateStockLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_logs do |t|
      t.references :product, null: false, foreign_key: true
      t.integer :change_amount
      t.string :log_type
      t.string :note

      t.timestamps
    end
  end
end
