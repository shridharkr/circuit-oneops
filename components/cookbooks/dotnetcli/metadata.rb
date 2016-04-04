name             'dotnetcli'
description      'Installs/Configures .NET CLI'
version          '0.1.0'
maintainer       'OneOps'
maintainer_email 'support@oneops.com'
license          '.NET CLI'


grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]
attribute 'example_file_name',
  :description => 'Dotnet Installation Folder',
  :default => 'usr/share/dotnet',
  :format => {
    :help => 'Default name of the file to create',
    :category => '1.Global',
    :order => 1
  }


  #Please correct the following errors:
  ### Error updating database. Cause: org.postgresql.util.PSQLException: ERROR: insert or update on table "dj_rfc_ci_attributes" violates foreign key constraint "dj_rfc_ci_attributes_atrid_fk" Detail: Key (attribute_id)=(19813) is not present in table "md_class_attributes". Where: SQL statement "INSERT INTO dj_rfc_ci_attributes( rfc_attr_id, rfc_id, attribute_id, old_attribute_value, new_attribute_value, owner, comments) VALUES (nextval('dj_pk_seq'), p_rfc_id, p_attribute_id, l_old_attr_value, p_new_attr_value, p_owner, p_comments) returning rfc_attr_id" PL/pgSQL function "dj_upsert_rfc_ci_attr" line 22 at SQL statement ### The error may involve com.oneops.cms.dj.dal.DJMapper.upsertRfcCIAttribute-Inline ### The error occurred while setting parameters ### SQL: {call dj_upsert_rfc_ci_attr(? ,?, ?, ?, ?, ?)} ### Cause: org.postgresql.util.PSQLException: ERROR: insert or update on table "dj_rfc_ci_attributes" violates foreign key constraint "dj_rfc_ci_attributes_atrid_fk" Detail: Key (attribute_id)=(19813) is not present in table "md_class_attributes". Where: SQL statement "INSERT INTO dj_rfc_ci_attributes( rfc_attr_id, rfc_id, attribute_id, old_attribute_value, new_attribute_value, owner, comments) VALUES (nextval('dj_pk_seq'), p_rfc_id, p_attribute_id, l_old_attr_value, p_new_attr_value, p_owner, p_comments) returning rfc_attr_id" PL/pgSQL function "dj_upsert_rfc_ci_attr" line 22 at SQL statement ; SQL []; ERROR: insert or update on table "dj_rfc_ci_attributes" violates foreign key constraint "dj_rfc_ci_attributes_atrid_fk" Detail: Key (attribute_id)=(19813) is not present in table "md_class_attributes". Where: SQL statement "INSERT INTO dj_rfc_ci_attributes( rfc_attr_id, rfc_id, attribute_id, old_attribute_value, new_attribute_value, owner, comments) VALUES (nextval('dj_pk_seq'), p_rfc_id, p_attribute_id, l_old_attr_value, p_new_attr_value, p_owner, p_comments) returning rfc_attr_id" PL/pgSQL function "dj_upsert_rfc_ci_attr" line 22 at SQL statement; nested exception is org.postgresql.util.PSQLException: ERROR: insert or update on table "dj_rfc_ci_attributes" violates foreign key constraint "dj_rfc_ci_attributes_atrid_fk" Detail: Key (attribute_id)=(19813) is not present in table "md_class_attributes". Where: SQL statement "INSERT INTO dj_rfc_ci_attributes( rfc_attr_id, rfc_id, attribute_id, old_attribute_value, new_attribute_value, owner, comments) VALUES (nextval('dj_pk_seq'), p_rfc_id, p_attribute_id, l_old_attr_value, p_new_attr_value, p_owner, p_comments) returning rfc_attr_id" PL/pgSQL function "dj_upsert_rfc_ci_attr" line 22 at SQL statement
