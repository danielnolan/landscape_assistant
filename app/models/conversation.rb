class Conversation < ApplicationRecord
  validates :title, presence: true
  validates :conversation_id, presence: true, uniqueness: true
end
