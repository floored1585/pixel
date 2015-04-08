require_relative '../lib/interface'

describe Interface do

  json_keys = [
    'device',
    'index',
    'last_updated',
    'if_alias',
    'if_name',
    'if_hc_in_octets',
    'if_hc_out_octets',
    'if_hc_in_ucast_pkts',
    'if_hc_out_ucast_pkts',
    'if_speed',
    'if_mtu',
    'if_admin_status',
    'if_admin_status_time',
    'if_oper_status',
    'if_oper_status_time',
    'if_in_discards',
    'if_in_errors',
    'if_out_discards',
    'if_out_errors',
    'bps_in',
    'bps_out',
    'discards_in',
    'errors_in',
    'discards_out',
    'errors_out',
    'pps_in',
    'pps_out',
    'bps_util_in',
    'bps_util_out',
    'if_type',
    'worker',
  ]

  # Up/Up
  interface_1 = {
    "device" => "gar-b11u1-dist", "index" => 604,"last_updated" => 1424752121,
    "if_alias" => "bb__gar-crmx-1__xe-1/0/3", "if_name" => "xe-0/2/0",
    "if_hc_in_octets" => "0.3959706331274391E16", "if_hc_out_octets" => "0.3281296197965732E16",
    "if_hc_in_ucast_pkts" => "0.4388140890014E13", "if_hc_out_ucast_pkts" => "0.3813525530792E13",
    "if_speed" => 10000000000,"if_mtu" => 1522,"if_admin_status" => 1,
    "if_admin_status_time" => 1409786067,"if_oper_status" => 1,"if_oper_status_time" => 1409786067,
    "if_in_discards" => "0.0", "if_in_errors" => "0.0", "if_out_discards" => "0.0",
    "if_out_errors" => "0.0", "bps_in" => 1349172320,"bps_out" => 1371081672,"discards_in" => 100,
    "errors_in" => 0,"discards_out" => 150,"errors_out" => 0,"pps_in" => 180411,
    "pps_out" => 262760, "bps_util_in" => 13.49,"bps_util_out" => 13.71, "if_type" => "bb" }
  interface_1_update = {
    "if_name" => "xe-0/2/0", "if_hc_in_octets" => "3959713831274390",
    "if_hc_out_octets" => "3281311197965730", "if_hc_in_ucast_pkts" => "4417738539412",
    "if_hc_out_ucast_pkts" => "3848146448961", "if_high_speed" => "10000",
    "if_alias" => "bb__gar-crmx-1__xe-1/0/3", "if_mtu" => "1522", "if_admin_status" => "1",
    "if_oper_status" => "1", "if_in_discards" => "0", "if_in_errors" => "0",
    "if_out_discards" => "0", "if_out_errors" => "0" }
  # Up/Down
  interface_2 = {
    "device" => "gar-b11u17-acc-g", "index" => 10040,"last_updated" => 1424752718,
    "if_alias" => "acc__", "if_name" => "Fa0/40", "if_hc_in_octets" => "0.0",
    "if_hc_out_octets" => "0.0", "if_hc_in_ucast_pkts" => "0.0", "if_hc_out_ucast_pkts" => "0.0",
    "if_speed" => 10000000,"if_mtu" => 1500,"if_admin_status" => 1,
    "if_admin_status_time" => 1415142088,"if_oper_status" => 2,"if_oper_status_time" => 1415142088,
    "if_in_discards" => "0.0", "if_in_errors" => "0.0", "if_out_discards" => "0.0",
    "if_out_errors" => "0.0", "bps_in" => 0,"bps_out" => 0,"discards_in" => 0,"errors_in" => 0,
    "discards_out" => 0,"errors_out" => 0,"pps_in" => 0,"pps_out" => 0,"bps_util_in" => 0.0,
    "bps_util_out" => 0.0,"if_type" => "acc" }
  interface_2_update = {
    "if_name"=>"Fa0/40", "if_hc_in_octets"=>"0", "if_hc_out_octets"=>"0",
    "if_hc_in_ucast_pkts"=>"0", "if_hc_out_ucast_pkts"=>"0", "if_high_speed"=>"10",
    "if_alias"=>"acc__", "if_mtu"=>"1500", "if_admin_status"=>"1", "if_oper_status"=>"2",
    "if_in_discards"=>"0", "if_in_errors"=>"0", "if_out_discards"=>"0", "if_out_errors"=>"0" }
  # Up/Up, AE
  interface_3 = {
    "device" => "gar-p1u1-dist", "index" => 656,"last_updated" => 1424752472,
    "if_alias" => "bb__gar-cr-1__ae3", "if_name" => "ae0",
    "if_hc_in_octets" => "0.484779762679182E15", "if_hc_out_octets" => "0.1111644194120525E16",
    "if_hc_in_ucast_pkts" => "0.878552042051E12", "if_hc_out_ucast_pkts" => "0.1174804345552E13",
    "if_speed" => 20000000000,"if_mtu" => 1514,"if_admin_status" => 1,
    "if_admin_status_time" => 1416350411,"if_oper_status" => 1,"if_oper_status_time" => 1416350411,
    "if_in_discards" => "0.0", "if_in_errors" => "0.0", "if_out_discards" => "0.0",
    "if_out_errors" => "0.0", "bps_in" => 408764184,"bps_out" => 1172468480,"discards_in" => 0,
    "errors_in" => 300,"discards_out" => 0,"errors_out" => 350,"pps_in" => 104732,
    "pps_out" => 144934, "bps_util_in" => 2.04,"bps_util_out" => 5.86,"if_type" => "bb" }
  interface_3_update = {
    "if_name"=>"ae0", "if_hc_in_octets"=>"493124877631750", "if_hc_out_octets"=>"1135292119081151",
    "if_hc_in_ucast_pkts"=>"895162904912", "if_hc_out_ucast_pkts"=>"1198370633351",
    "if_high_speed"=>"20000", "if_alias"=>"bb__gar-cr-1__ae3", "if_mtu"=>"1514",
    "if_admin_status"=>"1", "if_oper_status"=>"1", "if_in_discards"=>"0", "if_in_errors"=>"0",
    "if_out_discards"=>"0", "if_out_errors"=>"0" }
  # Shutdown
  interface_4 = {
    "device" => "irv-a3u2-acc-g", "index" => 10119,"last_updated" => 1424752571,"if_alias" => "",
    "if_name" => "Gi0/19", "if_hc_in_octets" => "0.0", "if_hc_out_octets" => "0.2628E4",
    "if_hc_in_ucast_pkts" => "0.0", "if_hc_out_ucast_pkts" => "0.2E1", "if_speed" => 1000000000,
    "if_mtu" => 1500,"if_admin_status" => 2,"if_admin_status_time" => 1415142087,
    "if_oper_status" => 2,"if_oper_status_time" => 1415142087,"if_in_discards" => "0.0",
    "if_in_errors" => "0.0", "if_out_discards" => "0.0", "if_out_errors" => "0.0", "bps_in" => 0,
    "bps_out" => 0,"discards_in" => 0,"errors_in" => 0,"discards_out" => 0,"errors_out" => 0,
    "pps_in" => 0,"pps_out" => 0,"bps_util_in" => 0.0,"bps_util_out" => 0.0,
    "if_type" => "unknown" }
  interface_4_update = {
    "if_name"=>"Gi0/19", "if_hc_in_octets"=>"0", "if_hc_out_octets"=>"2628",
    "if_hc_in_ucast_pkts"=>"0", "if_hc_out_ucast_pkts"=>"2", "if_high_speed"=>"1000",
    "if_alias"=>"", "if_mtu"=>"1500", "if_admin_status"=>"2", "if_oper_status"=>"2",
    "if_in_discards"=>"0", "if_in_errors"=>"0", "if_out_discards"=>"0", "if_out_errors"=>"0" }

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


  # populate should work the same no matter what state the interface is in
  describe '#populate' do

    before(:each) do
      # Create our empty interface
      @bad_int = Interface.new(device: 'gar-test-1', index: 103)
      @good_int = Interface.new(device: 'gar-p1u1-dist', index: 656)
    end


    it 'should return nil if the object does not exist' do
      expect(@bad_int.populate).to eql nil
    end

    it 'should return an object if the object exists' do
      expect(@good_int.populate).to be_a Interface
    end

    it 'should fill up the object' do
      expect(JSON.parse(@good_int.populate(interface_1).to_json)['data'].keys).to eql json_keys
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

    describe '#set_speed' do
      specify { expect{@int.set_speed('string')}.to raise_error TypeError }
      specify { expect{@int.set_speed('1000.1')}.to raise_error TypeError }
      specify { expect(@int.set_speed('1000')).to be_a Interface }
      specify { expect(@int.set_speed('1000').speed).to eql 1000 }
    end

    describe '#name' do
      specify { expect(@int.name).to eql nil }
    end

    describe '#substitute_name' do
      subs = { 'xe-' => 'XE-TEST', 'Gi' => 'GigabitEthernet' }
      specify { expect(@int.substitute_name(subs)).to eql nil }
    end

    describe '#alias' do
      specify { expect(@int.alias).to eql nil }
    end

    describe '#type' do
      specify { expect(@int.type).to eql nil }
    end

    describe '#clone_type' do
      # This interface has type 'unknown'
      unknown = Interface.new(device: 'irv-a3u2-acc-g', index: 10119).populate(interface_4)
      specify { expect(@int.clone_type(@int).type).to eql nil }
      specify { expect(@int.clone_type(@int)).to equal @int }
      specify { expect(@int.clone_type(unknown).type).to eql 'unknown' }
    end

    describe '#status' do
      specify { expect(@int.status).to eql "Down" }
    end

    describe '#bps_in' do
      specify { expect(@int.bps_in).to eql 0 }
    end
    describe '#bps_out' do
      specify { expect(@int.bps_out).to eql 0 }
    end

    describe '#pps_in' do
      specify { expect(@int.pps_in).to eql 0 }
    end
    describe '#pps_out' do
      specify { expect(@int.pps_out).to eql 0 }
    end

    describe '#discards_in' do
      specify { expect(@int.discards_in).to eql 0 }
    end
    describe '#discards_out' do
      specify { expect(@int.discards_out).to eql 0 }
    end

    describe '#errors_in' do
      specify { expect(@int.errors_in).to eql 0 }
    end
    describe '#errors_out' do
      specify { expect(@int.errors_out).to eql 0 }
    end

    describe '#bps_util_in' do
      specify { expect(@int.bps_util_in).to equal 0.0 }
    end
    describe '#bps_util_out' do
      specify { expect(@int.bps_util_out).to equal 0.0 }
    end

    describe '#physical?' do
      specify { expect(@int.physical?).to equal true }
    end

    describe '#update' do
      specify { expect(@int.update(interface_1_update, worker: 'test')).to equal @int }
    end

    describe '#write_to_influxdb' do
      #TODO
    end

  end


  context 'populated' do

    before(:each) do
      interface_1['last_updated'] = Time.now.to_i - 60
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

    describe '#set_speed' do
      specify { expect(@int1.set_speed('10000000000')).to be_a Interface }
      specify { expect(@int1.set_speed('10000000000').bps_util_in).to eql 13.49 }
      specify { expect(@int1.set_speed('100000000000').bps_util_in).to eql 1.35 }
      specify { expect(@int1.set_speed('1000000000').bps_util_in).to eql 100.0 }
      specify { expect(@int1.set_speed('0').bps_util_in).to eql 0.0 }
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

    describe '#alias' do
      specify { expect(@int1.alias).to eql 'bb__gar-crmx-1__xe-1/0/3' }
      specify { expect(@int2.alias).to eql 'acc__' }
      specify { expect(@int3.alias).to eql 'bb__gar-cr-1__ae3' }
      specify { expect(@int4.alias).to eql '' }
    end

    describe '#type' do
      specify { expect(@int1.type).to eql 'bb' }
      specify { expect(@int2.type).to eql 'acc' }
      specify { expect(@int3.type).to eql 'bb' }
      specify { expect(@int4.type).to eql 'unknown' }
    end

    describe '#clone_type' do
      specify { expect(@int1.clone_type(@int2).type).to eql 'acc' }
      specify { expect(@int2.clone_type(@int1).type).to eql 'bb' }
      specify { expect(@int3.clone_type(@int4).type).to eql 'unknown' }
      specify { expect(@int4.clone_type(@int3)).to equal @int4 }
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

    describe '#bps_in' do
      specify { expect(@int1.bps_in).to equal 1349172320 }
      specify { expect(@int2.bps_in).to equal 0 }
      specify { expect(@int3.bps_in).to equal 408764184 }
      specify { expect(@int4.bps_in).to equal 0 }
    end
    describe '#bps_out' do
      specify { expect(@int1.bps_out).to equal 1371081672 }
      specify { expect(@int2.bps_out).to equal 0 }
      specify { expect(@int3.bps_out).to equal 1172468480 }
      specify { expect(@int4.bps_out).to equal 0 }
    end

    describe '#pps_in' do
      specify { expect(@int1.pps_in).to equal 180411 }
      specify { expect(@int2.pps_in).to equal 0 }
      specify { expect(@int3.pps_in).to equal 104732 }
      specify { expect(@int4.pps_in).to equal 0 }
    end
    describe '#pps_out' do
      specify { expect(@int1.pps_out).to equal 262760 }
      specify { expect(@int2.pps_out).to equal 0 }
      specify { expect(@int3.pps_out).to equal 144934 }
      specify { expect(@int4.pps_out).to equal 0 }
    end

    describe '#discards_in' do
      specify { expect(@int1.discards_in).to equal 100 }
      specify { expect(@int2.discards_in).to equal 0 }
      specify { expect(@int3.discards_in).to equal 0 }
      specify { expect(@int4.discards_in).to equal 0 }
    end
    describe '#discards_out' do
      specify { expect(@int1.discards_out).to equal 150 }
      specify { expect(@int2.discards_out).to equal 0 }
      specify { expect(@int3.discards_out).to equal 0 }
      specify { expect(@int4.discards_out).to equal 0 }
    end

    describe '#errors_in' do
      specify { expect(@int1.errors_in).to equal 0 }
      specify { expect(@int2.errors_in).to equal 0 }
      specify { expect(@int3.errors_in).to equal 300 }
      specify { expect(@int4.errors_in).to equal 0 }
    end
    describe '#errors_out' do
      specify { expect(@int1.errors_out).to equal 0 }
      specify { expect(@int2.errors_out).to equal 0 }
      specify { expect(@int3.errors_out).to equal 350 }
      specify { expect(@int4.errors_out).to equal 0 }
    end

    describe '#bps_util_in' do
      specify { expect(@int1.bps_util_in).to equal 13.49 }
      specify { expect(@int2.bps_util_in).to equal 0.0 }
      specify { expect(@int3.bps_util_in).to equal 2.04 }
      specify { expect(@int4.bps_util_in).to equal 0.0 }
    end

    describe '#bps_util_out' do
      specify { expect(@int1.bps_util_out).to equal 13.71 }
      specify { expect(@int2.bps_util_out).to equal 0.0 }
      specify { expect(@int3.bps_util_out).to equal 5.86 }
      specify { expect(@int4.bps_util_out).to equal 0.0 }
    end

    describe '#physical?' do
      specify { expect(@int1.physical?).to equal true }
      specify { expect(@int2.physical?).to equal true }
      specify { expect(@int3.physical?).to equal false }
      specify { expect(@int4.physical?).to equal true }
    end

    describe '#update' do
      # The interface_1 and interface_1_update are specicially crated to give these
      #   outputs, ensuring accurate calcuation of bps and bps_util
      specify { expect(@int1.update(interface_1_update, worker: 'test')).to equal @int1 }
      specify { expect(@int1.update(interface_1_update, worker: 'test').bps_util_in).to eql 10.0 }
      specify { expect(@int1.update(interface_1_update, worker: 'test').bps_util_out).to eql 20.0 }
      specify { expect(@int1.update(interface_1_update, worker: 'test').bps_in).to eql 999_999_999 }
      specify { expect(@int1.update(interface_1_update, worker: 'test').bps_out).to eql 1_999_999_999 }
      specify { expect(@int2.update(interface_2_update, worker: 'test')).to equal @int2 }
      specify { expect(@int2.update(interface_2_update, worker: 'test').bps_util_in).to eql 0.0 }
      specify { expect(@int2.update(interface_2_update, worker: 'test').bps_util_out).to eql 0.0 }
      specify { expect(@int3.update(interface_3_update, worker: 'test')).to equal @int3 }
      specify { expect(@int4.update(interface_4_update, worker: 'test')).to equal @int4 }
      specify { expect(@int4.update(interface_4_update, worker: 'test').bps_util_in).to eql 0.0 }
      specify { expect(@int4.update(interface_4_update, worker: 'test').bps_util_out).to eql 0.0 }
    end

    describe '#write_to_influxdb' do
      #TODO
    end

  end

  # to_json
  describe '#to_json and #json_create' do

    context 'when freshly created' do

      before(:each) do
        @interface = Interface.new(device: 'gar-p1u1-dist', index: '656')
      end


      it 'should return a string' do
        expect(@interface.to_json).to be_a String
      end

      it 'should serialize and deserialize' do
        json = @interface.to_json
        expect(JSON.load(json)).to be_a Interface
        expect(JSON.load(json).to_json).to eql json
      end

    end


    context 'when populated' do

      before(:each) do
        @int1 = Interface.new(device: 'gar-b11u1-dist', index: 604).populate
        @int2 = Interface.new(device: 'gar-b11u17-acc-g', index: 10040).populate
        @int3 = Interface.new(device: 'gar-bdr-1', index: 541).populate
        @int4 = Interface.new(device: 'aon-cumulus-2', index: 15).populate
      end


      it 'should serialize and deserialize properly' do
        json1 = @int1.to_json
        json2 = @int2.to_json
        json3 = @int3.to_json
        json4 = @int4.to_json
        expect(JSON.load(json1).to_json).to eql json1
        expect(JSON.load(json2).to_json).to eql json2
        expect(JSON.load(json3).to_json).to eql json3
        expect(JSON.load(json4).to_json).to eql json4
      end

    end

  end

end
