require "rails_helper"

RSpec.describe Conversation, type: :model do
  describe "validations" do
    subject { FactoryBot.build(:conversation) }
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:conversation_id) }
    it { should validate_uniqueness_of(:conversation_id) }
  end
end
