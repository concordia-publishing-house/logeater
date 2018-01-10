class CreateEvents < ActiveRecord::Migration
  def up
    create_table :events do |t|
      t.timestamp :emitted_at
      t.timestamp :received_at
      t.integer :priority
      t.integer :syslog_version
      t.string :hostname
      t.string :appname
      t.string :proc_id
      t.string :msg_id
      t.text :structured_data
      t.text :message
      t.text :original
      t.string :ep_app
    end

    add_index :events, :ep_app
    execute "ALTER TABLE events ALTER COLUMN received_at SET DEFAULT now()"
  end

  def down
    remove_index :events, :ep_app
    drop_table :events
  end
end
