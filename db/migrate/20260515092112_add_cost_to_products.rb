class AddCostToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :cost, :decimal
  end
end
