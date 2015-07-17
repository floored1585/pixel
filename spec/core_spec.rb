require_relative 'rspec'
require_relative '../lib/core'
require_relative '../lib/configfile'
include Core

settings = Configfile.retrieve


# get_interface
describe '#get_interface' do

  context 'when called with a valid device and index' do
    specify { expect(get_interface(settings, DB, 'iad1-a-1', index: 1990)).to be_a Interface }
    specify { expect(get_interface(settings, DB, 'iad1-a-1', index: '1990')).to be_a Interface }
  end

  context 'when called with a valid device and name' do
    # Test exact match
    specify { expect(get_interface(settings, DB, 'iad1-a-1', name: 'ge-24/0/3')).to be_a Interface }
    # Test providing uppercase (db has lowercase)
    specify { expect(get_interface(settings, DB, 'iad1-a-1', name: 'GE-24/0/3')).to be_a Interface }
    # Test providing lowercase (db has uppercase)
    specify { expect(get_interface(settings, DB, 'iad1-trn-1', name: 'po1')).to be_a Interface }
  end

  context 'when called with an invalid device + index' do
    invalid = get_interface(settings, DB, 'test-a-1', index: 1990)
    specify { expect(invalid).to be_a Hash }
    specify { expect(invalid).to be_empty }
  end

  context 'when called with an invalid device + name' do
    invalid = get_interface(settings, DB, 'test-a-1', name: 'ge-24/0/3')
    specify { expect(invalid).to be_a Hash }
    specify { expect(invalid).to be_empty }
  end

  context 'when called with an invalid index' do
    invalid = get_interface(settings, DB, 'iad1-a-1', index: 199099)
    specify { expect(invalid).to be_a Hash }
    specify { expect(invalid).to be_empty }
  end

  context 'when called with an invalid name' do
    invalid = get_interface(settings, DB, 'iad1-a-1', name: 'ge-33/0/20')
    specify { expect(invalid).to be_a Hash }
    specify { expect(invalid).to be_empty }
  end

end


# get_device
describe '#get_device' do

  context 'when called with a valid device' do
    device = get_device(settings, DB, 'iad1-bdr-1')
    specify { expect(device).to be_a Device }
  end

  context 'when called with an invalid device' do
    device = get_device(settings, DB, 'imaginary-bdr-1')
    specify { expect(device).to be_a Hash }
  end

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

    it 'should add the devices correctly' do
      add_devices(settings, DB, {'test-1234-switch' => '10.1.2.3'})
      expect(DB[:device].where(:device => 'test-1234-switch', :ip => '10.1.2.3').count).to eql 1
    end

    it 'should update existing devices correctly' do
      add_devices(settings, DB, {'iad1-a-1' => '10.1.2.3'})
      expect(DB[:device].where(:device => 'iad1-a-1', :ip => '10.1.2.3').count).to eql 1
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
      other_cpu_count = DB[:cpu].natural_join(:component).
        exclude(:device => 'gar-b11u1-dist').count
      other_fan_count = DB[:fan].natural_join(:component).
        exclude(:device => 'gar-b11u1-dist').count
      other_memory_count = DB[:memory].natural_join(:component).
        exclude(:device => 'gar-b11u1-dist').count
      other_psu_count = DB[:psu].natural_join(:component).
        exclude(:device => 'gar-b11u1-dist').count
      other_temperature_count = DB[:temperature].natural_join(:component).
        exclude(:device => 'gar-b11u1-dist').count
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
