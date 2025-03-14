class AccountHistoricalEntriesJob < ApplicationJob
  queue_as :default

  def perform(account_id)
    account = Account.find(account_id)
    HistoricalInsightsService.new(account).process_historical_entries
  end
end
