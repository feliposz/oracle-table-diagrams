prompt Generating GraphViz script...

-- settings to build graphviz script (.gv)
set timing off feedback off heading off termout off wrap on

spool c:\temp\tmp_tabgraph.gv
select 'graph TabGraph {rankdir=LR;ratio=fill;edge[fontname=Consolas,fontsize=8];node[shape=record,fontname=Consolas,fontsize=8];' from dual -- header
union all
-- relationships
select distinct uc.table_name
             || ' -- ' || ucc.table_name
             || ' [dir=forward];'
from user_constraints uc, user_cons_columns ucc
where uc.r_constraint_name = ucc.constraint_name
  and uc.constraint_type = 'R'
  and regexp_like(uc.table_name, upper('&&1'))
union all
-- columns
select ut.table_name
    || ' [label=<<b>' || ut.table_name || '</b>|<table border="0">'
    || listagg('<tr><td>' || nvl(k.keys, chr(38)||'nbsp;') || '</td>'
               || '<td align="left">' || decode(utc.nullable,'N','<b>','')
               || lower(utc.column_name) || decode(utc.nullable, 'N','</b>','') || '</td></tr>', chr(10))
       within group (order by utc.column_id)
    || '</table>>];'
from user_tables ut
   , user_tab_columns utc
   , ( select owner
            , table_name
            , column_name
            , listagg(regexp_replace(constraint_name, '.*_(PK|FK[0-9])$', '\1'), ',')
              within group (order by replace(regexp_replace(constraint_name, '.*_(PK|FK[0-9])$', '\1'), 'PK', 'FK0')) as keys
       from user_cons_columns
       where regexp_like(constraint_name, '(_PK|_FK[0-9]+)$')
       group by owner, table_name, column_name ) k
where ut.table_name = utc.table_name
  and utc.table_name = k.table_name (+)
  and utc.column_name = k.column_name (+)
  and nvl(k.owner, user) = user
  and regexp_like(utc.table_name, upper('&&1'))
group by ut.table_name
union all
-- footer
select '}' from dual;

spool off

-- reset after script
set timing on feedback on heading on termout on wrap off

prompt Generating diagram
-- generate .svg from script
$V:\Portable\Programas\Graphviz\bin\dot.exe C:\Temp\tmp_tabgraph.gv -oC:\Temp\tmp_tabgraph.svg -Tsvg -Goverlap=false

-- open in default browser/viewer
$start C:\Temp\tmp_tabgraph.svg

undef 1
