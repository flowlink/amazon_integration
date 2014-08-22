require 'spec_helper'

describe Customer do

  subject { Factories.customers.first }

  it '.names' do
    expect(Customer.names('Pablo Cantero')).to eq(['Pablo', 'Cantero'])
    expect(Customer.names('Pablo Henrique Cantero')).to eq(['Pablo Henrique', 'Cantero'])
    expect(Customer.names('Pablo Henrique Sirio Tejero Cantero')).to eq(['Pablo Henrique Sirio Tejero', 'Cantero'])
  end

  it '#to_message' do
    expect(subject.to_message).to eq({
      id: 'CID',
      email: 'spree@example.com',
      first_name:  'First Middle',
      last_name: 'Last',
      updated_at:  nil,
      shipping_address: {
        firstname:  'First Middle',
        lastname:   'Last',
        address1:   '1 address line',
        address2:   '2 address lines',
        city:       'city',
        zipcode:    'zip',
        phone:      '555-555-5555',
        country:    'US',
        state:      'Vermont'
      },
      associated_marketplace: 'www.example.com'})
  end

end
