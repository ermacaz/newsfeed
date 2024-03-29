class AddVideoIdentifier < ActiveRecord::Migration[7.0]
  def change
    add_column :active_storage_blobs, :media_type, :string
    add_index :active_storage_blobs, :media_type
    ActiveStorage::Blob.update_all(:media_type=>:image)
  end
end
