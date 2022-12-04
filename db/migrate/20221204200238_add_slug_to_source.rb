class AddSlugToSource < ActiveRecord::Migration[7.0]
  def change
    add_column :news_sources, :slug, :string, :after=>:name
    add_index :news_sources, :slug
  end
end
