class Message
  include ActiveModel::Model
  include Assistants

  attr_accessor :id, :content, :thread_id, :role

  def self.messages_for_thread(thread_id)
    new(thread_id: thread_id).messages_for_thread
  end

  def initialize(params = {})
    @content = params[:content]
    @thread_id = params[:thread_id]
    @role = params[:role]
    @id = params[:id]
  end

  def create
    create_message
  end

  def assistant_message?
    role == "assistant"
  end

  def messages_for_thread
    return [] if thread_id.nil?

    messages = client.messages.list(
      thread_id: thread_id,
      parameters: {order: "asc"}
    )
    messages["data"].map do |message|
      self.class.new(
        content: message["content"][0]["text"]["value"],
        role: message["role"]
      )
    end
  end

  private

  attr_reader :params

  def create_message
    response = client.messages.create(
      thread_id: thread_id,
      parameters: {role: role, content: content}
    )
    @id = response["id"]
    self
  end
end
