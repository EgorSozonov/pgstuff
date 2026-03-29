create database %dbname;
revoke create on schema public from public;
revoke usage on schema public from public;
alter default privileges in schema public revoke execute on routines from public;
revoke all on database %dbname from public;

create role admin with login encrypted password 'asdf';
create role ddl with login encrypted password 'asdf';
create role dml with login encrypted password 'asdf';
create role dev with login encrypted password 'asdf';
create schema dev owner dev;

alter schema public owner admin;
grant usage, create in schema public to ddl;
alter default privileges in schema public grant select, insert, update, delete on tables to dml;
