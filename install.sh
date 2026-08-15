
if (( "$#" == 0 )); then
   echo "Must enter port number greater than 1000"
   exit 1
fi 

port="$1"
dataDir="/home/pg/data"
logDir="/var/log/pg"
runDir="/run/postgresql"

#Add current user to group "postgres"
if [[ $(id -nG | grep -qw postgres) ]]; then
   echo "Adding current user to group 'postgres'"
   echo ""
   doas usermod -aG $(id -nu) postgres
fi

#Install (package names may differ)
doas pacman -Syu --needed postgresql postgresql-client
doas mkdir -p "$dataDir"
doas chown postgres:postgres /home/pg "$dataDir"
doas chmod 750 /home/pg "$dataDir"

doas mkdir -p "$logDir"
doas chown postgres:postgres "$logDir"
doas chmod 755 "$logDir"


if [[ -f "$dataDir/PG_VERSION" ]]; then
   echo "Cluster is initialized."
else 
   echo "Initializing cluster at $dataDir"
   doas -u postgres initdb -D "$dataDir" --locale-provider builtin -E UTF-8 --locale=C.UTF-8
fi

#Prepare to run & run

doas mkdir -p "$runDir"
doas chown postgres:postgres "$runDir"
doas chmod 2775 "$runDir"
doas chown postgres "$runDir"
doas -u postgres \
   /usr/bin/pg_ctl -l "$logDir/log" -D "$dataDir" -o "-p $port" start
