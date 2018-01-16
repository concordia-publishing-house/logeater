class ChangeUserIdToBeStringInRequests < ActiveRecord::Migration[5.0]
  def up
    execute "alter table requests alter column user_id type varchar"
  end

  def down
    execute "alter table requests alter column user_id type integer"
  end
end
