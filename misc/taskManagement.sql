create table task(
   task_id uuid primary key, 
   name text not null, 
   queue integer not null, 
   status_id integer not null,
   weight smallint not null, 
   readiness smallint not null default 0, 
   deadline timestamptz
);
create index ix_task_status on task(status_id);
comment on table task is 'The main task table';
comment on table task.readiness is 'Number from 0 to 100';

create table task_link(src uuid not null, tgt uuid not null, kind smallint);
create unique index uq_task_link on task_link(src, tgt);
create index ix_task_link_tgt on task_link(tgt);
comment on table task_link is 'Links between tasks (subtasks, dependencies etc)';

create table task_queue(
   task_queue_id integer primary key, name text not null, initial_status_id integer not null
);
comment on table task_queue is 'Task queues with starting statuses';

create table status(
   status_id integer primary key, task_queue_id integer not null, name text not null
);
create index ix_status_queue on status(task_queue_id);
comment on table status is 'Task statuses';

create table transition(
   src integer not null, tgt integer not null,
   primary key(src, tgt)
);
comment on table transition is 'Allowed status transitions. 1 is the common end status';

create table main_transition(src integer primary key, tgt integer not null);
comment on table main_transition is 'Main progress paths through the statuses';

create table task_comment(
   comment_id uuid primary key, task_id uuid not null, author uuid not null, content text not null, 
   is_deleted boolean not null default false
);
create index ix_comment_task on task_comment(task_id);
comment on table task_comment is 'Comment on a task';

create table task_stats(
   task_id uuid primary key, 
   sub_readiness smallint not null, 
   blocked_by uuid, 
   is_blocking boolean not null default false
);
comment on table task_stats is 'Calculated statistics for a task';

create table worker(worker_id uuid primary key, name text not null);

create table worker_job(
   worker_job_id uuid primary key, worker_id uuid not null, start timestamptz not null, "end" timestamptz
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


-- rollback
drop table if exists task;
drop table if exists task_link;
drop table if exists task_stats;
drop table if exists task_queue;
drop table if exists status;
drop table if exists transition;
drop table if exists main_transition;
drop table if exists task_comment;
drop table if exists worker;
drop table if exists worker_job;
drop table if exists worker_task;


-- populate
insert into status(status_id, progression, name) values (0, 0, 'Done'), (1, 1, 'New');
insert into task_queue(task_queue_id, name, initial_status) values(1, 'A', 1);
-- Progression 1 = basic code task progression
insert into status(status_id, queue_id, name) values 
   (1, 1, 'Need info'),
   (3, 1, 'In progress'),
   (4, 1, 'Code review'),
   (5, 1, 'Deployment'); 
insert into transition(src, tgt) values 
   (0, 1), (2, 3), (3, 4), (4, 5), (5, 1), 
   (2, 0), (3, 0), (4, 0), (5, 0);
insert into main_transition(src, tgt) values 
   (1, 3), (3, 4), (4, 5), (5, 0); 
   
   


-- typical queries
select status.name, tgt.name 
from status 
join transition t on t.src = status.status_id 
join status tgt on tgt.status_id = t.tgt 
where status.status_id = 4;


select status.name, tgt.name 
from status 
join main_transition t on t.src = status.status_id 
join status tgt on tgt.status_id = t.tgt 
where status.status_id = 4;


-- validations?
-- all main transitions are allowed
-- all queue init statuses are > 0 - domain?
-- domain for Centigrade (readiness)
