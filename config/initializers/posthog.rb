Rails.application.config.posthog = PostHog::Client.new({
  api_key: ENV["POSTHOG_API_KEY"],
  host: ENV["POSTHOG_HOST"],
  on_error: Proc.new { |status, msg| print msg }
})
