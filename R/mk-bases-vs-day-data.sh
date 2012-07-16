#!/bin/sh

perl -e 'print "day\tbases\n"' > bases-vs-day.txt

#    select x.mydate, sum( x.bases ), sum( x.bases ) / 1000000000 From (
sqlrun "

    select x.mydate, sum( x.bases ) From (
        select to_char(bi.date_completed, 'yyyy-mm-dd') mydate, (ri.read_length * ii.filt_clusters) bases
        from index_illumina ii
        join read_illumina ri on ri.ii_seq_id = ii.seq_id
        join basecall_illumina bi
            on bi.flow_cell_id = ii.flow_cell_id
            and bi.lane = ii.lane
            and (
                (bi.index_sequence = ii.index_sequence)
                or
                (bi.index_sequence is null and ii.index_sequence is null)
            )
            and bi.date_completed is not null
--        where ii.flow_cell_id = '615HF'
    ) x
    group by x.mydate
    order by x.mydate

" --instance warehouse --parse >> bases-vs-day.txt;

#        (select pse.* from process_Step_executions pse where pse.ps_ps_id = 3601) gls
#    select o.*, ii.seq_id from
#    (
#        select gls.pse_id, gls.date_completed, sp.seq_id from sequence_pse sp join
#        (select pse.* from process_Step_executions pse join process_steps ps on ps.ps_id = pse.ps_ps_id and ps.pro_process_to = 'generate lane summary') gls
#        on gls.pse_id = sp.pse_id
#    ) o
#    join index_illumina@dw ii
#    on ii.seq_id = o.seq_id
