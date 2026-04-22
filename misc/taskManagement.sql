create table task(
   task_id uuid primary key, name text, progression integer not null, status integer not null,
   size smallint not null, readiness smallint not null default 0, deadline timestamptz
);
create index ix_task_status on task(status);
comment on table task is 'The main task table';

create table task_link(src uuid not null, tgt uuid not null, kind smallint);
create unique index uq_task_link on task_link(src, tgt);
create index ix_task_link_tgt on task_link(tgt);
comment on table task_link is 'Links between tasks (subtasks, dependencies etc)';

create table status(status_id integer primary key, progression integer not null, name text not null);
create index ix_status_progression on status(progression);
comment on table status is 'Task statuses';

create table transition(
   src integer not null, tgt integer not null,
   primary key(src, tgt)
);
comment on table transition is 'Allowed status transitions. 1 is the common end status';

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
drop table if exists status;
drop table if exists transition;
drop table if exists task_comment;
drop table if exists worker;
drop table if exists worker_job;
drop table if exists worker_task;


-- populate
insert into status(status_id, progression, name) values (0, 0, 'New'), (1, 0, 'Done');
-- Progression 1 = basic code task progression
insert into status(status_id, progression, name) values 
   (2, 1, 'Need info'),
   (3, 1, 'In progress'),
   (4, 1, 'Code review'),
   (5, 1, 'Deployment'); 
insert into transition(src, tgt) values 
   (2, 3), (3, 4), (4, 5), (5, 1), 
   (2, 0), (3, 0), (4, 0), (5, 0);


-- typical queries
select status.name, tgt.name 
from status 
join transition t on t.src = status.status_id 
join status tgt on tgt.status_id = t.tgt 
where status.status_id = 4;
