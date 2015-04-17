require_relative 'rspec'
require_relative '../lib/core'
require_relative '../lib/configfile'
include Core

settings = Configfile.retrieve


# get_interface
describe '#get_interface' do
end

# add_devices
describe '#add_devices' do
  around :each do |test|
    # Transaction -- don't commit ANY of the garbage executed in these tests
    DB.transaction(:rollback=>:always, :auto_savepoint=>true){test.run} 
  end


  context 'when adding' do

    it 'should not remove other devices' do
      before_count = DB[:device].count
      add_devices(settings, DB, {'test-1234-switch' => '10.1.2.3'})
      after_count = DB[:device].count

      expect(after_count).to eql (before_count + 1)
    end

    it 'should add the device correctly' do
      add_devices(settings, DB, {'test-1234-switch' => '10.1.2.3'})
      expect(DB[:device].where(:device => 'test-1234-switch', :ip => '10.1.2.3').count).to eql 1
    end

  end


  context 'when replacing' do

    device_count = nil
    device_ip_count = nil
    other_cpu_count = nil
    other_fan_count = nil
    other_memory_count = nil
    other_psu_count = nil
    other_temperature_count = nil

    DB.transaction(:rollback=>:always, :auto_savepoint=>true) do
      add_devices(settings, DB, {'gar-b11u1-dist' => '10.11.12.13'}, replace: true)
      device_count = DB[:device].count

      device_ip_count = DB[:device].where(:ip => '10.11.12.13').count

      other_cpu_count = DB[:cpu].exclude(:device => 'gar-b11u1-dist').count
      other_fan_count = DB[:fan].exclude(:device => 'gar-b11u1-dist').count
      other_memory_count = DB[:memory].exclude(:device => 'gar-b11u1-dist').count
      other_psu_count = DB[:psu].exclude(:device => 'gar-b11u1-dist').count
      other_temperature_count = DB[:temperature].exclude(:device => 'gar-b11u1-dist').count
    end

    it 'should remove all other devices' do
      expect(device_count).to eql 1
    end

    it 'should update the IP' do
      expect(device_ip_count).to eql 1
    end

    # Make sure the other devices' components are removed
    it "should delete other devices' CPUs" do
      expect(other_cpu_count).to eql 0
    end
    it "should delete other devices' Fans" do
      expect(other_fan_count).to eql 0
    end
    it "should delete other devices' Memory" do
      expect(other_memory_count).to eql 0
    end
    it "should delete other devices' PSUs" do
      expect(other_psu_count).to eql 0
    end
    it "should delete other devices' Temperatures" do
      expect(other_temperature_count).to eql 0
    end

  end

end
