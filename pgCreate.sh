if (( "$#" < 2 )); then
   echo "Must enter database and port number."
   exit 1
fi 

db="$1"
port="$2"

#Create database
#######################

echo "Creating the database..."
psql -U postgres -p $port <<EOF
create role ${db}_admin with login encrypted password 'asdf';
alter role ${db}_admin with createrole;

create database ${db} owner ${db}_admin;
EOF


#Create the roles in it
#######################
echo "Creating the roles..."
psql -U ${db}_admin -p $port -d $db <<EOF
alter schema public owner to ${db}_admin;
create schema infra;
create schema dev;

revoke usage, create on schema public from public;
alter default privileges in schema public revoke execute on routines from public;
revoke all on database ${db} from public;

create role ${db}_ddl with login encrypted password 'asdf';
grant ${db}_ddl to ${db}_admin;
grant connect, create on database ${db} to ${db}_ddl;
create role ${db}_dml with login encrypted password 'asdf';
grant connect on database ${db} to ${db}_dml;
create role ${db}_dev with login encrypted password 'asdf';
grant connect on database ${db} to ${db}_dev;

grant usage, create on schema public to ${db}_ddl;
grant usage on schema public to ${db}_dml;
alter default privileges for role ${db}_ddl in schema public 
   grant select, insert, update, delete on tables to ${db}_dml;
grant usage on schema public to ${db}_dev;
alter default privileges for role ${db}_ddl in schema public 
   grant select on tables to ${db}_dev;

grant usage, create on schema infra to ${db}_ddl;
grant usage on schema infra to ${db}_dml;
alter default privileges for role ${db}_ddl in schema infra 
   grant select, insert, update, delete on tables to ${db}_dml;
grant usage on schema infra to ${db}_dev;
alter default privileges for role ${db}_ddl in schema infra 
   grant select on tables to ${db}_dev;

grant usage, create on schema dev to ${db}_dev;
EOF





