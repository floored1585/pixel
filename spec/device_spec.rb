require 'logger'
require 'snmp'
require_relative '../lib/device'
require_relative '../lib/api'
require_relative '../lib/core_ext/object'
require_relative '../lib/configfile'

poll_cfg = Configfile.retrieve['poller']

APP_ROOT = File.dirname(__FILE__)
$LOG = Logger.new("#{APP_ROOT}/rspec.log", 0, 100*1024*1024)

describe Device do

  # Up/Up
  interface_1 = {"device" => "gar-b11u1-dist","index" => 604,"last_updated" => 1424752121,"if_alias" => "bb__gar-crmx-1__xe-1/0/3","if_name" => "xe-0/2/0","if_hc_in_octets" => "0.3959706331274391E16","if_hc_out_octets" => "0.3281296197965732E16","if_hc_in_ucast_pkts" => "0.4388140890014E13","if_hc_out_ucast_pkts" => "0.3813525530792E13","if_speed" => 10000000000,"if_mtu" => 1522,"if_admin_status" => 1,"if_admin_status_time" => 1409786067,"if_oper_status" => 1,"if_oper_status_time" => 1409786067,"if_in_discards" => "0.0","if_in_errors" => "0.0","if_out_discards" => "0.0","if_out_errors" => "0.0","bps_in" => 1349172320,"bps_out" => 1371081672,"discards_in" => 0,"errors_in" => 0,"discards_out" => 0,"errors_out" => 0,"pps_in" => 180411,"pps_out" => 262760,"bps_in_util" => 13.49,"bps_out_util" => 13.71,"if_type" => "bb"}
  # Up/Down
  interface_2 = {"device" => "gar-b11u17-acc-g","index" => 10040,"last_updated" => 1424752718,"if_alias" => "acc__","if_name" => "Fa0/40","if_hc_in_octets" => "0.0","if_hc_out_octets" => "0.0","if_hc_in_ucast_pkts" => "0.0","if_hc_out_ucast_pkts" => "0.0","if_speed" => 10000000,"if_mtu" => 1500,"if_admin_status" => 1,"if_admin_status_time" => 1415142088,"if_oper_status" => 2,"if_oper_status_time" => 1415142088,"if_in_discards" => "0.0","if_in_errors" => "0.0","if_out_discards" => "0.0","if_out_errors" => "0.0","bps_in" => 0,"bps_out" => 0,"discards_in" => 0,"errors_in" => 0,"discards_out" => 0,"errors_out" => 0,"pps_in" => 0,"pps_out" => 0,"bps_in_util" => 0.0,"bps_out_util" => 0.0,"if_type" => "acc"}
  # Up/Up, AE
  interface_3 = {"device" => "gar-p1u1-dist","index" => 656,"last_updated" => 1424752472,"if_alias" => "bb__gar-cr-1__ae3","if_name" => "ae0","if_hc_in_octets" => "0.484779762679182E15","if_hc_out_octets" => "0.1111644194120525E16","if_hc_in_ucast_pkts" => "0.878552042051E12","if_hc_out_ucast_pkts" => "0.1174804345552E13","if_speed" => 20000000000,"if_mtu" => 1514,"if_admin_status" => 1,"if_admin_status_time" => 1416350411,"if_oper_status" => 1,"if_oper_status_time" => 1416350411,"if_in_discards" => "0.0","if_in_errors" => "0.0","if_out_discards" => "0.0","if_out_errors" => "0.0","bps_in" => 408764184,"bps_out" => 1172468480,"discards_in" => 0,"errors_in" => 0,"discards_out" => 0,"errors_out" => 0,"pps_in" => 104732,"pps_out" => 144934,"bps_in_util" => 2.04,"bps_out_util" => 5.86,"if_type" => "bb"}
  # Shutdown
  interface_4 = {"device" => "irv-a3u2-acc-g","index" => 10119,"last_updated" => 1424752571,"if_alias" => "","if_name" => "Gi0/19","if_hc_in_octets" => "0.0","if_hc_out_octets" => "0.2628E4","if_hc_in_ucast_pkts" => "0.0","if_hc_out_ucast_pkts" => "0.2E1","if_speed" => 1000000000,"if_mtu" => 1500,"if_admin_status" => 2,"if_admin_status_time" => 1415142087,"if_oper_status" => 2,"if_oper_status_time" => 1415142087,"if_in_discards" => "0.0","if_in_errors" => "0.0","if_out_discards" => "0.0","if_out_errors" => "0.0","bps_in" => 0,"bps_out" => 0,"discards_in" => 0,"errors_in" => 0,"discards_out" => 0,"errors_out" => 0,"pps_in" => 0,"pps_out" => 0,"bps_in_util" => 0.0,"bps_out_util" => 0.0,"if_type" => "unknown"}
  interfaces = [ interface_1, interface_2, interface_3, interface_4 ]
  test_devices = %w[ gar-b11u17-acc-g irv-i1u1-dist aon-cumulus-2 gar-p1u1-dist ]


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

    it 'should return' do
      device = Device.new('gar-b11u17-acc-g', poll_ip: '172.24.7.54', poll_cfg: poll_cfg)
      expect(device).to be_a Device
    end

  end


  # populate should work the same no matter what state the device is in
  describe '#populate' do

    test_devices.each do |device|
      context 'when no options passed' do
        it 'should equal' do
          dev_obj = Device.new(device)
          expect(dev_obj.populate).to equal dev_obj
        end
      end
      context 'when :interfaces passed' do
        it 'should equal' do
          dev_obj = Device.new(device)
          expect(dev_obj.populate([:interfaces])).to equal dev_obj
        end
      end
      context 'when :cpus passed' do
        it 'should equal' do
          #dev_obj = Device.new(device)
          #specify { expect(dev_obj.populate([:cpus])).to equal dev_obj }
        end
      end
      context 'when :memory passed' do
        it 'should equal' do
          #dev_obj = Device.new(device)
          #specify { expect(dev_obj.populate([:memory])).to equal dev_obj }
        end
      end
      context 'when :temperatures passed' do
        it 'should equal' do
          #dev_obj = Device.new(device)
          #specify { expect(dev_obj.populate([:temperatures])).to equal dev_obj }
        end
      end
      context 'when :psus passed' do
        it 'should equal' do
          #dev_obj = Device.new(device)
          #specify { expect(dev_obj.populate([:psus])).to equal dev_obj }
        end
      end
      context 'when :fans passed' do
        it 'should equal' do
          #dev_obj = Device.new(device)
          #specify { expect(dev_obj.populate([:fans])).to equal dev_obj }
        end
      end
      context 'when :macs passed' do
        it 'should equal' do
          #dev_obj = Device.new(device)
          #specify { expect(dev_obj.populate([:macs])).to equal dev_obj }
        end
      end
      context 'when all options passed' do
        it 'should equal' do
          #dev_obj = Device.new(device)
          #symbols = [:interfaces, :cpus, :memory, :temperatures, :psus, :fans, :macs]
          #specify { expect(dev_obj.populate(symbols)).to equal dev_obj }
        end
      end
    end

  end


  describe '#interfaces' do

    context 'when newly created' do
      specify { expect(Device.new('gar-b11u17-acc-g').interfaces).to be_a Array }
    end

    context 'when populated' do
      specify { expect(Device.new('gar-b11u17-acc-g').populate([:interfaces]).interfaces).to be_a Array }
    end

  end


  describe '#poll' do
    before :each do
      @dev_name = Device.new('gar-b11u17-acc-g')
      @dev_name_ip = Device.new('gar-b11u17-acc-g', poll_ip: '172.24.7.54')
      @dev_name_ip_cfg = Device.new('gar-b11u17-acc-g', poll_ip: '172.24.7.54', poll_cfg: poll_cfg)
    end

    context 'when newly created with name' do
      specify { expect(@dev_name.poll(worker: 'test-worker')).to eql nil }
    end
    context 'when newly created with name and IP' do
      specify { expect(@dev_name_ip.poll(worker: 'test-worker')).to eql nil }
    end
    context 'when newly created with name, IP, and poll_cfg' do
      specify { expect(@dev_name_ip_cfg.poll(worker: 'test-worker')).to equal @dev_name_ip_cfg }
    end
    context 'when populated' do
      test_devices.each do |device|
      end
    end

  end

end
