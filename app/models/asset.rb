class Asset < ActiveRecord::Base
	self.table_name  = "assets"
	serialize :dependencies
end