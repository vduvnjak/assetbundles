class AddAssetChannels < ActiveRecord::Migration
  def up
    create_table :asset_channels do |t|
      t.string :version
      t.string :build_tag
      t.string :appid
      t.string :channel
      t.integer :deprecated, :default => false
    end
  end

  def down
    drop_table :asset_channels
  end
end