# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160201230524) do

  create_table "asset_bundles", force: :cascade do |t|
    t.string "catalog_id",    limit: 255
    t.text   "asset_bundles", limit: 65535
  end

  add_index "asset_bundles", ["catalog_id"], name: "index_asset_bundles_on_catalog_id", using: :btree

  create_table "asset_channels", force: :cascade do |t|
    t.string "catalog_id", limit: 255
    t.string "upid",       limit: 255
    t.string "channel",    limit: 255
  end

end
