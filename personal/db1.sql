alter schema public owner to personal_admin;

revoke usage, create on schema public from public;
alter default privileges in schema public revoke execute on routines from public;
revoke all on database personal from public;

create role personal_ddl with login encrypted password 'asdf';
grant personal_ddl to personal_admin;
grant connect, create on database personal to personal_ddl;
create role personal_dml with login encrypted password 'asdf';
grant connect on database personal to personal_dml;

grant usage, create on schema public to personal_ddl;
grant usage on schema public to personal_dml;
alter default privileges for role personal_ddl in schema public 
   grant select, insert, update, delete on tables to personal_dml;


