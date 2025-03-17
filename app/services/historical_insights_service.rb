class HistoricalInsightsService
    INSIGHTS_API_URL = ENV['INSIGHTS_APP_URL'] + '/api/categories'
  
    def initialize(account)
      @account = account
    end
  
    def process_historical_entries
      Rails.logger.info "Processing last 12 months of entries for account #{@account.id}"
      Rails.logger.info "Historical entries payload: #{historical_payload}"
  
      begin
        response = HTTParty.post(
          INSIGHTS_API_URL,
          body: historical_payload,
          headers: { 'Content-Type' => 'application/json' }
        )
  
        if response.success?
          save_categories(JSON.parse(response.body))
          Rails.logger.info "Successfully sent and saved account historical data. Response: #{response.code}"
        end
  
        response
      rescue StandardError => e
        Rails.logger.error "Failed to send account historical data: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        nil
      end
    end
  
    private
  
    def historical_payload
      entries = fetch_last_12_months_entries
      payload = {
        account_id: @account.id,
        family_id: @account.family_id,
        entries: entries.map { |entry| format_entry(entry) }
      }
  
      Rails.logger.debug "Generated payload for account #{@account.id} with #{entries.count} entries"
      payload.to_json
    end
  
    def fetch_last_12_months_entries
      Account::Entry.where(account_id: @account.id)
           .where('date >= ?', 12.months.ago)
           .order(date: :asc)
           .includes(:entryable) 
    end
  
    def format_entry(entry)
      {
        entry_id: entry.id,
        amount: entry.amount,
        name: entry.name,
        category: entry.entryable.category&.name,
        merchant: entry.entryable.merchant&.name,
        entry_type: entry.amount.positive? ? 'Income' : 'Expense',
        account: {
          name: @account.name,
          type: @account.accountable_type
        }
      }
    end
  
    def save_categories(categories_data)
      ActiveRecord::Base.transaction do
        categories_data.each do |category_data|
          entry = Account::Entry.find_by(id: category_data['entry_id'])
          next unless entry
  
          category = @account.family.categories.find_or_create_by!(
            name: category_data['category']
          ) do |cat|
            cat.color = Category::COLORS.sample
            cat.classification = entry.amount.positive? ? 'income' : 'expense'
          end
          
          if entry.entryable_type == 'Account::Transaction'
            entry.entryable.update!(category: category)
          end
        end
      end
    rescue StandardError => e
      Rails.logger.error "Failed to save categories: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise
    end
  end