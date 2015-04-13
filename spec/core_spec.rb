require_relative 'rspec'
require_relative '../lib/core'
require_relative '../lib/configfile'
include Core

settings = Configfile.retrieve

# add_devices
describe '#add_devices' do
  # Transaction -- don't commit ANY of this
  DB.transaction(:rollback => :always) do

    it 'should replace properly' do
      add_devices(settings, DB, {'gar-b11u1-dist' => '66.33.201.204'}, replace: true)
      device_count = DB[:device].select_all.count
      expect(device_count).to eql 1
    end

  end
end
