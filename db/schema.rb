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

ActiveRecord::Schema.define(version: 20171109171953) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "events", force: :cascade do |t|
    t.datetime "emitted_at"
    t.datetime "received_at",     default: -> { "now()" }
    t.integer  "priority"
    t.integer  "syslog_version"
    t.string   "hostname"
    t.string   "appname"
    t.string   "proc_id"
    t.string   "msg_id"
    t.text     "structured_data"
    t.text     "message"
    t.text     "original"
    t.string   "ep_app"
    t.index ["ep_app"], name: "index_events_on_ep_app", using: :btree
  end

  create_table "requests", force: :cascade do |t|
    t.string   "app",          null: false
    t.string   "logfile",      null: false
    t.string   "uuid",         null: false
    t.string   "subdomain"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer  "duration"
    t.string   "http_method"
    t.text     "path"
    t.jsonb    "params"
    t.string   "controller"
    t.string   "action"
    t.string   "remote_ip"
    t.string   "format"
    t.integer  "http_status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.boolean  "tester_bar"
    t.index ["app"], name: "index_requests_on_app", using: :btree
    t.index ["completed_at"], name: "index_requests_on_completed_at", using: :btree
    t.index ["controller", "action"], name: "index_requests_on_controller_and_action", using: :btree
    t.index ["http_status"], name: "index_requests_on_http_status", using: :btree
    t.index ["logfile"], name: "index_requests_on_logfile", using: :btree
    t.index ["params"], name: "index_requests_on_params", using: :gin
    t.index ["subdomain"], name: "index_requests_on_subdomain", using: :btree
    t.index ["uuid"], name: "index_requests_on_uuid", unique: true, using: :btree
  end

end
