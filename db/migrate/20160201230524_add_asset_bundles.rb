class AddAssetBundles < ActiveRecord::Migration
  def up
      create_table :asset_bundles do |t|
      t.string :catalog_id
      t.text :asset_bundles
    end
    add_index :asset_bundles, :catalog_id
  end

  def down
    drop_table :asset_bundles
  end
end
