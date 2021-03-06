#!/gsc/bin/perl

use warnings FATAL => 'all';
use strict;
use GSCApp;
App->init;

use Path::Class;

sub all_runs {
    my @r = GSC::FlowCellIllumina->get();
    my @x = GSC::Equipment::Solexa::Run->get();
#    my @r = GSC::FlowCellIllumina->get('flow_cell_id' => '11846');
#    return grep {$_} map { $_->get_solexa_run or warn $_->flow_cell_id } @r;
    return grep {$_} map { $_->get_solexa_run } @r;
}

sub _is_ads {
    my $pse = shift;
    return 0 if $pse->process_to ne 'allocate disk space';
    return 0 if $pse->pse_status eq 'abandoned';
    return 0 if $pse->pse_status eq 'expunged';
    return 1;
}

sub get_ads {
    my $r = shift or die;
    my $pse = $r->get_creation_event
        or die 'no creation event for ' . $r->flow_cell_id;
    my @ads = grep { _is_ads($_) } $pse->get_subsequent_pses;
    ( @ads <= 1 ) or die 'too many ads';
    if ( !@ads ) {
        my @next = $pse->get_subsequent_pses
            or die 'no next for ' . $pse->pse_id;
        ( @next == 1 ) or die 'more than 1 next for ' . $pse->pse_id;
        @ads = grep { _is_ads($_) } $next[0]->get_subsequent_pses;
    }
    ( @ads == 1 ) or die $pse->pse_id;
    return $ads[0];
}

#my @r = all_runs();
#for my $r (@r) {
#    my $main_ads = get_ads($r) or die 'no ads for ' . $r->flow_cell_id;
#}

sub analysis_start_date {
    my $self = shift;

    return '2007-08-29 11:40:19' if ( $self->flow_cell_id eq '10167' );
#    return '2008-04-02 09:26:53' if ( $self->flow_cell_id eq '11846' );

    my @pse = $self->get_pses(
        'process_to' => 'configure run analysis',
        'pse_status' => [qw(inprogress completed)]
    );
    ( @pse <= 1 ) or die $self->flow_cell_id;
    if (@pse) {
        $pse[0]->date_completed
            or die $self->flow_cell_id . ' no date completed';
        return $pse[0]->date_completed;
    }
    @pse = $self->get_pses(
        'process_to' => 'configure image analysis and base call',
        'pse_status' => [qw(inprogress completed)]
    ) or die $self->flow_cell_id;
    ( @pse <= 1 ) or die $self->flow_cell_id;
#    $pse[0]->date_scheduled or die $self->flow_cell_id . ' no date scheduled';
#    return $pse[0]->date_scheduled;
    if (@pse) {
        $pse[0]->date_completed
            or die $self->flow_cell_id . ' no date completed';
        return $pse[0]->date_completed;
    }
    die $self->flow_cell_id;
}

sub analysis_end_date {
    my $self = shift;

    return if $self->flow_cell_id eq '3230';
    return '2007-08-01 12:51:54' if $self->flow_cell_id eq '9133';

    my @pse = $self->get_pses(
        'process_to' => 'analysis completed',
        'pse_status' => [qw(inprogress completed)]
    );
    @pse or return;
#    (@pse == 1) or die $self->flow_cell_id;
    if (@pse > 1 && $self->flow_cell_id ne '42EG6') {
        die $self->flow_cell_id;
    }
    for (@pse) {
        return if( $_->pse_status eq 'wait');
    }
#    $pse[0]->date_completed or die $self->flow_cell_id;
#    return $pse[0]->date_completed;
    
    my $max_date = sub {
        @_ or die;
        my @sorted = sort { App::Time->compare_dates($b, $a) } @_;
        return $sorted[0];
    };
    my $date = sub {
        (@_ == 1) or die;
        if (!$_[0]->date_completed) {
            ($_[0]->pse_status eq 'inprogress') or die $_[0]->pse_id;
            $_[0]->date_scheduled or die;
            return $_[0]->date_scheduled;
        }
        return $_[0]->date_completed;
    };

    my @ii = $self->get_index_illumina or return;
    @pse = map { $_->get_creation_event } @ii;
    @pse = GSC::PSE->get(
        'pse_id'     => \@pse,
        'pse_status' => [qw(inprogress completed)],
    );
    if (@pse == 0 && $self->flow_cell_id eq '11271') {
        @pse = $self->get_pses(
            'process_to' => 'run alignment',
            'pse_status' => [qw(inprogress completed)]
        );
    }
    @pse or die $self->flow_cell_id;

#    @pse = $self->get_pses(
#        'process_to' => 'copy sequence files',
#        'pse_status' => [qw(inprogress completed)]
#    );
    if (@pse) {
        return $max_date->( map { $date->($_) } @pse );
    }
    @pse = $self->get_pses(
        'process_to' => 'generate lane summary',
        'pse_status' => [qw(inprogress completed)]
    );
    if (@pse) {
        return $max_date->( map { $date->($_) } @pse );
    }
    @pse = $self->get_pses(
        'process_to' => 'run alignment',
        'pse_status' => [qw(inprogress completed)]
    );
    if (@pse) {
        return $max_date->( map { $date->($_) } @pse );
    }
    # deal with not yet done runs
    return if ($self->get_creation_event->date_scheduled =~ /^2011/);
    die $self->flow_cell_id;
}

use IO::Handle;
my $fh1 = file('./run-start-end-dates.txt')->openw;
my $filtered_fh = file('./run-start-end-dates-filtered.txt')->openw;
my @r = all_runs();
#{ my @x = GSC::SolexaRunPSE->get(); }
my @start_run = map {
    my $d = analysis_start_date($_)
        or die $_->flow_cell_id;
#    analysis_end_date($_);
    [ $d, $_ ];
} @r;
@start_run = sort { $a->[0] cmp $b->[0] } @start_run;
for my $sr (@start_run) {
    my $r = $sr->[1] or die;
    next if $r->flow_cell_id eq '3230';
    next if $r->flow_cell_id eq '3033';
    my $end = analysis_end_date($r) or next;
    my $start = $sr->[0] or die;
    my $diff = App::Time->timediff($start, $end);
    my $fc = $r->flow_cell_id or die;
#    ($diff > 0) or die 'negative diff ' . $r->flow_cell_id;
    # in days
    $diff = $diff / (60 * 60 * 24);
    if ( $diff < 0.1 or $diff > 20 ) {
        $filtered_fh->print("$start $end $diff ($fc)\n");
        next;
    }
    $fh1->print("$start $end $diff ($fc)\n");
#    print analysis_start_date($r) . " ";
#    print( (analysis_end_date($r) || '<still running>') . "\n");
}
$fh1->close or die;
$filtered_fh->close or die;

$fh1 = file('./run-start-end-dates.txt')->openr;
my %month;

# get the same time frame as gb-vs-month.txt
$month{$_} = []
    for (
        qw(2006-12 2007-01 2007-02 2007-03 2007-04 2007-05 2007-06 2007-07 2007-08)
    );

while ( scalar( my $line  = $fh1->getline)) {
    chomp $line;
    my ($start, $end, $diff, $fc) = split(/\t/, $line);
    my $month = ( $start =~ /(^\d\d\d\d-\d\d).*/ )[0] or die;
    $month{$month} ||= [];
    push @{ $month{$month} }, $diff;
}

my $fh2 = file('./days-vs-month.txt')->openw or die;
$fh2->print("Month\tDays\n");
use List::AllUtils qw(sum);
for my $mon ( sort keys %month ) {
    my @all = @{ $month{$mon} };
    my $avg = sum(@all) / scalar(@all);
    $mon .= '-15';  # to make my R happy
    $fh2->print("$mon\t$avg\n");
}
$fh2->close or die;


