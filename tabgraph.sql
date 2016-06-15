-- settings to build graphviz script (.gv)
set timing off feedback off heading off termout off

spool c:\temp\tmp_tabgraph.gv
select 'digraph TabGraph {rankdir=LR;ratio=fill;node[shape=record];' from dual -- header
union all
-- relationships
select distinct uc.table_name || ':<'||pkc.column_name||'>'
             || ' -> ' || pkc.table_name || ':<'||fkc.column_name||'>'
             || ' [label="' || lower(uc.constraint_name) || '"];'
from user_constraints uc, user_cons_columns pkc, user_cons_columns fkc
where uc.r_constraint_name = pkc.constraint_name
  and uc.r_constraint_name = fkc.constraint_name
  and uc.constraint_type = 'R'
  and regexp_like(uc.table_name, upper('&&1'))
  and pkc.position = 1
  and fkc.position = 1
union all
-- columns
select ut.table_name
    || ' [label="' || ut.table_name || '|'
    || listagg('<' || utc.column_name || '> ' || lower(utc.column_name), '|') within group (order by utc.column_id) || '"];'
from user_tables ut, user_tab_columns utc, user_cons_columns ucc
where ut.table_name = utc.table_name
  and utc.table_name = ucc.table_name (+)
  and utc.column_name = ucc.column_name (+)
  and nvl(ucc.position, 1) = 1
  and regexp_like(utc.table_name, upper('&&1'))
group by ut.table_name
union all
-- footer
select '}' from dual;

spool off

-- reset after script
set timing on feedback on heading on termout on

-- generate .svg from script
$V:\Portable\Programas\Graphviz\bin\dot.exe C:\Temp\tmp_tabgraph.gv -oC:\Temp\tmp_tabgraph.svg -Tsvg

-- open in default browser/viewer
$start C:\Temp\tmp_tabgraph.svg

undef 1
