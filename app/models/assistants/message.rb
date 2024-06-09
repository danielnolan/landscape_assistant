module Assistants
  class Message
    include Assistants

    def initialize(params)
      @params = params
    end

    def create
      create_message(*role_and_content)
    end

    private

    attr_reader :params

    def role_and_content
      if params["messages"].present?
        role = params["messages"][0]["role"]
        content = params["messages"][0]["text"]
      elsif params["files"].present?
        file_id = upload_message_image
        message = JSON.parse(params["message1"])
        role = message.fetch("role")
        content = [
          {type: "text", text: message.fetch("text", "")},
          {type: "image_file", image_file: {file_id: file_id}}
        ]
      end
      [role, content]
    end

    def upload_message_image
      response = client.files.upload(
        parameters: {
          file: params[:files].to_path,
          purpose: "vision"
        }
      )
      response["id"]
    end

    def create_message(role, content)
      response = client.messages.create(
        thread_id: thread_id,
        parameters: {role: role, content: content}
      )
      response["id"]
    end

    def thread_id
      @thread_id ||= params[:thread_id]
    end
  end
end
