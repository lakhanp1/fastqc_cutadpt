use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;


BEGIN{
	use File::Basename qw(dirname);
	my $scriptPath = dirname(__FILE__);
	push(@INC, $scriptPath);
}

use quality_checking qw(fastQc qualityTrimming);



my %options = ('fastqc' => 1, 'fastqcOut' => "fastqc", 'trimmedOut' => "fastq_trimmed");
$options{'adapters'} = dirname(__FILE__).'/data/universal_adapters.fasta';

GetOptions(\%options, '1=s', '2=s', 'fastqc!', 'adapters=s', 'fastqcOut=s', 'trimmedOut=s', 'help|h') or die("Error in command line arguments\n");


if($options{'help'} || $options{'h'}){
	&pod2usage({EXIT => 2, VERBOSE => 2});
}

if(!$options{'1'}){
	print STDERR "Error: Please provide the FASTQ file for the analysis\n";
	&pod2usage({EXIT => 2, VERBOSE => 0});
}

if(!$options{'fastqcOut'}){
	print STDERR "Error: Please provide the output directory for storing FastQC-CutAdapt output\n";
	&pod2usage({EXIT => 2, VERBOSE => 0});
}


$options{'lib'} = 'SE';
my $fqcIn = $options{1};

if(defined $options{2}){
	$fqcIn .= " ".$options{2};
	$options{'lib'} = 'PE';
}

# can skip FastQC if user provided --nofastqc option
if($options{'fastqc'}){
	my $fqcDone = &fastQc($fqcIn, $options{'fastqcOut'});
}
else{
	print "## Skipping first round of FastQC and using existing FastQC results from path: ", $options{'fastqcOut'},"\n";
}

my $cutAdaptDone = &qualityTrimming(\%options, $options{'fastqcOut'}, $options{'trimmedOut'});


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

This script runs FastQC, detects the overrepresented sequences from FastQC report and trims the sequences using cutadapt
tool. FastQC is run again on the trimmed fastq files for comparison.


=head1 OPTIONS

=over 30

=item B<-1>

[STR] R1 FASTQ file

=item B<-2>

[STR] R2 FASTQ file

=item B<--nofastqc>

[FLAG] First round of FastQC is skipped and FastQC result is read directly from
--fastqcOut option.

=item B<--adapters>

[STR] FASTA file with Illumina adapters. Default: data/universal_adapters.fasta

=item B<--fastqcOut>

[STR] Directory to store the FastQc result. Make sure that the directory exists.

=item B<--trimmedOut>

[STR] Path to store trimmed FASTQ files

=item B<--help>

Show this scripts help information.

=back


=cut






