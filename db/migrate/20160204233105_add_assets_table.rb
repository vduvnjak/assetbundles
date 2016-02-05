class AddAssetsTable < ActiveRecord::Migration
  def up
      create_table :assets do |t|
      t.string :name
      t.string :assetFileHash
      t.string :typeTreeHash
      t.string :bundleFileHash
      t.string :bundleUrl
      t.string :dependencies
    end
    
  end

  def down
    drop_table :assets
  end
end