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

  describe '#get_updated_customer_domain' do
    context 'when customer domain is not nil' do
      # object of DNS class
      dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
      customer_domain = dns_obj.get_updated_customer_domain(node_attr['customer_domain'])
      it 'returns the customer domain with "." in it' do
        expect(customer_domain).to eq('.env.asm.org.oneops.com')
      end
    end
    context 'when customer domain is nil' do
      dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
      it 'throws an exception that the customer domain is required' do
        expect { dns_obj.get_updated_customer_domain(nil) }.to raise_exception(Exception)
      end
    end
  end

  describe '#remove_domain_name_from_customer_domain' do
    dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
    domain_name = node_attr['workorder']['services']['dns']['azure']['ciAttributes']['zone']
    customer_domain = dns_obj.remove_domain_name_from_customer_domain('.env.asm.org.oneops.com', domain_name)
    it 'removes the zone name from the customaer domain' do
      expect(customer_domain).to eq('.env.asm.org')
    end
    it 'does not remove the zone name from the customaer domain' do
      expect(customer_domain).to_not eq('.env.asm.org.oneops.com')
    end
  end

  describe '#check_cloud_dns_id' do
    dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)

    it 'does not raise exception if cloud dns id is not nil' do
      expect { dns_obj.check_cloud_dns_id(service_attrs, cloud_service) }.to_not raise_exception(Exception)
    end
    it 'throws exception when cloud_dns_id is empty' do
      service_attrs['cloud_dns_id'] = nil
      expect { dns_obj.check_cloud_dns_id(service_attrs, cloud_service) }.to raise_exception(Exception)
      service_attrs['cloud_dns_id'] = "asm.org"
    end
  end

  describe 'entrypoint_exit' do
    dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
    hostname_entry = dns_obj.entrypoint_exit(node_attr['workorder']['payLoad'])
    it 'expects the hostname entry to be false if payload has Entrypoint key' do
      expect(hostname_entry).to be_falsey
    end
  end

  describe '#get_aliases' do
    dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)

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
    dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
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
      dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
      it 'deletes current/active aliases from aliases' do
        expect(dns_obj.remove_current_aliases(node_attr['workorder']['rfcCi'], false)).to eq(["alias1"])
      end
    end
    context 'when aliases and current aliases are nil' do
      it 'checks aliases to be deleted when aliases are nil' do
        dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
        node_attr['workorder']['rfcCi']['ciBaseAttributes']['aliases'] = "[\"\"]"
        expect(dns_obj.remove_current_aliases(node_attr['workorder']['rfcCi'], false)).to eq([""])
        node_attr['workorder']['rfcCi']['ciBaseAttributes']['aliases'] = "[\"alias1\",\"alias2\"]"
      end

      it 'return aliases to be deleted when current aliases are nil' do
        dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
        node_attr['workorder']['rfcCi']['ciAttributes']['aliases'] = "[\"\"]"
        expect(dns_obj.remove_current_aliases(node_attr['workorder']['rfcCi'], false)).to eq(["alias1", "alias2"])
        node_attr['workorder']['rfcCi']['ciAttributes']['aliases'] = "[\"alias2\"]"
      end
    end
  end

  describe '#get_full_aliases' do
    it 'gives empty string when hostname entry is true' do
      dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
      full_aliases = dns_obj.get_full_aliases(node_attr['workorder']['rfcCi'], true)
      expect(full_aliases).to eq([])
    end
    it ' checks an array of full aliases with the provided one' do
      dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
      full_aliases = dns_obj.get_full_aliases(node_attr['workorder']['rfcCi'], false)
      expect(full_aliases).to eq(["full-alias1", "full-alias2"])
    end

    it ' rescue JSON Parse error' do
      dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
      node_attr['workorder']['rfcCi']['ciBaseAttributes']['full_aliases'] = "[\"\"\"]"
      expect { dns_obj.get_full_aliases(node_attr['workorder']['rfcCi'], false) }.to_not raise_error
      node_attr['workorder']['rfcCi']['ciBaseAttributes']['full_aliases'] = "[\"full-alias1\",\"full-alias2\"]"
    end
  end

  describe '#get_current_full_aliases' do
    dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
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
      it 'gives empty string when hostname entry is true' do
        current_full_aliases = dns_obj.get_current_full_aliases(node_attr['workorder']['rfcCi'], true)
        expect(current_full_aliases).to eq([])
      end
    end
  end

  describe '#remove_current_full_aliases' do
    context 'when full aliases and current full aliases are not nil' do
      dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
      it 'deletes current/active full aliases from full aliases array' do
        expect(dns_obj.remove_current_full_aliases(node_attr['workorder']['rfcCi'], false)).to eq(["full-alias1"])
      end
    end
    context 'when full aliases and current full aliases are nil' do
      dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
      it 'returns full aliases array when current full aliases are nil' do
        node_attr['workorder']['rfcCi']['ciAttributes']['full_aliases'] = "[\"\"]"
        expect(dns_obj.remove_current_full_aliases(node_attr['workorder']['rfcCi'], false)).to eq(["full-alias1", "full-alias2"])
        node_attr['workorder']['rfcCi']['ciAttributes']['full_aliases'] = "[\"full-alias2\"]"
      end
      dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
      it 'returns emty string when full aliases are nil' do
        node_attr['workorder']['rfcCi']['ciBaseAttributes']['full_aliases'] = "[\"\"]"
        expect(dns_obj.remove_current_full_aliases(node_attr['workorder']['rfcCi'], false)).to eq([""])
        node_attr['workorder']['rfcCi']['ciBaseAttributes']['full_aliases'] = "[\"full-alias1\",\"full-alias2\"]"
      end
    end
  end

  describe '#get_entries' do
    entries_response = ['contoso.com']
    entries_nil = nil

    context 'when aliases are not nil' do
      it 'returns entries on the basis of aliases with priority 0' do
        priority = node_attr['workorder']['cloud']['ciAttributes']['priority']
        dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
        allow(dns_obj.recordset).to receive(:get_existing_records_for_recordset) { entries_response }
        aliases = dns_obj.get_aliases(node_attr['workorder']['rfcCi'], false)
        entries = dns_obj.get_entries('.env.asm.org', priority, service_attrs['cloud_dns_id'], aliases)
        expect(entries).to eq([{ name: "alias1.env.asm.org", values: "contoso.com" }, { name: "alias2.env.asm.org", values: "contoso.com" }])
      end
      it 'returns entries on the basis of aliases with priority 1' do
        priority = node_attr['workorder']['cloud']['ciAttributes']['priority'] = "1"
        dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
        allow(dns_obj.recordset).to receive(:get_existing_records_for_recordset) { entries_response }
        aliases = dns_obj.get_aliases(node_attr['workorder']['rfcCi'], false)
        entries = dns_obj.get_entries('.env.asm.org', priority, service_attrs['cloud_dns_id'], aliases)
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
        dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
        allow(dns_obj.recordset).to receive(:get_existing_records_for_recordset) { entries_nil }
        aliases = dns_obj.get_aliases(node_attr['workorder']['rfcCi'], false)
        entries = dns_obj.get_entries('.env.asm.org', priority, service_attrs['cloud_dns_id'], aliases)
        expect(entries).to eq([])
      end

      it 'returns emty entries array when aliases are nil' do
        priority = node_attr['workorder']['cloud']['ciAttributes']['priority']
        dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
        node_attr['workorder']['rfcCi']['ciBaseAttributes']['aliases'] = "[\"\"]"
        aliases = dns_obj.get_aliases(node_attr['workorder']['rfcCi'], false)
        expect(dns_obj.get_entries('.env.asm.org', priority, service_attrs['cloud_dns_id'], aliases)).to eq([])
        node_attr['workorder']['rfcCi']['ciBaseAttributes']['aliases'] = "[\"alias1\",\"alias2\"]"
      end
    end
  end

  describe '#get_updated_entries' do
    context 'when full aliases are not nil' do
      entries_response = ['oneops.com']
      it 'returns entries on the basis of full aliases' do
        dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
        allow(dns_obj.recordset).to receive(:get_existing_records_for_recordset) { entries_response }
        aliases = dns_obj.get_aliases(node_attr['workorder']['rfcCi'], false)
        full_aliases = dns_obj.get_full_aliases(node_attr['workorder']['rfcCi'], false)
        priority = node_attr['workorder']['cloud']['ciAttributes']['priority']
        entries_for_get_entries_method = dns_obj.get_entries('.env.asm.org', priority, service_attrs['cloud_dns_id'], aliases)
        entries = dns_obj.get_updated_entries(entries_for_get_entries_method, full_aliases)
        expect(entries).to eq([{ name: "alias1.env.asm.org", values: "oneops.com" },
                               { name: "alias2.env.asm.org", values: "oneops.com" },
                               { name: "full-alias1", values: "oneops.com" },
                               { name: "full-alias2", values: "oneops.com" }])
      end
    end
    context 'when full aliases are nil' do
      it 'does not raise error when full aliases are nil' do
        dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
        node_attr['workorder']['rfcCi']['ciBaseAttributes']['full_aliases'] = "[]"
        aliases = dns_obj.get_aliases(node_attr['workorder']['rfcCi'], false)
        full_aliases = dns_obj.get_full_aliases(node_attr['workorder']['rfcCi'], false)
        priority = node_attr['workorder']['cloud']['ciAttributes']['priority']
        entries_for_get_entries_method = dns_obj.get_entries('.env.asm.org', priority, service_attrs['cloud_dns_id'], aliases)
        expect { dns_obj.get_updated_entries(entries_for_get_entries_method, full_aliases) }.to_not raise_error('Nil Check')
        node_attr['workorder']['rfcCi']['ciBaseAttributes']['full_aliases'] = "[\"full-alias1\",\"full-alias2\"]"
      end
    end
  end

  describe '#remove_record_set_from_azure' do
    it 'returns the entries to be removed from azure' do
      responsefromremoverecordset = ''
      entries_response = ['contoso.com']
      dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
      allow(dns_obj.recordset).to receive(:get_existing_records_for_recordset) { entries_response }
      allow(dns_obj.recordset).to receive(:remove_record_set) { responsefromremoverecordset }
      priority = "0"
      aliases = dns_obj.remove_current_aliases(node_attr['workorder']['rfcCi'], false)
      full_aliases = dns_obj.remove_current_full_aliases(node_attr['workorder']['rfcCi'], false)
      entries_for_get_entries_method = dns_obj.get_entries('.env.asm.org', priority, service_attrs['cloud_dns_id'], aliases)
      entries = dns_obj.get_updated_entries(entries_for_get_entries_method, full_aliases)
      result = dns_obj.remove_record_set_from_azure(entries)
      expect(result).to eq([{ name: "alias1.env.asm.org", values: "contoso.com" }, { name: "full-alias1", values: "contoso.com" }])
    end
    it 'gives empty string when entries are nil' do
      dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
      entries = []
      expect(dns_obj.remove_record_set_from_azure(entries)).to eq([])
    end
  end
end
