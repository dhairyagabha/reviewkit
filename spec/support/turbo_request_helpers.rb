# frozen_string_literal: true

module TurboRequestHelpers
  def turbo_stream_headers
    { "ACCEPT" => "text/vnd.turbo-stream.html" }
  end
end

RSpec.configure do |config|
  config.include TurboRequestHelpers, type: :request
end
