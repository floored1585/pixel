require_relative '../lib/device'

describe Device do

  # Up/Up
  interface_1 = {
    "device" => "gar-b11u1-dist","index" => 604,"last_updated" => 1424752121,
    "if_alias" => "bb__gar-crmx-1__xe-1/0/3","if_name" => "xe-0/2/0",
    "if_hc_in_octets" => "0.3959706331274391E16","if_hc_out_octets" => "0.3281296197965732E16",
    "if_hc_in_ucast_pkts" => "0.4388140890014E13","if_hc_out_ucast_pkts" => "0.3813525530792E13",
    "if_speed" => 10000000000,"if_mtu" => 1522,"if_admin_status" => 1,
    "if_admin_status_time" => 1409786067,"if_oper_status" => 1,"if_oper_status_time" => 1409786067,
    "if_in_discards" => "0.0","if_in_errors" => "0.0","if_out_discards" => "0.0",
    "if_out_errors" => "0.0","bps_in" => 1349172320,"bps_out" => 1371081672,"discards_in" => 0,
    "errors_in" => 0,"discards_out" => 0,"errors_out" => 0,"pps_in" => 180411,"pps_out" => 262760,
    "bps_in_util" => 13.49,"bps_out_util" => 13.71,"if_type" => "bb" }
  # Up/Down
  interface_2 = {
    "device" => "gar-b11u17-acc-g","index" => 10040,"last_updated" => 1424752718,
    "if_alias" => "acc__","if_name" => "Fa0/40","if_hc_in_octets" => "0.0",
    "if_hc_out_octets" => "0.0","if_hc_in_ucast_pkts" => "0.0","if_hc_out_ucast_pkts" => "0.0",
    "if_speed" => 10000000,"if_mtu" => 1500,"if_admin_status" => 1,
    "if_admin_status_time" => 1415142088,"if_oper_status" => 2,"if_oper_status_time" => 1415142088,
    "if_in_discards" => "0.0","if_in_errors" => "0.0","if_out_discards" => "0.0",
    "if_out_errors" => "0.0","bps_in" => 0,"bps_out" => 0,"discards_in" => 0,"errors_in" => 0,
    "discards_out" => 0,"errors_out" => 0,"pps_in" => 0,"pps_out" => 0,"bps_in_util" => 0.0,
    "bps_out_util" => 0.0,"if_type" => "acc"}
  # Up/Up, AE
  interface_3 = {
    "device" => "gar-p1u1-dist","index" => 656,"last_updated" => 1424752472,
    "if_alias" => "bb__gar-cr-1__ae3","if_name" => "ae0",
    "if_hc_in_octets" => "0.484779762679182E15","if_hc_out_octets" => "0.1111644194120525E16",
    "if_hc_in_ucast_pkts" => "0.878552042051E12","if_hc_out_ucast_pkts" => "0.1174804345552E13",
    "if_speed" => 20000000000,"if_mtu" => 1514,"if_admin_status" => 1,
    "if_admin_status_time" => 1416350411,"if_oper_status" => 1,"if_oper_status_time" => 1416350411,
    "if_in_discards" => "0.0","if_in_errors" => "0.0","if_out_discards" => "0.0",
    "if_out_errors" => "0.0","bps_in" => 408764184,"bps_out" => 1172468480,"discards_in" => 0,
    "errors_in" => 0,"discards_out" => 0,"errors_out" => 0,"pps_in" => 104732,"pps_out" => 144934,
    "bps_in_util" => 2.04,"bps_out_util" => 5.86,"if_type" => "bb"}
  # Shutdown
  interface_4 = {
    "device" => "irv-a3u2-acc-g","index" => 10119,"last_updated" => 1424752571,"if_alias" => "",
    "if_name" => "Gi0/19","if_hc_in_octets" => "0.0","if_hc_out_octets" => "0.2628E4",
    "if_hc_in_ucast_pkts" => "0.0","if_hc_out_ucast_pkts" => "0.2E1","if_speed" => 1000000000,
    "if_mtu" => 1500,"if_admin_status" => 2,"if_admin_status_time" => 1415142087,
    "if_oper_status" => 2,"if_oper_status_time" => 1415142087,"if_in_discards" => "0.0",
    "if_in_errors" => "0.0","if_out_discards" => "0.0","if_out_errors" => "0.0","bps_in" => 0,
    "bps_out" => 0,"discards_in" => 0,"errors_in" => 0,"discards_out" => 0,"errors_out" => 0,
    "pps_in" => 0,"pps_out" => 0,"bps_in_util" => 0.0,"bps_out_util" => 0.0,"if_type" => "unknown"}
  interfaces = [ interface_1, interface_2, interface_3, interface_4 ]
  test_devices = {
   'Cisco 2960' => 'gar-b11u17-acc-g',
   'Cisco 4948' => 'irv-i1u1-dist',
   'Cumulus' => 'aon-cumulus-2',
   'Juniper EX' => 'gar-p1u1-dist',
   'Juniper MX' => 'iad1-bdr-1',
   'Force10 S4810' => 'iad1-trn-1',
  }


  # Constructor
  describe '#new' do

    it 'should raise' do
      expect{Device.new}.to raise_error ArgumentError
    end

    it 'should return' do
      device = Device.new('gar-b11u17-acc-g')
      expect(device).to be_a Device
    end

    it 'should return' do
      device = Device.new('gar-b11u17-acc-g', poll_ip: '172.24.7.54')
      expect(device).to be_a Device
    end

    it 'should take the right name' do
      device1 = Device.new('gar-c11u1-dist', poll_ip: '172.24.7.54')
      device2 = Device.new('gar-c11u1-dist', poll_ip: '172.24.7.54')
      expect(device1.name).to eql 'gar-c11u1-dist'
      expect(device2.name).to eql 'gar-c11u1-dist'
    end

  end


  # populate should work the same no matter what state the device is in
  describe '#populate' do

    test_devices.each do |label, device|
      context "on a #{label} when no options passed" do
        it 'should equal' do
          dev_obj = Device.new(device)
          expect(dev_obj.populate).to equal dev_obj
        end
      end
      context "on a #{label} when :interfaces passed" do
        it 'should equal' do
          dev_obj = Device.new(device)
          expect(dev_obj.populate(:interfaces => true)).to equal dev_obj
        end
      end
      context "on a #{label} when :cpus passed" do
        it 'should equal' do
          dev_obj = Device.new(device)
          expect(dev_obj.populate(:cpus => true)).to equal dev_obj
        end
      end
      context "on a #{label} when :memory passed" do
        it 'should equal' do
          dev_obj = Device.new(device)
          expect(dev_obj.populate(:memory => true)).to equal dev_obj
        end
      end
      context "on a #{label} when :temperatures passed" do
        it 'should equal' do
          dev_obj = Device.new(device)
          expect(dev_obj.populate(:temperatures => true)).to equal dev_obj
        end
      end
      context "on a #{label} when :psus passed" do
        it 'should equal' do
          dev_obj = Device.new(device)
          expect(dev_obj.populate(:psus => true)).to equal dev_obj
        end
      end
      context "on a #{label} when :fans passed" do
        it 'should equal' do
          dev_obj = Device.new(device)
          expect(dev_obj.populate(:fans => true)).to equal dev_obj
        end
      end
      context "on a #{label} when all options passed" do
        it 'should equal' do
          dev_obj = Device.new(device)
          expect(dev_obj.populate(:all => true)).to equal dev_obj
        end
      end
    end

  end

  describe '#poll' do

    before :each do
    end


    context 'when newly created with name' do
      dev = Device.new('gar-c11u1-dist')

      specify { expect(dev.poll(worker: 'test-worker')).to eql nil }
    end

    context 'when newly created with name and IP' do
      dev = Device.new('irv-i1u1-dist', poll_ip: '208.113.142.180')
      dev_device = Device.new('irv-i1u1-dist', poll_ip: '208.113.142.180')
      dev_interfaces = Device.new('irv-i1u1-dist', poll_ip: '208.113.142.180')
      dev_temperatures = Device.new('irv-i1u1-dist', poll_ip: '208.113.142.180')
      dev_fans = Device.new('irv-i1u1-dist', poll_ip: '208.113.142.180')
      dev_psus = Device.new('irv-i1u1-dist', poll_ip: '208.113.142.180')
      dev_cpus = Device.new('irv-i1u1-dist', poll_ip: '208.113.142.180')
      dev_memory = Device.new('irv-i1u1-dist', poll_ip: '208.113.142.180')
      dev_all = Device.new('irv-i1u1-dist', poll_ip: '208.113.142.180')

      dev.poll(worker: 'test-worker')
      dev_device.poll(worker: 'test-worker', components: [])
      dev_interfaces.poll(worker: 'test-worker', components: [:interfaces])
      dev_temperatures.poll(worker: 'test-worker', components: [:temperatures])
      dev_fans.poll(worker: 'test-worker', components: [:fans])
      dev_psus.poll(worker: 'test-worker', components: [:psus])
      dev_cpus.poll(worker: 'test-worker', components: [:cpus])
      dev_memory.poll(worker: 'test-worker', components: [:memory])
      dev_all.poll(worker: 'test-worker', components: [:all])

      context 'and when all components polled' do
        it 'should return a Device object' do
          expect(dev).to be_a Device
          expect(dev_all).to be_a Device
        end
        it 'should have Interface objects' do
          expect(dev.interfaces.first).to be_a Interface
          expect(dev_all.interfaces.first).to be_a Interface
        end
        it 'should have Temperature objects' do
          expect(dev.temps.first).to be_a Temperature
          expect(dev_all.temps.first).to be_a Temperature
        end
        it 'should have Fan objects' do
          expect(dev.fans.first).to be_a Fan
          expect(dev_all.fans.first).to be_a Fan
        end
        it 'should have PSU objects' do
          expect(dev.psus.first).to be_a PSU
          expect(dev_all.psus.first).to be_a PSU
        end
        it 'should have CPU objects' do
          expect(dev.cpus.first).to be_a CPU
          expect(dev_all.cpus.first).to be_a CPU
        end
        it 'should have Memory objects' do
          expect(dev.memory.first).to be_a Memory
          expect(dev_all.memory.first).to be_a Memory
        end
        it 'should know the worker' do
          expect(dev.worker).to eql 'test-worker'
          expect(dev_all.worker).to eql 'test-worker'
        end
      end
      context 'and when an empty components array passed' do
        it 'should return a Device object' do
          expect(dev_device).to be_a Device
        end
        it 'should not have Interface objects' do
          expect(dev_device.interfaces.first).to eql nil
        end
        it 'should not have Temperature objects' do
          expect(dev_device.temps.first).to eql nil
        end
        it 'should not have Fan objects' do
          expect(dev_device.fans.first).to eql nil
        end
        it 'should not have PSU objects' do
          expect(dev_device.psus.first).to eql nil
        end
        it 'should not have CPU objects' do
          expect(dev_device.cpus.first).to eql nil
        end
        it 'should not have Memory objects' do
          expect(dev_device.memory.first).to eql nil
        end
        it 'should know the worker' do
          expect(dev_device.worker).to eql 'test-worker'
        end
      end
      context 'and when only interfaces polled' do
        it 'should return a Device object' do
          expect(dev_interfaces).to be_a Device
        end
        it 'should have Interface objects' do
          expect(dev_interfaces.interfaces.first).to be_a Interface
        end
        it 'should not have Temperature objects' do
          expect(dev_interfaces.temps.first).to eql nil
        end
        it 'should not have Fan objects' do
          expect(dev_interfaces.fans.first).to eql nil
        end
        it 'should not have PSU objects' do
          expect(dev_interfaces.psus.first).to eql nil
        end
        it 'should not have CPU objects' do
          expect(dev_interfaces.cpus.first).to eql nil
        end
        it 'should not have Memory objects' do
          expect(dev_interfaces.memory.first).to eql nil
        end
        it 'should know the worker' do
          expect(dev_interfaces.worker).to eql 'test-worker'
        end
      end
      context 'and when only temperatures polled' do
        it 'should return a Device object' do
          expect(dev_temperatures).to be_a Device
        end
        it 'should not have Interface objects' do
          expect(dev_temperatures.interfaces.first).to eql nil
        end
        it 'should have Temperature objects' do
          expect(dev_temperatures.temps.first).to be_a Temperature
        end
        it 'should not have Fan objects' do
          expect(dev_temperatures.fans.first).to eql nil
        end
        it 'should not have PSU objects' do
          expect(dev_temperatures.psus.first).to eql nil
        end
        it 'should not have CPU objects' do
          expect(dev_temperatures.cpus.first).to eql nil
        end
        it 'should not have Memory objects' do
          expect(dev_temperatures.memory.first).to eql nil
        end
        it 'should know the worker' do
          expect(dev_temperatures.worker).to eql 'test-worker'
        end
      end
      context 'and when only fans polled' do
        it 'should return a Device object' do
          expect(dev_fans).to be_a Device
        end
        it 'should not have Interface objects' do
          expect(dev_fans.interfaces.first).to eql nil
        end
        it 'should not have Temperature objects' do
          expect(dev_fans.temps.first).to eql nil
        end
        it 'should have Fan objects' do
          expect(dev_fans.fans.first).to be_a Fan
        end
        it 'should not have PSU objects' do
          expect(dev_fans.psus.first).to eql nil
        end
        it 'should not have CPU objects' do
          expect(dev_fans.cpus.first).to eql nil
        end
        it 'should not have Memory objects' do
          expect(dev_fans.memory.first).to eql nil
        end
        it 'should know the worker' do
          expect(dev_fans.worker).to eql 'test-worker'
        end
      end
      context 'and when only psus polled' do
        it 'should return a Device object' do
          expect(dev_psus).to be_a Device
        end
        it 'should not have Interface objects' do
          expect(dev_psus.interfaces.first).to eql nil
        end
        it 'should not have Temperature objects' do
          expect(dev_psus.temps.first).to eql nil
        end
        it 'should not have Fan objects' do
          expect(dev_psus.fans.first).to eql nil
        end
        it 'should have PSU objects' do
          expect(dev_psus.psus.first).to be_a PSU
        end
        it 'should not have CPU objects' do
          expect(dev_psus.cpus.first).to eql nil
        end
        it 'should not have Memory objects' do
          expect(dev_psus.memory.first).to eql nil
        end
        it 'should know the worker' do
          expect(dev_psus.worker).to eql 'test-worker'
        end
      end
      context 'and when only cpus polled' do
        it 'should return a Device object' do
          expect(dev_cpus).to be_a Device
        end
        it 'should not have Interface objects' do
          expect(dev_cpus.interfaces.first).to eql nil
        end
        it 'should not have Temperature objects' do
          expect(dev_cpus.temps.first).to eql nil
        end
        it 'should not have Fan objects' do
          expect(dev_cpus.fans.first).to eql nil
        end
        it 'should not have PSU objects' do
          expect(dev_cpus.psus.first).to eql nil
        end
        it 'should have CPU objects' do
          expect(dev_cpus.cpus.first).to be_a CPU
        end
        it 'should not have Memory objects' do
          expect(dev_cpus.memory.first).to eql nil
        end
        it 'should know the worker' do
          expect(dev_cpus.worker).to eql 'test-worker'
        end
      end
      context 'and when only memory polled' do
        it 'should return a Device object' do
          expect(dev_memory).to be_a Device
        end
        it 'should not have Interface objects' do
          expect(dev_memory.interfaces.first).to eql nil
        end
        it 'should not have Temperature objects' do
          expect(dev_memory.temps.first).to eql nil
        end
        it 'should not have Fan objects' do
          expect(dev_memory.fans.first).to eql nil
        end
        it 'should not have PSU objects' do
          expect(dev_memory.psus.first).to eql nil
        end
        it 'should not have CPU objects' do
          expect(dev_memory.cpus.first).to eql nil
        end
        it 'should have Memory objects' do
          expect(dev_memory.memory.first).to be_a Memory
        end
        it 'should know the worker' do
          expect(dev_memory.worker).to eql 'test-worker'
        end
      end

    end

    test_devices.each do |label, device|
      context "on a #{label} when populated" do
        dev_obj = Device.new(device).populate
        specify { expect(dev_obj.poll(worker: 'test-worker')).to equal dev_obj }
      end
    end

  end


  context 'when newly created' do

    before :each do
      @dev_name = Device.new('gar-b11u17-acc-g')
    end


    describe '#interfaces' do
      specify { expect(@dev_name.interfaces).to be_a Array }
      specify { expect(@dev_name.interfaces.first).to eql nil }
    end

    describe '#temps' do
      specify { expect(@dev_name.temps).to be_a Array }
      specify { expect(@dev_name.temps.first).to eql nil }
    end

    describe '#fans' do
      specify { expect(@dev_name.fans).to be_a Array }
      specify { expect(@dev_name.fans.first).to eql nil }
    end

    describe '#psus' do
      specify { expect(@dev_name.psus).to be_a Array }
      specify { expect(@dev_name.psus.first).to eql nil }
    end

    describe '#cpus' do
      specify { expect(@dev_name.cpus).to be_a Array }
      specify { expect(@dev_name.cpus.first).to eql nil }
    end

    describe '#memory' do
      specify { expect(@dev_name.memory).to be_a Array }
      specify { expect(@dev_name.memory.first).to eql nil }
    end

    describe '#get_interface' do
      specify { expect(@dev_name.get_interface(name: 'Fa0/1')).to eql nil }
      specify { expect(@dev_name.get_interface(index: '10001')).to eql nil }
      specify { expect(@dev_name.get_interface(index: 10001)).to eql nil }
      specify { expect(@dev_name.get_interface(index: 10001, name: 'Fa0/2')).to eql nil }
    end


  end


  context 'when populated' do

    before :each do
      @dev = Device.new('gar-b11u17-acc-g').populate(:all => true)
      @dev2 = Device.new('irv-i1u1-dist')
    end


    describe '#interfaces' do
      specify { expect(@dev.interfaces).to be_a Array }
      specify { expect(@dev.interfaces.first).to be_a Interface }
    end

    describe '#temps' do
      specify { expect(@dev.temps).to be_a Array }
      specify { expect(@dev2.populate(:all => true).temps.first).to be_a Temperature }
    end

    describe '#fans' do
      specify { expect(@dev.fans).to be_a Array }
      specify { expect(@dev2.populate(:all => true).fans.first).to be_a Fan }
    end

    describe '#psus' do
      specify { expect(@dev.psus).to be_a Array }
      specify { expect(@dev2.populate(:all => true).psus.first).to be_a PSU }
    end

    describe '#cpus' do
      specify { expect(@dev.cpus).to be_a Array }
      specify { expect(@dev2.populate(:all => true).cpus.first).to be_a CPU }
    end

    describe '#memory' do
      specify { expect(@dev.memory).to be_a Array }
      specify { expect(@dev2.populate(:all => true).memory.first).to be_a Memory }
    end

    describe '#get_interface' do
      specify { expect(@dev.get_interface(name: 'Fa0/1').name).to eql 'Fa0/1' }
      specify { expect(@dev.get_interface(name: 'fa0/1').name).to eql 'Fa0/1' }
      specify { expect(@dev.get_interface(index: '10001').name).to eql 'Fa0/1' }
      specify { expect(@dev.get_interface(index: 10001).name).to eql 'Fa0/1' }
      specify { expect(@dev.get_interface(index: 10002, name: 'Fa0/1').name).to eql 'Fa0/2' }
      specify { expect(@dev.get_interface).to eql nil }
    end


  end


  # to_json
  describe '#to_json and #json_create' do

    context 'when freshly created' do

      before(:each) do
        @dev = Device.new(device: 'gar-test-1')
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

      before(:each) do
        @c2960 = Device.new(test_devices['Cisco 2960']).populate(:all => true)
        @c4948 = Device.new(test_devices['Cisco 4948']).populate(:all => true)
        @cumulus = Device.new(test_devices['Cumulus']).populate(:all => true)
        @ex = Device.new(test_devices['Juniper EX']).populate(:all => true)
        @mx = Device.new(test_devices['Juniper MX']).populate(:all => true)
        @f10_s4810 = Device.new(test_devices['Force10 S4810']).populate(:all => true)
      end


      it 'should serialize and deserialize properly' do
        json_c2960 = @c2960.to_json
        json_c4948 = @c4948.to_json
        json_cumulus = @cumulus.to_json
        json_ex = @ex.to_json
        json_mx = @mx.to_json
        json_f10_s4810 = @f10_s4810.to_json
        expect(JSON.load(json_c2960).to_json).to eql json_c2960
        expect(JSON.load(json_c4948).to_json).to eql json_c4948
        expect(JSON.load(json_cumulus).to_json).to eql json_cumulus
        expect(JSON.load(json_ex).to_json).to eql json_ex
        expect(JSON.load(json_mx).to_json).to eql json_mx
        expect(JSON.load(json_f10_s4810).to_json).to eql json_f10_s4810
      end

    end

  end


  # True integration tests
  describe '#poll' do
    c2960 = Device.new(test_devices['Cisco 2960']).populate.poll(worker: 't')
    #c4948 = Device.new(test_devices['Cisco 4948']).populate.poll(worker: 't')
    #cumulus = Device.new(test_devices['Cumulus']).populate.poll(worker: 't')
    #ex = Device.new(test_devices['Juniper EX']).populate.poll(worker: 't')
    #mx = Device.new(test_devices['Juniper MX']).populate.poll(worker: 't')
    #f10_s4810 = Device.new(test_devices['Force10 S4810']).populate.poll(worker: 't')

    context 'on a Cisco 2960' do
      #'Cisco 2960' => 'gar-b11u17-acc-g',
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
