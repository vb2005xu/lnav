#! /bin/bash

lnav_test="${top_builddir}/src/lnav-test"


run_test ${lnav_test} -n \
    -c ";select * from access_log" \
    -c ':write-csv-to -' \
    ${test_dir}/logfile_access_log.0

check_output "access_log table is not working" <<EOF
log_line,log_part,log_time,log_idle_msecs,log_level,log_mark,c_ip,cs_method,cs_referer,cs_uri_query,cs_uri_stem,cs_user_agent,cs_username,cs_version,sc_bytes,sc_status
0,p.0,2009-07-20 22:59:26.000,0,info,0,192.168.202.254,GET,-,<NULL>,/vmw/cgi/tramp,gPXE/0.9.7,-,HTTP/1.0,134,200
1,p.0,2009-07-20 22:59:29.000,3000,error,0,192.168.202.254,GET,-,<NULL>,/vmw/vSphere/default/vmkboot.gz,gPXE/0.9.7,-,HTTP/1.0,46210,404
2,p.0,2009-07-20 22:59:29.000,0,info,0,192.168.202.254,GET,-,<NULL>,/vmw/vSphere/default/vmkernel.gz,gPXE/0.9.7,-,HTTP/1.0,78929,200
EOF


run_test ${lnav_test} -n \
    -c ";select * from access_log where log_level >= 'warning'" \
    -c ':write-csv-to -' \
    ${test_dir}/logfile_access_log.0

check_output "loglevel collator is not working" <<EOF
log_line,log_part,log_time,log_idle_msecs,log_level,log_mark,c_ip,cs_method,cs_referer,cs_uri_query,cs_uri_stem,cs_user_agent,cs_username,cs_version,sc_bytes,sc_status
1,p.0,2009-07-20 22:59:29.000,3000,error,0,192.168.202.254,GET,-,<NULL>,/vmw/vSphere/default/vmkboot.gz,gPXE/0.9.7,-,HTTP/1.0,46210,404
EOF


# XXX The timestamp on the file is used to determine the year for syslog files.
touch -t 201311030923 ${test_dir}/logfile_syslog.0
run_test ${lnav_test} -n \
    -c ";select * from syslog_log" \
    -c ':write-csv-to -' \
    ${test_dir}/logfile_syslog.0

check_output "syslog_log table is not working" <<EOF
log_line,log_part,log_time,log_idle_msecs,log_level,log_mark,log_hostname,log_pid,log_procname
0,p.0,2013-11-03 09:23:38.000,0,error,0,veridian,7998,automount
1,p.0,2013-11-03 09:23:38.000,0,info,0,veridian,16442,automount
2,p.0,2013-11-03 09:23:38.000,0,error,0,veridian,7999,automount
3,p.0,2013-11-03 09:47:02.000,1404000,info,0,veridian,<NULL>,sudo
EOF


run_test ${lnav_test} -n \
    -c ";select * from syslog_log where log_time >= datetime('2013-11-03T09:47:02.000')" \
    -c ':write-csv-to -' \
    ${test_dir}/logfile_syslog.0

check_output "log_time collation is wrong" <<EOF
log_line,log_part,log_time,log_idle_msecs,log_level,log_mark,log_hostname,log_pid,log_procname
3,p.0,2013-11-03 09:47:02.000,1404000,info,0,veridian,<NULL>,sudo
EOF


run_test ${lnav_test} -n \
    -c ':filter-in sudo' \
    -c ";select * from logline" \
    -c ':write-csv-to -' \
    ${test_dir}/logfile_syslog.0

check_output "logline table is not working" <<EOF
log_line,log_part,log_time,log_idle_msecs,log_level,log_mark,log_hostname,log_pid,log_procname,col_0,TTY,PWD,USER,COMMAND
0,p.0,2013-11-03 09:47:02.000,0,info,0,veridian,<NULL>,sudo,timstack,pts/6,/auto/wstimstack/rpms/lbuild/test,root,/usr/bin/tail /var/log/messages
EOF


run_test ${lnav_test} -n \
    -c ";update access_log set log_mark = 1 where sc_bytes > 60000" \
    -c ':write-to -' \
    ${test_dir}/logfile_access_log.0

check_output "setting log_mark is not working" <<EOF
192.168.202.254 - - [20/Jul/2009:22:59:29 +0000] "GET /vmw/vSphere/default/vmkernel.gz HTTP/1.0" 200 78929 "-" "gPXE/0.9.7"
EOF


export SQL_ENV_VALUE="foo bar,baz"

run_test ${lnav_test} -n \
    -c ';select $SQL_ENV_VALUE as val' \
    -c ':write-csv-to -' \
    ${test_dir}/logfile_access_log.0

check_output "env vars are not working in SQL" <<EOF
val
"foo bar,baz"
EOF


schema_dump() {
    ${lnav_test} -n -c ';.schema' ${test_dir}/logfile_access_log.0 | head -n7
}

run_test schema_dump

check_output "schema view is not working" <<EOF
ATTACH DATABASE '' AS 'main';
CREATE TABLE http_status_codes (
    status integer PRIMARY KEY,
    message text,

    FOREIGN KEY(status) REFERENCES access_log(sc_status)
);
EOF


run_test ${lnav_test} -n \
    -c ";select * from nonexistent_table" \
    ${test_dir}/logfile_access_log.0

check_error_output "errors are not reported" <<EOF
error: no such table: nonexistent_table
EOF

check_output "errors are not reported" <<EOF
EOF


run_test ${lnav_test} -n \
    -c ";delete from access_log" \
    ${test_dir}/logfile_access_log.0

check_error_output "errors are not reported" <<EOF
error: attempt to write a readonly database
EOF

check_output "errors are not reported" <<EOF
EOF


run_test ${lnav_test} -n \
    -c ":goto 1" \
    -c ":partition-name middle" \
    -c ";select * from access_log" \
    -c ":write-csv-to -" \
    ${test_dir}/logfile_access_log.0

check_output "partition-name does not work" <<EOF
log_line,log_part,log_time,log_idle_msecs,log_level,log_mark,c_ip,cs_method,cs_referer,cs_uri_query,cs_uri_stem,cs_user_agent,cs_username,cs_version,sc_bytes,sc_status
0,p.0,2009-07-20 22:59:26.000,0,info,0,192.168.202.254,GET,-,<NULL>,/vmw/cgi/tramp,gPXE/0.9.7,-,HTTP/1.0,134,200
1,middle,2009-07-20 22:59:29.000,3000,error,0,192.168.202.254,GET,-,<NULL>,/vmw/vSphere/default/vmkboot.gz,gPXE/0.9.7,-,HTTP/1.0,46210,404
2,middle,2009-07-20 22:59:29.000,0,info,0,192.168.202.254,GET,-,<NULL>,/vmw/vSphere/default/vmkernel.gz,gPXE/0.9.7,-,HTTP/1.0,78929,200
EOF


run_test ${lnav_test} -n \
    -c ":goto 1" \
    -c ":partition-name middle" \
    -c ":clear-partition" \
    -c ";select * from access_log" \
    -c ":write-csv-to -" \
    ${test_dir}/logfile_access_log.0

check_output "clear-partition does not work" <<EOF
log_line,log_part,log_time,log_idle_msecs,log_level,log_mark,c_ip,cs_method,cs_referer,cs_uri_query,cs_uri_stem,cs_user_agent,cs_username,cs_version,sc_bytes,sc_status
0,p.0,2009-07-20 22:59:26.000,0,info,0,192.168.202.254,GET,-,<NULL>,/vmw/cgi/tramp,gPXE/0.9.7,-,HTTP/1.0,134,200
1,p.0,2009-07-20 22:59:29.000,3000,error,0,192.168.202.254,GET,-,<NULL>,/vmw/vSphere/default/vmkboot.gz,gPXE/0.9.7,-,HTTP/1.0,46210,404
2,p.0,2009-07-20 22:59:29.000,0,info,0,192.168.202.254,GET,-,<NULL>,/vmw/vSphere/default/vmkernel.gz,gPXE/0.9.7,-,HTTP/1.0,78929,200
EOF

run_test ${lnav_test} -n \
    -c ":goto 1" \
    -c ":partition-name middle" \
    -c ":goto 2" \
    -c ":clear-partition" \
    -c ";select * from access_log" \
    -c ":write-csv-to -" \
    ${test_dir}/logfile_access_log.0

check_output "clear-partition does not work when in the middle of a part" <<EOF
log_line,log_part,log_time,log_idle_msecs,log_level,log_mark,c_ip,cs_method,cs_referer,cs_uri_query,cs_uri_stem,cs_user_agent,cs_username,cs_version,sc_bytes,sc_status
0,p.0,2009-07-20 22:59:26.000,0,info,0,192.168.202.254,GET,-,<NULL>,/vmw/cgi/tramp,gPXE/0.9.7,-,HTTP/1.0,134,200
1,p.0,2009-07-20 22:59:29.000,3000,error,0,192.168.202.254,GET,-,<NULL>,/vmw/vSphere/default/vmkboot.gz,gPXE/0.9.7,-,HTTP/1.0,46210,404
2,p.0,2009-07-20 22:59:29.000,0,info,0,192.168.202.254,GET,-,<NULL>,/vmw/vSphere/default/vmkernel.gz,gPXE/0.9.7,-,HTTP/1.0,78929,200
EOF
