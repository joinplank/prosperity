class SendTransactionToInsightsAppJob < ApplicationJob
  queue_as :default

  def perform(entry, user_id)
    InsightsApiService.new(entry, user_id).send_transaction
  rescue StandardError => e
    Rails.logger.error "Error processing InsightsApiJob for entry #{entry.id}: #{e.message}"
    raise
  end
end
