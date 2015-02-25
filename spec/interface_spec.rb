require_relative '../lib/interface'
require_relative '../lib/core_ext/object'

describe Interface do

  # Up/Up
  interface_1 = {"device" => "gar-b11u1-dist","index" => 604,"last_updated" => 1424752121,"if_alias" => "bb__gar-crmx-1__xe-1/0/3","if_name" => "xe-0/2/0","if_hc_in_octets" => "0.3959706331274391E16","if_hc_out_octets" => "0.3281296197965732E16","if_hc_in_ucast_pkts" => "0.4388140890014E13","if_hc_out_ucast_pkts" => "0.3813525530792E13","if_speed" => 10000000000,"if_mtu" => 1522,"if_admin_status" => 1,"if_admin_status_time" => 1409786067,"if_oper_status" => 1,"if_oper_status_time" => 1409786067,"if_in_discards" => "0.0","if_in_errors" => "0.0","if_out_discards" => "0.0","if_out_errors" => "0.0","bps_in" => 1349172320,"bps_out" => 1371081672,"discards_in" => 0,"errors_in" => 0,"discards_out" => 0,"errors_out" => 0,"pps_in" => 180411,"pps_out" => 262760,"bps_in_util" => 13.49,"bps_out_util" => 13.71,"if_type" => "bb"}
  # Up/Down
  interface_2 = {"device" => "gar-b11u17-acc-g","index" => 10040,"last_updated" => 1424752718,"if_alias" => "acc__","if_name" => "Fa0/40","if_hc_in_octets" => "0.0","if_hc_out_octets" => "0.0","if_hc_in_ucast_pkts" => "0.0","if_hc_out_ucast_pkts" => "0.0","if_speed" => 10000000,"if_mtu" => 1500,"if_admin_status" => 1,"if_admin_status_time" => 1415142088,"if_oper_status" => 2,"if_oper_status_time" => 1415142088,"if_in_discards" => "0.0","if_in_errors" => "0.0","if_out_discards" => "0.0","if_out_errors" => "0.0","bps_in" => 0,"bps_out" => 0,"discards_in" => 0,"errors_in" => 0,"discards_out" => 0,"errors_out" => 0,"pps_in" => 0,"pps_out" => 0,"bps_in_util" => 0.0,"bps_out_util" => 0.0,"if_type" => "acc"}
  # Up/Up, AE
  interface_3 = {"device" => "gar-p1u1-dist","index" => 656,"last_updated" => 1424752472,"if_alias" => "bb__gar-cr-1__ae3","if_name" => "ae0","if_hc_in_octets" => "0.484779762679182E15","if_hc_out_octets" => "0.1111644194120525E16","if_hc_in_ucast_pkts" => "0.878552042051E12","if_hc_out_ucast_pkts" => "0.1174804345552E13","if_speed" => 20000000000,"if_mtu" => 1514,"if_admin_status" => 1,"if_admin_status_time" => 1416350411,"if_oper_status" => 1,"if_oper_status_time" => 1416350411,"if_in_discards" => "0.0","if_in_errors" => "0.0","if_out_discards" => "0.0","if_out_errors" => "0.0","bps_in" => 408764184,"bps_out" => 1172468480,"discards_in" => 0,"errors_in" => 0,"discards_out" => 0,"errors_out" => 0,"pps_in" => 104732,"pps_out" => 144934,"bps_in_util" => 2.04,"bps_out_util" => 5.86,"if_type" => "bb"}
  # Shutdown
  interface_4 = {"device" => "irv-a3u2-acc-g","index" => 10119,"last_updated" => 1424752571,"if_alias" => "","if_name" => "Gi0/19","if_hc_in_octets" => "0.0","if_hc_out_octets" => "0.2628E4","if_hc_in_ucast_pkts" => "0.0","if_hc_out_ucast_pkts" => "0.2E1","if_speed" => 1000000000,"if_mtu" => 1500,"if_admin_status" => 2,"if_admin_status_time" => 1415142087,"if_oper_status" => 2,"if_oper_status_time" => 1415142087,"if_in_discards" => "0.0","if_in_errors" => "0.0","if_out_discards" => "0.0","if_out_errors" => "0.0","bps_in" => 0,"bps_out" => 0,"discards_in" => 0,"errors_in" => 0,"discards_out" => 0,"errors_out" => 0,"pps_in" => 0,"pps_out" => 0,"bps_in_util" => 0.0,"bps_out_util" => 0.0,"if_type" => "unknown"}
  interfaces = [ interface_1, interface_2, interface_3, interface_4 ]


  # Constructor
  describe '#new' do

    it 'should return' do
      int = Interface.new(device: 'gar-test-1', index: 103)
      expect(int).to be_a Interface
    end

    it 'should raise' do
      expect{Interface.new(device: 'gar-test-1', index: 103.25)}.to raise_error TypeError
    end

    it 'should raise' do
      expect{Interface.new(device: 'gar-test-1', index: 'string')}.to raise_error TypeError
    end

  end


  # set_speed should work the same no matter what state the object is in
  describe '#set_speed' do

    int = Interface.new(device: 'gar-test-1', index: 103)

    it 'should update speed' do
      int.set_speed('1000')
      expect(int.speed).to eql 1000
    end

    it 'should raise' do
      expect{int.set_speed('string')}.to raise_error TypeError
    end

    it 'should raise' do
      expect{int.set_speed('1000.1')}.to raise_error TypeError
    end

  end


  # populate should work the same no matter what state the interface is in
  describe '#populate' do

    before(:each) do
      # Create our empty interface
      @int = Interface.new(device: 'gar-test-1', index: 103)
    end

    context 'when no data passed' do
      specify { expect(@int.populate).to eql nil }
    end

    context 'when data passed' do
      interfaces.each do |int_data|
        specify { expect(@int.populate(int_data)).to eql @int }
      end
    end

  end


  # A fresh interface
  context 'when just created' do

    before(:each) do
      # Create our empty interface
      @int = Interface.new(device: 'gar-test-1', index: 103)
    end


    describe '#speed' do
      specify { expect(@int.speed).to eql nil }
    end

    describe '#name' do
      specify { expect(@int.speed).to eql nil }
    end

    describe '#substitute_name' do
      specify { expect(@int.speed).to eql nil }
    end

    describe '#status' do
      specify { expect(@int.status).to eql "Down" }
    end

    describe '#update' do
      #TODO
    end

    describe '#write_to_influxdb' do
      #TODO
    end

  end


  context 'populated' do

    before(:each) do
      @int1 = Interface.new(device: 'gar-b11u1-dist', index: 604).populate(interface_1)
      @int2 = Interface.new(device: 'gar-b11u17-acc-g', index: 10040).populate(interface_2)
      @int3 = Interface.new(device: 'gar-p1u1-dist', index: 656).populate(interface_3)
      @int4 = Interface.new(device: 'irv-a3u2-acc-g', index: 10119).populate(interface_4)
      @ints = [ @int1, @int2, @int3, @int4 ]
    end


    describe '#speed' do
      specify { expect(@int1.speed).to eql 10000000000 }
      specify { expect(@int2.speed).to eql 10000000 }
      specify { expect(@int3.speed).to eql 20000000000 }
      specify { expect(@int4.speed).to eql 1000000000 }
    end

    describe '#name' do
      specify { expect(@int1.name).to eql 'xe-0/2/0' }
      specify { expect(@int2.name).to eql 'Fa0/40' }
      specify { expect(@int3.name).to eql 'ae0' }
      specify { expect(@int4.name).to eql 'Gi0/19' }
    end

    describe '#substitute_name' do
      subs = { 'xe-' => 'XE-TEST', 'Gi' => 'GigabitEthernet' }
      specify { expect(@int1.substitute_name(subs)).to eql 'XE-TEST0/2/0' }
      specify { expect(@int2.substitute_name(subs)).to eql 'Fa0/40' }
      specify { expect(@int3.substitute_name(subs)).to eql 'ae0' }
      specify { expect(@int4.substitute_name(subs)).to eql 'GigabitEthernet0/19' }
    end

    describe '#status' do
      specify { expect(@int1.status).to eql 'Up' }
      specify { expect(@int1.status(:oper)).to eql 'Up' }
      specify { expect(@int1.status(:admin)).to eql 'Up' }
      specify { expect(@int2.status).to eql 'Down' }
      specify { expect(@int2.status(:oper)).to eql 'Down' }
      specify { expect(@int2.status(:admin)).to eql 'Up' }
      specify { expect(@int3.status).to eql 'Up' }
      specify { expect(@int3.status(:oper)).to eql 'Up' }
      specify { expect(@int3.status(:admin)).to eql 'Up' }
      specify { expect(@int4.status).to eql 'Down' }
      specify { expect(@int4.status(:oper)).to eql 'Down' }
      specify { expect(@int4.status(:admin)).to eql 'Down' }
    end

    describe '#update' do
      #TODO
    end

    describe '#write_to_influxdb' do
      #TODO
    end

  end

end
