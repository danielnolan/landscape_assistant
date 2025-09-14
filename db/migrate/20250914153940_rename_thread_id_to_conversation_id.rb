class RenameThreadIdToConversationId < ActiveRecord::Migration[8.0]
  def change
    rename_column :conversations, :thread_id, :conversation_id
  end
end
