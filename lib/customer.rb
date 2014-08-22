class Customer
  attr_accessor :customer_hash

  def initialize(customer_hash)
    @customer_hash = customer_hash
  end

  def self.names(full_name)
    names = full_name.to_s.split(' ')
    # Pablo Henrique Sirio Tejero Cantero
    # => ["Pablo Henrique Sirio Tejero", "Cantero"]
    [names[0..-2].to_a.join(' '), # Pablo Henrique Sirio Tejero
     names.last.to_s]             # Cantero
  end

  def last_updated_on
    @customer_hash['AssociatedMarketplaces']['MarketplaceDomain']['LastUpdatedOn']
  end

  def to_message
    {
      id:         @customer_hash['CustomerId'],
      email:      @customer_hash['PrimaryContactInfo']['Email'],
      first_name: Customer.names(@customer_hash['PrimaryContactInfo']['FullName'])[0],
      last_name:  Customer.names(@customer_hash['PrimaryContactInfo']['FullName'])[1],
      updated_at: last_updated_on,
      shipping_address: shipping_hash,
      associated_marketplace: @customer_hash['AssociatedMarketplaces']['MarketplaceDomain']['DomainName']
    }
  end

  private

  def convert_us_state_name(state_abbr)
    exceptions = { 'AA'   => 'U.S. Armed Forces – Americas',
                   'AE'   => 'U.S. Armed Forces – Europe',
                   'AP'   => 'U.S. Armed Forces – Pacific',
                   'D.C.' => 'District Of Columbia' }

    exceptions[state_abbr] || ModelUN.convert_state_abbr(state_abbr)
  end

  def full_state(address)
    state  = address['StateOrRegion'].to_s
    if address['CountryCode'].to_s.upcase != 'US'
      return state
    end
    convert_us_state_name(state)
  end

  def shipping_hash
    # Normalize the shipping addresses into an array.
    collection = if @customer_hash['ShippingAddressList']
      if @customer_hash['ShippingAddressList']['ShippingAddress'].is_a?(Array)
        @customer_hash['ShippingAddressList']['ShippingAddress']
      else
        [@customer_hash['ShippingAddressList']['ShippingAddress']]
      end
    else
      []
    end
    # If no addresses its nil
    return nil if collection.empty?

    # Find the default address
    address = collection.detect { |address| address if address['IsDefaultAddress'] == 'true' }

    # Build the default address hash
    firstname, lastname = Customer.names(address['FullName'])
    {
      firstname:  firstname,
      lastname:   lastname,
      address1:   address['AddressLine1'].to_s,
      address2:   address['AddressLine2'].to_s,
      city:       address['City'],
      zipcode:    address['PostalCode'],
      phone:      address['Phone'].to_s.strip,
      country:    address['CountryCode'],
      state:      full_state(address)
    }
  end

end
