#!/usr/bin/env bash
DOCUMENT_ROOT="/var/www/html"
SCRIPT_DIR=$DOCUMENT_ROOT"/local"
USER=$(php $SCRIPT_DIR/sql4git.php login)
PASSWORD=$(php $SCRIPT_DIR/sql4git.php password)
HOST=$(php $SCRIPT_DIR/sql4git.php host)
BASE=$(php $SCRIPT_DIR/sql4git.php database)
#echo $USER
#echo $PASSWORD
#echo $HOST
#echo $BASE


if [ -n "$BASE" ] && [ -n "$USER" ]  && [ -n "$HOST" ]  
then
 DIR=$DOCUMENT_ROOT"/bitrix/backup/backup_db/$BASE/"
 #echo $DIR

 mkdir -p $DIR
 # deleting old backups
 cd $DIR
 rm -rf *
 
 mkdir -p "2compare"
 # deleting old backups
 cd "2compare"
 rm -rf *
 # dumping db
 # dumping db

 if  [ -n "$PASSWORD" ]
 then 
  db=`mysql -u $USER -p$PASSWORD -h $HOST  $BASE -Bse 'show tables'`
 else
  db=`mysql -u $USER             -h $HOST  $BASE -Bse 'show tables'`
 fi
 
 for n in $db; do
  echo $n
   if  [ -n "$PASSWORD" ]
   then 
    mysqldump -u $USER -h $HOST -p$PASSWORD $BASE $n --extended-insert=FALSE --complete-insert=FALSE > "$DIR$n.sql"
   else
    mysqldump -u $USER -h $HOST             $BASE $n    --opt --skip-dump-date --skip-extended-insert  > "$DIR$n.sql"
   fi
   
  # exclude tables not interesting for version control
  [ "$n" == "b_cache_tag" ]					|| 
  [ "$n" == "b_captcha" ]					|| 
  [ "$n" == "b_form_result" ]				|| 
  [ "$n" == "b_form_result_answer" ]		|| 
  [ "$n" == "b_form_field" ] 				|| 
  [ "$n" == "b_file" ] 						|| 
  [ "$n" == "b_conv_context_counter_day" ] 	|| 
  [ "$n" == "b_catalog_price" ] 			|| 
  [ "$n" == "b_sale_basket" ] 				|| 
  [ "$n" == "b_sale_fuser" ] 				|| 
  # no location list  
  [[ "$n" == b_sale_loc_* ]] 				|| 
  [ "$n" == "b_sale_location" ] 			|| 
  [[ "$n" == b_sale_location_* ]] 			|| 
  # no order activitie  
  [ "$n" == "b_sale_order" ] 				|| 
  [[ "$n" == b_sale_order_* ]] 				||
  # no performance tests  
  [ "$n" == "b_perf_test" ] 				&& 
  continue
    #sleep 1
   # lets format the putput to one insert with multirows per table
   sed ':a;N;$!ba;s/)\;\nINSERT INTO `[A-Za-z0-9$_]*` VALUES /),\n/g' $DIR$n.sql > $DIR"2compare/"$n.sql
   # lets ignore changes in AUTO_INCREMENT 
   sed -i -E 's/AUTO_INCREMENT=[0-9]+/AUTO_INCREMENT=1/g' $DIR"2compare/"$n.sql
   # lets ignore changes in ALL datetime stamps 
   sed -i -E 's/[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}/2013-12-13 13:13:13/g' $DIR"2compare/"$n.sql
   if [ "$n" == "b_option" ]
   then
	# continue 
	 # if line begins with this regexp it will be omitted
     sed -n \
  "/^('main','dump_bucket_id',"\
."\|^('main', 'last_files_count',"\
."/!p" $DIR"2compare/"$n.sql > temp && mv temp $DIR"2compare/"$n.sql
    # 'main' for 'update_system_check' and 'update_system_update' has reversed dates
	sed -i -E "s/'[0-9]{2}.[0-9]{2}.[0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2}'/'12.13.2013 13:13:13'/g" $DIR"2compare/"$n.sql
	# assuming here all 10-digits numerics starting with 1 are system time, replacing them unifically
	sed -i -E "s/'1[0-9]{9}'/'1568123456'/g" $DIR"2compare/"$n.sql
   fi
 done
 else
  echo "No connection params provided"
fi
