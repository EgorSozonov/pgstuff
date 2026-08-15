if (( "$#" < 2 )); then
   echo "Must enter database and port number to delete"
   exit 1
fi 

db="$1"
port="$2"


psql -U postgres -p $port \
   "drop database $db; drop role ${db}_dml; drop role ${db}_ddl; \
   drop role ${db}_dev; drop role ${db}_admin;"
