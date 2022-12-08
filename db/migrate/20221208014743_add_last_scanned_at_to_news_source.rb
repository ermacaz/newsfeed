class AddLastScannedAtToNewsSource < ActiveRecord::Migration[7.0]
  def change
    add_column :news_sources, :scan_interval, :integer
    add_column :news_sources, :last_scanned_at, :datetime
  end
end
