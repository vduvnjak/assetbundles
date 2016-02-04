class AddAssetChannels < ActiveRecord::Migration
  def up
    create_table :asset_channels do |t|
      t.string :catalog_id
      t.string :upid
      t.string :channel
    end
  end

  def down
    drop_table :asset_channels
  end
end