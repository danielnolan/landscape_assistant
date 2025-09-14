class CreateResponseJob < ApplicationJob
  queue_as :default

  def perform(params:)
    message = Message.new(params)
    ResponseCreator.new.create_response(message:)
  end
end
