alter schema public owner to %dbname_admin;
create schema infra;
create schema dev;

revoke usage, create on schema public from public;
alter default privileges in schema public revoke execute on routines from public;
revoke all on database %dbname from public;

create role %dbname_ddl with login encrypted password 'asdf';
grant %dbname_ddl to %dbname_admin;
grant connect, create on database %dbname to %dbname_ddl;
create role %dbname_dml with login encrypted password 'asdf';
grant connect on database %dbname to %dbname_dml;
create role %dbname_dev with login encrypted password 'asdf';
grant connect on database %dbname to %dbname_dev;

grant usage, create on schema public to %dbname_ddl;
grant usage on schema public to %dbname_dml;
alter default privileges for role %dbname_ddl in schema public 
   grant select, insert, update, delete on tables to %dbname_dml;
grant usage on schema public to %dbname_dev;
alter default privileges for role %dbname_ddl in schema public 
   grant select on tables to %dbname_dev;

grant usage, create on schema infra to %dbname_ddl;
grant usage on schema infra to %dbname_dml;
alter default privileges for role %dbname_ddl in schema infra 
   grant select, insert, update, delete on tables to %dbname_dml;
grant usage on schema infra to %dbname_dev;
alter default privileges for role %dbname_ddl in schema infra 
   grant select on tables to %dbname_dev;

grant usage, create on schema dev to %dbname_dev;

