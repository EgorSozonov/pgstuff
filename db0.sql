create role %dbname_admin with login encrypted password 'asdf';
alter role %dbname_admin with createrole;

create database %dbname owner %dbname_admin;


