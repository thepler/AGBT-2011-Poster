#!/bin/sh

perl -e 'print "month\tgb\n"' > gb-vs-month.txt

#    select x.mydate, sum( x.bases ), sum( x.bases ) / 1000000000 From (
sqlrun "

    select concat(x.mydate,'-01'), sum( x.bases ) / 1000000000 From (
        select to_char(pse.date_completed, 'yyyy-mm') mydate, ri.kilobases_read bases
        from index_illumina ii
        join read_illumina ri on ri.ii_seq_id = ii.seq_id
        join process_step_executions@oltp pse
        on pse.pse_id = ii.creation_event_id
        and pse.date_completed is not null
        and pse.psesta_pse_status in ('inprogress', 'completed')
    ) x
    group by x.mydate
    order by x.mydate

" --instance warehouse --parse >> gb-vs-month.txt;

#        (select pse.* from process_Step_executions pse where pse.ps_ps_id = 3601) gls
#    select o.*, ii.seq_id from
#    (
#        select gls.pse_id, gls.date_completed, sp.seq_id from sequence_pse sp join
#        (select pse.* from process_Step_executions pse join process_steps ps on ps.ps_id = pse.ps_ps_id and ps.pro_process_to = 'generate lane summary') gls
#        on gls.pse_id = sp.pse_id
#    ) o
#    join index_illumina@dw ii
#    on ii.seq_id = o.seq_id
