class AssetBundle < ActiveRecord::Base
	self.table_name  = "asset_bundles"
	serialize :asset_bundles
end