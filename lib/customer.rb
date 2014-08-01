class Customer
  attr_accessor :customer_hash

  def initialize(customer_hash, config)
    puts "initialize: #{customer_hash.inspect}"
    @customer_hash = customer_hash
  end

  def to_message
    puts "#to_message: #{@customer_hash.inspect} #{self.inspect}"

    {
      id:         @customer_hash['CustomerId'],
      email:      @customer_hash['PrimaryContactInfo']['Email'],
      first_name: names(@customer_hash['PrimaryContactInfo']['Name'])[0],
      last_name:  names(@customer_hash['PrimaryContactInfo']['Name'])[1],
      updated_at: @customer_hash['LastUpdateDate']#,
      # shipping_address: shipping_hash
    }
  end

  private

  def full_state(address)
    state  = address['StateOrRegion'].to_s
    if address['CountryCode'].to_s.upcase != 'US'
      return state
    end
    convert_us_state_name(state)
  end

  def convert_us_state_name(state_abbr)
    exceptions = { 'AA'   => 'U.S. Armed Forces – Americas',
                   'AE'   => 'U.S. Armed Forces – Europe',
                   'AP'   => 'U.S. Armed Forces – Pacific',
                   'D.C.' => 'District Of Columbia' }

    exceptions[state_abbr] || ModelUN.convert_state_abbr(state_abbr)
  end

  def shipping_address
    collection = if @customer_hash['ShippingAddressList']['ShippingAddress'].is_a?(Array)
      @customer_hash['ShippingAddressList']['ShippingAddress']
    else
      [amazon_response['Customers']['Customer']]
    end
    address = collection.detect { |address| address if address['IsDefaultAddress'] == 'true' }
    firstname, lastname = names(address['FullName'])

    {
      firstname:  firstname,
      lastname:   lastname,
      address1:   address['AddressLine1'].to_s,
      address2:   address['AddressLine2'].to_s,
      city:       address['City'],
      zipcode:    address['PostalCode'],
      phone:      order_phone_number,
      country:    address['CountryCode'],
      state:      full_state(address)
    }
  end

  def names(full_name)
    names = full_name.to_s.split(' ')
    # Pablo Henrique Sirio Tejero Cantero
    # => ["Pablo", "Henrique Sirio Tejero Cantero"]
    [names.first.to_s,            # Pablo
     names[1..-1].to_a.join(' ')] # Henrique Sirio Tejero Cantero
  end

end
