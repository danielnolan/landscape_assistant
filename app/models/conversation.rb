class Conversation < ApplicationRecord
  validates :title, presence: true
  validates :thread_id, presence: true
end
