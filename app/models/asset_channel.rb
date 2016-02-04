class AssetChannel < ActiveRecord::Base
	self.table_name  = "asset_channels"
	belongs_to :asset_bundle, foreign_key: :catalog_id
end