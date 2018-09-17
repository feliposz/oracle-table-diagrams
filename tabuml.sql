prompt Generating PlantUML script.

-- settings to build PlantUML script (.uml)
set timing off feedback off heading off termout off wrap on

spool c:\temp\tmp_tabuml.uml
select '@startuml' from dual union all
select '!define Table(name,desc) class name as "desc" << (T,#FFAAAA) >>' from dual union all
select '!define primary_key(x) <b>x</b>' from dual union all
select '!define unique(x) <color:green>x</color>' from dual union all
select '!define not_null(x) <u>x</u>' from dual union all
select 'hide methods' from dual union all
select 'hide stereotypes' from dual union all
-- table formatting
select (case
          when col_first = 'Y'
          then 'Table(' || table_name || ', ' || table_name || ') {' || chr(10)
          else null
        end)
    --|| nvl(col_keys, chr(38)||'nbsp;')
    || '{field} '
    || decode(col_required,'Y','not_null(','')
    || decode(col_primary,'Y','primary_key(','')
    || lower(col_name)
    || decode(col_primary,'Y',')','')
    || decode(col_required,'Y',')','')
    || ': ' || lower(col_type)
    || (case
          when col_last = 'Y'
          then chr(10) || '}'
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
-- non-filtered table formatting
select distinct 'Table(' || table_pk || ', ' || table_pk || ') {' || chr(10) || '}'
from (-- relationships
      select distinct u.table_name as table_pk
      from user_constraints n, user_cons_columns u
      where n.r_constraint_name = u.constraint_name
        and n.constraint_type = 'R'
        and regexp_like(n.table_name, upper('&&1'))
        and not regexp_like(u.table_name, upper('&&1'))
     )
union all
-- relationship formatting
select distinct table_fk || ' --> ' || table_pk
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
-- footer
select '@enduml' from dual;

spool off;

-- reset after script
set timing on feedback on heading on termout on wrap off

prompt Generating diagram.
-- generate .svg from script
$java -jar V:\Portable\Programas\PlantUML\plantuml.jar C:\Temp\tmp_tabuml.uml -oC:\Temp\ -tsvg

-- open in default browser/viewer
$start C:\Temp\tmp_tabuml.svg

undef 1
