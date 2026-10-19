# One bot. It visits the store as its handle, the way a signed-in user would, and reports
# which button color it saw and which Cloud Run revision answered.
class Bot
  attr_reader :handle

  def self.button_color(html)
    Nokogiri::HTML5(html.to_s).at_css("#buy")&.[]("data-color")
  end

  def initialize(handle)
    @handle = handle
  end

  def cohort = Visitor.for(handle).cohort

  # target is "main" (the service URL, where Cloud Run splits traffic) or "canary" (the canary's tag URL).
  def visit(url, target)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    response = get(url)
    record(target, started,
      "status" => response.code.to_i,
      "color" => self.class.button_color(response.body),
      "revision" => response["X-Revision"],
      "version" => response["X-App-Version"])
  rescue StandardError => error
    record(target, started, "status" => 0, "error" => error.class.name)
  end

  private
    def get(url)
      uri = URI(url)
      request = Net::HTTP::Get.new(uri)
      request["X-Demo-User"] = handle
      request["User-Agent"] = "FlagshipBot/1 (#{handle})"
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 30) do |http|
        http.request(request)
      end
    end

    def record(target, started, fields)
      elapsed = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
      { "bot" => handle, "cohort" => cohort, "target" => target, "ms" => elapsed }.merge(fields)
    end
end
