class AddEnableBooleanToSources < ActiveRecord::Migration[6.0]
  def change
    add_column :news_sources, :enabled, :boolean, :default => true, :allow_null=>false
  end
end
