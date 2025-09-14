class Message
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :id, :integer
  attribute :content, :string, default: ""
  attribute :role, :string
  attribute :conversation_id, :string

  def assistant_message?
    role == "assistant"
  end
end
