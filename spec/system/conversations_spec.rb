require "rails_helper"

RSpec.describe "Conversations" do
  it "creates a new thread, and shows the assistant name" do
    stub_create_thread
    stub_assistant_request

    visit root_url

    expect(page).to have_text("HR Helper")
  end

  it "allows me to send a message to the assistant" do
    stub_create_thread
    stub_assistant_request
    stub_create_message
    stub_create_run

    visit root_url

    fill_in "How can I help?", with: "Hey what's up"
    find("input[type=hidden]", visible: false).set("thread_abc123")
    click_button "Send"

    expect(page).to have_text("Hey what's up")
  end

  def stub_create_run
    stub_request(:post, "https://api.openai.com/v1/threads/thread_abc123/runs")
      .to_return(status: 200, body: "", headers: {})
  end

  def stub_create_message
    stub_request(:post, "https://api.openai.com/v1/threads/thread_abc123/messages")
      .to_return(status: 200, body: message_body.to_json, headers: {})
  end

  def message_body
    {
      id: "msg_abc123",
      object: "thread.message",
      created_at: 1713226573,
      assistant_id: "asst_GHUDFORTEST",
      thread_id: "thread_abc123",
      run_id: nil,
      role: "user",
      content: [
        {
          type: "text",
          text: {
            value: "Hey what's up",
            annotations: []
          }
        }
      ],
      attachments: [],
      metadata: {}
    }
  end

  def stub_assistant_request
    stub_request(:get, "https://api.openai.com/v1/assistants/asst_GHUDFORTEST")
      .to_return(
        status: 200,
        body: assistant_body.to_json,
        headers: {"Content-Type" => "application/json"}
      )
  end

  def assistant_body
    {
      id: "asst_abc123",
      object: "assistant",
      created_at: 1699009709,
      name: "HR Helper",
      description: "",
      model: "gpt-4o",
      instructions: "You are an HR bot, you know all the things about HR",
      tools: [
        {
          type: "file_search"
        }
      ],
      metadata: {},
      top_p: 1.0,
      temperature: 1.0,
      response_format: "auto"
    }
  end

  def stub_create_thread
    stub_request(:post, "https://api.openai.com/v1/threads")
      .to_return(
        status: 200,
        body: thread_body.to_json,
        headers: {"Content-Type" => "application/json"}
      )
  end

  def thread_body
    {
      id: "thread_abc123",
      object: "thread",
      created_at: 1699012949,
      metadata: {},
      tool_resources: {}
    }
  end
end
