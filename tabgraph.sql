prompt Generating GraphViz script.

-- settings to build graphviz script (.gv)
set timing off feedback off heading off termout off wrap on

spool c:\temp\tmp_tabgraph.gv
select 'graph TabGraph {rankdir=RL;outputMode=nodesfirst;ratio=fill;edge[fontname=Arial,fontsize=8];node[shape=rectangle,fontname=Arial,fontsize=8];' from dual
union all
-- relationship formatting
select distinct table_fk || ' -- ' || table_pk || ' [dir=forward];'
from (-- relationships
      select distinct
             n.table_name as table_fk
           , u.table_name as table_pk
      from user_constraints n, user_cons_columns u
      where n.r_constraint_name = u.constraint_name
        and n.constraint_type = 'R'
        and regexp_like(n.table_name, upper('&&1'))
     )
union all
-- table formatting
select (case
          when col_first = 'Y'
          then table_name
              || '[shape=plaintext,margin=0,label=<<table border="1" cellborder="0" cellspacing="0" cellpadding="4">'
              || '<tr><td colspan="2" bgcolor="#c0c0c0"><b>' || table_name || '</b></td></tr><hr/>'
          else null
        end)
    || '<tr><td>' || nvl(col_keys, chr(38)||'nbsp;') || '</td><vr/>'
    || '<td align="left">'
    || decode(col_required,'Y','<b>','')
    || decode(col_primary,'Y','<u>','')
    || lower(col_name)
    || decode(col_primary,'Y','</u>','')
    || decode(col_required,'Y','</b>','')
    || '<font color="#c0c0c0"><i>' || lower(col_type) || '</i></font>'
    || '</td></tr>'
    || (case
          when col_last = 'Y'
          then '</table>>];'
          else null
        end)
from (-- tables/columns/keys
      select t.table_name as table_name
           , c.column_id as col_order
           , c.column_name as col_name
           , decode(c.nullable, 'N', 'Y', 'N') as col_required
           , case when k.keys like '%PK%' then 'Y' else 'N' end as col_primary
           , c.data_type
             || (case
                   when c.data_type in ('CHAR','VARCHAR2','NCHAR','NVARCHAR2') then '(' || c.data_length || ')'
                   when c.data_type in ('NUMBER') and c.data_scale > 0 then '(' || c.data_precision || ',' || c.data_scale || ')'
                   when c.data_type in ('NUMBER') and c.data_precision is not null then '(' || c.data_precision || ')'
                   else null
                 end) as col_type
           , k.keys as col_keys
           , (case when c.column_id = min(c.column_id) over (partition by c.table_name) then 'Y' else 'N' end) col_first
           , (case when c.column_id = max(c.column_id) over (partition by c.table_name) then 'Y' else 'N' end) col_last
      from user_tables t
         , user_tab_columns c
         , ( select owner
                  , table_name
                  , column_name
                  , listagg(regexp_replace(constraint_name, '.*_(PK|FK[0-9]+)$', '\1'), ',')
                    within group (order by replace(regexp_replace(constraint_name, '.*_(PK|FK[0-9]+)$', '\1'), 'PK', 'FK0')) as keys
             from user_cons_columns
             where regexp_like(constraint_name, '(_PK|_FK[0-9]+)$')
             group by owner, table_name, column_name ) k
      where t.table_name = c.table_name
        and c.table_name = k.table_name (+)
        and c.column_name = k.column_name (+)
        and nvl(k.owner, user) = user
        and regexp_like(c.table_name, upper('&&1'))
      order by table_name, col_order
      )
union all
-- footer
select '}' from dual;

spool off;

-- reset after script
set timing on feedback on heading on termout on wrap off

prompt Generating diagram.
-- generate .svg from script
$V:\Portable\Programas\Graphviz\bin\dot.exe C:\Temp\tmp_tabgraph.gv -oC:\Temp\tmp_tabgraph.svg -Tsvg -Goverlap=false -Gcharset=latin1

-- open in default browser/viewer
$start C:\Temp\tmp_tabgraph.svg

undef 1
