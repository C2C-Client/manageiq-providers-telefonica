describe ManageIQ::Providers::Telefonica::CloudManager::Provision do
  let(:options)      { {:src_vm_id => [template.id, template.name]} }
  let(:provider)     { FactoryBot.create(:ems_telefonica_with_authentication) }
  let(:template)     { FactoryBot.create(:template_telefonica, :ext_management_system => provider) }
  let(:user)         { FactoryBot.create(:user) }
  let(:vm_telefonica) { FactoryBot.create(:vm_telefonica, :ext_management_system => provider, :ems_ref => "6b586084-6c37-11e4-b299-56847afe9799") }
  let(:vm_prov)      { FactoryBot.create(:miq_provision_telefonica, :userid => user.userid, :source => template, :request_type => 'template', :state => 'pending', :status => 'Ok', :options => options) }

  before { subject.source = template }

  context "#find_destination_in_vmdb" do
    it "VM in same sub-class" do
      expect(vm_telefonica).to eq(subject.find_destination_in_vmdb("6b586084-6c37-11e4-b299-56847afe9799"))
    end

    it "VM in different sub-class" do
      FactoryBot.create(:vm_amazon, :ext_management_system => provider, :ems_ref => "6b586084-6c37-11e4-b299-56847afe9799")

      expect(subject.find_destination_in_vmdb("6b586084-6c37-11e4-b299-56847afe9799")).to be_nil
    end
  end

  context "#validate_dest_name" do
    it "with valid name" do
      allow(subject).to receive(:dest_name).and_return("new_vm_1")

      expect { subject.validate_dest_name }.to_not raise_error
    end

    it "with a nil name" do
      allow(subject).to receive(:dest_name).and_return(nil)

      expect { subject.validate_dest_name }.to raise_error(MiqException::MiqProvisionError)
    end

    it "with a duplicate name" do
      allow(subject).to receive(:dest_name).and_return(vm_telefonica.name)

      expect { subject.validate_dest_name }.to raise_error(MiqException::MiqProvisionError)
    end
  end

  context "#prepare_for_clone_task" do
    let(:flavor)  { FactoryBot.create(:flavor_telefonica) }

    before { allow(subject).to receive_messages(:instance_type => flavor, :validate_dest_name => nil) }

    context "availability zone" do
      let(:az)      { FactoryBot.create(:availability_zone_telefonica,      :ems_ref => "64890ac2-6c34-11e4-b72d-56847afe9799") }
      let(:az_null) { FactoryBot.create(:availability_zone_telefonica_null, :ems_ref => "6fd878d6-6c34-11e4-b72d-56847afe9799") }

      it "with valid Availability Zone" do
        subject.options[:dest_availability_zone] = [az.id, az.name]

        expect(subject.prepare_for_clone_task[:availability_zone]).to eq("64890ac2-6c34-11e4-b72d-56847afe9799")
      end

      it "with Null Availability Zone" do
        subject.options[:dest_availability_zone] = [az_null.id, az_null.name]

        expect(subject.prepare_for_clone_task[:availability_zone]).not_to be_nil
      end
    end

    context "security_groups" do
      let(:security_group_1) { FactoryBot.create(:security_group_telefonica, :ems_ref => "340c315c-6c30-11e4-a103-56847afe9799") }
      let(:security_group_2) { FactoryBot.create(:security_group_telefonica, :ems_ref => "41a73064-6c30-11e4-a103-56847afe9799") }

      it "with no security groups" do
        expect(subject.prepare_for_clone_task[:security_groups]).to eq([])
      end

      it "with one security group" do
        subject.options[:security_groups] = [security_group_1.id]

        expect(subject.prepare_for_clone_task[:security_groups]).to eq([security_group_1.ems_ref])
      end

      it "with two security group" do
        subject.options[:security_groups] = [security_group_1.id, security_group_2.id]

        expect(subject.prepare_for_clone_task[:security_groups]).to eq([security_group_1.ems_ref, security_group_2.ems_ref])
      end

      it "with a missing security group" do
        subject.options[:security_groups] = [security_group_1.id, (security_group_1.id + 1)]

        expect(subject.prepare_for_clone_task[:security_groups]).to eq([security_group_1.ems_ref])
      end
    end
  end

  it "#workflow" do
    workflow_class = ManageIQ::Providers::Telefonica::CloudManager::ProvisionWorkflow
    allow_any_instance_of(workflow_class).to receive(:get_dialogs).and_return(:dialogs => {})

    expect(vm_prov.workflow.class).to eq workflow_class
    expect(vm_prov.workflow_class).to eq workflow_class
  end
end
