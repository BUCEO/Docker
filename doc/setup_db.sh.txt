#!/bin/bash
sql_slave_user='CREAR USUARIO "mydb_slave_user"@"%" IDENTIFICADO POR "mydb_slave_pwd"; CONCEDER ESCLAVO DE REPLICACIÓN EN *.* A "mydb_slave_user"@"%"; VACIAR PRIVILEGIOS;' 
docker exec database_master sh -c "mysql -u root -pS3cret -e '$sql_slave_user'"
MS_STATUS=`docker exec database_master sh -c 'mysql -u root -pS3cret -e "MOSTRAR ESTADO DEL MAESTRO"'` 
CURRENT_LOG=`echo $MS_STATUS | awk '{print $6}'` 
CURRENT_POS=`echo $MS_STATUS | awk '{print $7}'`
sql_set_master="CAMBIAR MAESTRO A HOST_MAESTRO='database_master', USUARIO_MAESTRO='mydb_slave_user', CONTRASEÑA_MAESTRO='mydb_slave_pwd', ARCHIVO_REGISTRO_MAESTRO='$REGISTRO_ACTUAL', POS_REGISTRO_MAESTRO=$POS_ACTUAL; INICIAR ESCLAVO;" 
start_slave_cmd='mysql -u root -pS3cret -e "' 
start_slave_cmd+="$sql_set_master" 
start_slave_cmd+='"' 
docker exec database_slave sh -c "$start_slave_cmd"
docker exec database_slave sh -c "mysql -u root -pS3cret -e 'MOSTRAR ESTADO DEL ESCLAVO \G'"