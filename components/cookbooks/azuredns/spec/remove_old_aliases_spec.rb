require 'spec_helper'
require 'json'
# **Rubocop Suppression**
# rubocop:disable LineLength
# rubocop:disable StringLiterals
# rubocop:disable WordArray
require File.expand_path('../../libraries/dns.rb', __FILE__)
require File.expand_path('../../libraries/record_set.rb', __FILE__)
describe AzureDns::DNS do
  file_path = File.expand_path('test_json_data.json', __dir__)
  file = File.open(file_path)
  contents = file.read
  node_attr = JSON.parse(contents)
  cloud_service = node_attr['workorder']['services']['dns']['azure']
  service_attrs = cloud_service['ciAttributes']
  token = node_attr['azure_rest_token']
  resource_group = node_attr['platform-resource-group']

  describe '#validate_customer_domain' do
    context 'when customer domain is not nil' do
      # object of DNS class
      dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)
      customer_domain = dns_obj.validate_customer_domain(node_attr['customer_domain'])
      it 'returns the customer domain with "." in it' do
        expect(customer_domain).to eq('.env.asm.org.oneops.com')
      end
    end
    context 'when customer domain is nil' do
      dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)
      it 'throws an exception that the customer domain is required' do
        expect { dns_obj.validate_customer_domain(nil) }.to raise_exception(Exception)
      end
    end
  end

  describe '#remove_zone_name' do
    dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)
    domain_name = node_attr['workorder']['services']['dns']['azure']['ciAttributes']['zone']
    customer_domain = dns_obj.remove_zone_name('.env.asm.org.oneops.com', domain_name)
    it 'removes the zone name from the customaer domain' do
      expect(customer_domain).to eq('.env.asm.org')
    end
    it 'does not remove the zone name from the customaer domain' do
      expect(customer_domain).to_not eq('.env.asm.org.oneops.com')
    end
  end

  # For now skip unit test for this method
  describe '#checking_platform' do
    dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)
    box = node_attr['workorder']['box']['ciAttributes']
    it 'skip remove old aliases when platform is_active is false' do
      expect(dns_obj.checking_platform(box)).to be_falsey
    end
  end

  describe '#checking_cloud_dns_id' do
    dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)

    it 'checks Cloud dns is not nil' do
      expect(dns_obj.checking_cloud_dns_id(service_attrs, cloud_service)).to_not be_nil
    end
    it 'throws exception when cloud_dns_id is empty' do
      service_attrs['cloud_dns_id'] = nil
      expect { dns_obj.checking_cloud_dns_id(service_attrs, cloud_service) }.to raise_exception(Exception)
      service_attrs['cloud_dns_id'] = "asm.org"
    end
  end

  describe '#checking_hostname_entry' do
    dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)
    hostname_entry = dns_obj.checking_hostname_entry(node_attr['workorder']['payLoad'])
    it 'expects the hostname entry to be false if payload has Entrypoint key' do
      expect(hostname_entry).to be_falsey
    end
  end

  describe '#get_aliases' do
    dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)

    context 'when hostname entry is false' do
      it ' rescue JSON Parse error' do
        node_attr['workorder']['rfcCi']['ciBaseAttributes']['aliases'] = "[\"\"\"]"
        expect { dns_obj.get_aliases(node_attr['workorder']['rfcCi'], false) }.to_not raise_error
        node_attr['workorder']['rfcCi']['ciBaseAttributes']['aliases'] = "[\"alias1\",\"alias2\"]"
      end
    end
    it 'gives nil when hostname entry is true' do
      aliases = dns_obj.get_aliases(node_attr['workorder']['rfcCi'], true)
      expect(aliases).to eq([])
    end
    it ' checks an array of aliases with the provided one' do
      aliases = dns_obj.get_aliases(node_attr['workorder']['rfcCi'], false)
      expect(aliases).to eq(["alias1", "alias2"])
    end
  end

  describe '#get_current_aliases' do
    dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)
    context 'when hostname entry is false' do
      it ' checks a current array of aliases with the provided one' do
        current_aliases = dns_obj.get_current_aliases(node_attr['workorder']['rfcCi'], false)
        expect(current_aliases).to eq(["alias2"])
      end

      it ' rescue JSON Parse error' do
        node_attr['workorder']['rfcCi']['ciAttributes']['aliases'] = "[\"\"\"]"
        expect { dns_obj.get_current_aliases(node_attr['workorder']['rfcCi'], false) }.to_not raise_error
        node_attr['workorder']['rfcCi']['ciAttributes']['aliases'] = "[\"alias2\"]"
      end
    end
  end

  describe '#remove_current_aliases' do
    context 'when aliases and current aliases are not nil' do
      dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)
      it 'deletes current/active aliases from aliases' do
        dns_obj.get_aliases(node_attr['workorder']['rfcCi'], false)
        dns_obj.get_current_aliases(node_attr['workorder']['rfcCi'], false)
        expect(dns_obj.remove_current_aliases).to eq(["alias2"])
      end
    end
    context 'when aliases and current aliases are nil' do
      it 'checks aliases to be deleted when aliases are nil' do
        dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)
        node_attr['workorder']['rfcCi']['ciBaseAttributes']['aliases'] = "[\"\"]"
        dns_obj.get_aliases(node_attr['workorder']['rfcCi'], false)
        expect(dns_obj.remove_current_aliases).to eq([])
        node_attr['workorder']['rfcCi']['ciBaseAttributes']['aliases'] = "[\"alias1\",\"alias2\"]"
      end

      it 'checks aliases to be deleted when current aliases are nil' do
        dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)
        node_attr['workorder']['rfcCi']['ciAttributes']['aliases'] = "[\"\"]"
        dns_obj.get_current_aliases(node_attr['workorder']['rfcCi'], false)
        expect(dns_obj.remove_current_aliases).to eq([""])
        node_attr['workorder']['rfcCi']['ciAttributes']['aliases'] = "[\"alias2\"]"
      end
    end
  end

  describe '#get_full_aliases' do
    dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)

    it ' checks an array of full aliases with the provided one' do
      full_aliases = dns_obj.get_full_aliases(node_attr['workorder']['rfcCi'], false)
      expect(full_aliases).to eq(["full-alias1", "full-alias2"])
    end
    it 'gives nil when hostname entry is true' do
      full_aliases = dns_obj.get_full_aliases(node_attr['workorder']['rfcCi'], true)
      expect(full_aliases).to be_nil
    end
    it ' rescue JSON Parse error' do
      node_attr['workorder']['rfcCi']['ciBaseAttributes']['full_aliases'] = "[\"\"\"]"
      expect { dns_obj.get_full_aliases(node_attr['workorder']['rfcCi'], false) }.to_not raise_error
      node_attr['workorder']['rfcCi']['ciBaseAttributes']['full_aliases'] = "[\"full-alias1\",\"full-alias2\"]"
    end
  end

  describe '#get_current_full_aliases' do
    dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)
    context 'when hostname entry is false' do
      it ' checks an current array of full aliases with the provided one' do
        current_full_aliases = dns_obj.get_current_full_aliases(node_attr['workorder']['rfcCi'], false)
        expect(current_full_aliases).to eq(["full-alias2"])
      end
      it ' rescue JSON Parse error' do
        node_attr['workorder']['rfcCi']['ciAttributes']['full_aliases'] = "[\"\"\"]"
        expect { dns_obj.get_current_full_aliases(node_attr['workorder']['rfcCi'], false) }.to_not raise_error
        node_attr['workorder']['rfcCi']['ciAttributes']['full_aliases'] = "[\"full-alias2\"]"
      end
    end
    context 'when hostname entry is true' do
      it 'gives nil when hostname entry is true' do
        current_full_aliases = dns_obj.get_current_full_aliases(node_attr['workorder']['rfcCi'], true)
        expect(current_full_aliases).to be_nil
      end
    end
  end

  describe '#remove_current_full_aliases' do
    context 'when full aliases and current full aliases are not nil' do
      dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)
      it 'deletes current/active full aliases from full aliases array' do
        dns_obj.get_full_aliases(node_attr['workorder']['rfcCi'], false)
        dns_obj.get_current_full_aliases(node_attr['workorder']['rfcCi'], false)
        expect(dns_obj.remove_current_full_aliases).to eq(["full-alias2"])
      end
    end
    context 'when full aliases and current full aliases are nil' do
      dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)
      it 'throws an exception when current full aliases are nil' do
        node_attr['workorder']['rfcCi']['ciAttributes']['full_aliases'] = "[\"\"]"
        dns_obj.get_current_full_aliases(node_attr['workorder']['rfcCi'], false)
        expect(dns_obj.remove_current_full_aliases).to eq([""])
        node_attr['workorder']['rfcCi']['ciAttributes']['full_aliases'] = "[\"full-alias2\"]"
      end
      dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)
      it 'throws an exception when full aliases are nil' do
        node_attr['workorder']['rfcCi']['ciBaseAttributes']['full_aliases'] = "[\"\"]"
        dns_obj.get_full_aliases(node_attr['workorder']['rfcCi'], true)
        expect(dns_obj.remove_current_full_aliases).to eq([""])
        node_attr['workorder']['rfcCi']['ciBaseAttributes']['full_aliases'] = "[\"full-alias1\",\"full-alias2\"]"
      end
    end
  end

  describe '#set_alias_entries_to_be_deleted' do
    entries_response = ['contoso.com']
    entries_nil = nil

    context 'when aliases are not nil' do
      it 'sets deletable entries on the basis of aliases with priority 0' do
        priority = node_attr['workorder']['cloud']['ciAttributes']['priority']
        dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)
        allow(dns_obj.recordset).to receive(:get_existing_records_for_recordset) { entries_response }
        dns_obj.get_aliases(node_attr['workorder']['rfcCi'], false)
        entries = dns_obj.set_alias_entries_to_be_deleted('.env.asm.org', priority, service_attrs['cloud_dns_id'])
        expect(entries).to eq([{ name: "alias1.env.asm.org", values: "contoso.com" }, { name: "alias2.env.asm.org", values: "contoso.com" }])
      end
      it 'sets deletable entries on the basis of aliases with priority 1' do
        priority = node_attr['workorder']['cloud']['ciAttributes']['priority'] = "1"
        dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)
        allow(dns_obj.recordset).to receive(:get_existing_records_for_recordset) { entries_response }
        dns_obj.get_aliases(node_attr['workorder']['rfcCi'], false)
        entries = dns_obj.set_alias_entries_to_be_deleted('.env.asm.org', priority, service_attrs['cloud_dns_id'])
        expect(entries).to eq([{ name: "alias1.env.asm.org", values: "contoso.com" },
                               { name: "alias1.env", values: "contoso.com" },
                               { name: "alias2.env.asm.org", values: "contoso.com" },
                               { name: "alias2.env", values: "contoso.com" }])
        node_attr['workorder']['cloud']['ciAttributes']['priority'] = "0"
      end
    end
    context 'when aliases and value is nil' do
      it 'returns emty entries array when value is nil' do
        priority = node_attr['workorder']['cloud']['ciAttributes']['priority']
        dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)
        allow(dns_obj.recordset).to receive(:get_existing_records_for_recordset) { entries_nil }
        dns_obj.get_aliases(node_attr['workorder']['rfcCi'], false)
        entries = dns_obj.set_alias_entries_to_be_deleted('.env.asm.org', priority, service_attrs['cloud_dns_id'])
        expect(entries).to eq([])
      end

      it 'returns emty entries array when aliases are nil' do
        priority = node_attr['workorder']['cloud']['ciAttributes']['priority']
        dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)
        node_attr['workorder']['rfcCi']['ciBaseAttributes']['aliases'] = "[\"\"]"
        dns_obj.get_aliases(node_attr['workorder']['rfcCi'], false)
        expect(dns_obj.set_alias_entries_to_be_deleted('.env.asm.org', priority, service_attrs['cloud_dns_id'])).to eq([])
        node_attr['workorder']['rfcCi']['ciBaseAttributes']['aliases'] = "[\"alias1\",\"alias2\"]"
      end
    end
  end

  describe '#set_full_alias_entries_to_be_deleted' do
    context 'when full aliases are not nil' do
      entries_response = ['oneops.com']
      it 'sets deletable entries on the basis of full aliases' do
        dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)
        allow(dns_obj.recordset).to receive(:get_existing_records_for_recordset) { entries_response }

        dns_obj.get_full_aliases(node_attr['workorder']['rfcCi'], false)
        entries = dns_obj.set_full_alias_entries_to_be_deleted
        expect(entries).to eq([{ name: "full-alias1", values: "oneops.com" }, { name: "full-alias2", values: "oneops.com" }])
      end
    end
    context 'when full aliases are nil' do
      it 'throws an exception when full aliases are nil' do
        dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)
        node_attr['workorder']['rfcCi']['ciBaseAttributes']['full_aliases'] = "[]"
        dns_obj.get_full_aliases(node_attr['workorder']['rfcCi'], false)
        expect(dns_obj.set_full_alias_entries_to_be_deleted).to eq([])
        node_attr['workorder']['rfcCi']['ciBaseAttributes']['full_aliases'] = "[\"full-alias1\",\"full-alias2\"]"
      end
    end
  end

  describe '#remove_current_aliases_and_current_full_aliases' do
    it 'calls the functions and return result' do
      responsefromremoverecordset = ''
      entries_response = ['contoso.com']
      dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)
      allow(dns_obj.recordset).to receive(:get_existing_records_for_recordset) { entries_response }
      allow(dns_obj.recordset).to receive(:remove_record_set) { responsefromremoverecordset }
      dns_obj.remove_current_aliases_and_current_full_aliases(node_attr['workorder']['rfcCi'], false)
      priority = node_attr['workorder']['cloud']['ciAttributes']['priority']
      entries_result = dns_obj.remove_old_aliases('.env.asm.org', priority, service_attrs['cloud_dns_id'])
      expect(entries_result).to eq([{ name: "alias1.env.asm.org", values: "contoso.com" }, { name: "full-alias1", values: "contoso.com" }])
    end
  end

  describe '#remove_record_set_from_azure' do
    it 'returns the entries to be removed from azure' do
      responsefromremoverecordset = ''
      entries_response = ['contoso.com']
      dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)
      allow(dns_obj.recordset).to receive(:get_existing_records_for_recordset) { entries_response }
      allow(dns_obj.recordset).to receive(:remove_record_set) { responsefromremoverecordset }
      dns_obj.remove_current_aliases_and_current_full_aliases(node_attr['workorder']['rfcCi'], false)
      priority = node_attr['workorder']['cloud']['ciAttributes']['priority']
      dns_obj.set_alias_entries_to_be_deleted('.env.asm.org', priority, service_attrs['cloud_dns_id'])
      dns_obj.set_full_alias_entries_to_be_deleted
      entries_result = dns_obj.remove_record_set_from_azure
      expect(entries_result).to eq([{ name: "alias1.env.asm.org", values: "contoso.com" }, { name: "full-alias1", values: "contoso.com" }])
    end
    it 'gives empty string when entries are nil' do
      dns_obj = AzureDns::DNS.new(service_attrs, token, resource_group)
      dns_obj.entries = []
      expect(dns_obj.remove_record_set_from_azure).to eq([])
    end
  end
end
