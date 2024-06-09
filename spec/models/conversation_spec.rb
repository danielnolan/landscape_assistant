require "rails_helper"

RSpec.describe Conversation, type: :model do
  describe "validations" do
    subject { FactoryBot.build(:conversation) }
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:thread_id) }
    it { should validate_uniqueness_of(:thread_id) }
  end
end
