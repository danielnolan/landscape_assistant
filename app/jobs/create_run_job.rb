class CreateRunJob < ApplicationJob
  queue_as :default

  def perform(message_id, thread_id)
    Run.new(message_id, thread_id).create
  end
end
