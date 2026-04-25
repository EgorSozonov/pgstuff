create role personal_admin with login encrypted password 'asdf';
alter role personal_admin with createrole;

create database personal owner personal_admin;


