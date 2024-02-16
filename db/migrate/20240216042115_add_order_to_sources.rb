class AddOrderToSources < ActiveRecord::Migration[7.1]
  def change
    add_column :news_sources, :list_order, :integer
    add_index :news_sources, :list_order
  end
end
