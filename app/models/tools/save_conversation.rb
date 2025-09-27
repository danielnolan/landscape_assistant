module Tools
  class SaveConversation < OpenAI::BaseModel
    required :title, String, doc: "The clever title for the thread based off the conversation messages"
    required :conversation_id, String, doc: "The current conversation id to save"

    def call(arguments: {})
      Rails.logger.info("SaveConversation called with arguments: #{arguments}")
      conversation = Conversation.new(JSON.parse(arguments))
      response = if conversation.save
        conversation.broadcast_prepend_later_to(:conversations)
        "The conversation has been saved with the title: #{conversation.title}."
      else
        "An error occurred trying to save the conversation"
      end
      Rails.logger.info(response)
      response
    end
  end
end
