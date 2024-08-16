class Message
  include ActiveModel::Model
  include Assistants

  ROLE = "user".freeze

  attr_accessor :id, :content, :thread_id, :role

  def initialize(params = {})
    @content = params[:content]
    @thread_id = params[:thread_id]
    @role = params[:role]
  end

  def create
    create_message
  end

  private

  attr_reader :params

  def create_message
    response = client.messages.create(
      thread_id: thread_id,
      parameters: {role: ROLE, content: content}
    )
    @id = response["id"]
    self
  end
end
