create table if not exists 
hamster(id uuid primary key, name text not null, current_status_e smallint not null);

create or replace view infra.hamster as
select id, name from hamster;

