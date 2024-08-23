class Conversation < ApplicationRecord
  include Assistants

  validates :title, presence: true
  validates :thread_id, presence: true, uniqueness: true

  def create_thread
    response = client.threads.create
    response["id"]
  end
end
