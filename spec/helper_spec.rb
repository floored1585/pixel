require_relative 'rspec'
require_relative '../lib/helper'
require_relative '../lib/configfile'
include Helper

settings = Configfile.retrieve


# device_link
describe '#device_link' do

  it 'should generate a link' do
    link = device_link('gar-b11u1-dist')
    expect(link).to eql "<a href='/device/gar-b11u1-dist'>gar-b11u1-dist</a>"
  end

end


#TODO: #neighbor_link
#TODO: #alarm_type_text


# interface_link
describe '#interface_link' do

  it 'should generate a link' do
    int = JSON.load(DEV1_JSON).interfaces[10102]
    link = interface_link(settings, int)
    correct_link = "<a href='#{settings['grafana_if_dash']}" +
    "?title=gar-v11u1-acc-y%20::%20Gi0%2F2" +
    "&name=gar-v11u1-acc-y.10102" +
    "&ifSpeedBps=1000" +
    "&ifMaxBps=35802192" + 
    "' target='_blank'>Gi0/2</a>"

    expect(link).to eql correct_link

  end


end

describe '#interface_link' do
  around :each do |test|
    # Transaction -- don't commit ANY of the garbage executed in these tests
    DB.transaction(:rollback=>:always, :auto_savepoint=>true){test.run} 
  end
end
