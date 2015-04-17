require_relative 'rspec'

describe Interface do

  json_keys = [
    'device',
    'index',
    'last_updated',
    'alias',
    'name',
    'hc_in_octets',
    'hc_out_octets',
    'hc_in_ucast_pkts',
    'hc_out_ucast_pkts',
    'speed',
    'mtu',
    'admin_status',
    'admin_status_time',
    'oper_status',
    'oper_status_time',
    'in_discards',
    'in_errors',
    'out_discards',
    'out_errors',
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
    'type',
    'worker',
  ]

  interface_1 = JSON.parse(INTERFACE_1)['data']
  int1_update = {
    "name" => "xe-0/2/0", "hc_in_octets" => "3959713831274390",
    "hc_out_octets" => "3281311197965730", "hc_in_ucast_pkts" => "4417738539412",
    "hc_out_ucast_pkts" => "3848146448961", "high_speed" => "10000",
    "alias" => "acc__gar-crmx-2__xe-16/0/3", "mtu" => "1522", "admin_status" => "1",
    "oper_status" => "1", "in_discards" => "0", "in_errors" => "0",
    "out_discards" => "0", "out_errors" => "0" }
  interface_2 = JSON.parse(INTERFACE_2)['data']
  int2_update = {
    "name"=>"Fa0/40", "hc_in_octets"=>"0", "hc_out_octets"=>"0",
    "hc_in_ucast_pkts"=>"0", "hc_out_ucast_pkts"=>"0", "high_speed"=>"10",
    "alias"=>"acc__", "mtu"=>"1500", "admin_status"=>"1", "oper_status"=>"2",
    "in_discards"=>"0", "in_errors"=>"0", "out_discards"=>"0", "out_errors"=>"0" }
  interface_3 = JSON.parse(INTERFACE_3)['data']
  int3_update = {
    "name"=>"ae0", "hc_in_octets"=>"493124877631750", "hc_out_octets"=>"1135292119081151",
    "hc_in_ucast_pkts"=>"895162904912", "hc_out_ucast_pkts"=>"1198370633351",
    "high_speed"=>"20000", "alias"=>"bb__gar-cr-1__ae3", "mtu"=>"1514",
    "admin_status"=>"1", "oper_status"=>"1", "in_discards"=>"0", "in_errors"=>"0",
    "out_discards"=>"0", "out_errors"=>"0" }
  interface_4 = JSON.parse(INTERFACE_4)['data']
  int4_update = {
    "name"=>"Gi0/19", "hc_in_octets"=>"0", "hc_out_octets"=>"2628",
    "hc_in_ucast_pkts"=>"0", "hc_out_ucast_pkts"=>"2", "high_speed"=>"1000",
    "alias"=>"", "mtu"=>"1500", "admin_status"=>"2", "oper_status"=>"2",
    "in_discards"=>"0", "in_errors"=>"0", "out_discards"=>"0", "out_errors"=>"0" }
  imaginary_int = {
    "device" => "test-test-test-g", "index" => 10119,"last_updated" => 1424752571,"alias" => "",
    "name" => "Gi0/19", "hc_in_octets" => "0.0", "hc_out_octets" => "0.2628E4",
    "hc_in_ucast_pkts" => "0.0", "hc_out_ucast_pkts" => "0.2E1", "speed" => 1000000000,
    "mtu" => 1500,"admin_status" => 2,"admin_status_time" => 1415142087, "worker" => "te",
    "oper_status" => 2,"oper_status_time" => 1415142087,"in_discards" => "0.0",
    "in_errors" => "0.0", "out_discards" => "0.0", "out_errors" => "0.0", "bps_in" => 0,
    "bps_out" => 0,"discards_in" => 0,"errors_in" => 0,"discards_out" => 0,"errors_out" => 0,
    "pps_in" => 0,"pps_out" => 0,"bps_util_in" => 0.0,"bps_util_out" => 0.0,
    "type" => "unknown" }

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


  describe '#fetch' do

    before(:each) do
      # Create our empty interface
      @bad_int = Interface.fetch('gar-test-1', 103)
      @good_int = Interface.fetch('gar-p1u1-dist', 656)
    end


    it 'should return nil if the object does not exist' do
      expect(@bad_int).to eql nil
    end

    it 'should return an object if the object exists' do
      expect(@good_int).to be_a Interface
    end

    it 'should fill up the object' do
      expect(JSON.parse(@good_int.to_json)['data'].keys).to eql json_keys
    end

  end


  # populate
  describe '#populate' do
    it 'should fill up the object' do
      good = Interface.new(device: 'iad1-bdr-1', index: 1)
      expect(JSON.parse(good.populate(interface_1).to_json)['data'].keys).to eql json_keys
    end
  end


  # A fresh interface
  context 'when just created' do

    before(:each) do
      # Create our empty interface
      @int = Interface.new(device: 'gar-test-1', index: '103')
    end


    describe '#device' do
      specify { expect(@int.device).to eql 'gar-test-1' }
    end

    describe '#index' do
      specify { expect(@int.index).to eql 103 }
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

    describe '#oper_status_time' do
      specify { expect(@int.oper_status_time).to eql nil }
    end

    describe '#clone_type' do
      # This interface has type 'unknown'
      unknown = JSON.load(INTERFACE_4)
      specify { expect(@int.clone_type(@int).type).to eql nil }
      specify { expect(@int.clone_type(@int)).to equal @int }
      specify { expect(@int.clone_type(unknown).type).to eql 'unknown' }
    end

    describe '#status' do
      specify { expect(@int.status).to eql "Down" }
    end

    describe '#up?' do
      specify { expect(@int.up?).to eql false }
    end

    describe '#down?' do
      specify { expect(@int.down?).to eql true }
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

    describe '#discards_out_pct' do
      specify { expect(@int.discards_out_pct).to eql 0.0 }
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

    describe '#last_updated' do
      specify { expect(@int.last_updated).to eql 0 }
    end

    describe '#physical?' do
      specify { expect(@int.physical?).to equal true }
    end

    describe '#parent_name' do
      specify { expect(@int.parent_name).to equal nil }
    end

    describe '#neighbor' do
      specify { expect(@int.neighbor).to eql nil }
    end

    describe '#neighbor_port' do
      specify { expect(@int.neighbor_port).to eql nil }
    end

    describe '#update' do
      specify { expect(@int.update(int1_update, worker: 'test')).to equal @int }
      specify { expect(@int.update(int1_update, worker: 'test').device).to eql 'gar-test-1' }
      specify { expect(@int.update(int1_update, worker: 'test').alias).to eql 'acc__gar-crmx-2__xe-16/0/3' }
      specify { expect(@int.update(int1_update, worker: 'test').neighbor).to eql 'gar-crmx-2' }
      specify { expect(@int.update(int1_update, worker: 'test').neighbor_port).to eql 'xe-16/0/3' }
      specify { expect(@int.update(int1_update, worker: 'test').type).to eql 'acc' }
    end

    describe '#write_to_influxdb' do
      #TODO
    end

  end


  context 'when populated' do

    before(:each) do
      @int1_before = JSON.parse(INTERFACE_1)
      @int1_before['data']['last_updated'] = Time.now.to_i - 60
      @int1 = JSON.load(@int1_before.to_json)
      @int2 = JSON.load(INTERFACE_2)
      @int3 = JSON.load(INTERFACE_3)
      @int4 = JSON.load(INTERFACE_4)
      @ints = [ @int1, @int2, @int3, @int4 ]
    end

    describe '#device' do
      specify { expect(@int1.device).to eql 'gar-b11u1-dist' }
      specify { expect(@int2.device).to eql 'gar-b11u17-acc-g' }
      specify { expect(@int3.device).to eql 'gar-p1u1-dist' }
      specify { expect(@int4.device).to eql 'irv-a3u2-acc-g' }
    end

    describe '#index' do
      specify { expect(@int1.index).to eql 604 }
      specify { expect(@int2.index).to eql 10040 }
      specify { expect(@int3.index).to eql 656 }
      specify { expect(@int4.index).to eql 10119 }
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
      specify { expect(@int3.alias).to eql 'sub[ae12]__gar-cr-1__ae3' }
      specify { expect(@int4.alias).to eql '' }
    end

    describe '#type' do
      specify { expect(@int1.type).to eql 'bb' }
      specify { expect(@int2.type).to eql 'acc' }
      specify { expect(@int3.type).to eql 'sub' }
      specify { expect(@int4.type).to eql 'unknown' }
    end

    describe '#oper_status_time' do
      specify { expect(@int1.oper_status_time).to eql 1409786067 }
      specify { expect(@int2.oper_status_time).to eql 1415142088 }
      specify { expect(@int3.oper_status_time).to eql 1416350411 }
      specify { expect(@int4.oper_status_time).to eql 1415142087 }
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

    describe '#down?' do
      specify { expect(@int1.down?).to eql false }
      specify { expect(@int2.down?).to eql true }
      specify { expect(@int3.down?).to eql false }
      specify { expect(@int4.down?).to eql true }
    end

    describe '#up?' do
      specify { expect(@int1.up?).to eql true }
      specify { expect(@int2.up?).to eql false }
      specify { expect(@int3.up?).to eql true }
      specify { expect(@int4.up?).to eql false }
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
      specify { expect(@int1.discards_out).to equal 15000 }
      specify { expect(@int2.discards_out).to equal 0 }
      specify { expect(@int3.discards_out).to equal 0 }
      specify { expect(@int4.discards_out).to equal 0 }
    end

    describe '#discards_out_pct' do
      specify { expect(@int1.discards_out_pct).to eql 5.4 }
      specify { expect(@int2.discards_out_pct).to eql 0.0 }
      specify { expect(@int3.discards_out_pct).to eql 0.0 }
      specify { expect(@int4.discards_out_pct).to eql 0.0 }
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

    describe '#last_updated' do
      specify { expect(@int1.last_updated).to eql @int1_before['data']['last_updated'].to_i }
      specify { expect(@int2.last_updated).to eql interface_2['last_updated'].to_i }
      specify { expect(@int3.last_updated).to eql interface_3['last_updated'].to_i }
      specify { expect(@int4.last_updated).to eql interface_4['last_updated'].to_i }
    end

    describe '#physical?' do
      specify { expect(@int1.physical?).to equal true }
      specify { expect(@int2.physical?).to equal true }
      specify { expect(@int3.physical?).to equal false }
      specify { expect(@int4.physical?).to equal true }
    end

    describe '#parent_name' do
      specify { expect(@int1.parent_name).to eql nil }
      specify { expect(@int2.parent_name).to eql nil }
      specify { expect(@int3.parent_name).to eql 'ae12' }
      specify { expect(@int4.parent_name).to eql nil }
    end

    describe '#neighbor' do
      specify { expect(@int1.neighbor).to eql 'gar-crmx-1' }
      specify { expect(@int2.neighbor).to eql nil }
      specify { expect(@int3.neighbor).to eql 'gar-cr-1' }
      specify { expect(@int4.neighbor).to eql nil }
    end

    describe '#neighbor_port' do
      specify { expect(@int1.neighbor_port).to eql 'xe-1/0/3' }
      specify { expect(@int2.neighbor_port).to eql nil }
      specify { expect(@int3.neighbor_port).to eql 'ae3' }
      specify { expect(@int4.neighbor_port).to eql nil }
    end

    describe '#update' do
      # The interface_1 and int1_update are specicially crated to give these
      #   outputs, ensuring accurate calcuation of bps and bps_util
      specify { expect(@int1.update(int1_update, worker: 'test')).to equal @int1 }
      specify { expect(@int1.update(int1_update, worker: 'test').bps_util_in).to eql 10.0 }
      specify { expect(@int1.update(int1_update, worker: 'test').bps_util_out).to eql 20.0 }
      specify { expect(@int1.update(int1_update, worker: 'test').bps_in).to eql 999_999_999 }
      specify { expect(@int1.update(int1_update, worker: 'test').bps_out).to eql 1_999_999_999 }
      specify { expect(@int2.update(int2_update, worker: 'test')).to equal @int2 }
      specify { expect(@int2.update(int2_update, worker: 'test').bps_util_in).to eql 0.0 }
      specify { expect(@int2.update(int2_update, worker: 'test').bps_util_out).to eql 0.0 }
      specify { expect(@int3.update(int3_update, worker: 'test')).to equal @int3 }
      specify { expect(@int4.update(int4_update, worker: 'test')).to equal @int4 }
      specify { expect(@int4.update(int4_update, worker: 'test').bps_util_in).to eql 0.0 }
      specify { expect(@int4.update(int4_update, worker: 'test').bps_util_out).to eql 0.0 }
      specify { expect(@int1.update(int1_update, worker: 'test').oper_status_time).to equal interface_1['oper_status_time'].to_i }
      specify { expect(@int1.update(int1_update, worker: 'test').device).to eql interface_1['device'] }
      specify { expect(@int1.update(int1_update, worker: 'test').index).to eql 604 }
      specify { expect(@int1.update(int1_update, worker: 'test').alias).to eql 'acc__gar-crmx-2__xe-16/0/3' }
      specify { expect(@int1.update(int1_update, worker: 'test').neighbor).to eql 'gar-crmx-2' }
      specify { expect(@int1.update(int1_update, worker: 'test').neighbor_port).to eql 'xe-16/0/3' }
      specify { expect(@int1.update(int1_update, worker: 'test').type).to eql 'acc' }
      specify { expect(@int3.update(int3_update, worker: 'test').type).to eql 'bb' }
    end

    describe '#write_to_influxdb' do
      #TODO
    end

  end


  # save
  describe '#save' do

    before :each do
      # Insert our bare bones device, just name and IP
      DB[:device].insert(:device => 'test-v11u1-acc-y', :ip => '1.2.3.4')
    end
    after :each do
      # Clean up DB
      DB[:device].where(:device => 'test-v11u1-acc-y').delete
    end


    it 'should not exist before saving' do
      expect(Interface.fetch('test-v11u1-acc-y', 10139)).to eql nil
    end

    it 'should fail if empty' do
      int = Interface.new(device: 'test-v11u1-acc-y', index: 10139)
      expect{int.save(DB)}.to raise_error Sequel::NotNullConstraintViolation
    end

    it 'should fail if devices does not exist' do
      int = JSON.load(IMAGINARY_INT)
      expect{int.save(DB)}.to raise_error Sequel::ForeignKeyConstraintViolation
    end

    it 'should exist after being saved' do
      JSON.load(DEV2_JSON).interfaces[10139].save(DB)
      int = Interface.fetch('test-v11u1-acc-y', 10139)
      expect(int).to be_a Interface
    end

    it 'should update without error' do
      JSON.load(DEV2_JSON).interfaces[10139].save(DB)
      JSON.load(DEV2_JSON).interfaces[10139].save(DB)
      int = Interface.fetch('test-v11u1-acc-y', 10139)
      expect(int).to be_a Interface
    end

    it 'should be identical before and after' do
      JSON.load(DEV2_JSON).interfaces[10139].save(DB)
      int = Interface.fetch('test-v11u1-acc-y', 10139)
      expect(int.to_json).to eql JSON.load(DEV2_JSON).interfaces[10139].to_json
    end

  end


  # delete
  describe '#delete' do

    before :each do
      # Insert our bare bones device, just name and IP
      DB[:device].insert(:device => 'test-v11u1-acc-y', :ip => '1.2.3.4')
    end
    after :each do
      # Clean up DB
      DB[:device].where(:device => 'test-v11u1-acc-y').delete
    end


    it 'should return 1 if it exists' do
      JSON.load(DEV2_JSON).interfaces[10139].save(DB)
      object = Interface.new(device: 'test-v11u1-acc-y', index: 10139)
      expect(object.delete(DB)).to eql 1
    end

    it "should return 0 if nonexistant" do
      object = Interface.new(device: 'test-v11u1-acc-y', index: 10139)
      expect(object.delete(DB)).to eql 0
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

      int1 = Interface.fetch('gar-b11u1-dist', 604)
      int2 = Interface.fetch('gar-b11u17-acc-g', 10040)
      int3 = Interface.fetch('gar-bdr-1', 541)
      int4 = Interface.fetch('aon-cumulus-2', 15)

      json1 = int1.to_json
      json2 = int2.to_json
      json3 = int3.to_json
      json4 = int4.to_json

      specify { expect(JSON.load(json1).to_json).to eql json1 }
      specify { expect(JSON.load(json2).to_json).to eql json2 }
      specify { expect(JSON.load(json3).to_json).to eql json3 }
      specify { expect(JSON.load(json4).to_json).to eql json4 }

    end

  end

end
