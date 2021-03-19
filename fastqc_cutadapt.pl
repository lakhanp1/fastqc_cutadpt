BEGIN{
	use File::Basename qw(dirname);
	my $scriptPath = dirname(__FILE__);
	push(@INC, $scriptPath);
}

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

use quality_checking qw(fastQc qualityTrimming);


my %options = ('fastqcOut' => "fastqc", 'trimmedOut' => "fastq_trimmed");

GetOptions(\%options, '1=s', '2=s', 'fastqcOut=s', 'trimmedOut=s', 'help|h') or die("Error in command line arguments\n");


if($options{'help'} || $options{'h'}){
	&pod2usage({EXIT => 2, VERBOSE => 2});
}

if(!$options{'1'}){
	print STDERR "Error: Please provide the FASTQ file for the analysis\n";
	&pod2usage({EXIT => 2, VERBOSE => 0});
}

# if(!$options{'fastqcOut'}){
	# print STDERR "Error: Please provide the output directory for storing FastQC-CutAdapt output\n";
	# &pod2usage({EXIT => 2, VERBOSE => 0});
# }


$options{'lib'} = 'SE';
my $fqcIn = $options{1};

if(defined $options{2}){
	print "***";
	$fqcIn .= " ".$options{2};
	$options{'lib'} = 'PE';
}


my $fqcDone = &fastQc($fqcIn, $options{'fastqcOut'});

my $cutAdaptDone = &qualityTrimming(\%options, $options{'fastqcOut'});


if($cutAdaptDone){
	print "CutAdapt Trimming done...\n";
}






















__END__


=head1 NAME


=head1 SYNOPSIS

perl -I <Code dir Path> /complete/path/to/fqstqcCutadapt.pl -1 <R1.fastq> -2 <R2.fastq> --fastqcOut <FastQC/Out/Dir>

Help Options:

	--help	Show this scripts help information.

=head1 DESCRIPTION

ChIP-Seq pipeline: This script performs ChIP-Seq data analysis from start to end. Below are the steps performed:

1) FastQC
2) Adapter Trimming


=head1 OPTIONS

=over 30

=item B<-1>

[STR] R1 FASTQ file

=item B<-2>

[STR] R2 FASTQ file

=item B<--fastqcOut>

[STR] Directory to store the FastQc result. Make sure that the directory exists.

=item B<--trimmedOut>

[STR] Path to store trimmed FASTQ files

=item B<--help>

Show this scripts help information.

=back


=cut






