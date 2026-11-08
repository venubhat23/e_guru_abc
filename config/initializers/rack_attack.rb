# Throttles abusive traffic on public forms and auth endpoints.
class Rack::Attack
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new unless Rails.env.production?

  throttle("contact/ip", limit: 5, period: 10.minutes) do |req|
    req.ip if req.path == "/contact" && req.post?
  end

  throttle("vendor-signup/ip", limit: 5, period: 10.minutes) do |req|
    req.ip if req.path == "/become-a-vendor" && req.post?
  end

  throttle("login/ip", limit: 20, period: 5.minutes) do |req|
    req.ip if req.path == "/session" && req.post?
  end

  throttle("login/email", limit: 10, period: 5.minutes) do |req|
    req.params["email_address"].to_s.downcase.strip.presence if req.path == "/session" && req.post?
  end

  throttle("traffic-beacon/ip", limit: 120, period: 1.minute) do |req|
    req.ip if req.path == "/t" && req.post?
  end

  self.throttled_responder = lambda do |_req|
    [ 429, { "Content-Type" => "text/html" }, [ "<h1>Too many requests</h1><p>Please wait a few minutes and try again.</p>" ] ]
  end
end
