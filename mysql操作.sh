




desc history ;
查history表中第一条数据的tiemid值（asc正序）
select * from history order by  itemid asc  limit 1;
倒序排（desc函数）
select * from history_uint order by clock desc limit 1;
查history表中第一条数据的时间戳clock值
select * from history order by clock asc limit 1;
select * from expressions where expressionid='67569';
SELECT TABLE_NAME AS "Table", round(((data_length + index_length) / 1024 /1024), 2) AS Size_in_MB FROM information_schema.TABLES  WHERE table_schema = 'zabbix' ORDER BY Size_in_MB DESC LIMIT 10;

1 统计每个表所占用的空间
空间占用前十：
SELECT TABLE_NAME AS "Table", round(((data_length + index_length) / 1024 /1024), 2) AS Size_in_MB FROM information_schema.TABLES  WHERE table_schema = 'zabbix' ORDER BY Size_in_MB DESC LIMIT 10;
所有的表空间占用情况：
SELECT table_name AS "Tables",round(((data_length + index_length) / 1024 / 1024), 2) "Size in MB" FROM information_schema.TABLES  WHERE table_schema = 'zabbix' ORDER BY (data_length + index_length) DESC;
2 清理zabbix180天以前的历史数据：
#!/bin/bash
User="root"
Passwd="2wsx%RDX"
Date=`date -d $(date -d "-90 day" +%Y%m%d) +%s` #取90天之前的时间戳
$(which mysql) -u${User} -p${Passwd} -e "
use zabbix;
DELETE FROM history WHERE 'clock' < $Date;
optimize table history;
DELETE FROM history_str WHERE 'clock' < $Date;
optimize table history_str;
DELETE FROM history_uint WHERE 'clock' < $Date;
optimize table history_uint;
DELETE FROM history_text WHERE 'clock' < $Date;
optimize table history_text;
DELETE FROM  trends WHERE 'clock' < $Date;
optimize table  trends;
DELETE FROM trends_uint WHERE 'clock' < $Date;
optimize table trends_uint;
DELETE FROM events WHERE 'clock' < $Date;
optimize table events;
"
3、添加到系统计划任务：

#remove the zabbix mysql data before 7 day's ago
0 3 * * 0 /usr/local/script/clearzabbix.sh > /usr/local/script/clearzabbix.log
 

另：可以使用truncate命令直接清空数据库：


truncate table history;
truncate table history_uint;
truncate table history_str;
truncate table history_text;
truncate table trends;
truncate table trends_uint;
truncate table events;
如果想要删除表的所有数据，truncate语句要比 delete 语句快。

因为 truncate 删除了表，然后根据表结构重新建立它，而 delete 删除的是记录，并没有尝试去修改表。

不过truncate命令虽然快，却不像delete命令那样对事务处理是安全的。

因此，如果我们想要执行truncate删除的表正在进行事务处理，这个命令就会产生退出并产生错误信息。 




clock=1494777600
for i in `cat clock.sh`;do DELETE FROM history WHERE 'clock' < $i;done
DELETE FROM history WHERE 'clock' < 1536997826;

















SELECT TABLE_NAME AS "Table", round(((data_length + index_length) / 1024 /1024), 2) AS Size_in_MB FROM information_schema.TABLES  WHERE table_schema = 'zabbix' ORDER BY Size_in_MB DESC LIMIT 10;
+--------------------+------------+
| Table              | Size_in_MB |
+--------------------+------------+
| history_uint       |   60919.11 |
| history            |   38291.17 |
| trends_uint        |    3740.20 |
| trends             |    2195.08 |
| history_str        |     613.42 |
| events             |     495.58 |
| alerts             |     194.41 |
| event_recovery     |      63.72 |
| items              |      53.20 |
| items_applications |      14.48 |
+--------------------+------------+
10 rows in set (2.73 sec)