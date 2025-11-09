require "rails_helper"

RSpec.describe Conversation, type: :model do
  describe "validations" do
    subject { FactoryBot.build(:conversation) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:conversation_id) }
    it { is_expected.to validate_uniqueness_of(:conversation_id) }
  end
end
