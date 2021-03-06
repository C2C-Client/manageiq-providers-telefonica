describe ManageIQ::Providers::Telefonica::CloudManager::CloudVolume do
  let(:ems) { FactoryBot.create(:ems_telefonica) }
  let(:tenant) { FactoryBot.create(:cloud_tenant_telefonica, :ext_management_system => ems) }
  let(:cloud_volume) do
    FactoryBot.create(:cloud_volume_telefonica,
                      :ext_management_system => ems,
                      :name                  => 'test',
                      :ems_ref               => 'one_id',
                      :cloud_tenant          => tenant)
  end

  let(:the_raw_volume) do
    double.tap do |volume|
      allow(volume).to receive(:id).and_return('one_id')
      allow(volume).to receive(:status).and_return('available')
      allow(volume).to receive(:attributes).and_return({})
      allow(volume).to receive(:save).and_return(volume)
    end
  end

  let(:raw_volumes) do
    double.tap do |volumes|
      handle = double
      allow(handle).to receive(:volumes).and_return(volumes)
      allow(ExtManagementSystem).to receive(:find).with(ems.id).and_return(ems)
      allow(ems).to receive(:connect).with(hash_including(:service     => 'Volume',
                                                          :tenant_name => tenant.name)).and_return(handle)
      allow(volumes).to receive(:get).with(cloud_volume.ems_ref).and_return(the_raw_volume)
    end
  end

  before do
    raw_volumes
  end

  describe 'volume actions' do
    context ".create_volume" do
      let(:the_new_volume) { double }
      let(:volume_options) { {:cloud_tenant => tenant, :name => "new_name", :size => 2} }

      before do
        allow(raw_volumes).to receive(:new).and_return(the_new_volume)
      end

      it 'creates a volume' do
        allow(the_new_volume).to receive("id").and_return('new_id')
        allow(the_new_volume).to receive("status").and_return('creating')
        expect(the_new_volume).to receive(:save).and_return(the_new_volume)

        volume = CloudVolume.create_volume(ems.id, volume_options)
        expect(volume.class).to        eq Hash
        expect(volume[:name]).to       eq 'new_name'
        expect(volume[:ems_ref]).to    eq 'new_id'
        expect(volume[:status]).to     eq 'creating'
      end

      it "raises an error when the ems is missing" do
        expect { CloudVolume.create_volume(nil) }.to raise_error(ArgumentError)
      end

      it "validates the volume create operation" do
        validation = CloudVolume.validate_create_volume(ems)
        expect(validation[:available]).to be true
      end

      it "validates the volume create operation when ems is missing" do
        validation = CloudVolume.validate_create_volume(nil)
        expect(validation[:available]).to be false
      end

      it 'catches errors from provider' do
        expect(the_new_volume).to receive(:save).and_raise('bad request')

        expect { CloudVolume.create_volume(ems.id, volume_options) }.to raise_error(MiqException::MiqVolumeCreateError)
      end
    end

    context "#update_volume" do
      it 'updates the volume' do
        expect(the_raw_volume).to receive(:save)
        #c2c-provider: added the line for to resolve the size with (no args) error in rspec
        expect(the_raw_volume).to receive(:size)
        cloud_volume.update_volume({})
      end

      it "validates the volume update operation" do
        validation = cloud_volume.validate_update_volume
        expect(validation[:available]).to be true
      end

      it "validates the volume update operation when ems is missing" do
        expect(cloud_volume).to receive(:ext_management_system).and_return(nil)
        validation = cloud_volume.validate_update_volume
        expect(validation[:available]).to be false
      end

      it 'catches errors from provider' do
        expect(the_raw_volume).to receive(:save).and_raise('bad request')
        expect { cloud_volume.update_volume({}) }.to raise_error(MiqException::MiqVolumeUpdateError)
      end
    end

    context "#delete_volume" do
      it "validates the volume delete operation when status is in-use" do
        expect(cloud_volume).to receive(:status).and_return("in-use")
        validation = cloud_volume.validate_delete_volume
        expect(validation[:available]).to be false
      end

      it "validates the volume delete operation when status is available" do
        expect(cloud_volume).to receive(:status).and_return("available")
        validation = cloud_volume.validate_delete_volume
        expect(validation[:available]).to be true
      end

      it "validates the volume delete operation when status is error" do
        expect(cloud_volume).to receive(:status).and_return("error")
        validation = cloud_volume.validate_delete_volume
        expect(validation[:available]).to be true
      end

      it "validates the volume delete operation when ems is missing" do
        expect(cloud_volume).to receive(:ext_management_system).and_return(nil)
        validation = cloud_volume.validate_delete_volume
        expect(validation[:available]).to be false
      end

      it 'updates the volume' do
        expect(the_raw_volume).to receive(:destroy)
        cloud_volume.delete_volume
      end

      it 'catches errors from provider' do
        expect(the_raw_volume).to receive(:destroy).and_raise('bad request')
        expect { cloud_volume.delete_volume }.to raise_error(MiqException::MiqVolumeDeleteError)
      end
    end
  end

  describe "instance linsting for attaching volumes" do
    let(:first_instance) { FactoryBot.create(:vm_telefonica, :ext_management_system => ems, :ems_ref => "instance_0", :cloud_tenant => tenant) }
    let(:second_instance) { FactoryBot.create(:vm_telefonica, :ext_management_system => ems, :ems_ref => "instance_1", :cloud_tenant => tenant) }
    let(:other_tenant) { FactoryBot.create(:cloud_tenant_telefonica, :ext_management_system => ems) }
    let(:other_instance) { FactoryBot.create(:vm_telefonica, :ext_management_system => ems, :ems_ref => "instance_2", :cloud_tenant => other_tenant) }

    it "supports attachment to only those instances that are in the same tenant" do
      expect(cloud_volume.available_vms).to contain_exactly(first_instance, second_instance)
    end

    it "should exclude instances that are already attached to the volume" do
      attached_instance = FactoryBot.create(:vm_telefonica, :ext_management_system => ems, :ems_ref => "attached_instance", :cloud_tenant => tenant)
      allow(cloud_volume).to receive(:vms).and_return([attached_instance])
      expect(cloud_volume.available_vms).to contain_exactly(first_instance, second_instance)
    end
  end
end
