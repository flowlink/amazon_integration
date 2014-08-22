require 'spec_helper'

describe AmazonIntegration do

  let(:config) { [{ name: 'marketplace_id',     value: ENV['MARKETPLACE_ID'] },
                  { name: 'merchant_id',        value: ENV['MERCHANT_ID'] },
                  { name: 'aws_access_key_id',  value: ENV['AWS_ACCESS_KEY_ID'] },
                  { name: 'secret_key',         value: ENV['SECRET_KEY'] },
                  { name: 'amazon.last_updated_after', value: '2013-06-12' }] }

  let(:message) { { message_id: '1234567' } }

  let(:request) { { message: 'amazon:order:poll',
                    message_id: '1234567',
                    payload: { parameters: config } } }

  def auth
    { 'HTTP_X_AUGURY_TOKEN' => 'x123', 'CONTENT_TYPE' => 'application/json' }
  end

  def app
    AmazonIntegration
  end

  describe '/get_orders' do
    before do
      skip
      now = Time.new(2013, 8, 16, 10, 55, 14, '-03:00')
      Time.stub(now: now)
    end

    it 'gets orders from amazon' do
      skip
      VCR.use_cassette('amazon_client_valid_orders') do
        post '/get_orders', request.to_json, auth

        expect(last_response).to be_ok
        expect(json_response['message_id']).to eq('1234567')
      end
    end

    context 'when no orders' do
      before do
        MWS.stub(orders: [])
      end

      it 'does not fail' do
        post '/get_orders', request.to_json, auth

        expect(last_response).to be_ok
        expect(json_response).to eq('message_id' => '1234567')
      end
    end
  end

  describe '/feed_status' do
    before do
      skip 'might not need anymore'
      now = Time.new(2013, 10, 22, 21, 39, 01, '-04:00')
      Time.stub(now: now)
    end

    it 'gets feed status' do
      VCR.use_cassette('feed_status') do
        request = { message_id: '1234', message: 'amazon:feed:status',
                    payload: { feed_id: '8253017998', parameters: config } }

        post '/feed_status', request.to_json, auth
        expect(last_response).to be_ok
        expect(json_response['message_id']).to eq('1234')
        expect(json_response['notifications']).to have(1).item
        expect(json_response['notifications'].first['description']).to eq('Succesfully processed feed #8253017998')
      end
    end

    context 'when errors' do
      before do
        now = Time.new(2013, 10, 23, 14, 44, 11, '-03:00')
        Time.stub(now: now)
      end

      it 'returns a notification error' do
        VCR.use_cassette('inventory_feed_status_error') do
          request = { message_id: '1234', message: 'amazon:feed:status',
                      payload: { feed_id: '8259737688', parameters: config } }

          post '/feed_status', request.to_json, auth
          expect(last_response).to_not be_ok
          expect(json_response['message_id']).to eq('1234')
          expect(json_response).to_not have_key('messages')
          expect(json_response['notifications']).to have(1).item
          expect(json_response['notifications'].first['subject']).to include('This SKU does not exist in the Amazon.com catalog')
        end
      end
    end

    context 'when not processed' do
      before do
        now = Time.new(2013, 10, 23, 14, 44, 11, '-03:00')
        Time.stub(now: now)
      end

      it 're-schedules message status checker' do
        VCR.use_cassette('inventory_feed_status_not_processed') do
          request = { message_id: '1234',
                      message: 'amazon:feed:status',
                      payload: { feed_id: '8259716402', parameters: config } }


          post '/feed_status', request.to_json, auth
          expect(last_response).to be_ok
          expect(json_response['message_id']).to eq '1234'
          expect(json_response['delay']).to eq 2.minutes
          expect(json_response).to_not have_key('notifications')
          expect(json_response).to_not have_key('messages')
        end
      end
    end
  end

end
