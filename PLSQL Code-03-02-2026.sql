Implemented advanced PL/SQL collections with autonomous error logging:
========================================================================


create or replace package package_56
as
procedure p_r(p_cursor out sys_refcursor);
type r2 is record (id employees.employee_id%type, nm employees.last_name%type, sal employees.salary%type);
type v2 is table of r2;
type r5 is record (id employees.employee_id%type, nm employees.last_name%type, sal employees.salary%type);
type v5 is table of r5 index by pls_integer; 
type v7 is varray(107) of r5;
function f_r
return v1 pipelined;
procedure p_r1;
procedure p_r2(p_cursor out sys_refcursor);
procedure p_r3(p_cursor out sys_refcursor);
procedure p_r4(p_cursor out sys_refcursor);
procedure p_r5(p_cursor out sys_refcursor);
end package_56;

create or replace package body package_56
is
procedure error_logging
is
pragma autonomous_transaction;
sqlcd varchar2(200);
sqlmsg varchar2(200);
begin
sqlcd := f_exp(sqlcode);
sqlmsg := dbms_utility.format_error_backtrace;
insert into error_tracking(error_type,error_message,timestmp) values(sqlcd,sqlmsg,systimestamp);
commit;
exception
when others then
  rollback;
end error_logging;

procedure p_r(p_cursor out sys_refcursor)
is
r3 r2;
v3 v2 := v2();
begin
open p_cursor for 'select employee_id,last_name,salary from employees';
loop
fetch p_cursor into r3;
exit when p_cursor%notfound;
v3.extend;
v3(v3.count).id := r3.id;
v3(v3.count).nm := r3.nm;
v3(v3.count).sal := r3.sal;
end loop;

for i in 1..v3.count loop
insert into emp_tb1 values(v3(i).id,v3(i).nm,v3(i).sal);
end loop;
close p_cursor;
exception when others then
error_logging;
raise;
end p_r;

function f_r
return v1 pipelined
is
begin
for i in (select employee_id,last_name,salary from employees) loop
pipe row (r(i.employee_id,i.last_name,i.salary));
end loop;
return;
exception when others then
error_logging;
raise;
end f_r;

procedure p_r1
is
begin
for i in (select * from table(f_r)) loop
insert into emp_tb2 values(i.id,i.nm,i.sal);
end loop;
exception when others then
error_logging;
raise;
end p_r1;

procedure p_r2(p_cursor out sys_refcursor)
is
r4 r;
v2 v1:= v1();
v_id int;
v_nm varchar2(100);
v_sal int;
begin
open p_cursor for 'select employee_id,last_name,salary from employees';
loop
fetch p_cursor into v_id,v_nm,v_sal;
exit when p_cursor%notfound;
v2.extend;
v2(v2.count) := r(v_id,v_nm,v_sal);
end loop;
execute immediate 'truncate table nested_tbl2';
insert into nested_tbl2 values(v2);
for i in v2.first..v2.last loop
insert into emp_tb3 values(v2(i).id,v2(i).nm,v2(i).sal);
end loop;
close p_cursor;
exception when others then
error_logging;
raise;
end p_r2;

procedure p_r3(p_cursor out sys_refcursor)
is
v5 v2 := v2();
begin
open p_cursor for 'select employee_id,last_name,salary from employees';
fetch p_cursor bulk collect into v5;
forall i in 1..v5.count save exceptions
insert into emp_tb4 values(v5(i).id,v5(i).nm,v5(i).sal);
close p_cursor;
exception when others then
for j in 1..sql%bulk_exceptions.count loop
dbms_output.put_line(sql%bulk_exceptions(j).error_code||','||sql%bulk_exceptions(j).error_index);
end loop;
error_logging;
raise;
end p_r3;

procedure p_r4(p_cursor out sys_refcursor)
is
v6 v5;
r6 r5;
i pls_integer := 0;
begin
open p_cursor for 'select employee_id,last_name,salary from employees';
loop
fetch p_cursor into r6;
exit when p_cursor%notfound;
i := i+1;
v6(i) := r6;
end loop;
for i in 1..v6.count loop
insert into emp_tb5 values(v6(i).id,v6(i).nm,v6(i).sal);
end loop;
close p_cursor;
exception when others then
error_logging;
raise;
end p_r4;

procedure p_r5(p_cursor out sys_refcursor)
is
v8 v7 := v7();
r7 r5;
begin
open p_cursor for 'select employee_id,last_name,salary from employees';
loop
fetch p_cursor into r7;
exit when p_cursor%notfound;
v8.extend;
v8(v8.count).id := r7.id;
v8(v8.count).nm := r7.nm;
v8(v8.count).sal := r7.sal;
end loop;
for i in 1..v8.count loop
insert into emp_tb6 values(v8(i).id,v8(i).nm,v8(i).sal);
end loop;
close p_cursor;
exception when others then
error_logging;
raise;
end p_r5;

end package_56;
/


declare
p_cursor sys_refcursor;
begin
package_56.p_r(p_cursor);
package_56.p_r1;
package_56.p_r2(p_cursor);
package_56.p_r3(p_cursor);
package_56.p_r4(p_cursor);
package_56.p_r5(p_cursor);
end;
/
select * from error_tracking;
truncate table emp_tb1;
select count(*) from emp_tb1;
truncate table emp_tb2;
select count(*) from emp_tb2;
truncate table emp_tb1;
select count(*) from emp_tb1;
truncate table emp_tb3;
select count(*) from emp_tb3;
truncate table nestedtbl;
select count(*) from nested_tbl2;
truncate table emp_tb4;
select count(*) from emp_tb4;
truncate table emp_tb5;
select count(*) from emp_tb5;
truncate table emp_tb6;
select count(*) from emp_tb6;

select t.id,t.nm,t.sal
from nested_tbl2 u, table(u.emp_store) t
order by t.id desc;

create table emp_tb5 as select * from emp_tb4 where 1=2;
create table emp_tb6 as select * from emp_tb4 where 1=2;