class AddAssetBundles < ActiveRecord::Migration
  def up
      create_table :asset_bundles do |t|
      t.string :build_tag
      t.text :asset_bundles
      t.text :asset_names
    end
    add_index :asset_bundles, :build_tag
  end

  def down
    drop_table :asset_bundles
  end
end
