class InsightsApiService
  INSIGHTS_API_URL = ENV['INSIGHTS_APP_URL'] + '/api/insights' 

  def initialize(entry, user_id)
    @entry = entry
    @user_id = user_id
  end

  def send_transaction
    Rails.logger.info "Attempting to send transaction #{@entry.id} for user #{@user_id} to Insights API"
    
    response = HTTParty.post(
      INSIGHTS_API_URL,
      body: transaction_payload,
      headers: { 'Content-Type' => 'application/json' }
    )
    
    Rails.logger.info "Successfully sent transaction to Insights API. Response: #{response.code}"
    response
  rescue StandardError => e
    Rails.logger.error "Failed to send transaction to insights API: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    # Você pode querer adicionar mais tratamento de erro aqui
  end

  private

  def transaction_payload
    payload = {
      transaction_id: @entry.id,
      user_id: @user_id,
      amount: @entry.amount.abs,
      currency: @entry.currency,
      date: @entry.date,
      name: @entry.name,
      category: @entry.entryable.category&.name,
      merchant: @entry.entryable.merchant&.name,
      entry_type: determine_entry_type,
      account: {
        name: @entry.account.name,
        type: @entry.account.accountable_type
      }
    }
    
    Rails.logger.debug "Generated payload for transaction #{@entry.id}: #{payload}"
    payload.to_json
  end

  def determine_entry_type
    @entry.amount.positive? ? 'Income' : 'Expense'
  end
end 