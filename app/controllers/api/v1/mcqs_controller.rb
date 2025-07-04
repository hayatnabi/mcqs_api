require 'httparty'

class Api::V1::McqsController < ApplicationController
  def create
    text = params[:text]

    if text.blank?
      return render json: { error: 'Text is required' }, status: :bad_request
    end

    mcqs = generate_mcqs_from_openai(text)

    render json: { questions: mcqs }
  end

  private

  def generate_mcqs_from_openai(text)
    prompt = <<~PROMPT
      Generate 3 multiple-choice questions from the following paragraph. 
      Each question must have 4 options and 1 correct answer.

      Paragraph:
      #{text}

      Return the output as JSON in the following format:
      [
        {
          "question": "Question text here?",
          "options": ["Option A", "Option B", "Option C", "Option D"],
          "answer": "Correct option"
        },
        ...
      ]
    PROMPT

    puts "API KEY: #{ENV['OPENAI_API_KEY']}"

    response = HTTParty.post(
      "https://api.openai.com/v1/chat/completions",
      headers: {
        "Authorization" => "Bearer #{ENV['OPENAI_API_KEY']}",
        "Content-Type" => "application/json"
      },
      body: {
        model: "gpt-3.5-turbo",
        messages: [
          { role: "system", content: "You are a helpful MCQ generator for educational content." },
          { role: "user", content: prompt }
        ],
        temperature: 0.7
      }.to_json
    )

    puts response.body
    
    json = JSON.parse(response.body)

    if json["error"].present?
      return { error: json["error"] }  # just return the object
    else
      begin
        JSON.parse(json["choices"][0]["message"]["content"])
      rescue
        [{ error: "Failed to parse OpenAI response." }]
      end
    end
  end
end

# Note: Make sure to set the OPENAI_API_KEY in the .env file or environment variables.``