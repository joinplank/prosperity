require "test_helper"

class PlaidItemTest < ActiveSupport::TestCase
  include SyncableInterfaceTest

  setup do
    @plaid_item = @syncable = plaid_items(:one)
  end

  test "removes plaid item when destroyed" do
    @plaid_provider = mock

    PlaidItem.stubs(:plaid_provider).returns(@plaid_provider)

    @plaid_provider.expects(:remove_item).with(@plaid_item.access_token).once

    assert_difference "PlaidItem.count", -1 do
      @plaid_item.destroy
    end
  end

  test "sync_data updates last_synced_at and syncs accounts" do
    Timecop.freeze do
      mock_time = Time.current
      @plaid_item.stubs(:fetch_and_load_plaid_data).returns(:mock_plaid_data)
      @plaid_item.accounts.each do |account|
        account.expects(:sync_data).with(start_date: nil)
        if account.family.categories.none? && account.processable_account_type?
          account.expects(:process_historical_entries)
        end
      end
      @plaid_item.expects(:post_sync)

      result = @plaid_item.sync_data

      assert_equal :mock_plaid_data, result
      assert_equal mock_time, @plaid_item.last_synced_at
    end
  end
end
