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
    ) x
    group by x.mydate
    order by x.mydate

" --instance warehouse --parse >> bases-vs-day.txt;

