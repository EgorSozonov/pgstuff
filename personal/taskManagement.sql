-- prereq
create domain Centigrade smallint check (value >= 0 and value < 101);
comment on domain Centigrade is 'An integer from 0 to 100 inclusive';
create type task_link_e as enum(
   'subtask',
   'dependsOn',
   'mentions'
);
create or replace function update_updated_at_trigger()
returns trigger as $$
begin
   new.updated_at = now();
   return new;
end;
$$ language 'plpgsql';

-- table definitions
create table task(
   -- immutable:
   task_id uuid primary key, 
   name text not null, 
   queue_id integer not null,
   -- mutable:
   status_id integer not null,
   weight smallint not null, 
   readiness Centigrade not null default 0, 
   deadline timestamptz,
   updated_at timestamptz not null default current_timestamp
);
create index ix_task_status on task(status_id);
create trigger tr_task_updated_at before update on task
for each row execute function update_updated_at_trigger();
comment on table task is 'The main task table';

create table task_link(
   src uuid not null, tgt uuid not null, kind task_link_e,
   primary key(src, tgt)
);
create index ix_task_link_tgt on task_link(tgt);
comment on table task_link is 'Links between tasks (subtasks, dependencies etc)';

create table task_queue(
   task_queue_id integer primary key, name text not null, initial_status_id integer not null
);
comment on table task_queue is 'Task queues with starting statuses';

create table status(status_id integer primary key, name text not null);
comment on table status is 'Task statuses';

create table transition(src integer primary key, tgt integer not null);
comment on table transition is 'Main progressing status transitions. 0 is the global end status';

create table alt_transition(
   src integer not null, tgt integer not null,
   primary key(src, tgt)
);
comment on table alt_transition is 'Additional, sideways status transitions';

create table task_comment(
   comment_id uuid primary key, task_id uuid not null, author uuid not null, content text not null, 
   is_deleted boolean not null default false
);
create index ix_comment_task on task_comment(task_id);
comment on table task_comment is 'Comment on a task';

create table task_stats(
   task_id uuid primary key, 
   sub_readiness Centigrade not null, 
   blocked_by uuid, 
   is_blocking boolean not null default false
);
comment on table task_stats is 'Calculated statistics for a task';

create table worker(worker_id uuid primary key, name text not null);
comment on table worker is 'Employee or other person doing tasks';

create table worker_job(
   worker_job_id uuid primary key, 
   worker_id uuid not null, 
   start timestamptz not null, 
   "end" timestamptz
);
create index ix_worker_job on worker_job(worker_id);
comment on table worker_job is 'Worker hiring history';

create table worker_task(
   worker_task_id uuid primary key, 
   worker_id uuid not null, 
   task_id uuid not null, 
   start timestamptz not null, 
   "end" timestamptz
);
create index ix_worker_task_worker on worker_task(worker_id);
create index ix_worker_task_task on worker_task(task_id);
comment on table worker_task is 'An interval where a worker was assigned to a task';


-- DDL rollback
drop table if exists task;
drop table if exists task_link;
drop table if exists task_stats;
drop table if exists task_queue;
drop table if exists status;
drop table if exists transition;
drop table if exists alt_transition;
drop table if exists task_comment;
drop table if exists worker;
drop table if exists worker_job;
drop table if exists worker_task;


-- populate
insert into task values(uuidv7(), 'asdf', 1, 2, 3, 78, null);
insert into status(status_id, name) values (0, 'Done');
-- Status progression for basic tasks
insert into status(status_id, name) values 
   (1, 'New'),
   (2, 'In progress'),
   (3, 'Awaiting'),
   (4, 'Paused');
insert into task_queue(task_queue_id, name, initial_status) values(1, 'A', 1);
insert into transition(src, tgt) values 
   (1, 2), (2, 0), (3, 2), (4, 2); 
insert into alt_transition(src, tgt) values 
   (1, 3), (2, 3), (2, 4);
-- Status progression for programming 
insert into status(status_id, name) values 
   (5, 'New'),
   (6, 'In progress'),
   (7, 'Need info'),
   (8, 'Paused'),
   (9, 'Code review'),
   (10, 'Deployment'); 
insert into task_queue(task_queue_id, name, initial_status) values(2, 'Programming', 5);
insert into transition(src, tgt) values 
   (5, 6), (6, 9), (9, 10), (7, 6), (8, 6); 
insert into alt_transition(src, tgt) values 
   (5, 7), (6, 7), (6, 8);
   
   
-- API functions
create or replace function new_task(
   name_arg text not null, queue_name text not null, weight integer not null, deadline timestamptz
)
RETURNS void 
AS $new_task$
declare
   tehQueue task_queue%ROWTYPE;
BEGIN
   select * into strict tehQueue from task_queue where (name) = (queue_name);
   insert into task(
      task_id, 
      name, 
      queue_id,
      status_id,
      weight, 
      deadline
   ) values (
      uuidv7(), 
      name_arg, 
      queue.task_queue_id,
      queue.initial_status_id,
      weight, 
      deadline,
   );
END; $new_task$ LANGUAGE plpgsql;


create or replace function new_subtask(
   parent_id uuid not null, name_arg text not null, queue_name text not null, 
   weight integer not null, deadline timestamptz
)
RETURNS void 
AS $new_task$
declare
   parent task%ROWTYPE;
   queue task_queue%ROWTYPE;
   new_id uuid;
BEGIN
   new_id := uuidv7();
   select * into strict parent from task where (task_id) = (parent_id);
   select * into strict queue from task_queue where (task_queue_id) = (parent.queue_id);
   
   insert into task(
      task_id, 
      name, 
      queue_id,
      status_id,
      weight, 
      deadline
   ) values (
      uuidv7(), 
      name_arg, 
      parent.queue_id,
      queue.initial_status_id,
      weight, 
      deadline
   );
   insert into task_link(parent.task_id, new_id, 'subtask');
END; $new_task$ LANGUAGE plpgsql;
   

   
   
-- typical queries
select status_id, stat.*
from task t 
join transition tr on tr.src = t.status_id 
join status stat on stat.status_id = tr.tgt 
where status_id != 0;


-- validations?
-- validation that every status (except 0) has a main progress path
select * 
from status s
left join transition tr on tr.src = s.status_id
where s.status_id != 0 and tr.src is null;

