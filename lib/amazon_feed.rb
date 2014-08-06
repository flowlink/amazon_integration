class SubmissionError < StandardError; end

class AmazonFeed
  def initialize(config)
    @access_key = config['aws_access_key_id']
    @secret_key = config['secret_key']
    @seller_id  = config['merchant_id']
    @timestamp  = Time.now
  end

  def submit(type, doc)
    @action    = 'SubmitFeed'
    @feed_type = type

    res = HTTParty.post(request_uri, request_params(type, doc))

    doc = Nokogiri::XML(res).remove_namespaces!
    validate!(doc)
    doc.xpath('//FeedSubmissionId').text
  end

  private

  def validate!(doc)
    case
    when doc.root.name == 'ErrorResponse'
      raise SubmissionError,  "#{doc.xpath('//Message').text}\n#{doc.to_s}"
    when doc.xpath('//MessagesWithError').text.to_i > 0
      raise SubmissionError,  "#{doc.xpath('//ResultDescription').text}\n#{doc.to_s}"
    end
  end

  def signature
    digest = OpenSSL::Digest::Digest.new('sha256')
    Base64.encode64(OpenSSL::HMAC.digest(digest, @secret_key, canonical)).strip
  end

  def canonical
    ['POST', 'mws.amazonservices.com', '/', build_query].join("\n")
  end

  def request_uri
    'https://mws.amazonservices.com/?' << build_query(signature)
  end

  def build_query(signature=nil)
    query = {
      'AWSAccessKeyId'   => @access_key,
      'Action'           => @action,
      'SellerId'         => @seller_id,
      'SignatureMethod'  => 'HmacSHA256',
      'SignatureVersion' => '2',
      'Timestamp'        => @timestamp,
      'Version'          => '2009-01-01'
    }

    query['Signature'] = signature if signature
    query['FeedType'] = @feed_type if @feed_type
    query['FeedSubmissionId'] = @feed_id if @feed_id
    # Sort hash in natural-byte order
    Hash[Helpers.escape_date_time_params(query).sort].to_query
  end

  def request_params(type, doc)
    {
      format: 'xml',
      headers: { 'Content-MD5' => Digest::MD5.base64digest(doc) },
      body: doc
    }
  end

  module Helpers
    def self.escape_date_time_params(params={})
      params.map do |key, value|
        case value.class.name
        when 'Time', 'Date', 'DateTime'
          { key => value.iso8601 }
        when 'Hash'
          { key => escape_date_time_params(value) }
        else
          { key => value }
        end
      end.reduce({}, :merge)
    end
  end
end