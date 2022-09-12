class EnableMultiFeeds < ActiveRecord::Migration[7.0]
  def change
    add_column :news_sources, :multiple_feeds, :boolean, :default=>false, :nil=>:false
    change_column :news_sources, :feed_url, :string, :limit=>1000
  end
end
