require_relative 'rspec'
require_relative '../lib/helper'
require_relative '../lib/core'
require_relative '../lib/configfile'
include Helper
include Core

settings = Configfile.retrieve

#TODO: bps_cell
#TODO: total_bps_cell
#TODO: speed_cell
#TODO: neighbor_link
#TODO: alarm_type_text
#TODO: link_status_color
#TODO: link_status_tooltip


# humanize_time
describe '#humanize_time' do
  specify { expect(humanize_time(0)).to eql '0 seconds' }
  specify { expect(humanize_time(1)).to eql '1 second' }
  specify { expect(humanize_time(32)).to eql '32 seconds' }
  specify { expect(humanize_time(60)).to eql '1 minute' }
  specify { expect(humanize_time(310)).to eql '5 minutes' }
  specify { expect(humanize_time(3600)).to eql '1 hour' }
  specify { expect(humanize_time(3660)).to eql '1 hour' }
  specify { expect(humanize_time(7660)).to eql '2 hours' }
  specify { expect(humanize_time(86400)).to eql '1 day' }
  specify { expect(humanize_time(8640000)).to eql '100 days' }
end


# full_title
describe '#full_title' do
  specify { expect(full_title(nil)).to eql 'Pixel' }
  specify { expect(full_title('test')).to eql 'Pixel | test' }
end


# tr_attributes
describe '#tr_attributes' do

  around :each do |test|
    #Transaction -- don't commit ANY of the garbage executed in these tests
    DB.transaction(:rollback=>:always, :auto_savepoint=>true) do
      JSON.load(INT_TEST_DEVICE).save(DB)
      test.run
    end
  end


  context 'as a regular interface' do
    int = JSON.load(INT_NORMAL_JSON)
    attr1 = tr_attributes(int)
    attr2 = tr_attributes(int, hl_relation: true)
    attr3 = tr_attributes(int, hide_if_child: true)
    attr4 = tr_attributes(int, hl_relation: true, hide_if_child: true)

    expected_result = "data-toggle='tooltip' data-container='body' title='index: 604'" +
      " data-rel='tooltip-left' data-pxl-index='604' class=''"

    specify { expect(attr1).to eql expected_result }
    specify { expect(attr2).to eql expected_result }
    specify { expect(attr3).to eql expected_result }
    specify { expect(attr4).to eql expected_result }
  end

  context 'as a child interface with valid parent' do
    parent = JSON.load(INT_NORMAL_JSON)
    int1 = JSON.load(INT_CHILD1_JSON)
    int2 = JSON.load(INT_CHILD2_JSON)

    attr1 = tr_attributes(int1, parent)
    expected_1 = "data-toggle='tooltip' data-container='body' title='index: 600'" +
      " data-rel='tooltip-left' data-pxl-index='600' class=''"
    attr2 = tr_attributes(int2, parent)
    expected_2 = "data-toggle='tooltip' data-container='body' title='index: 597'" +
      " data-rel='tooltip-left' data-pxl-index='597' class=''"
    attr3 = tr_attributes(int1, parent, hl_relation: true)
    expected_3 = "data-toggle='tooltip' data-container='body' title='index: 600'" +
      " data-rel='tooltip-left' data-pxl-index='600' data-pxl-parent='604'" +
      " class='604_child pxl-child-tr'"
    attr4 = tr_attributes(int2, parent, hl_relation: true)
    expected_4 = "data-toggle='tooltip' data-container='body' title='index: 597'" +
      " data-rel='tooltip-left' data-pxl-index='597' data-pxl-parent='604'" +
      " class='604_child pxl-child-tr'"
    attr5 = tr_attributes(int1, parent, hide_if_child: true)
    expected_5 = "data-toggle='tooltip' data-container='body' title='index: 600'" +
      " data-rel='tooltip-left' data-pxl-index='600' class='panel-collapse collapse out'"
    attr6 = tr_attributes(int2, parent, hide_if_child: true)
    expected_6 = "data-toggle='tooltip' data-container='body' title='index: 597'" +
      " data-rel='tooltip-left' data-pxl-index='597' class='panel-collapse collapse out'"
    attr7 = tr_attributes(int1, parent, hl_relation: true, hide_if_child: true)
    expected_7 = "data-toggle='tooltip' data-container='body' title='index: 600'" +
      " data-rel='tooltip-left' data-pxl-index='600' data-pxl-parent='604'" +
      " class='604_child panel-collapse collapse out pxl-child-tr'"
    attr8 = tr_attributes(int2, parent, hl_relation: true, hide_if_child: true)
    expected_8 = "data-toggle='tooltip' data-container='body' title='index: 597'" +
      " data-rel='tooltip-left' data-pxl-index='597' data-pxl-parent='604'" +
      " class='604_child panel-collapse collapse out pxl-child-tr'"

    specify { expect(attr1).to eql expected_1 }
    specify { expect(attr2).to eql expected_2 }
    specify { expect(attr3).to eql expected_3 }
    specify { expect(attr4).to eql expected_4 }
    specify { expect(attr5).to eql expected_5 }
    specify { expect(attr6).to eql expected_6 }
    specify { expect(attr7).to eql expected_7 }
    specify { expect(attr8).to eql expected_8 }
  end

  context 'as a child interface with invalid parent' do
    int = JSON.load(INT_INVALID_CHILD_JSON)
    parent = get_interface(settings, DB, int.device, name: int.parent_name)

    attr1 = tr_attributes(int,parent)
    expected_1 = "data-toggle='tooltip' data-container='body' title='index: 595'" +
      " data-rel='tooltip-left' data-pxl-index='595' class=''"
    attr2 = tr_attributes(int, parent)
    expected_2 = "data-toggle='tooltip' data-container='body' title='index: 595'" +
      " data-rel='tooltip-left' data-pxl-index='595' class=''"
    attr3 = tr_attributes(int, parent, hl_relation: true)
    expected_3 = "data-toggle='tooltip' data-container='body' title='index: 595'" +
      " data-rel='tooltip-left' data-pxl-index='595' class=''"
    attr4 = tr_attributes(int, parent, hl_relation: true)
    expected_4 = "data-toggle='tooltip' data-container='body' title='index: 595'" +
      " data-rel='tooltip-left' data-pxl-index='595' class=''"

    specify { expect(attr1).to eql expected_1 }
    specify { expect(attr2).to eql expected_2 }
    specify { expect(attr3).to eql expected_3 }
    specify { expect(attr4).to eql expected_4 }
  end

end


# device_link
describe '#device_link' do

  it 'should generate a link' do
    link = device_link('gar-b11u1-dist')
    expect(link).to eql "<a href='/device/gar-b11u1-dist'>gar-b11u1-dist</a>"
  end

end




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
