class CreateConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :conversations do |t|
      t.string :title, null: false
      t.string :thread_id, null: false, index: true
      t.timestamps
    end
  end
end
