require 'hashdiff'
require_relative 'rspec'

describe Device do


  test_devices = {
    'Cisco 2960' => 'gar-b11u18-acc-y',
    'Cisco 4948' => 'irv-i1u1-dist',
    'Cumulus' => 'aon-cumulus-2',
    'Juniper EX' => 'gar-p1u1-dist',
    'Juniper MX' => 'gar-bdr-1',
    'Force10 S4810' => 'iad1-trn-1',
  }

  dev_hash = {
    "device" => "gar-v11u1-acc-y", "ip" => "172.24.8.117", "last_poll" => 1427920458,
    "next_poll" => 1427920564, "last_poll_duration" => 4, "last_poll_result" => 0,
    "last_poll_text" => "", "currently_polling" => 0, "worker" => "gar", "red_alarm" => 2,
    "pps_out" => 465065, "bps_out" => 3365960688, "discards_out" => 5131, "errors_out" => 500,
    "sys_descr" => "Cisco IOS Software, C3560 Software (C3560-IPSERVICESK9-M), Version 12.2(53)SE2, RELEASE SOFTWARE (fc3)\r\nTechnical Support: http://www.cisco.com/techsupport\r\nCopyright (c) 1986-2010 by Cisco Systems, Inc.\r\nCompiled Wed 21-Apr-10 05 => 33 by prod_rel_team",
    "vendor" => "Cisco", "sw_descr" => "C3560-IPSERVICESK9-M", "sw_version" => "12.2(53)SE2",
    "hw_model" => "catalyst3560G48TS", "uptime" => 42462808, "yellow_alarm" => 2 }

  json_keys = [
    'device',
    'ip',
    'last_poll',
    'next_poll',
    'last_poll_duration',
    'last_poll_result',
    'last_poll_text',
    'currently_polling',
    'worker',
    'pps_out',
    'bps_out',
    'discards_out',
    'errors_out',
    'sys_descr',
    'vendor',
    'sw_descr',
    'sw_version',
    'hw_model',
    'uptime',
    'yellow_alarm',
    'red_alarm',
    'interfaces',
    'cpus',
    'fans',
    'memory',
    'psus',
    'temps',
  ]


  # Constructor
  describe '#new' do

    it 'should raise' do
      expect{Device.new}.to raise_error ArgumentError
    end

    it 'should return' do
      device = Device.new('gar-b11u18-acc-y')
      expect(device).to be_a Device
    end

    it 'should return' do
      device = Device.new('gar-b11u18-acc-y', poll_ip: '172.24.7.55')
      expect(device).to be_a Device
    end

    it 'should take the right name' do
      device1 = Device.new('gar-c11u1-dist', poll_ip: '172.24.7.55')
      device2 = Device.new('gar-c11u1-dist', poll_ip: '172.24.7.55')
      expect(device1.name).to eql 'gar-c11u1-dist'
      expect(device2.name).to eql 'gar-c11u1-dist'
    end

  end


  # fetch should work the same no matter what state the device is in
  describe '#fetch' do

    test_devices.each do |label, device|
      context "on a #{label} when no options passed" do
        dev = Device.fetch(device)
        specify { expect(dev).to be_a Device }
        specify { expect(dev.interfaces.values.first).to eql nil }
        specify { expect(dev.cpus.values.first).to eql nil }
        specify { expect(dev.fans.values.first).to eql nil }
        specify { expect(dev.memory.values.first).to eql nil }
        specify { expect(dev.psus.values.first).to eql nil }
        specify { expect(dev.temps.values.first).to eql nil }
      end
      context "on a #{label} when :interfaces passed" do
        dev = Device.fetch(device, :interfaces => true)
        specify { expect(dev).to be_a Device }
        specify { expect(dev.interfaces.values.first).to be_a Interface }
        specify { expect(dev.cpus.values.first).to eql nil }
        specify { expect(dev.fans.values.first).to eql nil }
        specify { expect(dev.memory.values.first).to eql nil }
        specify { expect(dev.psus.values.first).to eql nil }
        specify { expect(dev.temps.values.first).to eql nil }
      end
      context "on a #{label} when :cpus passed" do
        dev = Device.fetch(device, :cpus => true)
        specify { expect(dev).to be_a Device }
        specify { expect(dev.interfaces.values.first).to eql nil }
        specify { expect(dev.cpus.values.first).to be_a CPU }
        specify { expect(dev.fans.values.first).to eql nil }
        specify { expect(dev.memory.values.first).to eql nil }
        specify { expect(dev.psus.values.first).to eql nil }
        specify { expect(dev.temps.values.first).to eql nil }
      end
      context "on a #{label} when :fans passed" do
        dev = Device.fetch(device, :fans => true)
        specify { expect(dev).to be_a Device }
        specify { expect(dev.interfaces.values.first).to eql nil }
        specify { expect(dev.cpus.values.first).to eql nil }
        specify { expect(dev.fans.values.first).to be_a Fan } unless label == 'Cumulus'
        specify { expect(dev.memory.values.first).to eql nil }
        specify { expect(dev.psus.values.first).to eql nil }
        specify { expect(dev.temps.values.first).to eql nil }
      end
      context "on a #{label} when :memory passed" do
        dev = Device.fetch(device, :memory => true)
        specify { expect(dev).to be_a Device }
        specify { expect(dev.interfaces.values.first).to eql nil }
        specify { expect(dev.cpus.values.first).to eql nil }
        specify { expect(dev.fans.values.first).to eql nil }
        specify { expect(dev.memory.values.first).to be_a Memory }
        specify { expect(dev.psus.values.first).to eql nil }
        specify { expect(dev.temps.values.first).to eql nil }
      end
      context "on a #{label} when :psus passed" do
        dev = Device.fetch(device, :psus => true)
        specify { expect(dev).to be_a Device }
        specify { expect(dev.interfaces.values.first).to eql nil }
        specify { expect(dev.cpus.values.first).to eql nil }
        specify { expect(dev.fans.values.first).to eql nil }
        specify { expect(dev.memory.values.first).to eql nil }
        specify { expect(dev.psus.values.first).to be_a PSU } unless label == 'Cumulus'
        specify { expect(dev.temps.values.first).to eql nil }
      end
      context "on a #{label} when :temperatures passed" do
        dev = Device.fetch(device, :temperatures => true)
        specify { expect(dev).to be_a Device }
        specify { expect(dev.interfaces.values.first).to eql nil }
        specify { expect(dev.cpus.values.first).to eql nil }
        specify { expect(dev.fans.values.first).to eql nil }
        specify { expect(dev.memory.values.first).to eql nil }
        specify { expect(dev.psus.values.first).to eql nil }
        specify { expect(dev.temps.values.first).to be_a Temperature } unless [ 'Cumulus', 'Cisco 2960' ].include? label
      end
      context "on a #{label} when all options passed" do
        dev = Device.fetch(device, :all => true)
        specify { expect(dev).to be_a Device }
        specify { expect(dev.interfaces.values.first).to be_a Interface }
        specify { expect(dev.cpus.values.first).to be_a CPU }
        specify { expect(dev.fans.values.first).to be_a Fan } unless label == 'Cumulus'
        specify { expect(dev.memory.values.first).to be_a Memory }
        specify { expect(dev.psus.values.first).to be_a PSU } unless label == 'Cumulus'
        specify { expect(dev.temps.values.first).to be_a Temperature } unless [ 'Cumulus', 'Cisco 2960' ].include? label
      end
    end

  end


  # populate
  describe '#populate' do
    it 'should fill up the object' do
      good = Device.new('gar-v11u1-acc-y')
      expect(JSON.parse(good.populate(dev_hash).to_json)['data'].keys).to eql json_keys
    end
    it 'should return nil if no data passed' do
      good = Device.new('gar-v11u1-acc-y')
      expect(good.populate({})).to eql nil
    end
  end


  context 'when newly created' do

    before :each do
      @dev_name = Device.new('gar-b11u18-acc-y')
    end


    describe '#name' do
      specify { expect(@dev_name.name).to eql 'gar-b11u18-acc-y' }
    end

    describe '#poll_ip' do
      dev_ip = Device.new('gar-b11u18-acc-y', poll_ip: '1.2.3.4')
      specify { expect(@dev_name.poll_ip).to eql nil }
      specify { expect(dev_ip.poll_ip).to eql '1.2.3.4' }
    end

    describe '#poller_uuid' do
      specify { expect(@dev_name.poller_uuid).to be_empty }
    end

    describe '#uptime' do
      specify { expect(@dev_name.uptime).to eql 0 }
    end

    describe '#interfaces' do
      specify { expect(@dev_name.interfaces).to be_a Hash }
      specify { expect(@dev_name.interfaces.values.first).to eql nil }
    end

    describe '#temps' do
      specify { expect(@dev_name.temps).to be_a Hash }
      specify { expect(@dev_name.temps.values.first).to eql nil }
    end

    describe '#fans' do
      specify { expect(@dev_name.fans).to be_a Hash }
      specify { expect(@dev_name.fans.values.first).to eql nil }
    end

    describe '#psus' do
      specify { expect(@dev_name.psus).to be_a Hash }
      specify { expect(@dev_name.psus.values.first).to eql nil }
    end

    describe '#cpus' do
      specify { expect(@dev_name.cpus).to be_a Hash }
      specify { expect(@dev_name.cpus.values.first).to eql nil }
    end

    describe '#memory' do
      specify { expect(@dev_name.memory).to be_a Hash }
      specify { expect(@dev_name.memory.values.first).to eql nil }
    end

    describe '#vendor' do
      specify { expect(@dev_name.vendor).to eql '' }
    end

    describe '#sw_descr' do
      specify { expect(@dev_name.sw_descr).to eql '' }
    end

    describe '#sw_version' do
      specify { expect(@dev_name.sw_version).to eql '' }
    end

    describe '#hw_model' do
      specify { expect(@dev_name.hw_model).to eql '' }
    end

    describe '#red_alarm' do
      specify { expect(@dev_name.red_alarm).to eql false }
    end

    describe '#yellow_alarm' do
      specify { expect(@dev_name.yellow_alarm).to eql false }
    end

    describe '#get_interface' do
      specify { expect(@dev_name.get_interface(name: 'Fa0/1')).to eql nil }
      specify { expect(@dev_name.get_interface(index: '10001')).to eql nil }
      specify { expect(@dev_name.get_interface(index: 10001)).to eql nil }
      specify { expect(@dev_name.get_interface(index: 10001, name: 'Fa0/2')).to eql nil }
    end

    describe '#get_children' do
      specify { expect(@dev_name.get_children(parent_name: 'Gi0/1')).to eql [] }
    end


  end


  context 'when populated' do

    dev1 = Device.fetch('gar-b11u18-acc-y', :all => true)
    dev2 = Device.fetch('irv-i1u1-dist', :all => true)
    alarm_none = JSON.load(P1U1_JSON_1)
    alarm_yellow = JSON.load(P1U1_JSON_2)
    alarm_red = JSON.load(P1U1_JSON_3)
    alarm_both = JSON.load(P1U1_JSON_4)


    describe '#name' do
      specify { expect(dev1.name).to eql 'gar-b11u18-acc-y' }
      specify { expect(dev2.name).to eql 'irv-i1u1-dist' }
    end

    describe '#poll_ip' do
      specify { expect(dev1.poll_ip).to eql '172.24.7.55' }
      specify { expect(dev2.poll_ip).to eql '208.113.142.180' }
    end

    describe '#poller_uuid' do
      specify { expect(dev1.poller_uuid).not_to be_empty }
      specify { expect(dev2.poller_uuid).not_to be_empty }
    end

    describe '#uptime' do
      specify { expect(dev1.uptime).to be_a Numeric }
      specify { expect(dev2.uptime).to be_a Numeric }
    end

    describe '#interfaces' do
      specify { expect(dev1.interfaces).to be_a Hash }
      specify { expect(dev1.interfaces.values.first).to be_a Interface }
    end

    describe '#temps' do
      specify { expect(dev1.temps).to be_a Hash }
      specify { expect(dev2.temps.values.first).to be_a Temperature }
    end

    describe '#fans' do
      specify { expect(dev1.fans).to be_a Hash }
      specify { expect(dev2.fans.values.first).to be_a Fan }
    end

    describe '#psus' do
      specify { expect(dev1.psus).to be_a Hash }
      specify { expect(dev2.psus.values.first).to be_a PSU }
    end

    describe '#cpus' do
      specify { expect(dev1.cpus).to be_a Hash }
      specify { expect(dev2.cpus.values.first).to be_a CPU }
    end

    describe '#memory' do
      specify { expect(dev1.memory).to be_a Hash }
      specify { expect(dev2.memory.values.first).to be_a Memory }
    end

    describe '#vendor' do
      specify { expect(dev1.vendor).to eql 'Cisco' }
      specify { expect(dev2.vendor).to eql 'Cisco' }
    end

    describe '#sw_descr' do
      specify { expect(dev1.sw_descr).to eql 'C2960-LANBASEK9-M' }
      specify { expect(dev2.sw_descr).to eql 'cat4500-ENTSERVICESK9-M' }
    end

    describe '#sw_version' do
      specify { expect(dev1.sw_version).to eql '15.0(2)SE4' }
      specify { expect(dev2.sw_version).to eql '12.2(53)SG2' }
    end

    describe '#hw_model' do
      specify { expect(dev1.hw_model).to eql 'catalyst296048TT' }
      specify { expect(dev2.hw_model).to eql 'catalyst494810GE' }
    end

    describe '#red_alarm' do
      specify { expect(alarm_none.red_alarm).to eql false }
      specify { expect(dev1.red_alarm).to eql false }
      specify { expect(alarm_yellow.red_alarm).to eql false }
      specify { expect(alarm_red.red_alarm).to eql true }
      specify { expect(alarm_both.red_alarm).to eql true }
    end

    describe '#yellow_alarm' do
      specify { expect(alarm_none.yellow_alarm).to eql false }
      specify { expect(dev1.yellow_alarm).to eql false }
      specify { expect(alarm_yellow.yellow_alarm).to eql true }
      specify { expect(alarm_red.yellow_alarm).to eql false }
      specify { expect(alarm_both.yellow_alarm).to eql true }
    end

    describe '#get_interface' do
      specify { expect(dev1.get_interface(name: 'Fa0/1').name).to eql 'Fa0/1' }
      specify { expect(dev1.get_interface(name: 'fa0/1').name).to eql 'Fa0/1' }
      specify { expect(dev1.get_interface(index: '10001').name).to eql 'Fa0/1' }
      specify { expect(dev1.get_interface(index: 10001).name).to eql 'Fa0/1' }
      specify { expect(dev1.get_interface(index: 10002, name: 'Fa0/1').name).to eql 'Fa0/2' }
      specify { expect(dev1.get_interface).to eql nil }
    end

    describe '#get_children' do
      specify { expect(dev1.get_children(parent_name: 'Po2').size).to eql 2 }
      specify { expect(dev1.get_children(parent_name: 'po2').size).to eql 2 }
      specify { expect(dev1.get_children(parent_name: 'PO2').size).to eql 2 }
      specify { expect(dev1.get_children(parent_index: 5002).size).to eql 2 }
      specify { expect(dev1.get_children(parent_index: '5002').size).to eql 2 }
      specify { expect(dev1.get_children(parent_name: 'PO2').first).to be_a Interface }
      specify { expect(dev1.get_children(parent_name: 'PO2').first.index.to_s).to match /1010[12]/ }
      specify { expect(dev1.get_children(parent_index: 5002).first).to be_a Interface }
      specify { expect(dev1.get_children(parent_index: '5002').first.index.to_s).to match /1010[12]/ }
      specify { expect(dev1.get_children(parent_index: '5001202')).to eql [] }
    end


  end

  # update_totals
  describe '#update_totals' do

    context 'when freshly created' do

      dev = Device.new('test')

      specify { expect(dev).to be_a Device }

      #bps_out
      specify { expect(dev.bps_out).to eql 0 }
      #pps_out
      specify { expect(dev.pps_out).to eql 0 }
      #discards_out
      specify { expect(dev.discards_out).to eql 0 }
      #errors_out
      specify { expect(dev.errors_out).to eql 0 }

    end

    context 'when fully populated' do

      dev = JSON.load(DEV1_JSON)

      specify { expect(dev).to be_a Device }

      #bps_out
      specify { expect(dev.bps_out).to eql 3365960688 }
      #pps_out_out
      specify { expect(dev.pps_out).to eql 465065 }
      #discards_out
      specify { expect(dev.discards_out).to eql 5131 }
      #errors_out
      specify { expect(dev.errors_out).to eql 500 }

    end

  end


  # save
  describe '#save' do

    after :each do
      # Clean up DB
      DB[:device].where(:device => 'test-v11u1-acc-y').delete
      DB[:device].where(:device => 'test-v11u2-acc-y').delete
    end


    it 'should not exist before saving' do
      expect(Device.fetch('test-v11u1-acc-y')).to eql nil
    end

    it 'should return nil if no poll IP' do
      dev = Device.new('test-v11u1-acc-y')
      expect(dev.save(DB)).to eql nil
    end

    it 'should save OK w/ name and IP' do
      dev = Device.new('test-v11u1-acc-y', poll_ip: '1.2.3.4')
      expect(dev.save(DB)).to be_a Device
    end

    it 'should exist after being saved' do
      JSON.load(DEV2_JSON).save(DB)
      dev = Device.fetch('test-v11u1-acc-y')
      expect(dev).to be_a Device
    end

    it 'should update without error' do
      JSON.load(DEV2_JSON).save(DB)
      JSON.load(DEV2_JSON).save(DB)
      dev = Device.fetch('test-v11u1-acc-y')
      expect(dev).to be_a Device
    end

    it 'should be identical before and after' do
      DB[:device].where(:device => 'test-v11u1-acc-y').delete
      JSON.load(DEV4_JSON).save(DB)
      fetched = JSON.parse(Device.fetch('test-v11u2-acc-y', :all => true).to_json)
      expect(fetched).to eql JSON.parse(DEV4_JSON)
    end

    it 'should delete outdated components' do
      # Future dated last_updated times
      JSON.load(DEV2_JSON).save(DB)
      # Past dated last_updated times (this should delete everything except the device)
      JSON.load(DEV3_JSON).save(DB)
      dev = Device.fetch('test-v11u1-acc-y', :all => true)
      expect(dev.interfaces).to be_empty
      expect(dev.cpus).to be_empty
      expect(dev.fans).to be_empty
      expect(dev.memory).to be_empty
      expect(dev.psus).to be_empty
      expect(dev.temps).to be_empty
    end

  end


  # delete
  describe '#delete' do

    after :each do
      # Clean up DB
      DB[:device].where(:device => 'test-v11u1-acc-y').delete
    end


    it 'should return 1 if device exists and is empty' do
      object = Device.new('test-v11u1-acc-y', poll_ip: '1.2.3.4')
      object.save(DB)
      expect(object.delete(DB)).to eql 1
    end

    it 'should return the number of deleted objects' do
      JSON.load(DEV2_JSON).save(DB)
      object = Device.fetch('test-v11u1-acc-y', :all => true)
      expect(object.delete(DB)).to eql 61
    end

    it "should return 0 if nonexistant" do
      object = Device.new('test-v11u1-acc-y')
      expect(object.delete(DB)).to eql 0
    end

  end


  # to_json
  describe '#to_json and #json_create' do

    context 'when freshly created' do

      before(:each) do
        @dev = Device.new('gar-test-1')
      end


      it 'should return a string' do
        expect(@dev.to_json).to be_a String
      end

      it 'should serialize and deserialize' do
        json = @dev.to_json
        expect(JSON.load(json)).to be_a Device
        expect(JSON.load(json).to_json).to eql json
      end

    end


    context 'when populated' do

      c2960 = Device.fetch(test_devices['Cisco 2960'], :all => true)
      c4948 = Device.fetch(test_devices['Cisco 4948'], :all => true)
      cumulus = Device.fetch(test_devices['Cumulus'], :all => true)
      ex = Device.fetch(test_devices['Juniper EX'], :all => true)
      mx = Device.fetch(test_devices['Juniper MX'], :all => true)
      f10_s4810 = Device.fetch(test_devices['Force10 S4810'], :all => true)

      json_c2960 = c2960.to_json
      json_c4948 = c4948.to_json
      json_cumulus = cumulus.to_json
      json_ex = ex.to_json
      json_mx = mx.to_json
      json_f10_s4810 = f10_s4810.to_json

      specify { expect(JSON.load(json_c2960).to_json).to eql json_c2960 }
      specify { expect(JSON.load(json_c4948).to_json).to eql json_c4948 }
      specify { expect(JSON.load(json_cumulus).to_json).to eql json_cumulus }
      specify { expect(JSON.load(json_ex).to_json).to eql json_ex }
      specify { expect(JSON.load(json_mx).to_json).to eql json_mx }
      specify { expect(JSON.load(json_f10_s4810).to_json).to eql json_f10_s4810 }

      it 'should not change' do
        hash = JSON.parse(JSON.load(DEV1_JSON).to_json)
        hash_expected = JSON.parse(DEV1_JSON)
        expect(HashDiff.diff(hash, hash_expected)).to be_empty
      end

      it 'should not change' do
        hash = JSON.parse(JSON.load(DEV2_JSON).to_json)
        hash_expected = JSON.parse(DEV2_JSON)
        expect(HashDiff.diff(hash, hash_expected)).to be_empty
      end

    end

  end


  # True integration tests
  describe '#poll' do
    #c2960 = Device.new(test_devices['Cisco 2960']).populate.poll(worker: 't')
    #c4948 = Device.new(test_devices['Cisco 4948']).populate.poll(worker: 't')
    #cumulus = Device.new(test_devices['Cumulus']).populate.poll(worker: 't')
    #ex = Device.new(test_devices['Juniper EX']).populate.poll(worker: 't')
    #mx = Device.new(test_devices['Juniper MX']).populate.poll(worker: 't')
    #f10_s4810 = Device.new(test_devices['Force10 S4810']).populate.poll(worker: 't')

    context 'on a Cisco 2960' do
      #'Cisco 2960' => 'gar-b11u18-acc-y',
    end

    context 'on a Cisco 4948' do
      #'Cisco 4948' => 'irv-i1u1-dist',
    end

    context 'on a Cumulus device' do
      #'Cumulus' => 'aon-cumulus-2',
    end

    context 'on a Juniper EX' do
      #'Juniper EX' => 'gar-p1u1-dist',
    end

    context 'on a Juniper MX' do
      #'Juniper MX' => 'iad1-bdr-1',
    end

    context 'on a Force10 S4810' do
      #'Force10 S4810' => 'iad1-trn-1',
    end

  end

end
